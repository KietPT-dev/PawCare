package com.pawcare.publicapi.availability;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.web.ApiException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class AvailabilityController {
    private final JdbcTemplate db;
    public AvailabilityController(JdbcTemplate db) { this.db = db; }

    /**
     * Public availability lookup before the customer creates a booking.
     * bookingStart format: 2026-10-13T14:30:00.
     */
    @GetMapping("/availability/providers/{providerId}")
    public Map<String,Object> providerAvailability(@PathVariable long providerId,
                                                    @RequestParam long serviceId,
                                                    @RequestParam String bookingStart) {
        Map<String,Object> service = service(providerId, serviceId);
        LocalDateTime start = parseTime(bookingStart);
        LocalDateTime end = start.plusMinutes(((Number) service.get("duration_minutes")).longValue());
        List<Map<String,Object>> available = availableStaff(providerId, start, end);
        return Map.of(
                "providerId", providerId,
                "serviceId", serviceId,
                "bookingStart", start.toString(),
                "bookingEnd", end.toString(),
                "available", !available.isEmpty(),
                "availableStaff", available
        );
    }

    /**
     * Customer-only ranking. It verifies pet ownership, then proposes active
     * services/providers suitable for the pet and requested time.
     */
    @GetMapping("/recommendations")
    public Map<String,Object> recommendations(@CurrentUser CurrentPrincipal principal,
                                              @RequestParam long petId,
                                              @RequestParam(required = false) Long categoryId,
                                              @RequestParam(required = false) String bookingStart) {
        customer(principal);
        Map<String,Object> pet = one("SELECT id,name,species FROM pets WHERE id=? AND customer_profile_id=? AND is_active=1",
                petId, principal.profileId());
        if (pet == null) throw new ApiException(404, "Pet not found");

        LocalDateTime start = bookingStart == null || bookingStart.isBlank() ? null : parseTime(bookingStart);
        String sql = """
                SELECT s.id service_id,s.name service_name,s.price,s.duration_minutes,s.pet_type_supported,
                       p.id provider_id,p.name provider_name,p.average_rating,p.service_area,
                       c.id category_id,c.name category_name
                FROM services s
                JOIN providers p ON p.id=s.provider_id
                JOIN service_categories c ON c.id=s.category_id
                WHERE s.is_active=1 AND p.is_active=1 AND p.status='APPROVED'
                """ + (categoryId == null ? "" : " AND c.id=?") + " ORDER BY p.average_rating DESC, s.price ASC";
        List<Map<String,Object>> rows = categoryId == null ? db.queryForList(sql) : db.queryForList(sql, categoryId);
        List<Map<String,Object>> result = new ArrayList<>();

        for (Map<String,Object> row : rows) {
            if (!supportsSpecies(row.get("pet_type_supported"), String.valueOf(pet.get("species")))) continue;
            long providerId = ((Number) row.get("provider_id")).longValue();
            List<Map<String,Object>> staff = List.of();
            LocalDateTime end = null;
            if (start != null) {
                end = start.plusMinutes(((Number) row.get("duration_minutes")).longValue());
                staff = availableStaff(providerId, start, end);
            }
            int score = score(row, staff.size(), start != null);
            Map<String,Object> candidate = new LinkedHashMap<>(row);
            candidate.put("score", score);
            candidate.put("available", start == null || !staff.isEmpty());
            candidate.put("availableStaffCount", staff.size());
            if (end != null) candidate.put("bookingEnd", end.toString());
            result.add(candidate);
        }
        result.sort(Comparator.comparingInt((Map<String,Object> x) -> (Integer) x.get("score")).reversed()
                .thenComparing(x -> String.valueOf(x.get("provider_name"))));
        return Map.of(
                "pet", Map.of("id", pet.get("id"), "name", pet.get("name"), "species", pet.get("species")),
                "requestedStart", start == null ? null : start.toString(),
                "data", result
        );
    }

    private Map<String,Object> service(long providerId, long serviceId) {
        Map<String,Object> row = one("""
                SELECT s.* FROM services s JOIN providers p ON p.id=s.provider_id
                WHERE s.id=? AND s.provider_id=? AND s.is_active=1 AND p.is_active=1 AND p.status='APPROVED'
                """, serviceId, providerId);
        if (row == null) throw new ApiException(404, "Active service or provider not found");
        return row;
    }

    private List<Map<String,Object>> availableStaff(long providerId, LocalDateTime start, LocalDateTime end) {
        return db.queryForList("""
                SELECT DISTINCT st.id,st.full_name,st.phone,st.email,st.skills
                FROM staff st
                JOIN staff_schedules ss ON ss.staff_id=st.id
                WHERE st.provider_id=? AND st.is_active=1
                  AND ss.status='AVAILABLE'
                  AND ss.start_at <= ? AND ss.end_at >= ?
                  AND NOT EXISTS (
                    SELECT 1 FROM bookings b
                    WHERE b.staff_id=st.id
                      AND b.status IN ('PENDING','CONFIRMED','CHECKED_IN','IN_SERVICE')
                      AND b.booking_start < ? AND b.booking_end > ?
                  )
                ORDER BY st.full_name
                """, providerId, Timestamp.valueOf(start), Timestamp.valueOf(end),
                Timestamp.valueOf(end), Timestamp.valueOf(start));
    }

    private int score(Map<String,Object> row, int staffCount, boolean hasTime) {
        double rating = row.get("average_rating") == null ? 0.0 : ((Number) row.get("average_rating")).doubleValue();
        int value = 50 + (int) Math.round(Math.min(rating, 5.0) * 5);
        if (hasTime && staffCount > 0) value += 25;
        if (hasTime && staffCount == 0) value -= 50;
        return value;
    }

    private boolean supportsSpecies(Object raw, String species) {
        if (raw == null || raw.toString().isBlank()) return true;
        return Arrays.stream(raw.toString().split(","))
                .map(String::trim).anyMatch(x -> x.equalsIgnoreCase(species) || x.equalsIgnoreCase("ALL"));
    }

    private LocalDateTime parseTime(String raw) {
        try { return LocalDateTime.parse(raw); }
        catch (DateTimeParseException e) { throw new ApiException(400, "bookingStart must use ISO local date-time, e.g. 2026-10-13T14:30:00"); }
    }
    private Map<String,Object> one(String sql, Object... args) {
        List<Map<String,Object>> rows = db.queryForList(sql, args);
        return rows.isEmpty() ? null : rows.get(0);
    }
    private void customer(CurrentPrincipal p) {
        if (!"CUSTOMER".equals(p.role())) throw new ApiException(403, "Customer account required");
    }
}
