package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
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

    public WalletController(WalletService wallets) { this.wallets = wallets; }

    @GetMapping("/wallets/me")
    public Map<String, Object> mine(@CurrentUser CurrentPrincipal principal) {
        return wallets.myWallet(principal);
    }

    @GetMapping("/wallets/me/transactions")
    public Object transactions(@CurrentUser CurrentPrincipal principal) {
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
    public Map<String,Object> providerWallet(@CurrentUser CurrentPrincipal principal) { return wallets.providerOverview(principal); }

    @GetMapping("/provider/wallet/payouts")
    public Object providerPayouts(@CurrentUser CurrentPrincipal principal) { return wallets.providerPayouts(principal); }

    @GetMapping("/provider/wallet/withdrawals")
    public Object providerWithdrawals(@CurrentUser CurrentPrincipal principal) { return wallets.providerWithdrawals(principal); }

    @PostMapping("/wallets/withdraw")
    public Map<String, Object> withdraw(@CurrentUser CurrentPrincipal principal,
                                         @Valid @RequestBody WithdrawRequest request) {
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
}
