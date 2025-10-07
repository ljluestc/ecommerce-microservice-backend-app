package com.selimhorri.app.logging;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public class StructuredLogger {

    private final Logger logger;

    private StructuredLogger(Class<?> clazz) {
        this.logger = LoggerFactory.getLogger(clazz);
    }

    public static StructuredLogger getLogger(Class<?> clazz) {
        return new StructuredLogger(clazz);
    }

    public void logRequest(String method, String path, String userId, Map<String, Object> additionalFields) {
        try {
            String requestId = UUID.randomUUID().toString();
            MDC.put("requestId", requestId);
            MDC.put("userId", userId);
            MDC.put("httpMethod", method);
            MDC.put("requestPath", path);
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "request");

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            logger.info("HTTP Request - {} {}", method, path);
        } finally {
            clearMDC();
        }
    }

    public void logResponse(String method, String path, int statusCode, long durationMs, Map<String, Object> additionalFields) {
        try {
            MDC.put("httpMethod", method);
            MDC.put("requestPath", path);
            MDC.put("responseCode", String.valueOf(statusCode));
            MDC.put("duration", String.valueOf(durationMs));
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "response");

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            logger.info("HTTP Response - {} {} - {} in {}ms", method, path, statusCode, durationMs);
        } finally {
            clearMDC();
        }
    }

    public void logError(String operation, String errorMessage, Throwable throwable, Map<String, Object> additionalFields) {
        try {
            MDC.put("operation", operation);
            MDC.put("errorMessage", errorMessage);
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "error");

            if (throwable != null) {
                MDC.put("exceptionClass", throwable.getClass().getSimpleName());
                MDC.put("exceptionMessage", throwable.getMessage());
            }

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            if (throwable != null) {
                logger.error("Error in operation: {} - {}", operation, errorMessage, throwable);
            } else {
                logger.error("Error in operation: {} - {}", operation, errorMessage);
            }
        } finally {
            clearMDC();
        }
    }

    public void logBusiness(String event, String entity, String action, Map<String, Object> additionalFields) {
        try {
            MDC.put("event", event);
            MDC.put("entity", entity);
            MDC.put("action", action);
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "business");

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            logger.info("Business Event - {} {} {}", event, entity, action);
        } finally {
            clearMDC();
        }
    }

    public void logPerformance(String operation, long durationMs, Map<String, Object> additionalFields) {
        try {
            MDC.put("operation", operation);
            MDC.put("duration", String.valueOf(durationMs));
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "performance");

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            Logger performanceLogger = LoggerFactory.getLogger("performance");
            performanceLogger.info("Performance - {} completed in {}ms", operation, durationMs);
        } finally {
            clearMDC();
        }
    }

    public void logDatabase(String query, long durationMs, int rowCount, Map<String, Object> additionalFields) {
        try {
            MDC.put("query", query);
            MDC.put("duration", String.valueOf(durationMs));
            MDC.put("rowCount", String.valueOf(rowCount));
            MDC.put("timestamp", Instant.now().toString());
            MDC.put("logType", "database");

            if (additionalFields != null) {
                additionalFields.forEach((key, value) -> MDC.put(key, String.valueOf(value)));
            }

            logger.debug("Database Query - {} rows in {}ms", rowCount, durationMs);
        } finally {
            clearMDC();
        }
    }

    public void info(String message, Object... args) {
        logger.info(message, args);
    }

    public void debug(String message, Object... args) {
        logger.debug(message, args);
    }

    public void warn(String message, Object... args) {
        logger.warn(message, args);
    }

    public void error(String message, Object... args) {
        logger.error(message, args);
    }

    private void clearMDC() {
        MDC.clear();
    }
}