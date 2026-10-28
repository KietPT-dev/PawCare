package com.pawcare.publicapi.marketplace;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.math.BigDecimal;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class MarketplaceController {
    private final JdbcTemplate db;
    public MarketplaceController(JdbcTemplate db) { this.db = db; }

    // Public catalogue --------------------------------------------------------
    @GetMapping("/providers")
    public List<Map<String,Object>> providers(@RequestParam(required=false) String status) {
        String s = status == null ? "APPROVED" : status;
        return db.queryForList("SELECT id,name,provider_type,phone,email,address,service_area,description,average_rating FROM providers WHERE status=? AND is_active=1 ORDER BY id DESC", s);
    }
    @GetMapping("/categories")
    public List<Map<String,Object>> categories() {
        return db.queryForList("SELECT id,name,description FROM service_categories WHERE is_active=1 ORDER BY name");
    }
    @GetMapping("/services")
    public List<Map<String,Object>> services(@RequestParam(required=false) Long providerId) {
        if (providerId == null) return db.queryForList("SELECT s.*,p.name provider_name,c.name category_name FROM services s JOIN providers p ON p.id=s.provider_id JOIN service_categories c ON c.id=s.category_id WHERE s.is_active=1 AND p.status='APPROVED' ORDER BY s.id DESC");
        return db.queryForList("SELECT s.*,c.name category_name FROM services s JOIN service_categories c ON c.id=s.category_id WHERE s.provider_id=? AND s.is_active=1 ORDER BY s.id DESC", providerId);
    }

    // Pets: Customer owns their own records ---------------------------------
    @GetMapping("/pets")
    public List<Map<String,Object>> pets(@CurrentUser CurrentPrincipal p) {
        customer(p); return db.queryForList("SELECT * FROM pets WHERE customer_profile_id=? AND is_active=1 ORDER BY id DESC",p.profileId());
    }
    @PostMapping("/pets")
    public Map<String,Object> createPet(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        customer(p); required(b,"name"); required(b,"species");
        db.update("INSERT INTO pets(customer_profile_id,name,species,breed,gender,birth_date,weight_kg,color,medical_notes,is_active) VALUES(?,?,?,?,?,?,?,?,?,1)",
            p.profileId(),required(b,"name"),required(b,"species"),text(b,"breed"),or(text(b,"gender"),"UNKNOWN"),text(b,"birthDate"),decimal(b,"weightKg"),text(b,"color"),text(b,"medicalNotes"));
        return Map.of("success",true,"id",lastId());
    }
    @PutMapping("/pets/{id}")
    public Map<String,Object> updatePet(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        customer(p); own("SELECT id FROM pets WHERE id=? AND customer_profile_id=?",id,p.profileId());
        db.update("UPDATE pets SET name=COALESCE(?,name),breed=COALESCE(?,breed),gender=COALESCE(?,gender),birth_date=COALESCE(?,birth_date),weight_kg=COALESCE(?,weight_kg),color=COALESCE(?,color),medical_notes=COALESCE(?,medical_notes) WHERE id=?",
            text(b,"name"),text(b,"breed"),text(b,"gender"),text(b,"birthDate"),decimal(b,"weightKg"),text(b,"color"),text(b,"medicalNotes"),id);
        return Map.of("success",true,"id",id);
    }
    @DeleteMapping("/pets/{id}")
    public Map<String,Object> deletePet(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        customer(p); own("SELECT id FROM pets WHERE id=? AND customer_profile_id=?",id,p.profileId());
        db.update("UPDATE pets SET is_active=0 WHERE id=?",id); return Map.of("success",true,"id",id);
    }

    // Provider profile, services, staff and availability --------------------
    @GetMapping("/provider/me")
    public Map<String,Object> providerMe(@CurrentUser CurrentPrincipal p) { return providerFor(p); }
    @PutMapping("/provider/me")
    public Map<String,Object> updateProvider(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        Map<String,Object> provider=providerFor(p);
        db.update("UPDATE providers SET name=COALESCE(?,name),phone=COALESCE(?,phone),email=COALESCE(?,email),address=COALESCE(?,address),service_area=COALESCE(?,service_area),description=COALESCE(?,description),business_hours=COALESCE(?,business_hours) WHERE id=?",
            text(b,"name"),text(b,"phone"),text(b,"email"),text(b,"address"),text(b,"serviceArea"),text(b,"description"),text(b,"businessHours"),provider.get("id"));
        return Map.of("success",true,"id",provider.get("id"));
    }
    @GetMapping("/provider/services")
    public List<Map<String,Object>> providerServices(@CurrentUser CurrentPrincipal p) {
        return db.queryForList("SELECT * FROM services WHERE provider_id=? ORDER BY id DESC",providerId(p));
    }
    @PostMapping("/provider/services")
    public Map<String,Object> createService(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        long pid=providerId(p); long category=number(b,"categoryId"); required(b,"name");
        BigDecimal price=decimalRequired(b,"price"); int duration=(int)number(b,"durationMinutes");
        if(price.signum()<0||duration<1) throw new ApiException(400,"price and durationMinutes must be positive");
        db.update("INSERT INTO services(provider_id,category_id,name,description,price,duration_minutes,pet_type_supported,is_active) VALUES(?,?,?,?,?,?,?,1)",
          pid,category,required(b,"name"),text(b,"description"),price,duration,text(b,"petTypeSupported"));
        return Map.of("success",true,"id",lastId());
    }
    @PutMapping("/provider/services/{id}")
    public Map<String,Object> updateService(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        long pid=providerId(p); own("SELECT id FROM services WHERE id=? AND provider_id=?",id,pid);
        BigDecimal price=decimal(b,"price"); Integer duration=integer(b,"durationMinutes");
        if(price!=null&&price.signum()<0) throw new ApiException(400,"price must not be negative");
        if(duration!=null&&duration<1) throw new ApiException(400,"durationMinutes must be positive");
        db.update("UPDATE services SET name=COALESCE(?,name),description=COALESCE(?,description),price=COALESCE(?,price),duration_minutes=COALESCE(?,duration_minutes),pet_type_supported=COALESCE(?,pet_type_supported),is_active=COALESCE(?,is_active) WHERE id=?",
          text(b,"name"),text(b,"description"),price,duration,text(b,"petTypeSupported"),bool(b,"isActive"),id);
        return Map.of("success",true,"id",id);
    }
    @DeleteMapping("/provider/services/{id}")
    public Map<String,Object> deactivateService(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        own("SELECT id FROM services WHERE id=? AND provider_id=?",id,providerId(p));db.update("UPDATE services SET is_active=0 WHERE id=?",id);return Map.of("success",true,"id",id);
    }
    @GetMapping("/provider/staff")
    public List<Map<String,Object>> staff(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT * FROM staff WHERE provider_id=? ORDER BY id DESC",providerId(p)); }
    @PostMapping("/provider/staff")
    public Map<String,Object> createStaff(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        required(b,"fullName"); db.update("INSERT INTO staff(provider_id,full_name,phone,email,skills,is_active) VALUES(?,?,?,?,?,1)",providerId(p),required(b,"fullName"),text(b,"phone"),text(b,"email"),text(b,"skills"));return Map.of("success",true,"id",lastId());
    }
    @PutMapping("/provider/staff/{id}")
    public Map<String,Object> updateStaff(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        own("SELECT id FROM staff WHERE id=? AND provider_id=?",id,providerId(p));db.update("UPDATE staff SET full_name=COALESCE(?,full_name),phone=COALESCE(?,phone),email=COALESCE(?,email),skills=COALESCE(?,skills),is_active=COALESCE(?,is_active) WHERE id=?",text(b,"fullName"),text(b,"phone"),text(b,"email"),text(b,"skills"),bool(b,"isActive"),id);return Map.of("success",true,"id",id);
    }
    @DeleteMapping("/provider/staff/{id}")
    public Map<String,Object> deactivateStaff(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        own("SELECT id FROM staff WHERE id=? AND provider_id=?",id,providerId(p));db.update("UPDATE staff SET is_active=0 WHERE id=?",id);return Map.of("success",true,"id",id);
    }
    @GetMapping("/provider/schedules")
    public List<Map<String,Object>> schedules(@CurrentUser CurrentPrincipal p) {
        return db.queryForList("SELECT ss.* FROM staff_schedules ss JOIN staff s ON s.id=ss.staff_id WHERE s.provider_id=? ORDER BY ss.start_at",providerId(p));
    }
    @PostMapping("/provider/schedules")
    public Map<String,Object> createSchedule(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        long sid=number(b,"staffId"); own("SELECT id FROM staff WHERE id=? AND provider_id=? AND is_active=1",sid,providerId(p));
        String start=required(b,"startAt"), end=required(b,"endAt"), status=scheduleStatus(b);
        validateScheduleTimes(start,end);
        db.update("INSERT INTO staff_schedules(staff_id,start_at,end_at,status,note) VALUES(?,?,?,?,?)",sid,start,end,status,text(b,"note"));return Map.of("success",true,"id",lastId());
    }

    @PutMapping("/provider/schedules/{id}")
    public Map<String,Object> updateSchedule(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        own("SELECT ss.id FROM staff_schedules ss JOIN staff s ON s.id=ss.staff_id WHERE ss.id=? AND s.provider_id=?",id,providerId(p));
        Map<String,Object> current=one("SELECT * FROM staff_schedules WHERE id=?",id);
        long staffId=b.get("staffId")==null?((Number)current.get("staff_id")).longValue():number(b,"staffId");
        own("SELECT id FROM staff WHERE id=? AND provider_id=? AND is_active=1",staffId,providerId(p));
        String start=or(text(b,"startAt"),String.valueOf(current.get("start_at"))), end=or(text(b,"endAt"),String.valueOf(current.get("end_at")));
        validateScheduleTimes(start,end);
        db.update("UPDATE staff_schedules SET staff_id=?,start_at=?,end_at=?,status=?,note=COALESCE(?,note) WHERE id=?",staffId,start,end,b.containsKey("status")?scheduleStatus(b):current.get("status"),text(b,"note"),id);return Map.of("success",true,"id",id);
    }
    @DeleteMapping("/provider/schedules/{id}")
    public Map<String,Object> deleteSchedule(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        own("SELECT ss.id FROM staff_schedules ss JOIN staff s ON s.id=ss.staff_id WHERE ss.id=? AND s.provider_id=?",id,providerId(p));db.update("DELETE FROM staff_schedules WHERE id=?",id);return Map.of("success",true,"id",id);
    }

    // Provider reporting and relationship views -----------------------------
    @GetMapping("/provider/customers") public List<Map<String,Object>> providerCustomers(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT u.id,u.full_name,u.email,u.phone,COUNT(b.id) booking_count,MAX(b.booking_start) last_booking_at FROM bookings b JOIN user_profiles u ON u.id=b.customer_profile_id WHERE b.provider_id=? GROUP BY u.id,u.full_name,u.email,u.phone ORDER BY last_booking_at DESC", providerId(p)); }
    @GetMapping("/provider/pets") public List<Map<String,Object>> providerPets(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT pt.id,pt.name,pt.species,pt.breed,pt.gender,pt.birth_date,pt.weight_kg,u.full_name customer_name,COUNT(b.id) booking_count,MAX(b.booking_start) last_booking_at FROM bookings b JOIN pets pt ON pt.id=b.pet_id JOIN user_profiles u ON u.id=pt.customer_profile_id WHERE b.provider_id=? GROUP BY pt.id,pt.name,pt.species,pt.breed,pt.gender,pt.birth_date,pt.weight_kg,u.full_name ORDER BY last_booking_at DESC", providerId(p)); }
    @GetMapping("/provider/reviews") public List<Map<String,Object>> providerReviews(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT r.*,u.full_name customer_name,s.name service_name FROM reviews r JOIN user_profiles u ON u.id=r.customer_profile_id JOIN bookings b ON b.id=r.booking_id JOIN services s ON s.id=b.service_id WHERE r.provider_id=? ORDER BY r.created_at DESC", providerId(p)); }
    @GetMapping("/provider/dashboard") public Map<String,Object> providerDashboard(@CurrentUser CurrentPrincipal p) { long id=providerId(p); Map<String,Object> c=one("SELECT COUNT(*) total_bookings,SUM(status='PENDING') pending_bookings,SUM(status='COMPLETED') completed_bookings,COALESCE(SUM(CASE WHEN status='COMPLETED' THEN estimated_price ELSE 0 END),0) completed_revenue FROM bookings WHERE provider_id=?",id); Map<String,Object> r=one("SELECT COUNT(*) review_count,COALESCE(AVG(rating),0) average_rating FROM reviews WHERE provider_id=? AND is_visible=1",id); Map<String,Object> x=new LinkedHashMap<>();x.putAll(c);x.putAll(r);return x; }
    @GetMapping("/provider/revenue") public List<Map<String,Object>> providerRevenue(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT DATE(booking_end) booking_date,COUNT(*) completed_bookings,COALESCE(SUM(estimated_price),0) revenue FROM bookings WHERE provider_id=? AND status='COMPLETED' GROUP BY DATE(booking_end) ORDER BY booking_date DESC LIMIT 30",providerId(p)); }

    // Booking lifecycle ------------------------------------------------------
    @GetMapping("/bookings")
    public List<Map<String,Object>> bookings(@CurrentUser CurrentPrincipal p,@RequestParam(required=false) String status,@RequestParam(required=false) String date,@RequestParam(required=false) String q) {
        if("CUSTOMER".equals(p.role())) return db.queryForList("SELECT b.*,pr.name provider_name,s.name service_name FROM bookings b JOIN providers pr ON pr.id=b.provider_id JOIN services s ON s.id=b.service_id WHERE b.customer_profile_id=? ORDER BY b.booking_start DESC",p.profileId());
        if("PROVIDER".equals(p.role())) {
            StringBuilder sql=new StringBuilder("SELECT b.*,u.full_name customer_name,pt.name pet_name,s.name service_name,st.full_name staff_name FROM bookings b JOIN providers pr ON pr.id=b.provider_id JOIN user_profiles u ON u.id=b.customer_profile_id JOIN pets pt ON pt.id=b.pet_id JOIN services s ON s.id=b.service_id LEFT JOIN staff st ON st.id=b.staff_id WHERE pr.owner_profile_id=?");
            List<Object> args=new ArrayList<>();args.add(p.profileId());
            if(status!=null&&!status.isBlank()){sql.append(" AND b.status=?");args.add(status.toUpperCase(Locale.ROOT));}
            if(date!=null&&!date.isBlank()){sql.append(" AND DATE(b.booking_start)=?");args.add(date);}
            if(q!=null&&!q.isBlank()){sql.append(" AND (u.full_name LIKE ? OR pt.name LIKE ? OR s.name LIKE ?)");String term="%"+q.trim()+"%";args.add(term);args.add(term);args.add(term);}
            sql.append(" ORDER BY b.booking_start DESC");return db.queryForList(sql.toString(),args.toArray());
        }
        throw new ApiException(403,"Unsupported role");
    }
    @GetMapping("/bookings/{id}")
    public Map<String,Object> booking(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        accessibleBooking(p,id);
        Map<String,Object> result=one("SELECT b.*,u.full_name customer_name,u.email customer_email,u.phone customer_phone,pt.name pet_name,pt.species pet_species,pt.breed pet_breed,s.name service_name,s.duration_minutes,st.full_name staff_name,pr.name provider_name FROM bookings b JOIN user_profiles u ON u.id=b.customer_profile_id JOIN pets pt ON pt.id=b.pet_id JOIN services s ON s.id=b.service_id LEFT JOIN staff st ON st.id=b.staff_id JOIN providers pr ON pr.id=b.provider_id WHERE b.id=?",id);
        if(result==null)throw new ApiException(404,"Booking not found");return result;
    }
    @GetMapping("/bookings/{id}/history")
    public List<Map<String,Object>> bookingHistory(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        accessibleBooking(p,id);
        return db.queryForList("SELECT h.*,u.full_name changed_by_name FROM booking_status_history h LEFT JOIN user_profiles u ON u.id=h.changed_by_profile_id WHERE h.booking_id=? ORDER BY h.changed_at DESC,h.id DESC",id);
    }
    @PostMapping("/bookings")
    public Map<String,Object> createBooking(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        customer(p); long pet=number(b,"petId"),provider=number(b,"providerId"),service=number(b,"serviceId");
        own("SELECT id FROM pets WHERE id=? AND customer_profile_id=? AND is_active=1",pet,p.profileId());
        Map<String,Object>s=one("SELECT * FROM services WHERE id=? AND provider_id=? AND is_active=1",service,provider);if(s==null)throw new ApiException(400,"Service is unavailable");
        String start=required(b,"bookingStart"); Long staff=b.get("staffId")==null?null:number(b,"staffId");
        if(staff!=null) {
            own("SELECT st.id FROM staff st WHERE st.id=? AND st.provider_id=? AND st.is_active=1",staff,provider);
            Integer conflict=db.queryForObject("SELECT COUNT(*) FROM bookings WHERE staff_id=? AND status IN ('PENDING','CONFIRMED','CHECKED_IN','IN_SERVICE') AND booking_start < DATE_ADD(?,INTERVAL ? MINUTE) AND booking_end > ?",Integer.class,staff,start,s.get("duration_minutes"),start);
            if(conflict != null && conflict > 0) throw new ApiException(409,"Selected staff already has an overlapping booking");
        }
        db.update("INSERT INTO bookings(customer_profile_id,pet_id,provider_id,service_id,staff_id,booking_start,booking_end,estimated_price,customer_note) VALUES(?,?,?,?,?,?,DATE_ADD(?,INTERVAL ? MINUTE),?,?)",p.profileId(),pet,provider,service,staff,start,start,s.get("duration_minutes"),s.get("price"),text(b,"customerNote"));
        long id=lastId(); Map<String,Object> owner=one("SELECT owner_profile_id,name FROM providers WHERE id=?",provider);
        db.update("INSERT INTO notifications(recipient_profile_id,title,content,notification_type,reference_type,reference_id) VALUES(?,?,?,?,?,?)",owner.get("owner_profile_id"),"Booking mới","Bạn có booking #"+id+" cần xác nhận tại "+owner.get("name"),"BOOKING_CREATED","BOOKING",id);
        return Map.of("success",true,"id",id);
    }
    @PutMapping("/bookings/{id}/status")
    public Map<String,Object> bookingStatus(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        Map<String,Object> booking=one("SELECT * FROM bookings WHERE id=?",id);if(booking==null)throw new ApiException(404,"Booking not found");
        String next=required(b,"status").toUpperCase(Locale.ROOT); String current=String.valueOf(booking.get("status"));
        boolean customer="CUSTOMER".equals(p.role())&&((Number)booking.get("customer_profile_id")).longValue()==p.profileId()&&"CANCELLED".equals(next);
        boolean provider="PROVIDER".equals(p.role())&&ownsProvider(((Number)booking.get("provider_id")).longValue(),p.profileId())&&List.of("CONFIRMED","REJECTED","CHECKED_IN","IN_SERVICE","COMPLETED").contains(next);
        if(!(customer||provider)||!transition(current,next))throw new ApiException(403,"Booking status change is not allowed");
        db.update("UPDATE bookings SET status=?,cancel_reason=CASE WHEN ?='CANCELLED' THEN ? ELSE cancel_reason END,provider_note=COALESCE(?,provider_note) WHERE id=?",next,next,text(b,"cancelReason"),text(b,"providerNote"),id);
        db.update("INSERT INTO booking_status_history(booking_id,previous_status,new_status,changed_by_profile_id,note) VALUES(?,?,?,?,?)",id,current,next,p.profileId(),text(b,"note"));
        if (!customer) {
            db.update("INSERT INTO notifications(recipient_profile_id,title,content,notification_type,reference_type,reference_id) VALUES(?,?,?,?,?,?)",
                booking.get("customer_profile_id"),
                "Cập nhật lịch hẹn",
                "Booking #" + id + " đã được cập nhật: " + next,
                "BOOKING_STATUS", "BOOKING", id);
        }
        return Map.of("success",true,"id",id,"status",next);
    }

    @PutMapping("/bookings/{id}/reschedule")
    public Map<String,Object> reschedule(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        customer(p); Map<String,Object> booking=one("SELECT * FROM bookings WHERE id=? AND customer_profile_id=?",id,p.profileId());
        if(booking==null) throw new ApiException(404,"Booking not found");
        if(!List.of("PENDING","CONFIRMED").contains(String.valueOf(booking.get("status")))) throw new ApiException(409,"This booking can no longer be rescheduled");
        String start=required(b,"bookingStart"); Map<String,Object> service=one("SELECT duration_minutes FROM services WHERE id=?",booking.get("service_id"));
        if(service==null) throw new ApiException(409,"Service unavailable");
        Object staff=booking.get("staff_id");
        if(staff!=null) { Integer conflicts=db.queryForObject("SELECT COUNT(*) FROM bookings WHERE staff_id=? AND id<>? AND status IN ('PENDING','CONFIRMED','CHECKED_IN','IN_SERVICE') AND booking_start<DATE_ADD(?,INTERVAL ? MINUTE) AND booking_end>?",Integer.class,staff,id,start,service.get("duration_minutes"),start); if(conflicts!=null&&conflicts>0) throw new ApiException(409,"Selected staff already has an overlapping booking"); }
        db.update("UPDATE bookings SET booking_start=?,booking_end=DATE_ADD(?,INTERVAL ? MINUTE),status='PENDING' WHERE id=?",start,start,service.get("duration_minutes"),id);
        db.update("INSERT INTO booking_status_history(booking_id,previous_status,new_status,changed_by_profile_id,note) VALUES(?,?,?,?,?)",id,booking.get("status"),"PENDING",p.profileId(),"Customer requested reschedule");
        return Map.of("success",true,"id",id,"status","PENDING");
    }

    // Reviews and notifications ---------------------------------------------
    @GetMapping("/reviews")
    public List<Map<String,Object>> reviews(@RequestParam(required=false) Long providerId) {
        return providerId==null?db.queryForList("SELECT * FROM reviews WHERE is_visible=1 ORDER BY id DESC"):db.queryForList("SELECT * FROM reviews WHERE provider_id=? AND is_visible=1 ORDER BY id DESC",providerId);
    }
    @PostMapping("/reviews")
    public Map<String,Object> createReview(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        customer(p);long bookingId=number(b,"bookingId");Map<String,Object>x=one("SELECT * FROM bookings WHERE id=? AND customer_profile_id=? AND status='COMPLETED'",bookingId,p.profileId());if(x==null)throw new ApiException(403,"Only completed own bookings can be reviewed");
        int rating=(int)number(b,"rating");if(rating<1||rating>5)throw new ApiException(400,"rating must be 1 to 5");
        db.update("INSERT INTO reviews(booking_id,customer_profile_id,provider_id,rating,comment) VALUES(?,?,?,?,?)",bookingId,p.profileId(),x.get("provider_id"),rating,text(b,"comment"));return Map.of("success",true,"id",lastId());
    }
    @PutMapping("/reviews/{id}")
    public Map<String,Object> updateReview(@CurrentUser CurrentPrincipal p,@PathVariable long id,@RequestBody Map<String,Object>b) {
        customer(p); own("SELECT id FROM reviews WHERE id=? AND customer_profile_id=?",id,p.profileId());
        Integer rating=integer(b,"rating");if(rating!=null&&(rating<1||rating>5))throw new ApiException(400,"rating must be 1 to 5");
        db.update("UPDATE reviews SET rating=COALESCE(?,rating),comment=COALESCE(?,comment) WHERE id=?",rating,text(b,"comment"),id);return Map.of("success",true,"id",id);
    }
    @DeleteMapping("/reviews/{id}")
    public Map<String,Object> deleteReview(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        customer(p);own("SELECT id FROM reviews WHERE id=? AND customer_profile_id=?",id,p.profileId());db.update("DELETE FROM reviews WHERE id=?",id);return Map.of("success",true,"id",id);
    }
    @GetMapping("/notifications")
    public List<Map<String,Object>> notifications(@CurrentUser CurrentPrincipal p) { return db.queryForList("SELECT * FROM notifications WHERE recipient_profile_id=? ORDER BY created_at DESC",p.profileId()); }
    @PutMapping("/notifications/{id}/read")
    public Map<String,Object> read(@CurrentUser CurrentPrincipal p,@PathVariable long id) { db.update("UPDATE notifications SET is_read=1,read_at=CURRENT_TIMESTAMP WHERE id=? AND recipient_profile_id=?",id,p.profileId());return Map.of("success",true,"id",id); }

    // Customer care notes ---------------------------------------------------
    @GetMapping("/care-notes")
    public List<Map<String,Object>> careNotes(@CurrentUser CurrentPrincipal p) {
        customer(p);
        return db.queryForList("SELECT n.*,pt.name pet_name FROM care_notes n LEFT JOIN pets pt ON pt.id=n.pet_id WHERE n.customer_profile_id=? ORDER BY n.created_at DESC,n.id DESC",p.profileId());
    }
    @PostMapping("/care-notes")
    public Map<String,Object> createCareNote(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        customer(p);
        String title=required(b,"title"); String content=text(b,"content");
        if(title.length()>180) throw new ApiException(400,"title must be at most 180 characters");
        if(content!=null&&content.length()>5000) throw new ApiException(400,"content must be at most 5000 characters");
        Long petId=b.get("petId")==null?null:number(b,"petId");
        if(petId!=null) own("SELECT id FROM pets WHERE id=? AND customer_profile_id=? AND is_active=1",petId,p.profileId());
        db.update("INSERT INTO care_notes(customer_profile_id,pet_id,title,content) VALUES(?,?,?,?)",p.profileId(),petId,title,content);
        return Map.of("success",true,"id",lastId());
    }
    @DeleteMapping("/care-notes/{id}")
    public Map<String,Object> deleteCareNote(@CurrentUser CurrentPrincipal p,@PathVariable long id) {
        customer(p); own("SELECT id FROM care_notes WHERE id=? AND customer_profile_id=?",id,p.profileId());
        db.update("DELETE FROM care_notes WHERE id=?",id); return Map.of("success",true,"id",id);
    }

    @GetMapping("/complaints")
    public List<Map<String,Object>> complaints(@CurrentUser CurrentPrincipal p) { customer(p); return db.queryForList("SELECT * FROM complaints WHERE customer_profile_id=? ORDER BY created_at DESC",p.profileId()); }
    @PostMapping("/complaints")
    public Map<String,Object> complaint(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b) {
        customer(p); long bookingId=number(b,"bookingId"); required(b,"content"); Map<String,Object> booking=one("SELECT * FROM bookings WHERE id=? AND customer_profile_id=?",bookingId,p.profileId());
        if(booking==null) throw new ApiException(404,"Booking not found");
        db.update("INSERT INTO complaints(booking_id,customer_profile_id,provider_id,content,status) VALUES(?,?,?,?, 'OPEN')",bookingId,p.profileId(),booking.get("provider_id"),required(b,"content"));
        return Map.of("success",true,"id",lastId());
    }

    private Map<String,Object> providerFor(CurrentPrincipal p){if(!"PROVIDER".equals(p.role()))throw new ApiException(403,"Provider account required");Map<String,Object>x=one("SELECT * FROM providers WHERE owner_profile_id=? AND is_active=1",p.profileId());if(x==null)throw new ApiException(403,"Provider profile unavailable");return x;}
    private Map<String,Object> accessibleBooking(CurrentPrincipal p,long id){Map<String,Object>b=one("SELECT * FROM bookings WHERE id=?",id);if(b==null)throw new ApiException(404,"Booking not found");boolean customer="CUSTOMER".equals(p.role())&&((Number)b.get("customer_profile_id")).longValue()==p.profileId();boolean provider="PROVIDER".equals(p.role())&&ownsProvider(((Number)b.get("provider_id")).longValue(),p.profileId());if(!(customer||provider))throw new ApiException(403,"Booking not found or not owned by you");return b;}
    private long providerId(CurrentPrincipal p){return ((Number)providerFor(p).get("id")).longValue();}
    private boolean ownsProvider(long id,long profile){return one("SELECT id FROM providers WHERE id=? AND owner_profile_id=?",id,profile)!=null;}
    private void customer(CurrentPrincipal p){if(!"CUSTOMER".equals(p.role()))throw new ApiException(403,"Customer account required");}
    private void own(String q,Object...args){if(one(q,args)==null)throw new ApiException(403,"Record not found or not owned by you");}
    private Map<String,Object> one(String q,Object...args){List<Map<String,Object>>r=db.queryForList(q,args);return r.isEmpty()?null:r.get(0);}
    private long lastId(){return db.queryForObject("SELECT LAST_INSERT_ID()",Long.class);}
    private String text(Map<String,Object>b,String k){Object v=b.get(k);return v==null?null:v.toString().trim();}
    private String required(Map<String,Object>b,String k){String v=text(b,k);if(v==null||v.isBlank())throw new ApiException(400,k+" is required");return v;}
    private long number(Map<String,Object>b,String k){try{return Long.parseLong(String.valueOf(b.get(k)));}catch(Exception e){throw new ApiException(400,k+" is required");}}
    private Integer integer(Map<String,Object>b,String k){try{return b.get(k)==null?null:Integer.valueOf(String.valueOf(b.get(k)));}catch(Exception e){throw new ApiException(400,k+" must be an integer");}}
    private BigDecimal decimal(Map<String,Object>b,String k){try{return b.get(k)==null?null:new BigDecimal(String.valueOf(b.get(k)));}catch(Exception e){throw new ApiException(400,k+" must be a number");}}
    private BigDecimal decimalRequired(Map<String,Object>b,String k){BigDecimal x=decimal(b,k);if(x==null)throw new ApiException(400,k+" is required");return x;}
    private Boolean bool(Map<String,Object>b,String k){return b.get(k)==null?null:Boolean.valueOf(String.valueOf(b.get(k)));}
    private String or(String a,String b){return a==null||a.isBlank()?b:a;}
    private String scheduleStatus(Map<String,Object>b){String status=or(text(b,"status"),"AVAILABLE").toUpperCase(Locale.ROOT);if(!List.of("AVAILABLE","BOOKED","BLOCKED").contains(status))throw new ApiException(400,"status must be AVAILABLE, BOOKED or BLOCKED");return status;}
    private void validateScheduleTimes(String start,String end){try{if(!java.time.LocalDateTime.parse(end.replace(' ','T')).isAfter(java.time.LocalDateTime.parse(start.replace(' ','T'))))throw new ApiException(400,"endAt must be after startAt");}catch(ApiException e){throw e;}catch(Exception e){throw new ApiException(400,"startAt and endAt must be valid dates");}}
    private boolean transition(String from,String to){return Map.of("PENDING",List.of("CONFIRMED","REJECTED","CANCELLED"),"CONFIRMED",List.of("CHECKED_IN","CANCELLED"),"CHECKED_IN",List.of("IN_SERVICE","CANCELLED"),"IN_SERVICE",List.of("COMPLETED")).getOrDefault(from,List.of()).contains(to);}
}
