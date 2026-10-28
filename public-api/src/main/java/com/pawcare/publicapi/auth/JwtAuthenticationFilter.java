package com.pawcare.publicapi.auth;

import com.pawcare.publicapi.web.ApiException;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Component
@Order(1)
public class JwtAuthenticationFilter implements Filter {
    public static final String ATTRIBUTE = "pawcare.principal";
    private final JwtService jwt;
    public JwtAuthenticationFilter(JwtService jwt) { this.jwt = jwt; }
    @Override public void doFilter(ServletRequest raw, ServletResponse response, FilterChain chain)
            throws java.io.IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) raw;
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try { request.setAttribute(ATTRIBUTE, jwt.verifyAccess(header.substring(7))); }
            catch (ApiException e) { ((HttpServletResponse) response).sendError(e.status(), e.getMessage()); return; }
        }
        chain.doFilter(request, response);
    }
}
