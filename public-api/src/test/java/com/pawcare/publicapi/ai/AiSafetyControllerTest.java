package com.pawcare.publicapi.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.notification.NotificationService;
import com.pawcare.publicapi.web.ApiException;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class AiSafetyControllerTest {
    @Test void internalEndpointsAreHiddenWhenAiIsDisabled() {
        AiInternalController controller = new AiInternalController(mock(JdbcTemplate.class), new ObjectMapper(), mock(NotificationService.class), false, "secret");
        ApiException error = assertThrows(ApiException.class, () -> controller.events(1, mock(HttpServletRequest.class)));
        assertEquals(404, error.status());
    }

    @Test void internalResultRejectsOutOfRangeRiskScoreBeforeWriting() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(startsWith("SELECT * FROM ai_scoring_outbox"), eq(7L))).thenReturn(java.util.List.of(Map.of("aggregate_type", "BOOKING", "aggregate_id", 3L)));
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("X-PawCare-AI-Token")).thenReturn("secret");
        AiInternalController controller = new AiInternalController(db, new ObjectMapper(), mock(NotificationService.class), true, "secret");
        ApiException error = assertThrows(ApiException.class, () -> controller.result(7, Map.of("riskScore", "1.1", "riskLevel", "HIGH"), request));
        assertEquals(400, error.status());
        verify(db, never()).update(startsWith("INSERT INTO ai_risk_scores"), any(Object[].class));
    }

    @Test void internalEndpointsRequireTheDedicatedTokenHeader() {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("X-PawCare-AI-Token")).thenReturn("wrong");
        AiInternalController controller = new AiInternalController(mock(JdbcTemplate.class), new ObjectMapper(), mock(NotificationService.class), true, "secret");
        ApiException error = assertThrows(ApiException.class, () -> controller.events(1, request));
        assertEquals(401, error.status());
    }

    @Test void scoringEventExposesOnlyAllowListedFeatures() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(startsWith("SELECT *, TIMESTAMPDIFF"), eq(1))).thenReturn(List.of(Map.of(
                "id", 7L, "aggregate_type", "PAYMENT_DEPOSIT", "aggregate_id", 3L,
                "event_type", "PAYMENT_DEPOSIT_PAID", "payload_version", 1,
                "event_age_seconds", 4, "feature_snapshot", "{\"amount\":500,\"hourOfDay\":9,\"email\":\"hidden@example.test\",\"bankAccount\":\"hidden\"}")));
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("X-PawCare-AI-Token")).thenReturn("secret");
        AiInternalController controller = new AiInternalController(db, new ObjectMapper(), mock(NotificationService.class), true, "secret");
        Map<String,Object> event = controller.events(1, request).get(0);
        assertEquals(7L, event.get("eventId"));
        Map<?,?> features = (Map<?,?>) event.get("features");
        assertEquals(500, features.get("amount"));
        assertEquals(9, features.get("hourOfDay"));
        assertEquals(4L, features.get("eventAgeSeconds"));
        org.junit.jupiter.api.Assertions.assertFalse(features.containsKey("email"));
        org.junit.jupiter.api.Assertions.assertFalse(features.containsKey("bankAccount"));
    }

    @Test void duplicateResultIsIdempotentAndDoesNotWriteAgain() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(startsWith("SELECT * FROM ai_scoring_outbox"), eq(7L))).thenReturn(List.of(Map.of("aggregate_type", "PAYMENT_DEPOSIT", "aggregate_id", 3L)));
        when(db.queryForList(startsWith("SELECT id FROM ai_risk_scores"), eq(7L))).thenReturn(List.of(Map.of("id", 1L)));
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("X-PawCare-AI-Token")).thenReturn("secret");
        AiInternalController controller = new AiInternalController(db, new ObjectMapper(), mock(NotificationService.class), true, "secret");
        Map<String,Object> result = controller.result(7, Map.of("riskScore", .5, "riskLevel", "LOW"), request);
        assertEquals(true, result.get("idempotent"));
        verify(db, never()).update(startsWith("INSERT INTO ai_risk_scores"), any(Object[].class));
    }

    @Test void nonAdminCannotReviewRiskScores() {
        AiAdminController controller = new AiAdminController(mock(JdbcTemplate.class), mock(com.pawcare.publicapi.audit.AuditService.class));
        ApiException error = assertThrows(ApiException.class, () -> controller.reviewScore(new CurrentPrincipal(1, "CUSTOMER", "x@x"), 1, Map.of("status", "REVIEWED")));
        assertEquals(403, error.status());
    }
}
