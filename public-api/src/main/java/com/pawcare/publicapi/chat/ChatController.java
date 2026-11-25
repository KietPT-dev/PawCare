package com.pawcare.publicapi.chat;

import com.pawcare.publicapi.auth.CurrentPrincipal;
import com.pawcare.publicapi.auth.CurrentUser;
import com.pawcare.publicapi.chat.dto.ConversationReportRequest;
import com.pawcare.publicapi.chat.dto.SendChatMessageRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class ChatController {
    private final ChatService chat;
    public ChatController(ChatService chat) { this.chat = chat; }

    @PostMapping("/bookings/{bookingId}/conversation")
    public Map<String,Object> createOrGet(@CurrentUser CurrentPrincipal principal, @PathVariable long bookingId) { return chat.createOrGet(principal, bookingId); }
    @GetMapping("/conversations")
    public List<Map<String,Object>> conversations(@CurrentUser CurrentPrincipal principal, @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size) { return chat.list(principal, page, size); }
    @GetMapping("/conversations/{id}/messages")
    public List<Map<String,Object>> messages(@CurrentUser CurrentPrincipal principal, @PathVariable long id, @RequestParam(required=false) Long beforeId, @RequestParam(defaultValue="50") int size) { return chat.messages(principal, id, beforeId, size); }
    @PostMapping("/conversations/{id}/messages")
    public Map<String,Object> send(@CurrentUser CurrentPrincipal principal, @PathVariable long id, @Valid @RequestBody SendChatMessageRequest request) { return chat.send(principal, id, request); }
    @PostMapping("/conversations/{id}/read")
    public Map<String,Object> read(@CurrentUser CurrentPrincipal principal, @PathVariable long id) { return chat.markRead(principal, id); }
    @PostMapping("/conversations/{id}/reports")
    public Map<String,Object> report(@CurrentUser CurrentPrincipal principal, @PathVariable long id, @Valid @RequestBody ConversationReportRequest request) { return chat.report(principal, id, request); }
    @GetMapping("/admin/conversations/reports")
    public List<Map<String,Object>> reports(@CurrentUser CurrentPrincipal principal, @RequestParam(required=false) String status, @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size) { return chat.reports(principal, status, page, size); }
    @GetMapping("/admin/conversations/{id}/messages")
    public List<Map<String,Object>> reportedMessages(@CurrentUser CurrentPrincipal principal, @PathVariable long id, @RequestParam(required=false) Long beforeId, @RequestParam(defaultValue="50") int size) { return chat.reportedMessages(principal, id, beforeId, size); }
}
