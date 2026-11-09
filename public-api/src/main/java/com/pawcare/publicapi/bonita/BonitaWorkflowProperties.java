package com.pawcare.publicapi.bonita;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Settings for the server-to-server bridge to Bonita Engine. */
@ConfigurationProperties(prefix = "pawcare.bonita.workflow")
public class BonitaWorkflowProperties {
    /** Disabled until the BookingService v2 process and its actor mapping are deployed. */
    private boolean enabled;
    private String baseUrl = "http://127.0.0.1:62666/bonita";
    private String username;
    private String password;
    private String processName = "BookingService";
    private long retryDelayMs = 15000;

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public String getBaseUrl() { return baseUrl; }
    public void setBaseUrl(String baseUrl) { this.baseUrl = baseUrl; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getProcessName() { return processName; }
    public void setProcessName(String processName) { this.processName = processName; }
    public long getRetryDelayMs() { return retryDelayMs; }
    public void setRetryDelayMs(long retryDelayMs) { this.retryDelayMs = retryDelayMs; }
}
