package com.pawcare.publicapi;

import com.pawcare.publicapi.bonita.BonitaWorkflowProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@EnableConfigurationProperties(BonitaWorkflowProperties.class)
public class PawCarePublicApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(PawCarePublicApiApplication.class, args);
    }
}
