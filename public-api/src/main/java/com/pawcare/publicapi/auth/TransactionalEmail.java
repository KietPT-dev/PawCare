package com.pawcare.publicapi.auth;

/** The values are intentionally transient: neither body nor link is stored. */
public record TransactionalEmail(String recipient, String subject, String textBody, String htmlBody, String template) { }
