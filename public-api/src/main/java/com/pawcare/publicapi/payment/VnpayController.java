package com.pawcare.publicapi.payment;
import com.pawcare.publicapi.auth.*;
import java.util.*;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/payments/vnpay")
public class VnpayController {
 private final VnpayService payments; public VnpayController(VnpayService payments){this.payments=payments;}
 @PostMapping("/create") Map<String,Object> create(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b,HttpServletRequest r){return payments.create(p,b,r.getRemoteAddr());}
 @GetMapping("/return") Map<String,Object> result(@RequestParam Map<String,String>q){return payments.returnResult(q);}
 @GetMapping("/ipn") Map<String,Object> ipn(@RequestParam Map<String,String>q){return payments.ipn(q);}
}
