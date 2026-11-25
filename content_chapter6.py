# -*- coding: utf-8 -*-
from docx_helpers import (
    add_heading_1, add_heading_2, add_heading_3, add_body_p, add_bullet_p
)

def build_chapter_6(doc):
    add_heading_1(doc, "CHƯƠNG 6. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN")
    
    # 6.1 Kết luận
    add_heading_2(doc, "6.1. Kết luận")
    add_body_p(doc,
        "Sau quá trình nghiên cứu, khảo sát thực tế và nỗ lực triển khai kỹ thuật nghiêm túc, đề tài tốt nghiệp: "
        "\"Xây dựng nền tảng Web và ứng dụng di động đặt dịch vụ chăm sóc thú cưng PawCare kết hợp quản lý quy trình nghiệp vụ\" "
        "đã hoàn thành xuất sắc toàn bộ các mục tiêu nghiên cứu và yêu cầu chức năng đặt ra ban đầu. Đề tài đã mang lại các kết quả "
        "khoa học và sản phẩm ứng dụng cụ thể sau:"
    )
    add_bullet_p(doc,
        "Thiết kế và xây dựng hoàn chỉnh nền tảng PawCare đa kênh, bao gồm: Ứng dụng di động khách hàng (Flutter), Cổng thông tin đối tác (React/Vite), "
        "Cổng quản trị quy trình doanh nghiệp (Bonita BPM Community 2025.2), và hệ thống Backend RESTful API tập trung (Spring Boot 3) "
        "kết nối cơ sở dữ liệu quan hệ MySQL 8.0.",
        bold_prefix="Xây dựng nền tảng phần mềm toàn diện: "
    )
    add_bullet_p(doc,
        "Hiện thực hóa đầy đủ 33 Use Cases chi tiết bao phủ toàn bộ các nghiệp vụ trọng yếu của ngành dịch vụ thú cưng: quản lý hồ sơ thú cưng, "
        "tìm kiếm và đề xuất đối tác theo thuật toán đa tiêu chí, cấu hình ca trực và khung giờ khả dụng (availability slots) của nhân viên kỹ thuật, "
        "ngăn chặn triệt để hiện tượng trùng lịch (collision prevention), và quy trình thực hiện dịch vụ hai chiều minh bạch.",
        bold_prefix="Hoàn thiện trọn vẹn các yêu cầu chức năng: "
    )
    add_bullet_p(doc,
        "Ứng dụng thành công chuẩn quốc tế BPMN 2.0 trên nền tảng Bonita BPM Engine để mô hình hóa và thực thi hai quy trình nghiệp vụ cốt lõi: "
        "Quy trình đăng ký và xét duyệt đối tác (BPMN 01) và Quy trình vòng đời booking dịch vụ hai chiều (BPMN 02). Việc tách rời logic quy trình "
        "khỏi mã nguồn ứng dụng giúp hệ thống đạt độ linh hoạt cao, dễ dàng thay đổi luồng nghiệp vụ mà không cần tái cấu trúc mã nguồn.",
        bold_prefix="Đột phá trong mô hình hóa quy trình nghiệp vụ (BPMN 2.0): "
    )
    add_bullet_p(doc,
        "Thiết kế thành công mô hình Sổ cái kép (Double-entry Ledger) kết hợp cơ chế Tạm giữ Ký quỹ (Escrow Pattern) và mẫu thiết kế "
        "Transactional Outbox Pattern. Tích hợp thanh toán số VietQR chuẩn NAPAS và xử lý webhook SePay tự động bảo đảm tính bất biến (idempotency), "
        "bảo vệ tối đa quyền lợi tài chính của cả khách hàng và nhà cung cấp dịch vụ.",
        bold_prefix="Giải pháp tài chính và ký quỹ an toàn, minh bạch: "
    )
    add_bullet_p(doc,
        "Toàn bộ mã nguồn backend, ứng dụng di động, cổng web, các mô hình quy trình BPMN, tài liệu đặc tả Use Case, thiết kế cơ sở dữ liệu, "
        "và kịch bản kiểm thử tự động đã được đóng gói chuẩn mực, sẵn sàng chuyển giao và đưa vào vận hành thử nghiệm.",
        bold_prefix="Sản phẩm bàn giao thực tế: "
    )
    add_body_p(doc,
        "Thông qua quá trình thực hiện đồ án tốt nghiệp, sinh viên đã tích lũy được khối lượng kiến thức chuyên sâu về phân tích thiết kế "
        "hệ thống hướng đối tượng (OOAD/UML), rèn luyện tư duy thiết kế kiến trúc phần mềm phân tầng chuẩn mực, làm chủ các công nghệ hiện đại "
        "(Spring Boot, Bonita BPM, Flutter, React, MySQL), đồng thời nâng cao kỹ năng nghiên cứu khoa học và biên soạn báo cáo học thuật chuyên nghiệp."
    )

    # 6.2 Hạn chế của đề tài
    add_heading_2(doc, "6.2. Hạn chế của đề tài")
    add_body_p(doc,
        "Bên cạnh những kết quả đạt được rất đáng khích lệ, nhóm nghiên cứu cũng thẳng thắn nhìn nhận những hạn chế còn tồn tại "
        "do giới hạn về thời gian thực hiện (khung thời gian đồ án tốt nghiệp) và điều kiện pháp lý thực tế:"
    )
    add_bullet_p(doc,
        "Do quy định của Ngân hàng Nhà nước và các cổng thanh toán tài chính đòi hỏi tư cách pháp nhân doanh nghiệp có giấy phép kinh doanh, "
        "chức năng thanh toán hiện tại của hệ thống mới dừng lại ở mức mô phỏng tài chính tích hợp thực tế (thanh toán qua chuyển khoản VietQR sandbox "
        "và ví nội bộ), chưa thể kết nối trực tiếp cổng thanh toán trực tuyến chính thức của các ngân hàng thương mại lớn.",
        bold_prefix="1. Giới hạn về tích hợp cổng thanh toán thương mại: "
    )
    add_bullet_p(doc,
        "Đối với các dịch vụ mang tính chất di động hoặc ngoại cảnh như dắt chó đi dạo (dog walking) hoặc chăm sóc thú cưng tại nhà khách hàng, "
        "hệ thống hiện tại chưa tích hợp tính năng định vị GPS thời gian thực để chủ nuôi theo dõi trực tiếp lộ trình di chuyển của kỹ thuật viên "
        "trên bản đồ vệ tinh.",
        bold_prefix="2. Chưa hỗ trợ định vị GPS thời gian thực (Real-time Tracking): "
    )
    add_bullet_p(doc,
        "Khách hàng và nhân viên kỹ thuật hiện tại tương tác chủ yếu qua nhật ký trạng thái dịch vụ và hình ảnh nghiệm thu; "
        "hệ thống chưa tích hợp tính năng gọi video trực tuyến (Live Video Call / WebRTC) để chủ nuôi có thể quan sát trực tiếp thú cưng trong lúc làm spa.",
        bold_prefix="3. Chưa hỗ trợ truyền phát video trực tiếp (Live Video Streaming): "
    )
    add_bullet_p(doc,
        "Các thử nghiệm hiệu năng mới được thực hiện trong môi trường phòng thí nghiệm và mạng cục bộ với tập dữ liệu hàng nghìn bản ghi; "
        "hệ thống chưa được kiểm thử tải cực hạn (Stress Testing) trên môi trường phân tán cụm đám mây (Cloud Cluster) với hàng triệu người dùng "
        "truy cập đồng thời.",
        bold_prefix="4. Quy mô thử nghiệm chịu tải phân tán: "
    )

    # 6.3 Hướng phát triển trong tương lai
    add_heading_2(doc, "6.3. Hướng phát triển trong tương lai")
    add_body_p(doc,
        "Nhằm nâng tầm PawCare trở thành một nền tảng thương mại dịch vụ thú cưng hàng đầu tại Việt Nam và khu vực, "
        "các định hướng nghiên cứu và phát triển nâng cấp trong giai đoạn tiếp theo bao gồm:"
    )
    add_bullet_p(doc,
        "Hoàn thiện tư cách pháp nhân để ký kết thỏa thuận hợp tác chính thức với các cổng thanh toán trung gian (VNPay, MoMo, ZaloPay) "
        "và các ngân hàng thương mại, triển khai cơ chế tài khoản phong tỏa tự động bảo chứng theo luật định.",
        bold_prefix="1. Tích hợp cổng thanh toán ngân hàng chính thức: "
    )
    add_bullet_p(doc,
        "Tích hợp dịch vụ bản đồ số (Google Maps Platform / OpenStreetMap) và công nghệ Geofencing để theo dõi vị trí GPS thời gian thực "
        "của người dắt chó đi dạo, tự động ghi nhận cự ly di chuyển và thời lượng phục vụ chính xác.",
        bold_prefix="2. Phát triển tính năng GPS Tracking thời gian thực: "
    )
    add_bullet_p(doc,
        "Nghiên cứu ứng dụng các mô hình học sâu và thị giác máy tính (Deep Learning / Computer Vision) để tự động nhận diện giống loài thú cưng "
        "qua ảnh chụp, phát hiện sớm các dấu hiệu bệnh ngoài da (viêm da, nấm, ve rận), và ứng dụng thuật toán học máy (Machine Learning) "
        "để cá nhân hóa danh sách đề xuất dịch vụ dựa trên lịch sử thói quen của từng chủ nuôi.",
        bold_prefix="3. Ứng dụng Trí tuệ Nhân tạo (AI & Computer Vision): "
    )
    add_bullet_p(doc,
        "Tích hợp phân hệ sàn thương mại điện tử chuyên biệt, kết nối các nhà phân phối thức ăn dinh dưỡng, thuốc thú y, thực phẩm chức năng "
        "và đồ chơi phụ kiện thú cưng chính hãng, tạo nên một hệ sinh thái chăm sóc thú cưng toàn diện \"tất cả trong một\" (All-in-One Pet Platform).",
        bold_prefix="4. Mở rộng sàn thương mại điện tử phụ kiện và thực phẩm: "
    )
    add_bullet_p(doc,
        "Tái cấu trúc hệ thống Backend từ mô hình Modular Monolith sang kiến trúc Vi dịch vụ (Microservices Architecture), "
        "đóng gói ứng dụng bằng Docker Container và triển khai điều phối trên nền tảng Kubernetes (K8s) kết hợp hệ thống hàng đợi phân tán "
        "(Apache Kafka / RabbitMQ), sẵn sàng mở rộng quy mô phục vụ hàng triệu người dùng trên toàn quốc.",
        bold_prefix="5. Nâng cấp kiến trúc sang Microservices & Kubernetes: "
    )
