package com.pawcare.publicapi.provider;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.web.ApiException;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/** Canonical server-side access gate for Provider business capabilities. */
@Component
public class ProviderAccessGuard {
    private final JdbcTemplate db;

    public ProviderAccessGuard(JdbcTemplate db) { this.db = db; }

    /** Allows an owner to view and complete their application regardless of decision state. */
    public Map<String, Object> requireProviderProfile(CurrentPrincipal principal) {
        if (!"PROVIDER".equals(principal.role())) throw new ApiException(403, "Provider account required");
        List<Map<String, Object>> rows = db.queryForList(
                "SELECT * FROM providers WHERE owner_profile_id=?", principal.profileId());
        if (rows.isEmpty()) throw new ApiException(403, "Provider profile unavailable");
        return rows.get(0);
    }

    /** Blocks every business operation until the Bonita callback has approved the provider. */
    public Map<String, Object> requireApprovedProvider(CurrentPrincipal principal) {
        Map<String, Object> provider = requireProviderProfile(principal);
        if (!"APPROVED".equals(String.valueOf(provider.get("status"))) || !isActive(provider.get("is_active"))) {
            throw approvalRequired(provider);
        }
        return provider;
    }

    public void requireApprovedProviderId(long providerId) {
        List<Map<String, Object>> rows = db.queryForList(
                "SELECT id,status,is_active FROM providers WHERE id=?", providerId);
        if (rows.isEmpty() || !"APPROVED".equals(String.valueOf(rows.get(0).get("status")))
                || !isActive(rows.get(0).get("is_active"))) {
            String status = rows.isEmpty() ? "UNAVAILABLE" : String.valueOf(rows.get(0).get("status"));
            throw new ApiException(409, "Nhà cung cấp chưa được phê duyệt để sử dụng dịch vụ",
                    "PROVIDER_APPROVAL_REQUIRED", Map.of("providerStatus", status));
        }
    }

    public void requireApprovedIfProvider(CurrentPrincipal principal) {
        if ("PROVIDER".equals(principal.role())) requireApprovedProvider(principal);
    }

    private ApiException approvalRequired(Map<String, Object> provider) {
        return new ApiException(403, "Hồ sơ Provider chưa được phê duyệt để sử dụng chức năng này",
                "PROVIDER_APPROVAL_REQUIRED",
                Map.of("providerStatus", String.valueOf(provider.get("status"))));
    }

    private boolean isActive(Object value) {
        return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1;
    }
}
