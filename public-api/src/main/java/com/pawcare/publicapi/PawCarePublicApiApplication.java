package com.pawcare.publicapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class PawCarePublicApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(PawCarePublicApiApplication.class, args);
    }
}
