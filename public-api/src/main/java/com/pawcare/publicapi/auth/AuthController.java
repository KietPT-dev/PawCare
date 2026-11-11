package com.pawcare.publicapi.auth;
import com.pawcare.publicapi.auth.dto.ActionTokenRequest;
import com.pawcare.publicapi.auth.dto.ChangePasswordRequest;
import com.pawcare.publicapi.auth.dto.EmailRequest;
import com.pawcare.publicapi.auth.dto.LoginRequest;
import com.pawcare.publicapi.auth.dto.PasswordResetRequest;
import com.pawcare.publicapi.auth.dto.RefreshTokenRequest;
import com.pawcare.publicapi.auth.dto.RegisterRequest;
import com.pawcare.publicapi.auth.dto.UpdateProfileRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/auth")
public class AuthController {
 private final AuthService auth; public AuthController(AuthService auth){this.auth=auth;}
 @PostMapping("/register") @ResponseStatus(HttpStatus.CREATED) Map<String,Object> register(@Valid @RequestBody RegisterRequest b){return auth.register(b.toPayload());}
 @PostMapping("/login") Map<String,Object> login(@Valid @RequestBody LoginRequest b){return auth.login(b.toPayload());}
 @PostMapping("/refresh") Map<String,Object> refresh(@Valid @RequestBody RefreshTokenRequest b){return auth.refresh(b.toPayload());}
 @PostMapping("/logout") @ResponseStatus(HttpStatus.NO_CONTENT) void logout(@Valid @RequestBody RefreshTokenRequest b){auth.logout(b.toPayload());}
 @GetMapping("/me") Map<String,Object> me(@CurrentUser CurrentPrincipal p){return auth.me(p);}
 @PutMapping("/me") Map<String,Object> updateMe(@CurrentUser CurrentPrincipal p,@Valid @RequestBody UpdateProfileRequest b){return auth.updateProfile(p,b.toPayload());}
 @PutMapping("/password") Map<String,Object> changePassword(@CurrentUser CurrentPrincipal p,@Valid @RequestBody ChangePasswordRequest b){return auth.changePassword(p,b.toPayload());}
 @PostMapping("/password-reset/request") @ResponseStatus(HttpStatus.ACCEPTED) Map<String,Object> requestPasswordReset(@Valid @RequestBody EmailRequest b){return auth.requestPasswordReset(b.email());}
 @PostMapping("/password-reset/confirm") Map<String,Object> resetPassword(@Valid @RequestBody PasswordResetRequest b){return auth.resetPassword(b.token(),b.newPassword());}
 @PostMapping("/email-verification/request") @ResponseStatus(HttpStatus.ACCEPTED) Map<String,Object> requestEmailVerification(@CurrentUser CurrentPrincipal p){return auth.requestEmailVerification(p);}
 @PostMapping("/email-verification/confirm") Map<String,Object> verifyEmail(@Valid @RequestBody ActionTokenRequest b){return auth.verifyEmail(b.token());}
}
