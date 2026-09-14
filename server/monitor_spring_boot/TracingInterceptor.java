package com.allianceone.hrm.core.config;

import java.nio.charset.StandardCharsets;

import org.slf4j.MDC;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.util.ContentCachingRequestWrapper;

import com.allianceone.hrm.core.validation.ParseToken;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "management.tracing.enabled", havingValue = "true")
public class TracingInterceptor implements WebMvcConfigurer, HandlerInterceptor {
    private final ParseToken parseToken;
    private static final String REQUEST_BODY_ON_ERROR_ATTRIBUTE = "app.request.body.on_error";

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(this);
    }

    @Override
    @SneakyThrows
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String userId = extractUserIdFromRequest(request);
        String requestId = java.util.UUID.randomUUID().toString();

        // Get current OpenTelemetry span context
        Span span = Span.current();
        String traceId = "";
        String spanId = "";

        if (span.getSpanContext().isValid()) {
            traceId = span.getSpanContext().getTraceId();
            spanId = span.getSpanContext().getSpanId();
        }

        MDC.put("traceId", traceId);
        MDC.put("spanId", spanId);
        MDC.put("traceFlags", "01");

        if (userId != null) {
            MDC.put("userId", userId);
        }
        MDC.put("requestId", requestId);
        MDC.put("requestUri", request.getRequestURI());
        MDC.put("httpMethod", request.getMethod());
        MDC.put("remoteAddr", getRemoteAddress(request));

        // Add to OpenTelemetry span for trace correlation
        if (span.getSpanContext().isValid()) {
            span.setAttribute("user.id", userId != null ? userId : "anonymous");
            span.setAttribute("http.request.id", requestId);
            span.setAttribute("http.method", request.getMethod());
            span.setAttribute("http.url", request.getRequestURL().toString());
            span.setAttribute("http.user_agent", request.getHeader("User-Agent"));

            String remoteAddr = getRemoteAddress(request);
            span.setAttribute("http.client_ip", remoteAddr);
        }

        return true;
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler, Exception ex) {
        Span span = Span.current();
        if (span.getSpanContext().isValid() 
			&& request.getRequestURL() != null 
			&& !request.getRequestURL().toString().contains("/api/v2/auth") // Exclude auth endpoints
		) {
            int httpStatus = response.getStatus();

            span.setAttribute("http.status_code", httpStatus);
            span.setAttribute("http.response.size", response.getBufferSize());

            if (ex != null) {
                // Exception occurred
                span.setStatus(StatusCode.ERROR, ex.getMessage());
                span.recordException(ex);
                span.setAttribute("error.type", ex.getClass().getSimpleName());
                log.error("Request to {} completed with exception: {}", request.getRequestURI(), ex.getMessage(), ex);

                // Log request body on exception if request was wrapped
                addRequestBodyToSpanOnError(request, span, httpStatus);

            } else if (httpStatus >= 400) {
                span.setStatus(StatusCode.ERROR, "HTTP " + httpStatus);
                addRequestBodyToSpanOnError(request, span, httpStatus);
            } else {
                // Successful response
                span.setStatus(StatusCode.OK);
            }
        }
        MDC.clear();
    }

    @SneakyThrows
    private void addRequestBodyToSpanOnError(HttpServletRequest request, Span span, int httpStatus) {
        if (request instanceof ContentCachingRequestWrapper wrappedRequest) {
            byte[] buf = wrappedRequest.getContentAsByteArray();
            if (buf.length > 0) {
                String requestBody = new String(buf, 0, buf.length,
                        wrappedRequest.getCharacterEncoding() != null ? wrappedRequest.getCharacterEncoding()
                                : StandardCharsets.UTF_8.name());
                String truncatedBody = requestBody.length() > 1024
                        ? requestBody.substring(0, 1024) + "... (truncated)"
                        : requestBody;
                span.setAttribute(REQUEST_BODY_ON_ERROR_ATTRIBUTE, truncatedBody);
            }
        }
    }

    private String extractUserIdFromRequest(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            Integer userId = parseToken.getId(authHeader);
            return userId != null ? userId.toString() : null;
        }
        return null;
    }

    private String getRemoteAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        return request.getRemoteAddr();
    }
}