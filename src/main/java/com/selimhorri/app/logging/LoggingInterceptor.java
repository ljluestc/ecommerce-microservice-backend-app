package com.selimhorri.app.logging;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.HashMap;
import java.util.Map;

@Component
public class LoggingInterceptor implements HandlerInterceptor {

    private static final StructuredLogger logger = StructuredLogger.getLogger(LoggingInterceptor.class);
    private static final String START_TIME_ATTRIBUTE = "startTime";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        long startTime = System.currentTimeMillis();
        request.setAttribute(START_TIME_ATTRIBUTE, startTime);

        Map<String, Object> additionalFields = new HashMap<>();
        additionalFields.put("userAgent", request.getHeader("User-Agent"));
        additionalFields.put("remoteAddr", request.getRemoteAddr());
        additionalFields.put("sessionId", request.getSession().getId());

        String userId = extractUserId(request);

        logger.logRequest(
            request.getMethod(),
            request.getRequestURI(),
            userId,
            additionalFields
        );

        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        Long startTime = (Long) request.getAttribute(START_TIME_ATTRIBUTE);
        if (startTime != null) {
            long duration = System.currentTimeMillis() - startTime;

            Map<String, Object> additionalFields = new HashMap<>();
            additionalFields.put("contentLength", response.getHeader("Content-Length"));
            additionalFields.put("contentType", response.getContentType());

            if (ex != null) {
                additionalFields.put("exception", ex.getClass().getSimpleName());
                additionalFields.put("exceptionMessage", ex.getMessage());
            }

            logger.logResponse(
                request.getMethod(),
                request.getRequestURI(),
                response.getStatus(),
                duration,
                additionalFields
            );
        }
    }

    private String extractUserId(HttpServletRequest request) {
        // Try to extract user ID from various sources
        String userId = request.getHeader("X-User-Id");
        if (userId == null) {
            userId = request.getParameter("userId");
        }
        if (userId == null && request.getUserPrincipal() != null) {
            userId = request.getUserPrincipal().getName();
        }
        return userId != null ? userId : "anonymous";
    }
}