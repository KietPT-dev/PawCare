package com.pawcare.publicapi.payment;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.web.ApiException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VnpayService {
    private static final DateTimeFormatter TIME=DateTimeFormatter.ofPattern("yyyyMMddHHmmss").withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
    private final JdbcTemplate db; private final boolean enabled; private final String tmn, secret, paymentUrl, returnUrl, ipnUrl;
    public VnpayService(JdbcTemplate db, @Value("${pawcare.vnpay.enabled}") boolean enabled,
      @Value("${pawcare.vnpay.tmn-code}") String tmn, @Value("${pawcare.vnpay.hash-secret}") String secret,
      @Value("${pawcare.vnpay.payment-url}") String paymentUrl, @Value("${pawcare.vnpay.return-url}") String returnUrl,
      @Value("${pawcare.vnpay.ipn-url}") String ipnUrl) {
      this.db=db;this.enabled=enabled;this.tmn=tmn;this.secret=secret;this.paymentUrl=paymentUrl;this.returnUrl=returnUrl;this.ipnUrl=ipnUrl;
    }
    public Map<String,Object> create(CurrentPrincipal user, Map<String,Object> body, String ip) {
      requireCustomer(user);
      long bookingId=number(body,"bookingId");
      Map<String,Object> booking=one("SELECT id, customer_profile_id, status, estimated_price FROM bookings WHERE id=?",bookingId);
      if(booking==null)throw new ApiException(404,"Booking not found");
      if(((Number)booking.get("customer_profile_id")).longValue()!=user.profileId())throw new ApiException(403,"You can only pay for your own booking");
      if(!List.of("PENDING","CONFIRMED").contains(booking.get("status")))throw new ApiException(400,"Booking is not payable");
      if(one("SELECT id FROM payments WHERE booking_id=?",bookingId)!=null)throw new ApiException(409,"A payment already exists for this booking");
      if(!enabled || blank(tmn)||blank(secret)||returnUrl.contains("replace-me")||ipnUrl.contains("replace-me"))throw new ApiException(503,"VNPAY Sandbox is not configured yet");
      String ref="PC-"+bookingId+"-"+UUID.randomUUID().toString().replace("-","").substring(0,16).toUpperCase(Locale.ROOT);
      BigDecimal amount=(BigDecimal)booking.get("estimated_price");
      db.update("INSERT INTO payments (booking_id, amount, payment_method, status, transaction_reference, gateway, gateway_transaction_ref) VALUES (?, ?, 'VNPAY', 'PENDING', ?, 'VNPAY', ?)",bookingId,amount,ref,ref);
      Map<String,String> p=new TreeMap<>();
      p.put("vnp_Amount",amount.movePointRight(2).setScale(0).toPlainString()); p.put("vnp_Command","pay"); p.put("vnp_CreateDate",TIME.format(Instant.now()));
      p.put("vnp_CurrCode","VND");p.put("vnp_IpAddr",safeIp(ip));p.put("vnp_Locale","vn");p.put("vnp_OrderInfo","PawCare payment "+ref);
      p.put("vnp_OrderType","other");p.put("vnp_ReturnUrl",returnUrl);p.put("vnp_TmnCode",tmn);p.put("vnp_TxnRef",ref);p.put("vnp_Version","2.1.0");
      String query=query(p); return Map.of("paymentId",one("SELECT id FROM payments WHERE transaction_reference=?",ref).get("id"),"transactionReference",ref,"paymentUrl",paymentUrl+"?"+query+"&vnp_SecureHash="+hmac(query));
    }
    public Map<String,Object> returnResult(Map<String,String> params) {
      boolean valid=verify(params); return Map.of("validSignature",valid,"success",valid&&"00".equals(params.get("vnp_ResponseCode"))&&"00".equals(params.get("vnp_TransactionStatus")),"transactionReference",params.get("vnp_TxnRef"),"responseCode",params.get("vnp_ResponseCode"));
    }
    @Transactional
    public Map<String,Object> ipn(Map<String,String> p) {
      if(!verify(p)) return response("97","Invalid signature");
      String ref=p.get("vnp_TxnRef"); Map<String,Object> pay=one("SELECT * FROM payments WHERE transaction_reference=? FOR UPDATE",ref);
      if(pay==null)return response("01","Order not found");
      BigDecimal expected=((BigDecimal)pay.get("amount")).movePointRight(2).setScale(0);
      if(!expected.toPlainString().equals(p.get("vnp_Amount")))return response("04","Invalid amount");
      boolean success="00".equals(p.get("vnp_ResponseCode"))&&"00".equals(p.get("vnp_TransactionStatus"));
      String status=success?"PAID":"FAILED";
      String existing=String.valueOf(pay.get("status"));
      if("PAID".equals(existing)) return response("02","Order already confirmed");
      db.update("UPDATE payments SET status=?, paid_at=CASE WHEN ?='PAID' THEN CURRENT_TIMESTAMP ELSE paid_at END, gateway_transaction_no=?, gateway_response_code=?, raw_callback_payload=?, callback_received_at=CURRENT_TIMESTAMP, updated_at=CURRENT_TIMESTAMP WHERE id=?",
              status,status,p.get("vnp_TransactionNo"),p.get("vnp_ResponseCode"),serialize(p),pay.get("id"));
      return response("00","Confirm Success");
    }
    private boolean verify(Map<String,String> params){return enabled&&!blank(secret)&&constant(params.get("vnp_SecureHash"),hmac(query(withoutHash(params))));}
    private Map<String,String> withoutHash(Map<String,String> p){Map<String,String> c=new TreeMap<>();p.forEach((k,v)->{if(k.startsWith("vnp_")&&!k.equals("vnp_SecureHash")&&!k.equals("vnp_SecureHashType"))c.put(k,v);});return c;}
    private String query(Map<String,String> p){return p.entrySet().stream().filter(e->e.getValue()!=null&&!e.getValue().isBlank()).map(e->enc(e.getKey())+"="+enc(e.getValue())).collect(java.util.stream.Collectors.joining("&"));}
    private String hmac(String data){try{Mac m=Mac.getInstance("HmacSHA512");m.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8),"HmacSHA512"));byte[] b=m.doFinal(data.getBytes(StandardCharsets.UTF_8));StringBuilder s=new StringBuilder();for(byte x:b)s.append(String.format("%02x",x));return s.toString();}catch(Exception e){throw new IllegalStateException("VNPAY signing failed",e);}}
    private boolean constant(String a,String b){return a!=null&&MessageDigest.isEqual(a.getBytes(StandardCharsets.UTF_8),b.getBytes(StandardCharsets.UTF_8));}
    private Map<String,Object> one(String q,Object...v){List<Map<String,Object>>rows=db.queryForList(q,v);return rows.isEmpty()?null:rows.get(0);}
    private long number(Map<String,Object>b,String f){try{return Long.parseLong(String.valueOf(b.get(f)));}catch(Exception e){throw new ApiException(400,f+" is required");}}
    private void requireCustomer(CurrentPrincipal p){if(!"CUSTOMER".equals(p.role()))throw new ApiException(403,"Only customers can create a payment");}
    private Map<String,Object>response(String code,String message){return Map.of("RspCode",code,"Message",message);}
    private String enc(String v){return URLEncoder.encode(v,StandardCharsets.US_ASCII);}
    private String safeIp(String v){return v==null||!v.matches("[0-9a-fA-F:.]+")?"127.0.0.1":v;}
    private boolean blank(String v){return v==null||v.isBlank();}
    private String serialize(Map<String,String> p){return new TreeMap<>(p).toString();}
}
