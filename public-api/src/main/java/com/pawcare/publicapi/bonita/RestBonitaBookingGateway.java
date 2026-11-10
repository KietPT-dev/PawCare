package com.pawcare.publicapi.bonita;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Minimal Bonita Engine REST client used only by the workflow outbox. */
@Service
public class RestBonitaBookingGateway implements BonitaBookingGateway {
    private final JdbcTemplate db;
    private final ObjectMapper json;
    private final BonitaWorkflowProperties settings;

    public RestBonitaBookingGateway(JdbcTemplate db, ObjectMapper json, BonitaWorkflowProperties settings) {
        this.db = db;
        this.json = json;
        this.settings = settings;
    }

    @Override
    public void synchronize(long bookingId, BookingWorkflowEvent event) throws Exception {
        if (!settings.isEnabled()) return;
        if (blank(settings.getUsername()) || blank(settings.getPassword())) {
            throw new IllegalStateException("Bonita workflow is enabled but PAWCARE_BONITA_USERNAME/PASSWORD is missing");
        }
        Session session = login();
        if (event == BookingWorkflowEvent.START) {
            startCase(session, bookingId);
            return;
        }
        Long caseId = db.query("SELECT bonita_case_id FROM bookings WHERE id=?", rs -> rs.next() ? rs.getObject(1, Long.class) : null, bookingId);
        if (caseId == null) throw new IllegalStateException("Booking #" + bookingId + " has no Bonita case yet; START must be synchronized first");
        synchronizeExistingCase(session, caseId, event);
    }

    private void startCase(Session session, long bookingId) throws Exception {
        Map<String, Object> existing = db.queryForList("SELECT bonita_case_id FROM bookings WHERE id=?", bookingId).stream().findFirst().orElse(null);
        if (existing == null) throw new IllegalStateException("Booking #" + bookingId + " does not exist");
        long caseId;
        if (existing.get("bonita_case_id") instanceof Number number) {
            caseId = number.longValue();
        } else {
            long processId = processId(session);
            JsonNode created = call(session, "POST", "/API/bpm/process/" + processId + "/instantiation", "{}");
            caseId = id(created, "caseId", "id");
            db.update("UPDATE bookings SET bonita_case_id=?,bonita_process_definition_id=? WHERE id=?", caseId, processId, bookingId);
        }
        putVariable(session, caseId, "bookingId", Long.toString(bookingId));
        // In the v2 process this is a technical bootstrap task. The external
        // customer has already created the booking in PawCare, so they never
        // need a Bonita login or a Bonita form.
        completeNamedTask(session, caseId, "Đặt lịch", false);
    }

    private void synchronizeExistingCase(Session session, long caseId, BookingWorkflowEvent event) throws Exception {
        switch (event) {
            case PROVIDER_APPROVED -> {
                putVariable(session, caseId, "bookingAccepted", "true");
                completeNamedTask(session, caseId, "Xác nhận lịch", true);
            }
            case PROVIDER_REJECTED -> {
                putVariable(session, caseId, "bookingAccepted", "false");
                completeNamedTask(session, caseId, "Xác nhận lịch", true);
            }
            case PROVIDER_SERVICE_DONE -> completeNamedTask(session, caseId, "Báo hoàn tất dịch vụ", true);
            case CUSTOMER_CONFIRMED -> {
                putVariable(session, caseId, "customerDecision", "CONFIRM");
                completeNamedTask(session, caseId, "Xác nhận hoàn tất", true);
            }
            case CUSTOMER_DISPUTED -> {
                putVariable(session, caseId, "customerDecision", "DISPUTE");
                completeNamedTask(session, caseId, "Xác nhận hoàn tất", true);
            }
            case ADMIN_RELEASE_TO_PROVIDER -> {
                putVariable(session, caseId, "disputeDecision", "RELEASE_TO_PROVIDER");
                completeNamedTask(session, caseId, "Xử lý tranh chấp", true);
            }
            case ADMIN_REFUND_TO_CUSTOMER -> {
                putVariable(session, caseId, "disputeDecision", "REFUND_TO_CUSTOMER");
                completeNamedTask(session, caseId, "Xử lý tranh chấp", true);
            }
            // Cancellation and expiry are terminal events in PawCare. A v2
            // diagram should include a boundary/message event if visual close
            // out of those cases is required; they are kept as audited outbox
            // records even when no human task needs completion.
            case CANCELLED, EXPIRED -> { }
            default -> throw new IllegalArgumentException("Unsupported workflow event " + event);
        }
    }

    private long processId(Session session) throws Exception {
        String filter = encode("name=" + settings.getProcessName());
        JsonNode rows = call(session, "GET", "/API/bpm/process?c=100&f=" + filter, null);
        if (!rows.isArray() || rows.isEmpty()) throw new IllegalStateException("Deployed Bonita process '" + settings.getProcessName() + "' was not found");
        // Bonita keeps older deployed versions in the same response. Never
        // instantiate the first match blindly: it may be a disabled version.
        for (JsonNode row : rows) {
            if ("ENABLED".equalsIgnoreCase(text(row, "activationState"))) {
                return id(row, "id");
            }
        }
        throw new IllegalStateException("No ENABLED Bonita process named '" + settings.getProcessName() + "' was found");
    }

    private void completeNamedTask(Session session, long caseId, String taskName, boolean required) throws Exception {
        JsonNode rows = call(session, "GET", "/API/bpm/humanTask?c=100&f=" + encode("parentCaseId=" + caseId) + "&f=" + encode("state=ready"), null);
        JsonNode task = null;
        if (rows.isArray()) for (JsonNode row : rows) {
            if (taskName.equals(text(row, "displayName")) || taskName.equals(text(row, "name"))) { task = row; break; }
        }
        if (task == null) {
            if (required) throw new IllegalStateException("Bonita case #" + caseId + " has no ready task named '" + taskName + "'");
            return;
        }
        call(session, "PUT", "/API/bpm/humanTask/" + id(task, "id"), "{\"state\":\"completed\"}");
    }

    private void putVariable(Session session, long caseId, String name, String value) throws Exception {
        call(session, "PUT", "/API/bpm/caseVariable/" + caseId + "/" + encode(name), json.writeValueAsString(Map.of("value", value)));
    }

    private Session login() throws Exception {
        CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        HttpClient client = HttpClient.newBuilder().cookieHandler(cookies).connectTimeout(Duration.ofSeconds(8)).build();
        String form = "username=" + encode(settings.getUsername()) + "&password=" + encode(settings.getPassword()) + "&redirect=false";
        HttpResponse<String> response = client.send(HttpRequest.newBuilder(uri("/loginservice"))
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .POST(HttpRequest.BodyPublishers.ofString(form)).build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() / 100 != 2) throw new IllegalStateException("Bonita login failed (HTTP " + response.statusCode() + ")");
        String token = response.headers().firstValue("X-Bonita-API-Token").orElse("");
        if (token.isBlank()) throw new IllegalStateException("Bonita login did not return X-Bonita-API-Token");
        return new Session(client, token);
    }

    private JsonNode call(Session session, String method, String path, String body) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path)).timeout(Duration.ofSeconds(12))
                .header("Accept", "application/json").header("X-Bonita-API-Token", session.csrfToken);
        if (body != null) request.header("Content-Type", "application/json");
        switch (method) {
            case "GET" -> request.GET();
            case "POST" -> request.POST(HttpRequest.BodyPublishers.ofString(body));
            case "PUT" -> request.PUT(HttpRequest.BodyPublishers.ofString(body));
            default -> throw new IllegalArgumentException("Unsupported HTTP method " + method);
        }
        HttpResponse<String> response = session.client.send(request.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() / 100 != 2) throw new IllegalStateException("Bonita " + method + " " + path + " failed (HTTP " + response.statusCode() + "): " + response.body());
        return response.body() == null || response.body().isBlank() ? json.createObjectNode() : json.readTree(response.body());
    }

    private URI uri(String path) { return URI.create(settings.getBaseUrl().replaceAll("/+$", "") + path); }
    private String encode(String value) { return URLEncoder.encode(value, StandardCharsets.UTF_8); }
    private boolean blank(String value) { return value == null || value.isBlank(); }
    private long id(JsonNode node, String... fields) {
        for (String field : fields) if (node.hasNonNull(field)) return node.get(field).asLong();
        throw new IllegalStateException("Bonita response does not contain an id: " + node);
    }
    private String text(JsonNode node, String field) { return node.hasNonNull(field) ? node.get(field).asText() : ""; }
    private record Session(HttpClient client, String csrfToken) { }
}
