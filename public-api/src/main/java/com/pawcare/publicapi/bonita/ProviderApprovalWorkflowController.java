package com.pawcare.publicapi.bonita;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.bonita.dto.ProviderApprovalCallbackRequest;
import com.pawcare.publicapi.bonita.dto.ProviderApprovalDecisionRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** API boundary between the Admin portal, Bonita ProviderApproval, and canonical provider data. */
@RestController
@RequestMapping("/api/v1")
public class ProviderApprovalWorkflowController {
    private final ProviderApprovalWorkflowService workflow;

    public ProviderApprovalWorkflowController(ProviderApprovalWorkflowService workflow) { this.workflow = workflow; }

    @GetMapping("/admin/providers/{providerId}/workflow")
    public Map<String, Object> status(@CurrentUser CurrentPrincipal principal, @PathVariable long providerId) {
        return workflow.status(principal, providerId);
    }

    @PostMapping("/admin/providers/{providerId}/workflow/retry")
    public Map<String, Object> retry(@CurrentUser CurrentPrincipal principal, @PathVariable long providerId) {
        return workflow.retry(principal, providerId);
    }

    @PostMapping("/admin/providers/{providerId}/workflow/decision")
    public Map<String, Object> submitDecision(@CurrentUser CurrentPrincipal principal, @PathVariable long providerId,
                                               @Valid @RequestBody ProviderApprovalDecisionRequest request) {
        return workflow.submitDecision(principal, providerId, request);
    }

    @PostMapping("/internal/provider-approval/synchronize")
    public Map<String, Object> synchronize(@RequestHeader(value = "X-PawCare-Workflow-Token", required = false) String workflowToken,
                                           @RequestHeader(value = "Authorization", required = false) String authorization,
                                           @Valid @RequestBody ProviderApprovalCallbackRequest request) {
        workflow.requireBridgeToken(workflowToken, authorization);
        return workflow.applyBonitaDecision(request);
    }
}
