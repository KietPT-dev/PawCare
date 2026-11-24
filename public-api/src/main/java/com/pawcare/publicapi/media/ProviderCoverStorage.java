package com.pawcare.publicapi.media;

import java.io.IOException;
import org.springframework.web.multipart.MultipartFile;

public interface ProviderCoverStorage {
    String store(long providerId, MultipartFile file) throws IOException;
    void delete(String publicUrl) throws IOException;
}
