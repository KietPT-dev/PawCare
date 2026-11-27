package com.pawcare.publicapi.provider;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class ProviderAccessGuardTest {
    private static final CurrentPrincipal PROVIDER = new CurrentPrincipal(7L, "PROVIDER", "provider@pawcare.test");

    @Test
    void pendingProviderGetsStructuredApprovalError() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForList(anyString(), any(Object[].class)))
                .thenReturn(List.of(Map.of("id", 5L, "status", "PENDING", "is_active", 1)));

        ApiException error = assertThrows(ApiException.class,
                () -> new ProviderAccessGuard(db).requireApprovedProvider(PROVIDER));

        assertEquals(403, error.status());
        assertEquals("PROVIDER_APPROVAL_REQUIRED", error.code());
        assertEquals("PENDING", error.details().get("providerStatus"));
    }

    @Test
    void approvedActiveProviderPassesGuard() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        Map<String, Object> provider = Map.of("id", 5L, "status", "APPROVED", "is_active", 1);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(provider));

        assertEquals(provider, new ProviderAccessGuard(db).requireApprovedProvider(PROVIDER));
    }
}
