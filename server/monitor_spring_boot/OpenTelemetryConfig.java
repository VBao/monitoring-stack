package com.allianceone.hrm.core.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.metrics.Meter;
import io.opentelemetry.api.logs.Logger;
import lombok.extern.slf4j.Slf4j;

/**
 * Derived OpenTelemetry beans for injection.
 *
 * The OpenTelemetry SDK is auto-configured by opentelemetry-spring-boot-starter
 * using otel.* properties from application YAML. Do NOT manually build the SDK here
 * as it conflicts with auto-configuration and disables auto-instrumentation
 * (spring-web, JDBC, logback, etc.).
 */
@Slf4j
@Configuration
@ConditionalOnProperty(name = "management.tracing.enabled", havingValue = "true")
public class OpenTelemetryConfig {

    @Value("${otel.service.name:hrms-backend}")
    private String serviceName;

    @Value("${otel.service.version:1.0-SNAPSHOT}")
    private String serviceVersion;

    @Bean
    public Tracer tracer(OpenTelemetry openTelemetry) {
        return openTelemetry.getTracer(serviceName, serviceVersion);
    }

    @Bean
    public Meter meter(OpenTelemetry openTelemetry) {
        return openTelemetry.getMeter(serviceName);
    }

    @Bean
    public Logger otelLogger(OpenTelemetry openTelemetry) {
        return openTelemetry.getLogsBridge().get(serviceName);
    }
}
