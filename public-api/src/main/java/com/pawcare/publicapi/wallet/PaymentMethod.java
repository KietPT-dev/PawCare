package com.pawcare.publicapi.wallet;

import com.pawcare.publicapi.web.ApiException;
import java.util.Locale;

public enum PaymentMethod {
    WALLET, VIETQR;

    public static PaymentMethod from(Object value) {
        if (value == null) return VIETQR;
        try {
            return valueOf(value.toString().trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new ApiException(400, "paymentMethod must be WALLET or VIETQR");
        }
    }
}
