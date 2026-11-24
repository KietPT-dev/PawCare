package com.pawcare.publicapi.media;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;

class ProviderCoverServiceTest {
    @Test
    void replacesOwnCoverWithAValidatedImage() throws Exception {
        JdbcTemplate db = mock(JdbcTemplate.class);
        ProviderCoverStorage storage = mock(ProviderCoverStorage.class);
        when(db.queryForList(anyString(), any(Object[].class))).thenReturn(List.of(Map.of("id", 8L, "cover_image_url", "/api/v1/media/provider-covers/old.jpg")));
        when(storage.store(anyLong(), any())).thenReturn("/api/v1/media/provider-covers/new.jpg");
        ProviderCoverService service = new ProviderCoverService(db, storage, 1024);

        Map<String, Object> result = service.replace(8L, new MockMultipartFile("file", "cover.jpg", "image/jpeg", new byte[] {1, 2}));

        assertEquals("/api/v1/media/provider-covers/new.jpg", result.get("coverImageUrl"));
        verify(db).update(anyString(), any(Object[].class));
        verify(storage).delete("/api/v1/media/provider-covers/old.jpg");
    }
}
