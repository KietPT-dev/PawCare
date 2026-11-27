package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.provider.ProviderAccessGuard;
import com.pawcare.publicapi.wallet.dto.WithdrawRequest;
import com.pawcare.publicapi.wallet.dto.WithdrawalDecisionRequest;
import com.pawcare.publicapi.wallet.dto.TopUpRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class WalletController {
    private final WalletService wallets;
    private final ProviderAccessGuard providerAccess;

    public WalletController(WalletService wallets, ProviderAccessGuard providerAccess) { this.wallets = wallets; this.providerAccess = providerAccess; }

    @GetMapping("/wallets/me")
    public Map<String, Object> mine(@CurrentUser CurrentPrincipal principal) {
        approveProviderIfNeeded(principal);
        return wallets.myWallet(principal);
    }

    @GetMapping("/wallets/me/transactions")
    public Object transactions(@CurrentUser CurrentPrincipal principal) {
        approveProviderIfNeeded(principal);
        return wallets.myTransactions(principal);
    }

    @PostMapping("/wallets/topups")
    public Map<String, Object> topUp(@CurrentUser CurrentPrincipal principal, @Valid @RequestBody TopUpRequest request) {
        return wallets.createTopUp(principal, request);
    }

    @GetMapping("/wallets/topups/{id}")
    public Map<String, Object> topUpStatus(@CurrentUser CurrentPrincipal principal, @PathVariable long id) {
        return wallets.topUpStatus(principal, id);
    }

    @GetMapping("/provider/wallet")
    public Map<String,Object> providerWallet(@CurrentUser CurrentPrincipal principal) { providerAccess.requireApprovedProvider(principal); return wallets.providerOverview(principal); }

    @GetMapping("/provider/wallet/payouts")
    public Object providerPayouts(@CurrentUser CurrentPrincipal principal) { providerAccess.requireApprovedProvider(principal); return wallets.providerPayouts(principal); }

    @GetMapping("/provider/wallet/withdrawals")
    public Object providerWithdrawals(@CurrentUser CurrentPrincipal principal) { providerAccess.requireApprovedProvider(principal); return wallets.providerWithdrawals(principal); }

    @PostMapping("/wallets/withdraw")
    public Map<String, Object> withdraw(@CurrentUser CurrentPrincipal principal,
                                         @Valid @RequestBody WithdrawRequest request) {
        providerAccess.requireApprovedIfProvider(principal);
        return wallets.requestWithdrawal(principal, request);
    }

    @GetMapping("/admin/withdrawals")
    public Object withdrawals(@CurrentUser CurrentPrincipal principal,
                              @RequestParam(required = false) String status) {
        return wallets.listWithdrawals(principal, status);
    }

    @PutMapping("/admin/withdrawals/{id}")
    public Map<String, Object> decide(@CurrentUser CurrentPrincipal principal,
                                      @PathVariable long id,
                                      @Valid @RequestBody WithdrawalDecisionRequest request) {
        return wallets.decideWithdrawal(principal, id, request);
    }

    private void approveProviderIfNeeded(CurrentPrincipal principal) {
        providerAccess.requireApprovedIfProvider(principal);
    }
}
