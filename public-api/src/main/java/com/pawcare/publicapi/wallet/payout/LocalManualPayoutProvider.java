package com.pawcare.publicapi.wallet.payout;

import org.springframework.stereotype.Component;

/** Local-safe adapter: creates a reconciliation reference only; it never calls a bank. */
@Component
public class LocalManualPayoutProvider implements PayoutProvider {
    @Override public PayoutSubmission submit(PayoutInstruction instruction) {
        return new PayoutSubmission("LOCAL-MANUAL-" + instruction.withdrawalId(), "PROCESSING",
                "Manual reconciliation required; no bank transfer was initiated.");
    }
}
