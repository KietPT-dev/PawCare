package com.pawcare.publicapi.config;

import com.pawcare.publicapi.auth.CurrentUserResolver;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final CurrentUserResolver resolver;
    private final String[] allowedOriginPatterns;

    public WebConfig(CurrentUserResolver resolver,
                     @Value("${PAWCARE_CORS_ORIGIN_PATTERNS:http://localhost:*,http://127.0.0.1:*}") String originPatterns) {
        this.resolver = resolver;
        this.allowedOriginPatterns = originPatterns.split("\\s*,\\s*");
    }

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(resolver);
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                // Local Flutter/Vite ports are dynamic. Production should set
                // PAWCARE_CORS_ORIGIN_PATTERNS to its explicit HTTPS domains.
                .allowedOriginPatterns(allowedOriginPatterns)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("Authorization", "Content-Type")
                .allowCredentials(false);
    }
}
