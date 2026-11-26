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

    @Test void nonAdminCannotReviewRiskScores() {
        AiAdminController controller = new AiAdminController(mock(JdbcTemplate.class), mock(com.pawcare.publicapi.audit.AuditService.class));
        ApiException error = assertThrows(ApiException.class, () -> controller.reviewScore(new CurrentPrincipal(1, "CUSTOMER", "x@x"), 1, Map.of("status", "REVIEWED")));
        assertEquals(403, error.status());
    }
}
