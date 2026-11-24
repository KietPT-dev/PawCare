# -*- coding: utf-8 -*-
from docx_helpers import (
    add_heading_1, add_heading_2, add_heading_3, add_body_p, 
    add_bullet_p, add_image_figure, add_table_caption
)

def build_chapter_4(doc):
    add_heading_1(doc, "CHƯƠNG 4. THIẾT KẾ GIAO DIỆN")
    
    add_body_p(doc,
        "Thiết kế giao diện người dùng (User Interface - UI) và trải nghiệm người dùng (User Experience - UX) "
        "đóng vai trò quyết định đến tính khả dụng, mức độ hài lòng và sự đón nhận của người dùng đối với hệ thống phần mềm. "
        "Hệ thống PawCare được thiết kế theo mô hình đa nền tảng đáp ứng chuyên biệt cho 3 nhóm đối tượng sử dụng: "
        "(1) Khách hàng sử dụng ứng dụng di động native đa nền tảng Flutter; (2) Đối tác nhà cung cấp sử dụng Cổng thông tin Web "
        "đơn trang (SPA) bằng React và Vite; và (3) Quản trị viên sử dụng Cổng điều phối quản trị xây dựng trên nền tảng Bonita BPM UI Designer. "
        "Chương 4 trình bày kiến trúc bản đồ màn hình tổng thể và thiết kế chi tiết các màn hình nghiệp vụ trọng tâm của từng phân hệ."
    )

    # 4.1 Kiến trúc bản đồ màn hình
    add_heading_2(doc, "4.1. Kiến trúc bản đồ màn hình hệ thống (UI Sitemap)")
    add_body_p(doc,
        "Kiến trúc điều hướng màn hình của hệ thống PawCare được thiết kế dựa trên tài liệu đặc tả thiết kế giai đoạn 2 "
        "(Thiet_ke_REST_UI_BPMN_PawCare.docx), đảm bảo tính phân cấp mạch lạc, trực quan và tối ưu hóa số lượt nhấp chuột (clicks) "
        "của người dùng để hoàn thành một tác vụ:"
    )

    add_image_figure(doc, "downloads_staging/ui_map.png", 
                     "Hình 4.1. Bản đồ luồng điều hướng màn hình hệ thống PawCare (UI Sitemap)", 6.0)
    add_body_p(doc,
        "Hình 4.1 biểu diễn bản đồ tương tác màn hình của toàn bộ 3 phân hệ. Thiết kế giao diện của PawCare tuân thủ nghiêm ngặt "
        "các nguyên tắc thiết kế UI/UX chuyên nghiệp sau:"
    )
    add_bullet_p(doc,
        "Mỗi màn hình chỉ tập trung dẫn dắt người dùng thực hiện một hành động cốt lõi rõ ràng (Single Primary Action): "
        "Ví dụ nút \"Đặt lịch ngay\" cố định ở đáy màn hình chi tiết dịch vụ, nút \"Chấp nhận booking\" trên thẻ đơn hàng, "
        "hoặc nút \"Phê duyệt đối tác\" trên hồ sơ thẩm định.",
        bold_prefix="Hành động chính rõ ràng: "
    )
    add_bullet_p(doc,
        "Giao diện chỉ hiển thị các nút thao tác mà vai trò (Role) và trạng thái hiện tại của đơn hàng cho phép. "
        "Tuyệt đối không để người dùng tự do lựa chọn trạng thái nhảy cóc (ví dụ: đối tác không thể nhảy từ IN_SERVICE sang COMPLETED "
        "mà bắt buộc phải qua SERVICE_DONE để chờ khách xác nhận).",
        bold_prefix="Hiển thị hành động theo ngữ cảnh: "
    )
    add_bullet_p(doc,
        "Các biểu mẫu nhập liệu (Form) hiển thị thông báo lỗi xác thực (Validation) ngay cạnh trường nhập liệu vi phạm với màu đỏ nổi bật "
        "và thông báo tiếng Việt rõ nghĩa, kèm dấu sao (*) bắt buộc đối với các trường then chốt.",
        bold_prefix="Xác thực tại chỗ (In-place Validation): "
    )
    add_bullet_p(doc,
        "Toàn bộ hệ thống áp dụng bộ quy ước màu sắc trạng thái booking đồng bộ trên cả Mobile, Web Đối tác và Web Admin: "
        "Màu vàng cam đại diện cho trạng thái PENDING (Chờ xử lý); Màu xanh dương đại diện cho CONFIRMED (Đã xác nhận); "
        "Màu tím đại diện cho IN_SERVICE (Đang thực hiện); Màu xanh ngọc đại diện cho SERVICE_DONE (Chờ khách duyệt); "
        "Màu xanh lá cây đại diện cho COMPLETED (Hoàn tất); và Màu đỏ đại diện cho CANCELLED / REJECTED (Đã hủy / Từ chối).",
        bold_prefix="Quy chuẩn màu trạng thái thống nhất: "
    )

    # 4.2 Giao diện Mobile Khách hàng
    add_heading_2(doc, "4.2. Giao diện ứng dụng di động dành cho Khách hàng (Flutter)")
    add_body_p(doc,
        "Ứng dụng di động khách hàng (pawcare-customer-mobile) được tối ưu hóa cho trải nghiệm di động trên cả hai nền tảng iOS và Android. "
        "Cấu trúc giao diện được tổ chức theo các luồng nghiệp vụ chính:"
    )
    add_bullet_p(doc,
        "Cung cấp hai tab chuyển đổi mượt mà giữa Đăng nhập và Đăng ký. Biểu mẫu đăng ký yêu cầu họ tên, email, số điện thoại và mật khẩu. "
        "Mật khẩu có nút ẩn/hiện trực quan. Khi đăng nhập thành công, token JWT được lưu trữ an toàn vào SharedPreferences để duy trì phiên đăng nhập.",
        bold_prefix="1. Màn hình Xác thực (auth_screen.dart): "
    )
    add_bullet_p(doc,
        "Trang chủ hiển thị thanh tìm kiếm nhanh ở phía trên, banner các chương trình ưu đãi, danh sách các danh mục dịch vụ nổi bật "
        "(Tắm vệ sinh, Cắt tỉa lông, Khách sạn lưu trú), và danh sách các cơ sở chăm sóc được đề xuất theo thuật toán thông minh "
        "kèm khoảng cách địa lý (km), điểm đánh giá số sao và mức giá khởi điểm.",
        bold_prefix="2. Màn hình Trang chủ & Khám phá (home_screen.dart & discovery_screen.dart): "
    )
    add_bullet_p(doc,
        "Hiển thị toàn bộ thông tin chi tiết của cơ sở: bộ sưu tập hình ảnh cơ sở vật chất, địa chỉ trụ sở, giờ mở cửa/đóng cửa, "
        "giới thiệu chuyên môn, bảng giá niêm yết của từng dịch vụ kèm thời lượng thực hiện, danh sách kỹ thuật viên kèm chứng chỉ, "
        "và danh sách các bài nhận xét đánh giá từ khách hàng trước. Nút \"Đặt lịch\" luôn được ghim cố định ở đáy màn hình.",
        bold_prefix="3. Màn hình Chi tiết Đối tác & Dịch vụ (provider_detail_screen.dart): "
    )
    add_bullet_p(doc,
        "Khách hàng lựa chọn thú cưng thụ hưởng dịch vụ từ danh sách thú cưng cá nhân (nếu chưa có có thể nhấn nút thêm nhanh). "
        "Chọn ngày hẹn trên lịch tuần (Calendar Strip). Khi chọn ngày, hệ thống gọi API truy vấn các khung giờ còn trống (availability slots) "
        "và hiển thị dạng thẻ thời gian (chip slots): ô màu xanh là slot còn rảnh, ô xám mờ là slot đã có người đặt hoặc quá giờ.",
        bold_prefix="4. Màn hình Cấu hình Đặt lịch (booking_screen.dart): "
    )
    add_bullet_p(doc,
        "Tóm tắt chi tiết đơn đặt lịch: thông tin dịch vụ, kỹ thuật viên phụ trách, thời gian hẹn, tổng số tiền thanh toán. "
        "Khách hàng lựa chọn phương thức thanh toán: Trừ tiền từ số dư Ví PawCare hoặc Quét mã VietQR chuyển khoản nhanh. "
        "Màn hình hiển thị rõ chính sách tạm giữ ký quỹ: \"Số tiền này sẽ được giữ an toàn và chỉ thanh toán cho đối tác khi quý khách đã hài lòng xác nhận hoàn tất\".",
        bold_prefix="5. Màn hình Xác nhận Đơn hàng & Thanh toán (booking_checkout_screen.dart): "
    )
    add_bullet_p(doc,
        "Trực quan hóa tiến trình thực hiện theo dạng thanh tiến trình (Stepper): Đã đặt hẹn -> Đã xác nhận -> Đã tiếp nhận (Checked-in) -> "
        "Đang làm dịch vụ (In-service) -> Đối tác hoàn tất (Service Done). Khi ở trạng thái SERVICE_DONE, màn hình bật sáng nút nổi bật: "
        "\"Xác nhận hoàn tất dịch vụ\" và nút \"Khiếu nại / Tranh chấp\". Sau khi nhấn xác nhận, hệ thống tự động mở cửa sổ đánh giá sao (1-5 sao) "
        "và khung viết nhận xét.",
        bold_prefix="6. Màn hình Chi tiết Tiến độ & Đánh giá (booking_detail_screen.dart): "
    )
    add_bullet_p(doc,
        "Danh sách thẻ thú cưng với ảnh đại diện tròn, tên, giống loài, độ tuổi và cân nặng hiện tại. Cho phép xem nhanh sổ ghi chú chăm sóc "
        "(tiền sử dị ứng xà phòng, sợ sấy lông, lịch tiêm ngừa) giúp chủ nuôi dễ dàng chia sẻ thông tin cho cơ sở chăm sóc.",
        bold_prefix="7. Màn hình Quản lý Thú cưng (pets_screen.dart): "
    )
    add_bullet_p(doc,
        "Hiển thị trực quan Số dư khả dụng (Available Balance) và Số dư đang tạm giữ ký quỹ (Escrow Balance). Cung cấp nút \"Nạp tiền qua VietQR\" "
        "tự động sinh mã QR ngân hàng kèm nội dung chuyển khoản định danh duy nhất (PAW<id>), và danh sách lịch sử biến động số dư chi tiết.",
        bold_prefix="8. Màn hình Ví cá nhân & Lịch sử giao dịch (wallet_screen.dart): "
    )

    # 4.3 Giao diện Web Đối tác
    add_heading_2(doc, "4.3. Giao diện Cổng thông tin dành cho Đối tác (React Web Portal)")
    add_body_p(doc,
        "Cổng thông tin đối tác (pawcare-provider-web) được xây dựng theo chuẩn giao diện Web Dashboard quản trị hiện đại, "
        "tận dụng khả năng phản hồi tức thì của React 18 và Vite. Giao diện bao gồm thanh điều hướng bên trái (Sidebar) "
        "và khu vực nội dung chính được chia thành các phân trang nghiệp vụ:"
    )
    add_bullet_p(doc,
        "Hiển thị các thẻ thống kê tổng quan (Cards): Tổng số booking trong ngày, Số lượng booking PENDING chờ duyệt, Tổng doanh thu ví "
        "và Điểm đánh giá trung bình. Kèm theo đó là bảng dữ liệu các đơn đặt lịch sắp diễn ra trong ngày để kỹ thuật viên chuẩn bị.",
        bold_prefix="1. Bảng điều khiển vận hành (Dashboard.jsx): "
    )
    add_bullet_p(doc,
        "Trung tâm điều hành của cơ sở. Danh sách booking được phân loại thành các Tab trạng thái trực quan: Chờ duyệt, Sắp tới, Đang phục vụ, "
        "Đã hoàn thành và Đã hủy. Trên mỗi dòng đơn hàng, đối tác có thể xem chi tiết yêu cầu của khách và bấm các nút chuyển trạng thái nghiệp vụ: "
        "\"Chấp nhận\", \"Từ chối (yêu cầu nhập lý do)\", \"Xác nhận Check-in\", \"Bắt đầu dịch vụ\", và \"Báo cáo hoàn tất (Service Done)\".",
        bold_prefix="2. Quản lý Đơn đặt lịch (BookingsPage.jsx): "
    )
    add_bullet_p(doc,
        "Cho phép cơ sở thêm mới, điều chỉnh đơn giá, thời lượng của từng dịch vụ; quản lý danh sách kỹ thuật viên (thêm nhân viên, gán kỹ năng); "
        "và thiết lập ma trận ca làm việc khả dụng (Availability Slots Calendar) theo từng ngày trong tuần.",
        bold_prefix="3. Quản lý Dịch vụ, Nhân sự và Lịch làm việc (OperationsPage.jsx): "
    )
    add_bullet_p(doc,
        "Theo dõi số dư ví doanh thu (đã khấu trừ 10% phí sàn PawCare). Cung cấp chức năng tạo \"Yêu cầu rút tiền\" (Withdrawal Request) "
        "về tài khoản ngân hàng thụ hưởng của cơ sở, xem trạng thái phê duyệt của Admin và tra cứu toàn bộ lịch sử bút toán sổ cái.",
        bold_prefix="4. Quản lý Ví doanh thu & Rút tiền (WalletPage.jsx): "
    )
    add_bullet_p(doc,
        "Hiển thị danh sách tất cả các đánh giá và phản hồi của khách hàng. Cung cấp khung nhập liệu cho phép đối tác gửi văn bản giải trình "
        "hoặc lời cảm ơn tới khách hàng, nâng cao uy tín thương hiệu.",
        bold_prefix="5. Đánh giá và Chăm sóc khách hàng (ReviewsPage.jsx): "
    )

    # 4.4 Giao diện Web Quản trị
    add_heading_2(doc, "4.4. Giao diện Cổng thông tin Quản trị viên (Bonita BPM Portal)")
    add_body_p(doc,
        "Cổng quản trị viên được tích hợp trực tiếp trên nền tảng Bonita BPM Community 2025.2 thông qua các Web Fragments "
        "được thiết kế bằng Bonita UI Designer, cho phép quản lý toàn diện quy trình và dữ liệu hệ thống:"
    )
    add_bullet_p(doc,
        "Bảng điều khiển vĩ mô hiển thị các biểu đồ thống kê: Tốc độ tăng trưởng tài khoản (Khách hàng mới, Đối tác mới), "
        "tổng giá trị giao dịch dịch vụ (GMV), doanh thu phí sàn tích lũy (10%), biểu đồ tròn phân bố trạng thái booking, "
        "và các cảnh báo vận hành hệ thống.",
        bold_prefix="1. Dashboard Giám sát Hệ thống (AdminPawCareDashboardFragment): "
    )
    add_bullet_p(doc,
        "Hàng đợi các hồ sơ đối tác đang ở trạng thái PENDING. Quản trị viên xem xét thông tin đăng ký, thẩm định các tài liệu giấy phép kinh doanh, "
        "chứng chỉ thú y đính kèm. Cung cấp 3 nút chức năng tương ứng với các nhánh rẽ của BPMN 01: \"Phê duyệt (APPROVE)\", "
        "\"Từ chối (REJECT kèm lý do)\", và \"Yêu cầu bổ sung hồ sơ (NEED_MORE_INFO)\".",
        bold_prefix="2. Xét duyệt Hồ sơ Đối tác (AdminPawCareProvidersFragment): "
    )
    add_bullet_p(doc,
        "Cho phép tra cứu và lọc toàn bộ các booking trong toàn hệ thống. Quản trị viên có thể xem lịch sử chuyển trạng thái chi tiết, "
        "can thiệp hỗ trợ các trường hợp khách hàng hoặc đối tác gặp sự cố.",
        bold_prefix="3. Giám sát Booking Toàn hệ thống (AdminPawCareBookingsFragment): "
    )
    add_bullet_p(doc,
        "Nơi tiếp nhận các vụ khiếu nại tranh chấp (Disputes) từ khách hàng khi dịch vụ gặp sự cố. Quản trị viên xem xét nội dung giải trình "
        "từ hai phía, đưa ra phán quyết hoàn tiền (Refund) cho khách hàng hoặc giải phóng ký quỹ (Settle) cho đối tác, đảm bảo sự công bằng tuyệt đối.",
        bold_prefix="4. Xử lý Khiếu nại & Tranh chấp (AdminPawCareComplaintsFragment): "
    )
    add_bullet_p(doc,
        "Quản lý danh sách các yêu cầu rút tiền từ ví của các đối tác, thực hiện đối soát số dư sổ cái và phê duyệt lệnh chi.",
        bold_prefix="5. Giám sát Tài chính & Phê duyệt Rút tiền (AdminPawCareFinanceFragment): "
    )
