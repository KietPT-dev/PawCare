package com.pawcare.publicapi.media;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

/** Local-only storage adapter. Replace this interface implementation for S3/object storage. */
@Service
public class LocalProviderCoverStorage implements ProviderCoverStorage {
    private static final Map<String, String> EXTENSIONS = Map.of("image/jpeg", ".jpg", "image/png", ".png", "image/webp", ".webp");
    private final Path root;
    private final String publicPath;

    public LocalProviderCoverStorage(@Value("${pawcare.media.provider-cover-directory:./data/provider-covers}") String root,
                                     @Value("${pawcare.media.provider-cover-public-path:/api/v1/media/provider-covers/}") String publicPath) {
        this.root = Path.of(root).toAbsolutePath().normalize();
        this.publicPath = publicPath.endsWith("/") ? publicPath : publicPath + "/";
    }

    @Override
    public String store(long providerId, MultipartFile file) throws IOException {
        String extension = EXTENSIONS.get(file.getContentType());
        if (extension == null) throw new IllegalArgumentException("Unsupported image type");
        Files.createDirectories(root);
        String filename = "provider-" + providerId + "-" + UUID.randomUUID() + extension;
        Path destination = root.resolve(filename).normalize();
        if (!destination.startsWith(root)) throw new IOException("Invalid upload destination");
        Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
        return publicPath + filename;
    }

    @Override
    public void delete(String publicUrl) throws IOException {
        if (publicUrl == null || !publicUrl.startsWith(publicPath)) return;
        String filename = publicUrl.substring(publicPath.length());
        Path target = root.resolve(filename).normalize();
        if (target.startsWith(root)) Files.deleteIfExists(target);
    }
}
