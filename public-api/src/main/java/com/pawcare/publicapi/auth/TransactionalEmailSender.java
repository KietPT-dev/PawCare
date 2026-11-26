package com.pawcare.publicapi.auth;

/**
 * Sends transactional account-security messages. Implementations must never
 * persist or log action-token links because those links authenticate the user.
 */
public interface TransactionalEmailSender {
    void send(TransactionalEmail message);
}
