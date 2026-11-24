# -*- coding: utf-8 -*-
from docx_helpers import add_heading_1, add_heading_2, add_heading_3, add_body_p, add_bullet_p

def build_chapter_1(doc):
    add_heading_1(doc, "CHƯƠNG 1. TỔNG QUAN VỀ ĐỀ TÀI")
    
    # 1.1 Lý do chọn đề tài
    add_heading_2(doc, "1.1. Lý do chọn đề tài")
    add_body_p(doc, 
        "Trong những năm gần đây, cùng với sự tăng trưởng ổn định của nền kinh tế và quá trình đô thị hóa "
        "nhanh chóng tại Việt Nam, nhận thức và lối sống của người dân đô thị đã có những bước chuyển biến sâu sắc. "
        "Thú cưng không còn đơn thuần được nuôi để giữ nhà hay bắt chuột theo tập quán truyền thống, mà đã trở thành "
        "những người bạn đồng hành thân thiết, thậm chí được xem như thành viên chính thức trong gia đình. Hiện tượng xã hội "
        "này được giới nghiên cứu xã hội học và kinh tế học định nghĩa là xu hướng \"nhân hóa thú cưng\" (Pet Humanization), "
        "trong đó các chủ nuôi tự định vị mình là những \"bố mẹ thú cưng\" (pet parents) và sẵn sàng đầu tư ngân sách đáng kể "
        "để chăm sóc toàn diện về sức khỏe thể chất, tinh thần cũng như diện mạo cho thú cưng của mình [12]."
    )
    add_body_p(doc,
        "Theo các báo cáo nghiên cứu thị trường uy tín từ Euromonitor International và Hiệp hội Thú cưng Châu Á (Pet Fair Asia), "
        "ngành công nghiệp chăm sóc thú cưng (Pet Care Industry / Pet Economy) tại khu vực Đông Nam Á đang duy trì tốc độ "
        "tăng trưởng kép (CAGR) ấn tượng từ 12% đến 15% mỗi năm. Riêng tại thị trường Việt Nam, quy mô thị trường dịch vụ và sản phẩm "
        "thú cưng đã vượt mốc 500 triệu USD vào năm 2024 và được dự báo sẽ tiếp tục bùng nổ trong giai đoạn 2025 – 2030 [12], [13]. "
        "Các đô thị phát triển năng động như Thành phố Hồ Chí Minh, Hà Nội, Bà Rịa - Vũng Tàu, Bình Dương và Đà Nẵng là những "
        "địa bàn ghi nhận mật độ thú cưng nuôi trong các căn hộ, nhà phố cao nhất, kéo theo nhu cầu bức thiết đối với các dịch vụ "
        "chăm sóc chuyên nghiệp như: tắm sấy khử khuẩn, vệ sinh tai móng, cắt tỉa lông tạo hình thẩm mỹ (pet grooming), dịch vụ lưu trú "
        "khách sạn thú cưng (pet boarding/hotel), và dịch vụ chăm sóc tại nhà hoặc dắt chó đi dạo (pet sitting / dog walking)."
    )
    add_body_p(doc,
        "Mặc dù nhu cầu thị trường tăng trưởng vượt bậc, quá trình khảo sát thực tế hoạt động vận hành dịch vụ chăm sóc thú cưng "
        "hiện nay cho thấy một nghịch lý lớn: quy trình kinh doanh và tương tác giữa khách hàng và các cơ sở cung cấp dịch vụ vẫn "
        "mang nặng tính thủ công, phân mảnh và tiềm ẩn nhiều rủi ro nghiêm trọng:"
    )
    add_bullet_p(doc,
        "Quy trình tìm kiếm và đặt lịch phân tán, thiếu minh bạch: Chủ nuôi thú cưng gặp rất nhiều khó khăn khi muốn tra cứu thông tin "
        "về các cơ sở chăm sóc uy tín trong bán kính gần. Thông tin về giá cả dịch vụ, điều kiện tiếp nhận (chủng loại thú cưng, cân nặng, "
        "yêu cầu tiêm chủng) thường không được niêm yết rõ ràng. Khách hàng chủ yếu liên hệ qua số điện thoại cá nhân, tin nhắn Zalo hoặc "
        "Facebook Messenger. Cách thức này dẫn đến việc nhân viên tư vấn phản hồi chậm, thông tin bị trôi, và khách hàng không thể "
        "chủ động nắm bắt khung giờ còn trống (availability slots) của cơ sở.",
        bold_prefix="Đối với khách hàng (Chủ nuôi): "
    )
    add_bullet_p(doc,
        "Công tác điều phối ca trực và quản lý lịch hẹn thủ công, dễ xung đột: Đa số các tiệm spa và cá nhân cung cấp dịch vụ thú cưng "
        "quy mô vừa và nhỏ hiện nay quản lý lịch hẹn bằng sổ tay hoặc các bảng tính Excel rời rạc. Khi lượng khách tăng cao vào các khung giờ "
        "cao điểm hoặc dịp lễ tết, tình trạng nhầm lẫn ca trực của kỹ thuật viên, quên lịch hẹn của khách, hoặc đặt trùng một nhân viên "
        "cho hai thú cưng cùng một lúc (booking collision) xảy ra thường xuyên. Điều này gây nên sự bức xúc lớn cho khách hàng và làm suy giảm "
        "nghiêm trọng uy tín thương hiệu của cơ sở.",
        bold_prefix="Đối với nhà cung cấp dịch vụ (Đối tác / Providers): "
    )
    add_bullet_p(doc,
        "Thiếu cơ chế xác nhận hai chiều và bảo vệ quyền lợi tài chính: Quy trình thực hiện dịch vụ truyền thống hoàn toàn thiếu vắng "
        "nhật ký trạng thái có kiểm chứng. Khi xảy ra sự cố (thú cưng bị xây xước trong lúc cắt móng, trễ giờ bàn giao, hoặc chất lượng "
        "không như cam kết), hai bên dễ rơi vào tranh chấp gay gắt do không có bằng chứng ghi nhận tại thời điểm tiếp nhận (Checked-in) "
        "và thời điểm hoàn tất (Service Done). Bên cạnh đó, việc chuyển khoản trực tiếp qua tài khoản ngân hàng cá nhân hoặc thanh toán "
        "tiền mặt không có cơ chế ký quỹ (escrow) trung gian khiến khách hàng chịu rủi ro mất tiền cọc nếu đối tác hủy hẹn, ngược lại đối tác "
        "cũng đối mặt với nguy cơ khách \"bùng lịch\" gây lãng phí khung giờ phục vụ.",
        bold_prefix="Về tính an toàn và minh bạch giao dịch: "
    )
    add_body_p(doc,
        "Trước bối cảnh trên, việc ứng dụng các thành tựu của công nghệ thông tin – đặc biệt là kiến trúc ứng dụng đa nền tảng "
        "(Cross-platform Mobile, Web SPA, RESTful Microservices/APIs) kết hợp với công nghệ Quản lý Quy trình Nghiệp vụ "
        "(Business Process Management - BPM) theo chuẩn quốc tế BPMN 2.0 – là một giải pháp mang tính đột phá và tất yếu khách quan. "
        "Một hệ thống phần mềm chuyên nghiệp không chỉ số hóa công tác đặt lịch mà còn chuẩn hóa toàn bộ vòng đời cung ứng dịch vụ, "
        "từ thẩm định hồ sơ đối tác, phân bổ lịch làm việc của kỹ thuật viên, điều phối trạng thái thực hiện, đến cơ chế tạm giữ ký quỹ "
        "và đối soát tài chính minh bạch [1], [2], [15]."
    )
    add_body_p(doc,
        "Xuất phát từ thực tiễn sinh động của thị trường cùng mong muốn vận dụng các kiến thức chuyên sâu về công nghệ phần mềm "
        "và quản lý quy trình vào giải quyết một bài toán xã hội có giá trị kinh tế cao, đề tài: \"Xây dựng nền tảng Web và ứng dụng "
        "di động đặt dịch vụ chăm sóc thú cưng PawCare kết hợp quản lý quy trình nghiệp vụ\" đã được lựa chọn thực hiện làm đồ án tốt nghiệp."
    )

    # 1.2 Mục tiêu đề tài
    add_heading_2(doc, "1.2. Mục tiêu đề tài")
    add_body_p(doc,
        "Đề tài PawCare được định hướng với hệ thống mục tiêu rõ ràng, gắn liền giữa nghiên cứu học thuật và khả năng ứng dụng thực tế:"
    )
    add_bullet_p(doc,
        "Nghiên cứu, thiết kế và phát triển hoàn chỉnh một nền tảng thương mại dịch vụ (Pet Service Marketplace) kết hợp quy trình nghiệp vụ "
        "chuẩn hóa, kết nối trực tiếp chủ nuôi thú cưng với các cơ sở và kỹ thuật viên chăm sóc uy tín. Nền tảng đảm bảo vận hành đồng bộ "
        "trên các môi trường ứng dụng di động (Mobile App), cổng thông tin đối tác (Provider Web Portal) và hệ thống quản trị trung tâm "
        "(Admin Workflow Portal), giải quyết triệt để bài toán đặt lịch, ngăn ngừa xung đột thời gian và bảo đảm an toàn giao dịch.",
        bold_prefix="Mục tiêu tổng quát: "
    )
    add_body_p(doc, "Mục tiêu cụ thể của đề tài bao gồm:")
    add_bullet_p(doc,
        "Xây dựng ứng dụng di động dành cho Khách hàng (Customer Mobile App) bằng công nghệ Flutter, cung cấp các tính năng: đăng ký, "
        "đăng nhập xác thực JWT, quản lý hồ sơ sức khỏe thú cưng, tìm kiếm dịch vụ thông minh theo vị trí địa lý và tiêu chí lọc, đặt lịch theo "
        "thời gian thực, thanh toán đặt cọc qua ví nội bộ tích hợp VietQR, theo dõi tiến độ phục vụ hai chiều và đánh giá chất lượng.",
        bold_prefix="Phân hệ Khách hàng: "
    )
    add_bullet_p(doc,
        "Xây dựng Cổng thông tin Web dành cho Đối tác (Provider Web Portal) bằng React và Vite, cho phép nhà cung cấp dịch vụ quản lý hồ sơ "
        "pháp lý cơ sở, thiết lập danh mục dịch vụ và bảng giá, quản lý hồ sơ nhân viên kỹ thuật, cấu hình khung giờ làm việc khả dụng "
        "(availability slots), tiếp nhận/xử lý booking, cập nhật trạng thái thực hiện và theo dõi biến động số dư ví doanh thu.",
        bold_prefix="Phân hệ Đối tác: "
    )
    add_bullet_p(doc,
        "Xây dựng Cổng điều phối và quản trị hệ thống (Admin Portal) trên nền tảng Bonita BPM Community 2025.2, phục vụ công tác xét duyệt "
        "hồ sơ đối tác mới, chuẩn hóa danh mục dịch vụ dùng chung, giám sát toàn diện các luồng booking trên hệ thống, can thiệp phân xử "
        "khiếu nại tranh chấp và quản lý đối soát dòng tiền.",
        bold_prefix="Phân hệ Quản trị viên: "
    )
    add_bullet_p(doc,
        "Thiết kế và phát triển hệ thống Backend RESTful API tập trung (Public API) bằng framework Spring Boot, đáp ứng chuẩn OpenAPI 3.0, "
        "tối ưu hóa hiệu năng truy vấn cơ sở dữ liệu MySQL 8.0, triển khai cơ chế kiểm soát truy cập dựa trên vai trò (RBAC), mẫu thiết kế "
        "sổ cái kép (Double-entry Ledger), cơ chế ký quỹ (Escrow) và xử lý giao dịch bất biến (Idempotent Webhook) từ cổng VietQR SePay.",
        bold_prefix="Phân hệ Backend và Dịch vụ Dữ liệu: "
    )
    add_bullet_p(doc,
        "Mô hình hóa và thực thi bằng công nghệ BPMN 2.0 hai quy trình nghiệp vụ cốt lõi: Quy trình đăng ký và xét duyệt hồ sơ đối tác "
        "(BPMN 01) và Quy trình vòng đời đặt dịch vụ hai chiều kèm xử lý khiếu nại (BPMN 02), chứng minh tính ưu việt của việc kết hợp "
        "Workflow Engine vào kiến trúc phần mềm hướng dịch vụ.",
        bold_prefix="Mô hình hóa quy trình nghiệp vụ: "
    )

    # 1.3 Đối tượng và phạm vi nghiên cứu
    add_heading_2(doc, "1.3. Đối tượng và phạm vi nghiên cứu")
    add_heading_3(doc, "1.3.1. Đối tượng nghiên cứu")
    add_body_p(doc, "Đối tượng nghiên cứu của đồ án tập trung vào các nội dung trọng tâm sau:")
    add_bullet_p(doc, "Nghiệp vụ quản lý, vận hành và chuỗi cung ứng dịch vụ chăm sóc thú cưng tại các đô thị ở Việt Nam.")
    add_bullet_p(doc, "Hành vi người dùng: Quy trình ra quyết định, tìm kiếm, lựa chọn dịch vụ và thanh toán của chủ nuôi thú cưng; quy trình quản lý đơn hàng và điều phối nhân sự của các cơ sở chăm sóc.")
    add_bullet_p(doc, "Chuẩn mô hình hóa quy trình nghiệp vụ doanh nghiệp BPMN 2.0 (Business Process Model and Notation) và kiến trúc thực thi quy trình của Bonita BPM Engine [1], [2].")
    add_bullet_p(doc, "Kiến trúc hệ thống phần mềm phân tán đa nền tảng: Kiến trúc RESTful API, thiết kế cơ sở dữ liệu quan hệ bảo đảm toàn vẹn giao dịch (ACID), mô hình ký quỹ (Escrow) và cơ chế phân quyền bảo mật JWT/RBAC [4], [10].")

    add_heading_3(doc, "1.3.2. Phạm vi nghiên cứu")
    add_body_p(doc, "Phạm vi nghiên cứu và triển khai của đề tài được xác định rõ ràng nhằm đảm bảo tính khả thi và hoàn thiện cao nhất:")
    add_bullet_p(doc, 
        "Hệ thống tập trung chuyên biệt vào các dịch vụ chăm sóc thú cưng thiết yếu (Essential Pet Care Services), bao gồm: "
        "tắm sấy, vệ sinh móng tai mắt, cắt tỉa lông tạo hình (grooming), trông giữ thú cưng tại nhà hoặc khách sạn lưu trú (pet sitting/boarding), "
        "và dắt chó đi dạo. Đề tài không đi vào phạm vi chẩn đoán điều trị y tế chuyên sâu (bệnh viện thú y phẫu thuật điều trị nội trú) "
        "và không xây dựng sàn thương mại điện tử bán lẻ phụ kiện/thức ăn vật lý.",
        bold_prefix="Phạm vi nghiệp vụ: "
    )
    add_bullet_p(doc,
        "Hệ thống thiết lập phân quyền chặt chẽ cho 3 nhóm tác nhân chính: Khách hàng (Customer), Nhà cung cấp dịch vụ (Provider) "
        "và Quản trị viên hệ thống (Administrator), cùng với phân hệ xử lý nghiệp vụ tự động hóa chạy nền (Automated Subsystem).",
        bold_prefix="Phạm vi người dùng: "
    )
    add_bullet_p(doc,
        "Backend sử dụng Java 17/21 và Spring Boot 3; Nền tảng quản lý quy trình sử dụng Bonita BPM Community 2025.2; Cơ sở dữ liệu "
        "sử dụng MySQL 8.0; Ứng dụng di động xây dựng bằng Flutter SDK 3.x; Cổng Web đối tác xây dựng bằng React 18 và Vite.",
        bold_prefix="Phạm vi công nghệ: "
    )
    add_bullet_p(doc,
        "Để phù hợp với điều kiện nghiên cứu đồ án tốt nghiệp và tuân thủ các quy định pháp lý, chức năng thanh toán được triển khai "
        "ở mức mô phỏng tài chính tích hợp thực tế thông qua việc quét mã chuẩn VietQR (chuyển khoản sandbox với mã nội dung PAW<id>), "
        "ghi nhận webhook SePay tự động và quản lý số dư ký quỹ qua ví nội bộ, không tích hợp cổng thanh toán trực tiếp của ngân hàng "
        "yêu cầu tư cách pháp nhân doanh nghiệp.",
        bold_prefix="Phạm vi thanh toán: "
    )

    # 1.4 Phương pháp nghiên cứu
    add_heading_2(doc, "1.4. Phương pháp nghiên cứu")
    add_body_p(doc, "Để đạt được các mục tiêu đề ra, đề tài áp dụng kết hợp các phương pháp nghiên cứu khoa học và kỹ thuật phần mềm chuẩn tắc:")
    add_bullet_p(doc,
        "Thu thập, đọc và tổng hợp các tài liệu tiêu chuẩn kỹ thuật quốc tế (đặc tả BPMN 2.0 từ OMG, tài liệu kiến trúc Spring Boot từ VMware Tanzu, "
        "tài liệu Flutter từ Google, tài liệu Bonita BPM từ Bonitasoft) và các báo cáo khảo sát kinh tế thị trường thú cưng [1], [2], [4], [6], [12].",
        bold_prefix="Phương pháp nghiên cứu lý thuyết: "
    )
    add_bullet_p(doc,
        "Khảo sát thực tế tại các phòng khám, spa thú cưng tại TP.HCM và Vũng Tàu; đóng vai khách hàng trải nghiệm quy trình đặt lịch trên các "
        "nền tảng quốc tế (Rover, Wag!, Collar, Mad Paws) nhằm phân tích ưu nhược điểm, rút ra các bài học thiết kế giao diện và luồng xử lý phù hợp "
        "với bối cảnh Việt Nam.",
        bold_prefix="Phương pháp khảo sát và phân tích hiện trạng: "
    )
    add_bullet_p(doc,
        "Sử dụng ngôn ngữ mô hình hóa thống nhất (UML 2.5) với phần mềm StarUML để xây dựng hệ thống biểu đồ phân tích thiết kế hoàn chỉnh: "
        "Biểu đồ Use Case (UCD), Biểu đồ tuần tự (Sequence Diagram), Biểu đồ phân rã chức năng (FDD) và Biểu đồ quan hệ thực thể (ERD) [14].",
        bold_prefix="Phương pháp phân tích và thiết kế hệ thống (OOAD): "
    )
    add_bullet_p(doc,
        "Áp dụng chuẩn BPMN 2.0 trên Bonita Studio để trực quan hóa và thiết kế các quy trình nghiệp vụ đa bước, xác định rõ các điểm rẽ nhánh "
        "điều kiện (Gateways), các tác vụ người dùng (User Tasks) và tác vụ dịch vụ tự động (Service Tasks).",
        bold_prefix="Phương pháp mô hình hóa quy trình nghiệp vụ: "
    )
    add_bullet_p(doc,
        "Áp dụng quy trình phát triển phần mềm lặp (Iterative & Agile), tiến hành phát triển song song các phân hệ (Backend API, Mobile App, "
        "Web Portal) và tích hợp liên tục (Continuous Integration) qua các giai đoạn.",
        bold_prefix="Phương pháp phát triển phần mềm: "
    )
    add_bullet_p(doc,
        "Xây dựng ma trận kiểm thử toàn diện, áp dụng kiểm thử tự động (Unit Test, Integration Test) trên Spring Boot và Vitest, kết hợp kịch bản "
        "kiểm thử đầu cuối (E2E Test) trên dữ liệu thực tế nhằm đánh giá độ tin cậy và hiệu năng hệ thống.",
        bold_prefix="Phương pháp kiểm thử và đánh giá: "
    )

    # 1.5 Ý nghĩa của đề tài
    add_heading_2(doc, "1.5. Ý nghĩa của đề tài")
    add_body_p(doc, "Đề tài mang lại cả giá trị khoa học học thuật lẫn giá trị ứng dụng thực tiễn to lớn:")
    add_bullet_p(doc,
        "Làm sáng tỏ phương pháp luận kết hợp giữa công nghệ Quản lý Quy trình Nghiệp vụ (BPM) với kiến trúc phần mềm phân tán hiện đại. "
        "Chứng minh tính khả thi của việc sử dụng Workflow Engine (Bonita BPM) làm trung gian điều phối các trạng thái nghiệp vụ phức tạp, "
        "tách biệt hoàn toàn giữa logic quy trình (process logic) và logic ứng dụng (application logic), giúp hệ thống dễ bảo trì và mở rộng.",
        bold_prefix="Ý nghĩa khoa học và học thuật: "
    )
    add_bullet_p(doc,
        "Cung cấp cho cộng đồng chủ nuôi thú cưng một công cụ số tiện lợi, minh bạch, giúp tiết kiệm thời gian tìm kiếm, đặt lịch chuẩn xác "
        "và hoàn toàn an tâm về chất lượng dịch vụ cũng như tính an toàn tài chính. Đồng thời, nền tảng cung cấp cho các hộ kinh doanh dịch vụ "
        "thú cưng vừa và nhỏ một giải pháp chuyển đổi số toàn diện với chi phí tối ưu, nâng cao năng suất phục vụ và chất lượng quản trị.",
        bold_prefix="Ý nghĩa thực tiễn đối với xã hội: "
    )
    add_bullet_p(doc,
        "Giúp sinh viên tổng hợp, vận dụng nhuần nhuyễn toàn bộ khối lượng kiến thức đã tích lũy trong suốt quá trình đào tạo ngành Công nghệ thông tin "
        "tại Trường Đại học Bà Rịa - Vũng Tàu, từ lập trình hướng đối tượng, kiến trúc phần mềm, mô hình hóa dữ liệu, đến xây dựng ứng dụng di động "
        "và tích hợp hệ thống quy mô doanh nghiệp.",
        bold_prefix="Ý nghĩa đối với quá trình đào tạo: "
    )
