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

/** Small Bonita REST adapter for ProviderApproval. It intentionally never updates PawCare provider state. */
@Service
public class RestBonitaProviderApprovalGateway implements BonitaProviderApprovalGateway {
    private final JdbcTemplate db; private final ObjectMapper json; private final ProviderApprovalWorkflowProperties settings;
    public RestBonitaProviderApprovalGateway(JdbcTemplate db, ObjectMapper json, ProviderApprovalWorkflowProperties settings) { this.db=db; this.json=json; this.settings=settings; }

    @Override public void startApprovalCase(long providerId) throws Exception {
        if (!settings.isEnabled()) return;
        Session session=login();
        Map<String,Object> provider=db.queryForList("SELECT id,bonita_case_id FROM providers WHERE id=?",providerId).stream().findFirst().orElseThrow(() -> new IllegalArgumentException("Provider not found"));
        long caseId;
        if (provider.get("bonita_case_id") instanceof Number id) caseId=id.longValue();
        else {
            long processId=processId(session);
            caseId=id(call(session,"POST","/API/bpm/process/"+processId+"/instantiation","{}"),"caseId","id");
            db.update("UPDATE providers SET bonita_case_id=?,bonita_process_definition_id=? WHERE id=? AND bonita_case_id IS NULL",caseId,processId,providerId);
        }
        put(session,caseId,"providerId",Long.toString(providerId)); put(session,caseId,"approvalDecision","PENDING"); put(session,caseId,"reviewNote","");
    }

    @Override public void submitDecision(long providerId, String decision, String reviewNote) throws Exception {
        if (!settings.isEnabled()) throw new IllegalStateException("ProviderApproval Bonita bridge is disabled");
        Long caseId=db.query("SELECT bonita_case_id FROM providers WHERE id=?", rs -> rs.next()?rs.getObject(1,Long.class):null,providerId);
        if (caseId==null) throw new IllegalStateException("Provider approval case has not been created yet");
        Session session=login(); JsonNode task=findReadyTask(session,caseId,"Xét duyệt");
        if (task==null) throw new IllegalStateException("Bonita case #"+caseId+" has no ready task named 'Xét duyệt'");
        call(session,"POST","/API/bpm/userTask/"+id(task,"id")+"/execution",json.writeValueAsString(Map.of("decision",decision,"reviewNote",reviewNote==null?"":reviewNote)));
    }

    private long processId(Session s) throws Exception { JsonNode rows=call(s,"GET","/API/bpm/process?c=100&f="+enc("name="+settings.getProcessName()),null); for(JsonNode row:rows) if("ENABLED".equalsIgnoreCase(text(row,"activationState"))) return id(row,"id"); throw new IllegalStateException("No ENABLED Bonita process named '"+settings.getProcessName()+"' found"); }
    private JsonNode findReadyTask(Session s,long caseId,String name) throws Exception { JsonNode rows=call(s,"GET","/API/bpm/humanTask?c=100&f="+enc("parentCaseId="+caseId)+"&f="+enc("state=ready"),null); for(JsonNode row:rows) if(name.equals(text(row,"displayName"))||name.equals(text(row,"name"))) return row; return null; }
    private void put(Session s,long caseId,String name,String value) throws Exception { call(s,"PUT","/API/bpm/caseVariable/"+caseId+"/"+enc(name),json.writeValueAsString(Map.of("value",value))); }
    private Session login() throws Exception { if(blank(settings.getUsername())||blank(settings.getPassword())) throw new IllegalStateException("ProviderApproval bridge enabled but Bonita credentials are missing"); CookieManager cm=new CookieManager(null,CookiePolicy.ACCEPT_ALL); HttpClient c=HttpClient.newBuilder().cookieHandler(cm).connectTimeout(Duration.ofSeconds(8)).build(); String form="username="+enc(settings.getUsername())+"&password="+enc(settings.getPassword())+"&redirect=false"; HttpResponse<String> r=c.send(HttpRequest.newBuilder(uri("/loginservice")).header("Content-Type","application/x-www-form-urlencoded").POST(HttpRequest.BodyPublishers.ofString(form)).build(),HttpResponse.BodyHandlers.ofString()); if(r.statusCode()/100!=2) throw new IllegalStateException("Bonita login failed (HTTP "+r.statusCode()+")"); String token=r.headers().firstValue("X-Bonita-API-Token").orElse(""); if(token.isBlank()) throw new IllegalStateException("Bonita login did not return CSRF token"); return new Session(c,token); }
    private JsonNode call(Session s,String method,String path,String body) throws Exception { HttpRequest.Builder b=HttpRequest.newBuilder(uri(path)).timeout(Duration.ofSeconds(12)).header("Accept","application/json").header("X-Bonita-API-Token",s.token); if(body!=null)b.header("Content-Type","application/json"); if("GET".equals(method))b.GET(); else if("POST".equals(method))b.POST(HttpRequest.BodyPublishers.ofString(body)); else b.PUT(HttpRequest.BodyPublishers.ofString(body)); HttpResponse<String> r=s.client.send(b.build(),HttpResponse.BodyHandlers.ofString()); if(r.statusCode()/100!=2) throw new IllegalStateException("Bonita "+method+" "+path+" failed (HTTP "+r.statusCode()+")"); return r.body()==null||r.body().isBlank()?json.createObjectNode():json.readTree(r.body()); }
    private URI uri(String path){return URI.create(settings.getBaseUrl().replaceAll("/+$","")+path);} private String enc(String v){return URLEncoder.encode(v,StandardCharsets.UTF_8);} private boolean blank(String v){return v==null||v.isBlank();} private long id(JsonNode n,String... names){for(String name:names)if(n.hasNonNull(name))return n.get(name).asLong();throw new IllegalStateException("Bonita response lacks id");} private String text(JsonNode n,String name){return n.hasNonNull(name)?n.get(name).asText():"";} private record Session(HttpClient client,String token){}
}
