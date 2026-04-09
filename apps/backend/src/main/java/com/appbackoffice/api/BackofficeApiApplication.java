package com.appbackoffice.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BackofficeApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(BackofficeApiApplication.class, args);
    }
}
