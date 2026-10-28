package com.pawcare.publicapi.auth;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/auth")
public class AuthController {
 private final AuthService auth; public AuthController(AuthService auth){this.auth=auth;}
 @PostMapping("/register") @ResponseStatus(HttpStatus.CREATED) Map<String,Object> register(@RequestBody Map<String,Object>b){return auth.register(b);}
 @PostMapping("/login") Map<String,Object> login(@RequestBody Map<String,Object>b){return auth.login(b);}
 @PostMapping("/refresh") Map<String,Object> refresh(@RequestBody Map<String,Object>b){return auth.refresh(b);}
 @PostMapping("/logout") @ResponseStatus(HttpStatus.NO_CONTENT) void logout(@RequestBody Map<String,Object>b){auth.logout(b);}
 @GetMapping("/me") Map<String,Object> me(@CurrentUser CurrentPrincipal p){return auth.me(p);}
 @PutMapping("/me") Map<String,Object> updateMe(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b){return auth.updateProfile(p,b);}
 @PutMapping("/password") Map<String,Object> changePassword(@CurrentUser CurrentPrincipal p,@RequestBody Map<String,Object>b){return auth.changePassword(p,b);}
}
