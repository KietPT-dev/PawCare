package com.pawcare.publicapi.auth;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

final class AccountEmailFactory {
    private AccountEmailFactory() { }

    static TransactionalEmail verification(String email, String fullName, String baseLink, String token) {
        String link = actionLink(baseLink, "verify-email", token);
        String greeting = greeting(fullName);
        return new TransactionalEmail(email, "Xác minh email PawCare",
                greeting + "\n\nBạn vừa yêu cầu xác minh email cho tài khoản PawCare. Mở liên kết này trong ứng dụng PawCare để hoàn tất: "
                        + link + "\n\nLiên kết có hiệu lực trong 30 phút và chỉ dùng được một lần. Không chia sẻ liên kết này. Nếu bạn không thực hiện yêu cầu, hãy bỏ qua email này.",
                "<p>" + greetingHtml(fullName) + "</p><p>Bạn vừa yêu cầu xác minh email cho tài khoản PawCare.</p>"
                        + "<p><a href=\"" + escapeHtml(link) + "\">Xác minh email trong ứng dụng PawCare</a></p>"
                        + "<p>Liên kết có hiệu lực trong 30 phút và chỉ dùng được một lần. Không chia sẻ liên kết này. Nếu bạn không thực hiện yêu cầu, hãy bỏ qua email này.</p>",
                "EMAIL_VERIFY");
    }

    static TransactionalEmail passwordReset(String email, String fullName, String baseLink, String token) {
        String link = actionLink(baseLink, "reset-password", token);
        String greeting = greeting(fullName);
        return new TransactionalEmail(email, "Đặt lại mật khẩu PawCare",
                greeting + "\n\nBạn vừa yêu cầu đặt lại mật khẩu PawCare. Mở liên kết này trong ứng dụng PawCare để tiếp tục: "
                        + link + "\n\nLiên kết có hiệu lực trong 30 phút và chỉ dùng được một lần. Không chia sẻ liên kết này. Nếu bạn không thực hiện yêu cầu, hãy bỏ qua email này.",
                "<p>" + greetingHtml(fullName) + "</p><p>Bạn vừa yêu cầu đặt lại mật khẩu PawCare.</p>"
                        + "<p><a href=\"" + escapeHtml(link) + "\">Đặt lại mật khẩu trong ứng dụng PawCare</a></p>"
                        + "<p>Liên kết có hiệu lực trong 30 phút và chỉ dùng được một lần. Không chia sẻ liên kết này. Nếu bạn không thực hiện yêu cầu, hãy bỏ qua email này.</p>",
                "PASSWORD_RESET");
    }

    static TransactionalEmail passwordChanged(String email, String fullName) {
        String greeting = greeting(fullName);
        return new TransactionalEmail(email, "Mật khẩu PawCare đã được thay đổi",
                greeting + "\n\nMật khẩu PawCare của bạn vừa được thay đổi. Nếu đây không phải là bạn, hãy liên hệ hỗ trợ ngay.",
                "<p>" + greetingHtml(fullName) + "</p><p>Mật khẩu PawCare của bạn vừa được thay đổi.</p><p>Nếu đây không phải là bạn, hãy liên hệ hỗ trợ ngay.</p>",
                "PASSWORD_CHANGED");
    }

    private static String actionLink(String baseLink, String action, String token) {
        baseLink = baseLink.replaceAll("/+$", "");
        String separator = baseLink.contains("?") ? "&" : "?";
        return baseLink + "/" + action + separator + "token=" + URLEncoder.encode(token, StandardCharsets.UTF_8);
    }

    private static String greeting(String fullName) {
        return "Xin chào " + (fullName == null || fullName.isBlank() ? "bạn" : fullName.trim()) + ",";
    }

    private static String greetingHtml(String fullName) {
        return escapeHtml(greeting(fullName));
    }

    private static String escapeHtml(String value) {
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
}
