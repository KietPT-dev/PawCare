package com.pawcare.publicapi.media;

import com.pawcare.publicapi.web.ApiException;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ProviderCoverService {
    private final JdbcTemplate db;
    private final ProviderCoverStorage storage;
    private final long maxBytes;

    public ProviderCoverService(JdbcTemplate db, ProviderCoverStorage storage,
                                @Value("${pawcare.media.provider-cover-max-bytes:5242880}") long maxBytes) {
        this.db = db;
        this.storage = storage;
        this.maxBytes = maxBytes;
    }

    @Transactional
    public Map<String, Object> replace(long providerId, MultipartFile file) {
        if (file == null || file.isEmpty()) throw new ApiException(400, "Cover image is required");
        if (file.getSize() > maxBytes) throw new ApiException(400, "Cover image exceeds maximum size");
        if (!List.of("image/jpeg", "image/png", "image/webp").contains(file.getContentType())) throw new ApiException(400, "Cover image must be JPEG, PNG or WebP");
        Map<String, Object> provider = one(providerId);
        if (provider == null) throw new ApiException(404, "Provider not found");
        try {
            String publicUrl = storage.store(providerId, file);
            db.update("UPDATE providers SET cover_image_url=? WHERE id=?", publicUrl, providerId);
            deleteQuietly((String) provider.get("cover_image_url"));
            return Map.of("success", true, "coverImageUrl", publicUrl);
        } catch (IOException error) {
            throw new ApiException(503, "Cover image storage is unavailable");
        }
    }

    @Transactional
    public Map<String, Object> remove(long providerId) {
        Map<String, Object> provider = one(providerId);
        if (provider == null) throw new ApiException(404, "Provider not found");
        db.update("UPDATE providers SET cover_image_url=NULL WHERE id=?", providerId);
        deleteQuietly((String) provider.get("cover_image_url"));
        return Map.of("success", true);
    }

    private Map<String, Object> one(long providerId) {
        List<Map<String, Object>> rows = db.queryForList("SELECT id,cover_image_url FROM providers WHERE id=?", providerId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    private void deleteQuietly(String url) {
        try { storage.delete(url); } catch (IOException ignored) { /* old media is safe to retry/clean later */ }
    }
}
