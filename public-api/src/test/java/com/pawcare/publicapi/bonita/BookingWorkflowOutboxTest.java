package com.pawcare.publicapi.bonita;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

class BookingWorkflowOutboxTest {
    @Test
    void doesNotDeliverWhenAnotherWorkerAlreadyClaimedEvent() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        BonitaBookingGateway gateway = mock(BonitaBookingGateway.class);
        BonitaWorkflowProperties properties = new BonitaWorkflowProperties();
        properties.setEnabled(true);
        when(db.queryForList(anyString(), anyLong())).thenReturn(List.of(Map.of("id", 7L, "booking_id", 19L, "event_type", "START")));
        when(db.update(anyString(), any(Object[].class))).thenReturn(0);

        new BookingWorkflowOutbox(db, new ObjectMapper(), gateway, properties).synchronizeNow(19L);

        verifyNoInteractions(gateway);
    }

    @Test
    void claimsAndDeliversEventOnce() throws Exception {
        JdbcTemplate db = mock(JdbcTemplate.class);
        BonitaBookingGateway gateway = mock(BonitaBookingGateway.class);
        BonitaWorkflowProperties properties = new BonitaWorkflowProperties();
        properties.setEnabled(true);
        when(db.queryForList(anyString(), anyLong())).thenReturn(List.of(Map.of("id", 7L, "booking_id", 19L, "event_type", "START")));
        when(db.update(anyString(), any(Object[].class))).thenReturn(1);

        new BookingWorkflowOutbox(db, new ObjectMapper(), gateway, properties).synchronizeNow(19L);

        verify(gateway).synchronize(19L, BookingWorkflowEvent.START);
        verify(db, times(2)).update(anyString(), any(Object[].class));
    }
}
