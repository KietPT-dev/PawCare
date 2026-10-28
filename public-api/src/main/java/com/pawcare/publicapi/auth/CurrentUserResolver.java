package com.pawcare.publicapi.auth;

import com.pawcare.publicapi.web.ApiException;
import org.springframework.core.MethodParameter;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.*;
import org.springframework.web.method.support.*;

@Component
public class CurrentUserResolver implements HandlerMethodArgumentResolver {
    public boolean supportsParameter(MethodParameter p) { return p.hasParameterAnnotation(CurrentUser.class) && p.getParameterType() == CurrentPrincipal.class; }
    public Object resolveArgument(MethodParameter p, ModelAndViewContainer m, NativeWebRequest w, WebDataBinderFactory b) {
        CurrentPrincipal principal = (CurrentPrincipal) w.getNativeRequest(jakarta.servlet.http.HttpServletRequest.class).getAttribute(JwtAuthenticationFilter.ATTRIBUTE);
        if (principal == null) throw new ApiException(401, "Authentication required");
        return principal;
    }
}
