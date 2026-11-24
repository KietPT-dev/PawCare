package com.pawcare.publicapi.config;

import com.pawcare.publicapi.auth.CurrentUserResolver;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import java.nio.file.Path;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final CurrentUserResolver resolver;
    private final String[] allowedOriginPatterns;
    private final String providerCoverDirectory;
    private final String providerCoverPublicPath;

    public WebConfig(CurrentUserResolver resolver,
                     @Value("${PAWCARE_CORS_ORIGIN_PATTERNS:http://localhost:*,http://127.0.0.1:*}") String originPatterns,
                     @Value("${pawcare.media.provider-cover-directory:./data/provider-covers}") String providerCoverDirectory,
                     @Value("${pawcare.media.provider-cover-public-path:/api/v1/media/provider-covers/}") String providerCoverPublicPath) {
        this.resolver = resolver;
        this.allowedOriginPatterns = originPatterns.split("\\s*,\\s*");
        this.providerCoverDirectory = Path.of(providerCoverDirectory).toAbsolutePath().normalize().toUri().toString();
        this.providerCoverPublicPath = providerCoverPublicPath.endsWith("/") ? providerCoverPublicPath : providerCoverPublicPath + "/";
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
                .allowedHeaders("Authorization", "Content-Type", "X-PawCare-Workflow-Token")
                .allowCredentials(false);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler(providerCoverPublicPath + "**")
                .addResourceLocations(providerCoverDirectory);
    }
}
