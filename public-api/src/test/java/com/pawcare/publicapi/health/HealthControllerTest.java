package com.pawcare.publicapi.health;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;

class HealthControllerTest {
    @Test
    void reportsUpWhenDatabaseIsReachable() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        when(db.queryForObject("SELECT 1", Integer.class)).thenReturn(1);

        var response = new HealthController(db).health();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("UP", response.getBody().get("status"));
    }

    @Test
    void reportsUnavailableWithoutLeakingDatabaseFailure() {
        JdbcTemplate db = mock(JdbcTemplate.class);
        doThrow(new DataAccessResourceFailureException("do not expose connection data"))
                .when(db).queryForObject("SELECT 1", Integer.class);

        var response = new HealthController(db).health();

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals("DOWN", response.getBody().get("status"));
    }
}
