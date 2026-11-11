package com.pawcare.publicapi.wallet.payout;

import java.math.BigDecimal;

/** Boundary for a future bank/disbursement integration. Implementations must
 * never move money implicitly when an administrator merely approves a request. */
public interface PayoutProvider {
    PayoutSubmission submit(PayoutInstruction instruction);

    record PayoutInstruction(long withdrawalId, BigDecimal amount) { }
    record PayoutSubmission(String reference, String state, String message) { }
}
