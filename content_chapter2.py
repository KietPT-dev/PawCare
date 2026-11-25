# -*- coding: utf-8 -*-
from docx_helpers import add_heading_1, add_heading_2, add_heading_3, add_body_p, add_bullet_p

def build_chapter_2(doc):
    add_heading_1(doc, "CHƯƠNG 2. CƠ SỞ LÝ THUYẾT")
    
    add_body_p(doc,
        "Để xây dựng một hệ thống thương mại dịch vụ quy mô hoàn chỉnh như PawCare, việc nghiên cứu và lựa chọn "
        "ngăn xếp công nghệ (technology stack) đóng vai trò quyết định đến tính khả thi, hiệu năng, độ tin cậy và khả năng "
        "mở rộng lâu dài của dự án. Chương 2 tập trung trình bày các cơ sở lý thuyết chuyên sâu về các công nghệ, framework, "
        "chuẩn ký hiệu và kiến trúc phần mềm thực tế được áp dụng trong dự án PawCare, bao gồm: Framework Spring Boot và kiến trúc "
        "RESTful API; Nền tảng quản lý quy trình nghiệp vụ Bonita BPM và chuẩn BPMN 2.0; Framework di động Flutter; Thư viện React "
        "và công cụ xây dựng Vite; Hệ quản trị cơ sở dữ liệu quan hệ MySQL và mô hình giao dịch sổ cái/ký quỹ (Escrow); cùng các cơ chế "
        "bảo mật phân quyền JWT/RBAC và chuẩn thanh toán số VietQR."
    )

    # 2.1 Spring Boot & RESTful API
    add_heading_2(doc, "2.1. Framework Spring Boot và Kiến trúc Backend RESTful API")
    add_heading_3(doc, "2.1.1. Khái niệm và quá trình phát triển của Spring Boot")
    add_body_p(doc,
        "Spring Framework là nền tảng phát triển ứng dụng Java cấp doanh nghiệp (Enterprise Java) phổ biến và mạnh mẽ nhất hiện nay, "
        "được khởi xướng bởi Rod Johnson vào năm 2002. Trải qua hơn hai thập kỷ phát triển, Spring đã trở thành tiêu chuẩn công nghiệp "
        "nhờ vào khả năng module hóa linh hoạt và quản lý vòng đời đối tượng vượt trội. Tuy nhiên, ở các phiên bản đầu, việc cấu hình "
        "Spring đòi hỏi một khối lượng rất lớn các file XML phức tạp (thường được gọi là \"XML configuration hell\"), gây tốn nhiều thời gian "
        "và làm chậm tiến độ phát triển [3], [4]."
    )
    add_body_p(doc,
        "Để khắc phục hạn chế trên, tập đoàn Pivotal (nay trực thuộc VMware Tanzu) đã phát triển và giới thiệu Spring Boot vào năm 2014. "
        "Spring Boot là một framework mở rộng được xây dựng trên nền Spring Framework truyền thống, áp dụng triệt để nguyên lý "
        "\"Quy ước hơn cấu hình\" (Convention over Configuration). Spring Boot cung cấp các cấu hình tự động (Auto-configuration) "
        "thông minh, tích hợp sẵn các Web Server dạng nhúng (Embedded Tomcat, Jetty) và bộ thư viện phụ thuộc khởi động (Starters), "
        "giúp lập trình viên có thể khởi tạo và triển khai một ứng dụng Java web độc lập (Standalone Application) chất lượng cao chỉ trong "
        "vài phút mà không cần cấu hình phức tạp [4]."
    )

    add_heading_3(doc, "2.1.2. Các đặc điểm kỹ thuật nổi bật của Spring Boot")
    add_body_p(doc, "Các đặc điểm kiến trúc nền tảng của Spring Boot bao gồm:")
    add_bullet_p(doc,
        "Đảo ngược điều khiển (Inversion of Control - IoC) và Tiêm phụ thuộc (Dependency Injection - DI): IoC là nguyên lý chuyển giao "
        "quyền kiểm soát việc khởi tạo, quản lý và hủy các đối tượng (gọi là Spring Beans) cho IoC Container của Spring. Thay vì một đối tượng "
        "tự khởi tạo các phụ thuộc của nó thông qua toán tử new, Spring sử dụng kỹ thuật DI để tự động \"bơm\" (inject) các phụ thuộc cần thiết "
        "thông qua Constructor hoặc chú thích (Annotation như @Autowired). Điều này giúp giảm thiểu tối đa sự phụ thuộc chặt chẽ (tight coupling) "
        "giữa các thành phần, tăng tính linh hoạt và tạo điều kiện lý tưởng cho việc viết mã kiểm thử tự động (Unit Test / Mocking) [3].",
        bold_prefix="Nguyên lý IoC và DI: "
    )
    add_bullet_p(doc,
        "Cơ chế Tự động cấu hình (Auto-configuration): Spring Boot tự động phân tích các thư viện có mặt trong Classpath và các biến môi trường "
        "để tự động cấu hình các Bean tương ứng. Ví dụ: khi phát hiện có MySQL Connector trong file cấu hình Maven (pom.xml), Spring Boot "
        "sẽ tự động thiết lập DataSource, Connection Pool (HikariCP) và Transaction Manager mà không cần viết mã thủ công [4].",
        bold_prefix="Auto-configuration: "
    )
    add_bullet_p(doc,
        "Kiến trúc phân tầng chuẩn mực (Layered Architecture): Ứng dụng Spring Boot được tổ chức chặt chẽ theo 4 tầng chức năng: "
        "(1) Controller Layer: Tiếp nhận các yêu cầu HTTP từ phía client, phân tích tham số, xác thực dữ liệu đầu vào (@Valid) và trả về "
        "phản hồi HTTP/JSON; (2) Service Layer: Đóng gói toàn bộ logic nghiệp vụ (business logic) của hệ thống, quản lý ranh giới giao dịch "
        "(@Transactional); (3) Repository Layer: Đảm nhiệm việc giao tiếp với cơ sở dữ liệu thông qua Spring Data JPA hoặc JDBC Template; "
        "và (4) Entity/Domain Layer: Định nghĩa các mô hình dữ liệu ánh xạ trực tiếp tới bảng CSDL [3], [15].",
        bold_prefix="Mô hình phân tầng: "
    )

    add_heading_3(doc, "2.1.3. Kiến trúc RESTful API và chuẩn OpenAPI Specification")
    add_body_p(doc,
        "REST (Representational State Transfer) là một mẫu kiến trúc phần mềm do Roy Fielding đề xuất trong luận án tiến sĩ năm 2000, "
        "thiết lập các nguyên tắc chuẩn mực cho việc truyền thông giữa máy khách (Client) và máy chủ (Server) trên môi trường mạng thông qua "
        "giao thức HTTP. Một hệ thống API chuẩn RESTful phải tuân thủ nghiêm ngặt các ràng buộc:"
    )
    add_bullet_p(doc, "Kiến trúc Client-Server tách biệt: Tách rời hoàn toàn giao diện người dùng và logic xử lý dữ liệu lưu trữ.")
    add_bullet_p(doc, "Phi trạng thái (Stateless): Mỗi yêu cầu HTTP gửi từ client lên server phải chứa đựng đầy đủ mọi thông tin cần thiết để server hiểu và xử lý, máy chủ không lưu giữ ngữ cảnh phiên làm việc của client trong bộ nhớ giữa các request.")
    add_bullet_p(doc, "Định danh tài nguyên qua URI: Mọi thực thể nghiệp vụ (User, Pet, Provider, Booking, Review) được định danh như một tài nguyên (Resource) thông qua danh từ số nhiều (ví dụ: /api/v1/bookings, /api/v1/providers).")
    add_bullet_p(doc, "Sử dụng đúng ngữ nghĩa các phương thức HTTP (HTTP Verbs): GET (truy vấn dữ liệu), POST (tạo mới tài nguyên), PUT (cập nhật toàn phần), PATCH (cập nhật từng phần) và DELETE (xóa tài nguyên).")
    add_bullet_p(doc, "Chuẩn hóa mã trạng thái HTTP (HTTP Status Codes): 200 OK (thành công), 201 Created (tạo mới thành công), 400 Bad Request (lỗi cú pháp dữ liệu), 401 Unauthorized (chưa xác thực), 403 Forbidden (không có quyền), 404 Not Found (không tìm thấy tài nguyên), 409 Conflict (xung đột dữ liệu), 422 Unprocessable Entity (dữ liệu vi phạm luật nghiệp vụ), và 500 Internal Server Error (lỗi hệ thống).")
    add_body_p(doc,
        "Nhằm tạo điều kiện thuận lợi cho việc tích hợp giữa các nhóm phát triển đa nền tảng (Mobile, Web, Workflow Engine), "
        "chuẩn OpenAPI Specification (OAS 3.0 / Swagger) được áp dụng để tài liệu hóa toàn bộ hợp đồng API (API Contract). "
        "Mỗi endpoint trong PawCare đều được định nghĩa rõ ràng về URL, header xác thực, cấu trúc request JSON, mã phản hồi "
        "và lược đồ dữ liệu đầu ra [4]."
    )

    add_heading_3(doc, "2.1.4. Ứng dụng trong hệ thống PawCare")
    add_body_p(doc,
        "Trong dự án PawCare, Spring Boot 3 được sử dụng làm nền tảng cốt lõi để xây dựng phân hệ Backend trung tâm (thư mục public-api). "
        "Hệ thống cung cấp hơn 30 RESTful endpoints phục vụ đồng thời cho Ứng dụng di động khách hàng (Flutter), Cổng thông tin đối tác (React) "
        "và Cổng quản trị Bonita BPM. Spring Boot chịu trách nhiệm điều phối toàn bộ các nghiệp vụ trọng yếu: xác thực định danh và phát hành token JWT, "
        "xử lý logic tìm kiếm và đề xuất đối tác theo khoảng cách và đánh giá, quản lý thuật toán kiểm tra xung đột khung giờ khả dụng "
        "(collision prevention), quản lý sổ cái ví điện tử và tạm giữ ký quỹ (Escrow), cũng như tiếp nhận và xử lý webhook thanh toán VietQR "
        "đảm bảo tính bất biến (Idempotency)."
    )

    # 2.2 Bonita BPM & BPMN 2.0
    add_heading_2(doc, "2.2. Nền tảng Quản lý Quy trình Nghiệp vụ Bonita BPM và Chuẩn BPMN 2.0")
    add_heading_3(doc, "2.2.1. Khái niệm BPM và Chuẩn ký hiệu BPMN 2.0")
    add_body_p(doc,
        "Quản lý Quy trình Nghiệp vụ (Business Process Management - BPM) là phương pháp luận khoa học và tập hợp các giải pháp phần mềm "
        "nhằm mô hình hóa, tự động hóa, thực thi, kiểm soát và tối ưu hóa các quy trình hoạt động kinh doanh trong tổ chức. Thay vì viết "
        "các đoạn mã xử lý trạng thái phức tạp, lồng ghép nhiều câu lệnh if-else rối rắm bên trong mã nguồn ứng dụng (gây hiện tượng mã nguồn phình to "
        "và rất khó bảo trì khi nghiệp vụ thay đổi), BPM cho phép tách rời hoàn toàn logic quy trình ra khỏi mã nguồn ứng dụng [1], [2]."
    )
    add_body_p(doc,
        "BPMN 2.0 (Business Process Model and Notation - phiên bản 2.0 do tổ chức tiêu chuẩn quốc tế OMG ban hành năm 2011) là chuẩn đồ họa "
        "nghiệp vụ được công nhận rộng rãi trên toàn cầu. BPMN 2.0 cung cấp một hệ thống ký hiệu trực quan dễ hiểu đối với cả các nhà phân tích "
        "kinh doanh, quản lý lẫn kỹ sư phần mềm, đồng thời có thể chuyển đổi trực tiếp sang định dạng XML có thể thực thi được bởi các Workflow Engine. "
        "Các phần tử chính trong BPMN 2.0 bao gồm: (1) Flow Objects: Gồm Sự kiện (Events: Start, Intermediate, End), Tác vụ (Activities/Tasks: "
        "User Task, Service Task, Script Task), và Cổng phân nhánh điều kiện (Gateways: Exclusive XOR, Parallel AND, Inclusive OR); "
        "(2) Connecting Objects: Gồm Luồng tuần tự (Sequence Flow) và Luồng thông điệp (Message Flow); và (3) Swimlanes: Gồm Bể bơi (Pools) "
        "đại diện cho các tổ chức/tác nhân tham gia và Làn bơi (Lanes) phân định trách nhiệm của từng vai trò nội bộ [1]."
    )

    add_heading_3(doc, "2.2.2. Nền tảng Bonita BPM Community 2025.2")
    add_body_p(doc,
        "Bonita BPM là một nền tảng mã nguồn mở hàng đầu thế giới về quản lý quy trình nghiệp vụ và phát triển ứng dụng thông minh (Digital Process "
        "Automation Platform), được phát triển bởi hãng Bonitasoft (Pháp). Kiến trúc của Bonita BPM bao gồm 3 phân hệ trụ cột:"
    )
    add_bullet_p(doc,
        "Môi trường phát triển tích hợp đồ họa (IDE) xây dựng trên nền Eclipse. Cho phép kỹ sư thiết kế trực quan các biểu đồ BPMN 2.0, "
        "định nghĩa mô hình dữ liệu nghiệp vụ (Business Data Model - BDM), thiết kế giao diện form người dùng và cấu hình các bộ kết nối (Connectors) "
        "giao tiếp với hệ thống bên ngoài.",
        bold_prefix="Bonita Studio: "
    )
    add_bullet_p(doc,
        "Trái tim thực thi của hệ thống, là một Java Workflow Engine hiệu năng cao có thể nhúng hoặc chạy độc lập. Engine chịu trách nhiệm "
        "khởi tạo và duy trì vòng đời của các thể hiện quy trình (Process Instances), phân bổ công việc vào danh sách chờ của người dùng, "
        "kích hoạt các tác vụ nền, quản lý biến dữ liệu trạng thái và lưu vết nhật ký kiểm toán (Audit Trail) đầy đủ [2].",
        bold_prefix="Bonita Engine: "
    )
    add_bullet_p(doc,
        "Giao diện tương tác người dùng trên nền web, nơi Quản trị viên và người dùng nghiệp vụ đăng nhập để thực thi các tác vụ được giao "
        "(User Tasks), theo dõi tiến độ các quy trình đang chạy và trích xuất báo cáo giám sát quy trình.",
        bold_prefix="Bonita Portal: "
    )

    add_heading_3(doc, "2.2.3. Cơ chế REST API Extension và Scripting Groovy")
    add_body_p(doc,
        "Một trong những tính năng mở rộng mạnh mẽ nhất của Bonita BPM là khả năng phát triển các REST API Extensions sử dụng ngôn ngữ "
        "kịch bản Groovy (một ngôn ngữ động chạy trên nền máy ảo JVM, tương thích hoàn toàn với Java). REST API Extensions cho phép các lập trình viên "
        "bổ sung các điểm cuối API tùy chỉnh chạy trực tiếp trong ngữ cảnh của Bonita Engine. Thông qua Groovy Scripts, hệ thống có thể dễ dàng "
        "thực hiện việc xác thực quyền hạn của người dùng, truy vấn cơ sở dữ liệu quan hệ, gọi các dịch vụ bên ngoài, hoặc kích hoạt các tiến trình "
        "nghiệp vụ mới một cách linh hoạt mà không làm gián đoạn Engine chính [2]."
    )

    add_heading_3(doc, "2.2.4. Ứng dụng trong hệ thống PawCare")
    add_body_p(doc,
        "Trong đề tài PawCare, nền tảng Bonita BPM đóng vai trò là \"bộ não điều phối quy trình trung tâm\". Toàn bộ logic phức tạp của hai quy trình "
        "sống còn được mô hình hóa và thực thi bằng Bonita:"
    )
    add_bullet_p(doc,
        "Điều phối quy trình từ khi đối tác gửi đơn đăng ký và tài liệu chứng minh, qua các bước thẩm định của Quản trị viên (Phê duyệt, "
        "Yêu cầu bổ sung, hoặc Từ chối kèm lý do), tự động kích hoạt tài khoản đối tác sang trạng thái APPROVED trong CSDL MySQL để bắt đầu nhận booking.",
        bold_prefix="Quy trình BPMN 01 (Xét duyệt đối tác): "
    )
    add_bullet_p(doc,
        "Quản lý nghiêm ngặt máy trạng thái của đơn đặt lịch qua các pha liên tục: PENDING -> CONFIRMED -> CHECKED_IN -> IN_SERVICE -> SERVICE_DONE -> "
        "COMPLETED, đồng thời kích hoạt các tác vụ ký quỹ, thanh toán và xử lý ngoại lệ khi có khiếu nại phát sinh từ phía khách hàng.",
        bold_prefix="Quy trình BPMN 02 (Vòng đời booking và thực hiện dịch vụ): "
    )

    # 2.3 Flutter
    add_heading_2(doc, "2.3. Công nghệ Phát triển Ứng dụng Di động Đa nền tảng Flutter")
    add_heading_3(doc, "2.3.1. Khái niệm và kiến trúc của Flutter")
    add_body_p(doc,
        "Flutter là bộ công cụ phát triển giao diện người dùng đa nền tảng (UI Software Development Kit) mã nguồn mở do Google sáng lập "
        "và giới thiệu lần đầu vào năm 2017. Điểm khác biệt mang tính cách mạng của Flutter so with các công nghệ đa nền tảng truyền thống "
        "(như React Native hay Apache Cordova) nằm ở kiến trúc đồ họa độc lập: Flutter không sử dụng các widget native của hệ điều hành, "
        "cũng không thông qua tầng cầu nối JavaScript Bridge chậm chạp. Thay vào đó, Flutter tích hợp sẵn công cụ đồ họa Skia 2D (và gần đây là Impeller), "
        "trực tiếp render từng điểm ảnh (pixel) lên màn hình phần cứng [5], [6]."
    )
    add_body_p(doc,
        "Flutter sử dụng ngôn ngữ lập trình Dart – một ngôn ngữ hướng đối tượng hiện đại, an toàn về kiểu (type-safe) và hỗ trợ cơ chế null safety. "
        "Dart sở hữu năng lực biên dịch linh hoạt hai chế độ: (1) JIT (Just-in-Time compilation) phục vụ quá trình lập trình với tính năng Hot Reload "
        "nổi tiếng (cho phép nhà phát triển cập nhật mã nguồn và quan sát thay đổi giao diện ngay lập tức trong vòng chưa đầy một giây mà không làm "
        "mất trạng thái ứng dụng); và (2) AOT (Ahead-of-Time compilation) khi đóng gói sản phẩm, biên dịch mã nguồn trực tiếp sang mã máy nhị phân ARM "
        "cho cả iOS và Android, mang lại hiệu năng đồ họa mượt mà đạt chuẩn 60 đến 120 khung hình/giây (FPS) [6]."
    )

    add_heading_3(doc, "2.3.2. Triết lý \"Everything is a Widget\" và Cây Widget (Widget Tree)")
    add_body_p(doc,
        "Trong Flutter, mọi thành phần xuất hiện trên màn hình đều là một Widget: từ các phần tử cấu trúc layout (Row, Column, Container, Stack), "
        "các thành phần tương tác (Button, TextField, GestureDetector), đến các định dạng kiểu dáng (Padding, Theme, TextStyle). Toàn bộ giao diện "
        "ứng dụng được tổ chức dưới dạng một cấu trúc dữ liệu phân cấp gọi là Cây Widget (Widget Tree). Flutter chia các widget thành hai nhóm chính:"
    )
    add_bullet_p(doc, "StatelessWidget: Các widget tĩnh, không chứa trạng thái nội tại có thể thay đổi theo thời gian. Giao diện của widget được vẽ một lần duy nhất dựa trên cấu hình ban đầu truyền vào.")
    add_bullet_p(doc, "StatefulWidget: Các widget động, gắn liền với một đối tượng State. Khi dữ liệu nghiệp vụ biến đổi, phương thức setState() được gọi để kích hoạt việc vẽ lại (rebuild) các nhánh widget liên quan trên màn hình.")

    add_heading_3(doc, "2.3.3. Ứng dụng trong hệ thống PawCare")
    add_body_p(doc,
        "Ứng dụng di động khách hàng (thư mục pawcare-customer-mobile) được phát triển hoàn toàn bằng Flutter SDK 3.x. "
        "Giao diện ứng dụng được thiết kế theo ngôn ngữ Material Design hiện đại, tối ưu hóa triệt để cho thao tác một tay trên màn hình cảm ứng: "
        "thanh điều hướng đáy tiện lợi, bộ lọc tìm kiếm dịch vụ trực quan, màn hình đặt lịch thời gian thực hiển thị lịch trống dạng ô slot màu sắc, "
        "và màn hình quản lý thú cưng sinh động với thẻ avatar, cân nặng và sổ theo dõi sức khỏe."
    )

    # 2.4 React & Vite
    add_heading_2(doc, "2.4. Công nghệ Xây dựng Giao diện Web: React và Vite")
    add_heading_3(doc, "2.4.1. Khái niệm và kiến trúc của thư viện React")
    add_body_p(doc,
        "React (thường gọi là React.js) là một thư viện JavaScript mã nguồn mở được phát triển bởi Meta (Facebook) vào năm 2013, chuyên biệt cho "
        "việc xây dựng giao diện người dùng đơn trang (Single Page Applications - SPAs). React hoạt động dựa trên triết lý kiến trúc dựa trên thành phần "
        "(Component-Based Architecture), cho phép lập trình viên chia nhỏ giao diện phức tạp thành các khối độc lập, có thể tái sử dụng cao và dễ kiểm thử [7]."
    )
    add_body_p(doc,
        "Điểm sáng công nghệ cốt lõi của React là mô hình DOM ảo (Virtual DOM) và thuật toán Reconciliation. Khi trạng thái dữ liệu (state) "
        "của một component thay đổi, React không cập nhật trực tiếp lên DOM thực của trình duyệt (vốn là một thao tác rất tốn kém tài nguyên). "
        "Thay vào đó, React tạo ra một bản sao DOM ảo trong bộ nhớ, tính toán sự khác biệt tối thiểu giữa bản sao mới và bản sao cũ (thuật toán Diffing), "
        "sau đó chỉ cập nhật đúng những phần tử thực sự thay đổi lên màn hình, tối ưu hóa tốc độ phản hồi của trang web [7]."
    )

    add_heading_3(doc, "2.4.2. Công cụ xây dựng thế hệ mới Vite")
    add_body_p(doc,
        "Vite (từ gốc tiếng Pháp mang nghĩa là \"nhanh\") là một công cụ xây dựng web hiện đại do Evan You (tác giả của Vue.js) sáng lập. "
        "Trước đây, các dự án React truyền thống thường sử dụng Webpack để đóng gói (bundle) toàn bộ mã nguồn trước khi khởi động dev server, "
        "dẫn đến thời gian khởi động có thể mất từ vài chục giây đến vài phút đối với các dự án lớn. Vite giải quyết triệt để vấn đề này nhờ tận dụng "
        "chuẩn Native ES Modules (ESM) sẵn có trên trình duyệt hiện đại kết hợp với trình tiền xử lý esbuild viết bằng ngôn ngữ Go. "
        "Nhờ đó, server phát triển của Vite khởi động gần như ngay lập tức và tốc độ Hot Module Replacement (HMR) cực nhanh, nâng cao đáng kể năng suất "
        "phát triển [8]."
    )

    add_heading_3(doc, "2.4.3. Ứng dụng trong hệ thống PawCare")
    add_body_p(doc,
        "Trong dự án PawCare, React 18 kết hợp Vite được ứng dụng để xây dựng toàn bộ phân hệ Cổng thông tin Đối tác (thư mục pawcare-provider-web). "
        "Giao diện được thiết kế chuyên nghiệp theo bố cục Dashboard quản trị, cho phép các chủ cơ sở thú cưng theo dõi bảng chỉ số doanh thu thời gian thực, "
        "danh sách đơn đặt lịch theo từng thẻ trạng thái, quản lý ca trực nhân viên theo dạng lưới thời gian, và xử lý các phản hồi đánh giá của khách hàng "
        "với độ trễ cực thấp."
    )

    # 2.5 MySQL & Transaction Models
    add_heading_2(doc, "2.5. Hệ Quản trị Cơ sở Dữ liệu MySQL và Mô hình Giao dịch Tài chính")
    add_heading_3(doc, "2.5.1. Khái niệm và đặc tính của MySQL 8.0")
    add_body_p(doc,
        "MySQL là hệ quản trị cơ sở dữ liệu quan hệ (RDBMS) mã nguồn mở phổ biến nhất trên thế giới, thuộc quyền sở hữu của tập đoàn Oracle. "
        "Phiên bản MySQL 8.0 mang lại nhiều bước tiến vượt bậc về hiệu năng truy vấn, bảo mật và hỗ trợ các kiểu dữ liệu hiện đại như JSON [9]."
    )
    add_body_p(doc,
        "Cơ sở dữ liệu PawCare sử dụng engine lưu trữ tiêu chuẩn InnoDB. InnoDB hỗ trợ toàn vẹn khóa ngoại (Foreign Key Constraints), "
        "cơ chế khóa mức dòng (Row-level Locking) hạn chế tối đa tranh chấp ghi dữ liệu đồng thời, và tuân thủ nghiêm ngặt chuẩn tính chất giao dịch ACID:"
    )
    add_bullet_p(doc, "Tính nguyên tử (Atomicity): Đảm bảo tất cả các thao tác trong một giao dịch (ví dụ: trừ tiền ví khách và tạo đơn booking) cùng thành công hoặc cùng bị hủy bỏ (Rollback) hoàn toàn, không có trạng thái dang dở.")
    add_bullet_p(doc, "Tính nhất quán (Consistency): Dữ liệu sau khi hoàn thành giao dịch luôn thỏa mãn mọi ràng buộc toàn vẹn, quy tắc miền giá trị và khóa ngoại.")
    add_bullet_p(doc, "Tính cô lập (Isolation): Các giao dịch thực thi đồng thời không được can thiệp hoặc nhìn thấy trạng thái trung gian của nhau trước khi hoàn tất.")
    add_bullet_p(doc, "Tính bền vững (Durability): Khi một giao dịch đã được xác nhận (Commit), kết quả lưu trữ sẽ được bảo toàn vĩnh viễn ngay cả khi hệ thống gặp sự cố mất điện đột ngột.")

    add_heading_3(doc, "2.5.2. Mô hình Sổ cái kép (Double-entry Ledger) và Cơ chế Ký quỹ (Escrow)")
    add_body_p(doc,
        "Để quản lý an toàn dòng tiền trong nền tảng marketplace nơi PawCare đóng vai trò trung gian giữa Khách hàng và Đối tác, "
        "hệ thống áp dụng hai mô hình tài chính chuẩn mực [15]:"
    )
    add_bullet_p(doc,
        "Mọi biến động số dư tài khoản của người dùng (nạp tiền, thanh toán đặt cọc, thanh toán hoàn tất, hoàn tiền, rút tiền) "
        "không đơn thuần là việc cập nhật một con số số dư (balance) trong bảng wallets, mà bắt buộc phải sinh ra một bản ghi giao dịch bất biến "
        "trong bảng wallet_transactions. Bản ghi này lưu rõ loại giao dịch (DEPOSIT, ESCROW_LOCK, ESCROW_RELEASE, PLATFORM_FEE, WITHDRAWAL), "
        "số tiền, số dư trước và sau giao dịch. Cơ chế này đảm bảo lịch sử tài chính có thể kiểm toán (auditable) bất cứ lúc nào.",
        bold_prefix="Mô hình Sổ cái kép: "
    )
    add_bullet_p(doc,
        "Khi khách hàng xác nhận đặt lịch dịch vụ, toàn bộ số tiền thanh toán (100%) sẽ được trừ khỏi số dư khả dụng (available_balance) "
        "và chuyển sang số dư tạm giữ ký quỹ (escrow_balance) của khách hàng. Số tiền này hoàn toàn bị khóa và chưa được chuyển vào tài khoản "
        "của Đối tác. Chỉ khi dịch vụ hoàn tất và hai bên xác nhận (hoặc sau thời gian chờ SLA mà không có tranh chấp), số tiền ký quỹ mới được "
        "hệ thống giải phóng và phân bổ: 90% chuyển vào ví đối tác và 10% chuyển thành doanh thu hoa hồng của sàn PawCare. Nếu booking bị từ chối "
        "hoặc hủy hợp lệ, 100% tiền ký quỹ được hoàn trả nguyên vẹn về ví khả dụng của khách hàng.",
        bold_prefix="Cơ chế Tạm giữ Ký quỹ (Escrow Pattern): "
    )

    add_heading_3(doc, "2.5.3. Mẫu thiết kế Transactional Outbox Pattern")
    add_body_p(doc,
        "Trong kiến trúc kết hợp giữa cơ sở dữ liệu quan hệ MySQL và Workflow Engine Bonita BPM, bài toán đặt ra là làm thế nào để đảm bảo "
        "tính nhất quán dữ liệu (eventual consistency) khi một sự kiện nghiệp vụ xảy ra (ví dụ: tạo booking thành công) phải kích hoạt "
        "tiến trình tương ứng bên Bonita BPM. Nếu thực hiện gọi trực tiếp HTTP sang Bonita ngay trong giao dịch CSDL, lỗi mạng có thể làm mất "
        "sự kiện hoặc khiến giao dịch DB bị rollback oan uổng."
    )
    add_body_p(doc,
        "PawCare áp dụng mẫu thiết kế chuẩn Transactional Outbox Pattern: Cùng lúc với thao tác lưu thông tin booking vào CSDL, "
        "hệ thống ghi một bản ghi sự kiện vào bảng trung gian booking_workflow_outbox trong cùng một transaction nguyên tử. "
        "Một tiến trình xử lý nền (Background Worker / Outbox Poller) định kỳ quét các bản ghi chưa xử lý để gửi thông điệp sang Bonita BPM "
        "với cơ chế thử lại (retry) và ghi nhận thời gian thuê (lease_until), đảm bảo không bao giờ bị mất mát sự kiện [15]."
    )

    # 2.6 Supporting Tech
    add_heading_2(doc, "2.6. Các Công nghệ và Kỹ thuật Hỗ trợ")
    add_heading_3(doc, "2.6.1. Xác thực và Phân quyền dựa trên JWT và RBAC")
    add_body_p(doc,
        "Hệ thống triển khai cơ chế xác thực không trạng thái (Stateless Authentication) dựa trên tiêu chuẩn RFC 7519 - JSON Web Token (JWT) [10]. "
        "Cấu trúc của mỗi token bao gồm 3 phần được mã hóa Base64URL và nối với nhau bằng dấu chấm:"
    )
    add_bullet_p(doc, "Header: Chứa loại token (JWT) và thuật toán băm chữ ký số sử dụng (HMAC SHA-256).")
    add_bullet_p(doc, "Payload: Chứa các thông tin định danh (Claims) như: Mã tài khoản người dùng (sub / userId), địa chỉ email, họ tên, và vai trò người dùng (role).")
    add_bullet_p(doc, "Signature: Chữ ký số được tạo ra bằng cách băm kết hợp Header, Payload và chuỗi bí mật nội bộ (PAWCARE_JWT_SECRET) chỉ máy chủ lưu trữ.")
    add_body_p(doc,
        "Mô hình kiểm soát truy cập dựa trên vai trò (Role-Based Access Control - RBAC) phân định chặt chẽ quyền hạn của 3 nhóm tác nhân chính: "
        "CUSTOMER (chỉ có quyền thao tác trên dữ liệu thú cưng, ví và booking của chính mình), PROVIDER (chỉ có quyền quản lý dịch vụ, nhân viên "
        "và booking thuộc cơ sở của mình), và ADMIN (có toàn quyền giám sát hệ thống, xét duyệt đối tác và giải quyết khiếu nại). "
        "Bên cạnh đó, hệ thống bổ sung cơ chế giới hạn tần suất truy cập (Rate Limiting) trên bảng auth_rate_limits và tự động khóa tạm thời "
        "tài khoản khi phát hiện dấu hiệu tấn công dò mật khẩu (Brute Force Protection)."
    )

    add_heading_3(doc, "2.6.2. Tiêu chuẩn Thanh toán số VietQR và Xử lý Webhook SePay")
    add_body_p(doc,
        "VietQR là tiêu chuẩn nhận diện mã phản hồi nhanh quốc gia do Công ty Cổ phần Thanh toán Quốc gia Việt Nam (NAPAS) ban hành "
        "theo quy định của Ngân hàng Nhà nước Việt Nam [11]. Tiêu chuẩn này đồng bộ hóa định dạng thanh toán mã QR của tất cả các ngân hàng "
        "thương mại và ví điện tử lớn tại Việt Nam."
    )
    add_body_p(doc,
        "PawCare tích hợp cơ chế nạp tiền và thanh toán thông qua việc sinh mã VietQR động chứa mã chuyển khoản định danh duy nhất "
        "theo quy tắc: PAW<payment_deposit_id>. Khách hàng sử dụng ứng dụng Mobile Banking quét mã để chuyển khoản. Khi tiền về tài khoản trung gian, "
        "cổng thanh toán đối soát SePay tự động bắn một HTTP POST Webhook tới endpoint /api/v1/payments/webhook của hệ thống PawCare. "
        "Hệ thống thực hiện xác thực chữ ký API Key, trích xuất mã PAW, đối soát số tiền và mã giao dịch ngân hàng (bank_tran_id). "
        "Cơ chế Idempotency đảm bảo rằng nếu cổng SePay gửi lại webhook nhiều lần (do mạng trễ), hệ thống chỉ cộng tiền và kích hoạt "
        "đơn hàng đúng một lần duy nhất, ngăn ngừa hoàn toàn nguy cơ cộng tiền kép."
    )
