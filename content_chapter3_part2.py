# -*- coding: utf-8 -*-
from docx_helpers import (
    add_heading_2, add_heading_3, add_body_p, 
    add_bullet_p, add_image_figure, add_table_caption, format_custom_table,
    set_table_borders, set_cell_margins, set_cell_shading, FONT_NAME, FONT_SIZE_TABLE
)
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def add_db_spec_table(doc, table_num, tname, tdesc, columns):
    caption_text = f"Bảng 3.{table_num}. Đặc tả cấu trúc bảng {tname} ({tdesc})"
    add_table_caption(doc, caption_text)
    
    table = doc.add_table(rows=len(columns) + 1, cols=5)
    headers = ["Thuộc tính", "Kiểu dữ liệu", "Khóa", "Ràng buộc", "Diễn giải ý nghĩa nghiệp vụ"]
    for i, h in enumerate(headers):
        table.rows[0].cells[i].paragraphs[0].text = h
        
    for r_idx, col in enumerate(columns):
        row = table.rows[r_idx + 1]
        for c_idx, val in enumerate(col):
            row.cells[c_idx].paragraphs[0].text = str(val)
            
    format_custom_table(table, [1.5, 1.2, 0.6, 1.0, 1.9], 
                        [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, 
                         WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])
    
    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_before = Pt(0)
    p_after.paragraph_format.space_after = Pt(4)

def build_chapter_3_part2(doc):
    # 3.3.3 Sơ đồ tuần tự
    add_heading_3(doc, "3.3.3. Sơ đồ tuần tự (Sequence Diagram)")
    add_body_p(doc,
        "Biểu đồ tuần tự (Sequence Diagram) là loại biểu đồ tương tác quan trọng nhất trong mô hình hóa động (dynamic modeling), "
        "thể hiện cách thức các đối tượng trong hệ thống trao đổi thông điệp (messages) với nhau theo trình tự thời gian để hoàn thành "
        "một ca sử dụng cụ thể. Toàn bộ 18 sơ đồ tuần tự dưới đây được trích xuất trực tiếp từ file pawcare_sd.mdj bằng StarUML, "
        "bao phủ đầy đủ các kịch bản tương tác cốt lõi của 3 nhóm tác nhân:"
    )

    # 1. Khách hàng SDs
    add_body_p(doc, "a) Các sơ đồ tuần tự thuộc Phân hệ Khách hàng (Customer):", bold=True)
    
    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Đăng ký!Đăng ký tài khoản.png",
                     "Hình 3.9. Sơ đồ tuần tự Đăng ký tài khoản (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.9 biểu diễn chu trình Đăng ký tài khoản của Người dùng vãng lai. Người dùng nhập thông tin họ tên, email, số điện thoại, mật khẩu "
        "trên giao diện di động (GD Đăng ký). Giao diện gửi dữ liệu tới Control Đăng ký để xác thực cú pháp (email regex, độ phức tạp mật khẩu). "
        "Nếu hợp lệ, Controller truy vấn cơ sở dữ liệu kiểm tra xem email/username đã tồn tại hay chưa. Nếu đã tồn tại, hệ thống phản hồi thông báo lỗi; "
        "nếu chưa tồn tại, mật khẩu được băm an toàn bằng thuật toán BCrypt và lưu bản ghi mới vào CSDL với vai trò CUSTOMER."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Quản lý thú cưng!Quản lý thú cưng.png",
                     "Hình 3.10. Sơ đồ tuần tự Quản lý thú cưng (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.10 thể hiện luồng quản lý hồ sơ thú cưng. Khách hàng gửi yêu cầu xem danh sách thú cưng từ giao diện, Controller truy vấn CSDL "
        "theo customer_id và trả về danh sách thẻ thú cưng. Khi khách hàng thêm mới hoặc chỉnh sửa thông tin (tên, loài, giống, tuổi, cân nặng, tiền sử tiêm chủng), "
        "Controller kiểm tra tính hợp lệ của dữ liệu, xác minh quyền sở hữu bản ghi và cập nhật vào bảng pets."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Tìm kiếm!Tìm kiếm dịch vụ.png",
                     "Hình 3.11. Sơ đồ tuần tự Tìm kiếm dịch vụ (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.11 đặc tả quy trình tìm kiếm và xếp hạng đối tác. Khách hàng nhập từ khóa hoặc chọn các tiêu chí lọc (loại dịch vụ, khoảng giá, khu vực). "
        "Control Tìm kiếm tiếp nhận yêu cầu, gọi Service truy vấn CSDL các đối tác đang ở trạng thái APPROVED và dịch vụ ACTIVE. Hệ thống tự động tính điểm "
        "gợi ý dựa trên công thức đa tiêu chí (độ phù hợp dịch vụ 30%, lịch trống 25%, thú cưng 20%, điểm đánh giá 15%, giá 10%) và trả về danh sách đối tác được xếp hạng."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Xem thông tin dich vụ!Xem thông tin dịch vụ.png",
                     "Hình 3.12. Sơ đồ tuần tự Xem thông tin dịch vụ (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.12 mô tả việc truy xuất thông tin chi tiết dịch vụ. Khi khách hàng chọn một đối tác cụ thể, hệ thống gửi yêu cầu lấy thông tin hồ sơ cơ sở, "
        "danh mục dịch vụ, bảng giá chi tiết, thời lượng phục vụ, danh sách nhân viên kỹ thuật kèm kỹ năng chuyên môn, khung giờ làm việc và các đánh giá gần nhất từ CSDL."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Tạo booking!Tạo booking.png",
                     "Hình 3.13. Sơ đồ tuần tự Tạo booking (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.13 là sơ đồ tuần tự trọng yếu nhất của phân hệ khách hàng. Khách hàng chọn dịch vụ, chọn thú cưng, ngày và khung giờ phục vụ. "
        "Control Đặt lịch tiếp nhận, kiểm tra ràng buộc điều kiện nhận thú cưng và thực hiện kiểm tra chống trùng lịch (collision prevention) "
        "đối với nhân viên được chỉ định. Nếu hợp lệ, hệ thống kiểm tra số dư ví khả dụng, thực hiện khóa tạm giữ ký quỹ (escrow lock), "
        "tạo bản ghi booking ở trạng thái PENDING, ghi nhận lịch sử vào booking_status_history, và ghi sự kiện vào booking_workflow_outbox để bắn thông báo tới Đối tác."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Khách hàng!Đánh giá!Đánh giá dịch vụ.png",
                     "Hình 3.14. Sơ đồ tuần tự Đánh giá dịch vụ (Khách hàng)", 5.8)
    add_body_p(doc,
        "Hình 3.14 mô tả luồng đánh giá sau khi hoàn tất dịch vụ. Khách hàng chỉ có thể mở biểu mẫu đánh giá khi đơn booking đã chuyển sang trạng thái COMPLETED. "
        "Khách hàng chấm điểm số sao (1-5) và viết nhận xét. Controller xác thực ràng buộc, lưu đánh giá vào bảng reviews, cập nhật lại điểm đánh giá trung bình "
        "(rating_avg) và tổng số lượt đánh giá của Đối tác trong bảng providers."
    )

    # 2. Đối tác SDs
    add_body_p(doc, "b) Các sơ đồ tuần tự thuộc Phân hệ Đối tác (Provider):", bold=True)
    
    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Quản lý phân quyền!Quản lý tài khoản người dùng.png",
                     "Hình 3.15. Sơ đồ tuần tự Quản lý phân quyền tài khoản người dùng (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.15 thể hiện quy trình phân quyền nội bộ tại cơ sở của Đối tác. Chủ cơ sở (Provider Admin) truy cập danh sách nhân viên, gán vai trò "
        "(Kỹ thuật viên tắm sấy, Groomer tạo hình, Nhân viên tiếp đón). Controller kiểm tra quyền hạn của chủ cơ sở và cập nhật quyền hạn tương ứng vào CSDL."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Thiết lập lịch!Thiết lập lịch.png",
                     "Hình 3.16. Sơ đồ tuần tự Thiết lập lịch làm việc khả dụng (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.16 mô tả luồng thiết lập ca trực và khung giờ khả dụng (availability slots). Đối tác chọn nhân viên, cấu hình ngày làm việc, giờ bắt đầu và kết thúc, "
        "ngày nghỉ lễ hoặc trạng thái bận. Hệ thống kiểm tra điều kiện (start_time < end_time, không chồng lấn ca trực cũ) và lưu các khung slot vào bảng staff_schedules."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Quản lý Booking!Quản lý Booking.png",
                     "Hình 3.17. Sơ đồ tuần tự Quản lý Booking (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.17 đặc tả luồng tiếp nhận và cập nhật tiến độ thực hiện đơn booking. Khi có booking mới ở trạng thái PENDING, đối tác có quyền chọn Chấp nhận "
        "(chuyển sang CONFIRMED và phân công nhân viên) hoặc Từ chối (chuyển sang REJECTED kèm lý do bắt buộc, tự động giải phóng tiền ký quỹ hoàn về cho khách). "
        "Khi khách đưa thú cưng tới, đối tác cập nhật CHECKED_IN; khi bắt đầu làm dịch vụ chuyển sang IN_SERVICE; và khi hoàn tất dịch vụ chuyển sang SERVICE_DONE."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Thống kê!Xem doanh thu và báo cáo.png",
                     "Hình 3.18. Sơ đồ tuần tự Xem doanh thu và báo cáo (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.18 biểu diễn luồng tra cứu tài chính của đối tác. Đối tác chọn khoảng thời gian cần báo cáo (tuần/tháng/năm). Controller truy vấn các đơn "
        "hoàn tất thành công và lịch sử biến động số dư trong bảng wallet_transactions, tổng hợp doanh thu thuần (90%), số dư khả dụng và số dư tạm giữ ký quỹ."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Quản lý hồ sơ đối tác!Quản lý hồ sơ đối tác.png",
                     "Hình 3.19. Sơ đồ tuần tự Quản lý hồ sơ đối tác (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.19 mô tả luồng cập nhật thông tin cơ sở đối tác: tên thương hiệu, địa chỉ, số điện thoại hotline, tọa độ bản đồ, ảnh đại diện, "
        "và tải lên các tài liệu chứng minh giấy phép kinh doanh/chứng chỉ hành nghề vào bảng provider_documents để chờ duyệt."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!Đối tác!Phản hồi đánh giá!Phản hồi đánh giá.png",
                     "Hình 3.20. Sơ đồ tuần tự Phản hồi đánh giá (Đối tác)", 5.8)
    add_body_p(doc,
        "Hình 3.20 thể hiện luồng tương tác chăm sóc khách hàng. Đối tác đọc các đánh giá của khách hàng, nhập nội dung phản hồi giải trình hoặc cảm ơn. "
        "Hệ thống lưu nội dung phản hồi vào trường reply_comment của bảng reviews và bắn thông báo tới tài khoản khách hàng tương ứng."
    )

    # 3. Quản trị viên SDs
    add_body_p(doc, "c) Các sơ đồ tuần tự thuộc Phân hệ Quản trị viên (Administrator):", bold=True)
    
    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Quản lý phân quyền!Quản lý tài khoản người dùng.png",
                     "Hình 3.21. Sơ đồ tuần tự Quản lý tài khoản người dùng (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.21 mô tả chức năng kiểm soát tài khoản của Admin: tra cứu danh sách toàn bộ người dùng, kích hoạt trạng thái ACTIVE, tạm khóa SUSPENDED "
        "khi phát hiện hành vi gian lận hoặc vi phạm chính sách cộng đồng."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Giám sát Booking!Giám sát Booking.png",
                     "Hình 3.22. Sơ đồ tuần tự Giám sát Booking (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.22 đặc tả chức năng giám sát vận hành toàn hệ thống. Quản trị viên lọc và theo dõi tất cả các booking theo thời gian thực, "
        "xem nhật ký chuyển trạng thái (status history) để kịp thời phát hiện các đơn hàng trễ tiến độ hoặc gặp lỗi vận hành."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Thống kê!Xem doanh thu và báo cáo.png",
                     "Hình 3.23. Sơ đồ tuần tự Xem doanh thu và báo cáo (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.23 biểu diễn luồng tổng hợp tài chính vĩ mô của sàn PawCare: tính toán tổng giá trị giao dịch (GMV), doanh thu phí dịch vụ sàn thu được (10%), "
        "tổng quỹ tiền đang tạm giữ ký quỹ (escrow balance toàn hệ thống) và các báo cáo tăng trưởng người dùng."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Duyệt hồ sơ đối tác!Duyệt hồ sơ đối tác.png",
                     "Hình 3.24. Sơ đồ tuần tự Duyệt hồ sơ đối tác (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.24 mô tả quy trình thẩm định đối tác mới. Quản trị viên mở hàng đợi hồ sơ PENDING trên Bonita BPM Portal, thẩm tra giấy phép kinh doanh, "
        "chứng chỉ hành nghề và địa điểm cơ sở. Admin đưa ra quyết định APPROVE (kích hoạt đối tác), REJECT (từ chối kèm lý do) hoặc NEED_MORE_INFO (yêu cầu bổ sung)."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Quản lý danh mục!Quản lý danh mục.png",
                     "Hình 3.25. Sơ đồ tuần tự Quản lý danh mục dịch vụ (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.25 thể hiện luồng quản lý danh mục dịch vụ chuẩn. Quản trị viên khởi tạo hoặc cập nhật các nhóm dịch vụ dùng chung (Tắm vệ sinh, Cắt tỉa lông, "
        "Khách sạn lưu trú). Nếu danh mục đang có dịch vụ liên kết, hệ thống chỉ cho phép chuyển sang trạng thái ẩn (is_active = false) nhằm bảo đảm toàn vẹn tham chiếu."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/Chức năng chung!QTV!Xử lý khiếu nại và kiểm duyệt đánh giá!Xử lý khiếu nại và kiểm duyệt đánh giá.png",
                     "Hình 3.26. Sơ đồ tuần tự Xử lý khiếu nại và kiểm duyệt đánh giá (Quản trị viên)", 5.8)
    add_body_p(doc,
        "Hình 3.26 mô tả quy trình giải quyết tranh chấp. Khi khách hàng mở khiếu nại (bảng complaints), Quản trị viên tiếp nhận hồ sơ, yêu cầu giải trình từ hai phía, "
        "thẩm định bằng chứng và ra phán quyết: Hoàn tiền toàn phần/bán phần cho khách hàng hoặc Giải phóng thanh toán cho đối tác, đồng thời ẩn các đánh giá chứa ngôn từ phản cảm."
    )

    # 3.3.4 BPMN 2.0
    add_heading_3(doc, "3.3.4. Mô hình hóa quy trình nghiệp vụ với chuẩn BPMN 2.0")
    add_body_p(doc,
        "Để chuẩn hóa các quy trình nghiệp vụ phức tạp có sự phối hợp đa tác nhân và xử lý trạng thái nhiều bước, "
        "PawCare áp dụng chuẩn quốc tế BPMN 2.0 trên nền tảng Bonita BPM Community 2025.2. Hai quy trình trọng tâm sau được mô hình hóa và thực thi:"
    )

    add_image_figure(doc, "downloads_staging/bpmn_approval.png", 
                     "Hình 3.27. Sơ đồ quy trình BPMN 01: Đăng ký và xét duyệt hồ sơ đối tác", 6.0)
    add_body_p(doc,
        "Quy trình BPMN 01 (Hình 3.27) mô tả toàn bộ vòng đời xét duyệt đối tác cung ứng dịch vụ. Bắt đầu khi ứng viên đối tác gửi hồ sơ đăng ký "
        "(POST /api/v1/providers/apply). Quy trình tự động khởi tạo một Process Instance trên Bonita Engine và phân bổ công việc về làn (Lane) của Quản trị viên. "
        "Admin thực hiện User Task \"Thẩm định hồ sơ và tài liệu\". Tại cổng phân nhánh điều kiện (Exclusive Gateway): "
        "(1) Nếu đủ điều kiện (APPROVE), hệ thống gọi Service Task tự động cập nhật approval_status = 'APPROVED' trong MySQL, gửi thông báo chúc mừng và đối tác bắt đầu được hiển thị; "
        "(2) Nếu thiếu giấy tờ (NEED_MORE_INFO), quy trình gửi yêu cầu bổ sung và chờ đối tác cập nhật lại; "
        "(3) Nếu không đạt yêu cầu (REJECT), quy trình chuyển trạng thái đối tác sang REJECTED kèm văn bản lý do giải trình."
    )

    add_image_figure(doc, "downloads_staging/bpmn_booking.png", 
                     "Hình 3.28. Sơ đồ quy trình BPMN 02: Vòng đời booking và thực hiện dịch vụ hai chiều", 6.0)
    add_body_p(doc,
        "Quy trình BPMN 02 (Hình 3.28) điều phối toàn bộ vòng đời của một đơn đặt lịch từ khởi tạo đến kết thúc. Quy trình tuân thủ nghiêm ngặt máy trạng thái:"
    )
    add_bullet_p(doc, "Khởi tạo (PENDING): Khách hàng tạo booking, kiểm tra xung đột slot thành công, số tiền thanh toán được khóa trong ví tạm giữ ký quỹ (Escrow). Thông báo được bắn tức thì tới Đối tác.")
    add_bullet_p(doc, "Tiếp nhận (CONFIRMED hoặc REJECTED): Đối tác có quyền chấp nhận (chuyển sang CONFIRMED và phân công kỹ thuật viên) hoặc từ chối kèm lý do (chuyển sang REJECTED, lập tức hoàn tiền ký quỹ 100% cho khách).")
    add_bullet_p(doc, "Thực hiện dịch vụ hai chiều: Khi khách đưa thú cưng tới, đối tác quét mã xác nhận CHECKED_IN; khi bắt đầu công đoạn chăm sóc chuyển sang IN_SERVICE; khi kết thúc công đoạn chăm sóc, đối tác cập nhật SERVICE_DONE. Tại bước này, tiền ký quỹ vẫn tiếp tục bị khóa an toàn.")
    add_bullet_p(doc, "Xác nhận và Quyết toán (COMPLETED hoặc DISPUTED): Khách hàng kiểm tra thú cưng và nhấn nút \"Xác nhận hoàn tất\" (COMPLETED). Hệ thống kích hoạt cơ chế giải phóng ký quỹ: 90% số tiền chuyển vào ví khả dụng của đối tác, 10% chuyển vào tài khoản doanh thu sàn PawCare. Nếu khách hàng không hài lòng, khách có quyền mở Khiếu nại (DISPUTED) để Quản trị viên can thiệp xử lý.")

    # 3.4 Thiết kế CSDL
    add_heading_2(doc, "3.4. Thiết kế cơ sở dữ liệu")
    add_heading_3(doc, "3.4.1. Sơ đồ thực thể kết hợp (ERD)")
    add_body_p(doc,
        "Cơ sở dữ liệu của PawCare được thiết kế trên hệ quản trị MySQL 8.0 với engine lưu trữ InnoDB, tuân thủ chuẩn hóa dạng 3 (3NF) "
        "nhằm triệt tiêu dư thừa dữ liệu và đảm bảo toàn vẹn tham chiếu. Dưới đây là Sơ đồ quan hệ thực thể (ERD) hoàn chỉnh của hệ thống:"
    )

    add_image_figure(doc, "downloads_staging/erd.png", 
                     "Hình 3.29. Sơ đồ thực thể kết hợp (ERD) cơ sở dữ liệu hệ thống PawCare", 6.0)
    add_body_p(doc,
        "Sơ đồ ERD (Hình 3.29) được tổ chức thành 5 cụm thực thể liên kết chặt chẽ:"
    )
    add_bullet_p(doc, "Cụm Người dùng và Hồ sơ: user_profiles đóng vai trò thực thể trung tâm, liên kết 1-1 với providers (hồ sơ cơ sở đối tác), 1-N với provider_documents (tài liệu chứng minh), và 1-N với pets (danh sách thú cưng của khách hàng).")
    add_bullet_p(doc, "Cụm Dịch vụ và Nhân sự: service_categories đóng vai trò danh mục chuẩn dùng chung, liên kết 1-N với services. Bảng providers sở hữu 1-N với services, 1-N với staff (kỹ thuật viên), và staff sở hữu 1-N với staff_schedules (lịch làm việc khả dụng).")
    add_bullet_p(doc, "Cụm Giao dịch và Đặt lịch: bookings liên kết khóa ngoại với customers (user_profiles), providers, services, staff và pets. Mỗi booking có 1-N với booking_status_history để lưu vết tiến độ và 1-N với payments.")
    add_bullet_p(doc, "Cụm Ví điện tử và Ký quỹ: wallets liên kết 1-1 với user_profiles. Bảng wallets có quan hệ 1-N với wallet_transactions (lịch sử sổ cái kép), payment_deposits (giao dịch nạp tiền VietQR), và withdrawal_requests (yêu cầu rút tiền).")
    add_bullet_p(doc, "Cụm Tương tác và Vận hành: reviews (đánh giá dịch vụ), complaints (khiếu nại tranh chấp), notifications (thông báo người dùng), booking_workflow_outbox (sự kiện đồng bộ Bonita BPM), và audit_logs (nhật ký kiểm toán an toàn).")

    # 3.4.2 Đặc tả các bảng CSDL
    add_heading_3(doc, "3.4.2. Đặc tả các bảng cơ sở dữ liệu")
    add_body_p(doc,
        "Dưới đây là bảng đặc tả kỹ thuật chi tiết của toàn bộ các bảng trong cơ sở dữ liệu PawCare, "
        "được trích xuất trực tiếp từ các file migration mã nguồn thực tế (001_pawcare_mysql_schema.sql đến 013_...):"
    )

    table_counter = 40

    # 1. user_profiles
    add_db_spec_table(doc, table_counter, "user_profiles", "Hồ sơ người dùng dùng chung", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh duy nhất của tài khoản"),
        ("email", "VARCHAR(191)", "", "NOT NULL UNIQUE", "Địa chỉ email dùng để đăng nhập và nhận thông báo"),
        ("phone", "VARCHAR(32)", "", "NULL", "Số điện thoại liên hệ chính của người dùng"),
        ("full_name", "VARCHAR(120)", "", "NOT NULL", "Họ và tên đầy đủ của người dùng"),
        ("role", "ENUM", "", "NOT NULL DEFAULT 'CUSTOMER'", "Vai trò hệ thống: 'CUSTOMER', 'PROVIDER', 'ADMIN'"),
        ("password_hash", "VARCHAR(255)", "", "NOT NULL", "Chuỗi mật khẩu đã được băm an toàn bằng thuật toán BCrypt"),
        ("status", "ENUM", "", "NOT NULL DEFAULT 'ACTIVE'", "Trạng thái tài khoản: 'ACTIVE', 'INACTIVE', 'SUSPENDED'"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm khởi tạo tài khoản"),
        ("updated_at", "DATETIME", "", "NOT NULL ON UPDATE CURRENT_TIMESTAMP", "Thời điểm cập nhật thông tin gần nhất")
    ])
    table_counter += 1

    # 2. providers
    add_db_spec_table(doc, table_counter, "providers", "Thông tin nhà cung cấp dịch vụ (Đối tác)", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh duy nhất của cơ sở đối tác"),
        ("user_id", "BIGINT", "FK", "NOT NULL UNIQUE", "Khóa ngoại liên kết tới bảng user_profiles (chủ tài khoản)"),
        ("business_name", "VARCHAR(191)", "", "NOT NULL", "Tên cơ sở hoặc thương hiệu dịch vụ chăm sóc"),
        ("provider_type", "ENUM", "", "NOT NULL DEFAULT 'BUSINESS'", "Hình thức hoạt động: 'INDIVIDUAL' (cá nhân), 'BUSINESS' (cửa hàng/spa)"),
        ("address", "VARCHAR(255)", "", "NOT NULL", "Địa chỉ trụ sở hoặc cơ sở chăm sóc thú cưng"),
        ("city", "VARCHAR(80)", "", "NOT NULL", "Tỉnh / Thành phố hoạt động"),
        ("latitude", "DECIMAL(10,8)", "", "NULL", "Tọa độ vĩ độ địa lý phục vụ định vị bản đồ"),
        ("longitude", "DECIMAL(11,8)", "", "NULL", "Tọa độ kinh độ địa lý phục vụ định vị bản đồ"),
        ("bio", "TEXT", "", "NULL", "Mô tả giới thiệu chi tiết về cơ sở và kinh nghiệm"),
        ("approval_status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái xét duyệt: 'PENDING', 'APPROVED', 'REJECTED'"),
        ("rating_avg", "DECIMAL(3,2)", "", "NOT NULL DEFAULT 5.00", "Điểm đánh giá trung bình theo thang điểm 5"),
        ("rating_count", "INT", "", "NOT NULL DEFAULT 0", "Tổng số lượt đánh giá đã nhận từ khách hàng"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm đăng ký làm đối tác"),
        ("updated_at", "DATETIME", "", "NOT NULL ON UPDATE CURRENT_TIMESTAMP", "Thời điểm cập nhật thông tin gần nhất")
    ])
    table_counter += 1

    # 3. provider_documents
    add_db_spec_table(doc, table_counter, "provider_documents", "Tài liệu chứng minh hồ sơ đối tác", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh tài liệu chứng minh"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng providers"),
        ("document_type", "VARCHAR(50)", "", "NOT NULL", "Loại tài liệu: 'CCCD', 'BUSINESS_LICENSE', 'CERTIFICATE'"),
        ("file_url", "VARCHAR(255)", "", "NOT NULL", "Đường dẫn lưu trữ file ảnh hoặc văn bản scan"),
        ("verification_status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái xác minh: 'PENDING', 'VERIFIED', 'REJECTED'"),
        ("submitted_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm tải tài liệu lên hệ thống")
    ])
    table_counter += 1

    # 4. pets
    add_db_spec_table(doc, table_counter, "pets", "Hồ sơ thú cưng của khách hàng", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh duy nhất của thú cưng"),
        ("customer_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới user_profiles (chủ sở hữu)"),
        ("name", "VARCHAR(80)", "", "NOT NULL", "Tên gọi của thú cưng"),
        ("pet_type", "ENUM", "", "NOT NULL", "Loài thú cưng: 'DOG' (chó), 'CAT' (mèo), 'OTHER'"),
        ("breed", "VARCHAR(80)", "", "NULL", "Giống loài cụ thể (Poodle, Corgi, Mèo Anh lông ngắn,...)"),
        ("gender", "ENUM", "", "NOT NULL DEFAULT 'UNKNOWN'", "Giới tính: 'MALE', 'FEMALE', 'UNKNOWN'"),
        ("age_years", "DECIMAL(4,1)", "", "NULL", "Tuổi của thú cưng (tính theo năm)"),
        ("weight_kg", "DECIMAL(5,2)", "", "NOT NULL", "Cân nặng (kg) phục vụ tính giá và chọn gói dịch vụ"),
        ("vaccination_notes", "TEXT", "", "NULL", "Ghi chú lịch sử tiêm phòng dại, vắc-xin tổng hợp"),
        ("special_notes", "TEXT", "", "NULL", "Ghi chú đặc biệt về tính cách, dị ứng hoặc bệnh ngoài da"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm thêm thú cưng vào hệ thống")
    ])
    table_counter += 1

    # 5. service_categories
    add_db_spec_table(doc, table_counter, "service_categories", "Danh mục dịch vụ chuẩn dùng chung", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã danh mục dịch vụ"),
        ("name", "VARCHAR(120)", "", "NOT NULL UNIQUE", "Tên nhóm dịch vụ (Tắm vệ sinh, Cắt tỉa lông, Lưu trú)"),
        ("description", "TEXT", "", "NULL", "Mô tả chi tiết về quy chuẩn nhóm dịch vụ"),
        ("is_active", "BOOLEAN", "", "NOT NULL DEFAULT TRUE", "Trạng thái kích hoạt cho phép đối tác chọn"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm tạo danh mục")
    ])
    table_counter += 1

    # 6. services
    add_db_spec_table(doc, table_counter, "services", "Dịch vụ do đối tác cấu hình", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh dịch vụ"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng providers"),
        ("category_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng service_categories"),
        ("name", "VARCHAR(191)", "", "NOT NULL", "Tên dịch vụ cụ thể do đối tác đặt"),
        ("description", "TEXT", "", "NULL", "Mô tả chi tiết các bước trong quy trình dịch vụ"),
        ("base_price", "DECIMAL(12,2)", "", "NOT NULL", "Đơn giá dịch vụ cơ bản (VNĐ)"),
        ("duration_minutes", "INT", "", "NOT NULL", "Thời lượng thực hiện dịch vụ (tính theo phút)"),
        ("is_active", "BOOLEAN", "", "NOT NULL DEFAULT TRUE", "Cờ hiển thị dịch vụ cho khách hàng đặt lịch"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm tạo dịch vụ")
    ])
    table_counter += 1

    # 7. staff
    add_db_spec_table(doc, table_counter, "staff", "Nhân viên kỹ thuật của cơ sở đối tác", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh nhân viên kỹ thuật"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng providers"),
        ("full_name", "VARCHAR(120)", "", "NOT NULL", "Họ và tên của nhân viên"),
        ("phone", "VARCHAR(32)", "", "NULL", "Số điện thoại liên hệ cá nhân của nhân viên"),
        ("role_title", "VARCHAR(80)", "", "NOT NULL DEFAULT 'Groomer'", "Chức danh chuyên môn: Groomer, Trợ tá, Bác sĩ thú y"),
        ("is_active", "BOOLEAN", "", "NOT NULL DEFAULT TRUE", "Trạng thái làm việc của nhân viên tại cơ sở"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm tiếp nhận nhân sự")
    ])
    table_counter += 1

    # 8. staff_schedules
    add_db_spec_table(doc, table_counter, "staff_schedules", "Khung giờ làm việc khả dụng (Availability Slots)", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh khung giờ làm việc"),
        ("staff_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng staff"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng providers"),
        ("work_date", "DATE", "", "NOT NULL", "Ngày làm việc cụ thể"),
        ("start_time", "TIME", "", "NOT NULL", "Thời điểm bắt đầu khung ca trực"),
        ("end_time", "TIME", "", "NOT NULL", "Thời điểm kết thúc khung ca trực"),
        ("is_available", "BOOLEAN", "", "NOT NULL DEFAULT TRUE", "Trạng thái còn rảnh (True) hoặc đã có lịch (False)")
    ])
    table_counter += 1

    # 9. bookings
    add_db_spec_table(doc, table_counter, "bookings", "Đơn đặt lịch dịch vụ thú cưng", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh duy nhất của booking"),
        ("booking_code", "VARCHAR(32)", "", "NOT NULL UNIQUE", "Mã đặt chỗ định danh người dùng nhìn thấy (PAW-...)"),
        ("customer_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới user_profiles (khách hàng đặt)"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới providers (cơ sở phục vụ)"),
        ("service_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới services (dịch vụ sử dụng)"),
        ("staff_id", "BIGINT", "FK", "NULL", "Khóa ngoại liên kết tới staff (nhân viên được chỉ định)"),
        ("pet_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới pets (thú cưng được chăm sóc)"),
        ("booking_date", "DATE", "", "NOT NULL", "Ngày hẹn thực hiện dịch vụ"),
        ("start_time", "TIME", "", "NOT NULL", "Khung giờ bắt đầu phục vụ"),
        ("end_time", "TIME", "", "NOT NULL", "Khung giờ dự kiến kết thúc phục vụ"),
        ("total_price", "DECIMAL(12,2)", "", "NOT NULL", "Tổng số tiền dịch vụ tại thời điểm khóa giá"),
        ("status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái: PENDING, CONFIRMED, CHECKED_IN, IN_SERVICE, SERVICE_DONE, COMPLETED, CANCELLED, REJECTED"),
        ("cancellation_reason", "TEXT", "", "NULL", "Lý do từ chối của đối tác hoặc lý do hủy của khách"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm gửi yêu cầu đặt lịch")
    ])
    table_counter += 1

    # 10. booking_status_history
    add_db_spec_table(doc, table_counter, "booking_status_history", "Nhật ký chuyển đổi trạng thái booking", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã bản ghi lịch sử trạng thái"),
        ("booking_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng bookings"),
        ("from_status", "VARCHAR(32)", "", "NULL", "Trạng thái trước khi chuyển đổi"),
        ("to_status", "VARCHAR(32)", "", "NOT NULL", "Trạng thái mới sau khi chuyển đổi"),
        ("changed_by", "BIGINT", "FK", "NOT NULL", "Khóa ngoại user_profiles (người thực hiện thao tác)"),
        ("notes", "TEXT", "", "NULL", "Ghi chú tiến độ hoặc biên bản bàn giao"),
        ("changed_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm thực hiện chuyển đổi trạng thái")
    ])
    table_counter += 1

    # 11. payments
    add_db_spec_table(doc, table_counter, "payments", "Giao dịch thanh toán booking", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh giao dịch thanh toán"),
        ("booking_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng bookings"),
        ("amount", "DECIMAL(12,2)", "", "NOT NULL", "Số tiền thanh toán của giao dịch (VNĐ)"),
        ("payment_method", "ENUM", "", "NOT NULL", "Phương thức thanh toán: 'VIETQR', 'WALLET'"),
        ("payment_status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái: 'PENDING', 'ESCROWED', 'SETTLED', 'REFUNDED'"),
        ("transaction_ref", "VARCHAR(64)", "", "NULL", "Mã tham chiếu đối soát duy nhất từ hệ thống ngân hàng"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm khởi tạo giao dịch")
    ])
    table_counter += 1

    # 12. reviews
    add_db_spec_table(doc, table_counter, "reviews", "Đánh giá chất lượng dịch vụ", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh đánh giá"),
        ("booking_id", "BIGINT", "FK", "NOT NULL UNIQUE", "Khóa ngoại liên kết tới bảng bookings (mỗi đơn 1 review)"),
        ("customer_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới user_profiles (người đánh giá)"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới providers (đối tác nhận đánh giá)"),
        ("rating", "TINYINT", "", "NOT NULL CHECK (rating BETWEEN 1 AND 5)", "Điểm đánh giá số sao (từ 1 đến 5 sao)"),
        ("comment", "TEXT", "", "NULL", "Nội dung nhận xét chi tiết của khách hàng"),
        ("reply_comment", "TEXT", "", "NULL", "Nội dung phản hồi giải trình của Đối tác"),
        ("replied_at", "DATETIME", "", "NULL", "Thời điểm đối tác gửi phản hồi"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm khách hàng gửi đánh giá")
    ])
    table_counter += 1

    # 13. notifications
    add_db_spec_table(doc, table_counter, "notifications", "Thông báo nghiệp vụ người dùng", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh thông báo"),
        ("user_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới user_profiles (người nhận)"),
        ("title", "VARCHAR(191)", "", "NOT NULL", "Tiêu đề thông báo ngắn gọn"),
        ("content", "TEXT", "", "NOT NULL", "Nội dung chi tiết của thông báo"),
        ("is_read", "BOOLEAN", "", "NOT NULL DEFAULT FALSE", "Trạng thái đã đọc (True) hoặc chưa đọc (False)"),
        ("reference_type", "VARCHAR(50)", "", "NULL", "Loại đối tượng liên kết ('BOOKING', 'WALLET', 'COMPLAINT')"),
        ("reference_id", "BIGINT", "", "NULL", "Mã ID của đối tượng liên quan để điều hướng màn hình"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm phát sinh thông báo")
    ])
    table_counter += 1

    # 14. complaints
    add_db_spec_table(doc, table_counter, "complaints", "Khiếu nại tranh chấp dịch vụ", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh hồ sơ khiếu nại"),
        ("booking_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng bookings"),
        ("complainant_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại user_profiles (người gửi khiếu nại)"),
        ("respondent_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại user_profiles (người bị khiếu nại)"),
        ("reason", "VARCHAR(191)", "", "NOT NULL", "Lý do khiếu nại chính (Sai lệch dịch vụ, Thú cưng xây xước,...)"),
        ("details", "TEXT", "", "NOT NULL", "Mô tả chi tiết sự việc và yêu cầu bồi hoàn"),
        ("status", "ENUM", "", "NOT NULL DEFAULT 'OPEN'", "Trạng thái xử lý: 'OPEN', 'PROCESSING', 'RESOLVED', 'REJECTED'"),
        ("admin_resolution", "TEXT", "", "NULL", "Phán quyết chính thức và phương án giải quyết của Quản trị viên"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm nộp khiếu nại")
    ])
    table_counter += 1

    # 15. wallets
    add_db_spec_table(doc, table_counter, "wallets", "Ví tiền điện tử nội bộ", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh ví tài khoản"),
        ("user_id", "BIGINT", "FK", "NOT NULL UNIQUE", "Khóa ngoại liên kết tới bảng user_profiles"),
        ("available_balance", "DECIMAL(14,2)", "", "NOT NULL DEFAULT 0.00", "Số dư khả dụng có thể sử dụng đặt lịch hoặc rút tiền"),
        ("escrow_balance", "DECIMAL(14,2)", "", "NOT NULL DEFAULT 0.00", "Số dư tạm giữ ký quỹ đang bị khóa theo booking"),
        ("currency", "VARCHAR(10)", "", "NOT NULL DEFAULT 'VND'", "Đơn vị tiền tệ lưu trữ (VNĐ)"),
        ("updated_at", "DATETIME", "", "NOT NULL ON UPDATE CURRENT_TIMESTAMP", "Thời điểm cập nhật số dư ví gần nhất")
    ])
    table_counter += 1

    # 16. wallet_transactions
    add_db_spec_table(doc, table_counter, "wallet_transactions", "Sổ cái kép ghi nhận biến động số dư ví", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh bút toán sổ cái"),
        ("wallet_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới bảng wallets"),
        ("txn_type", "ENUM", "", "NOT NULL", "Loại biến động: 'DEPOSIT', 'ESCROW_LOCK', 'ESCROW_RELEASE', 'PLATFORM_FEE', 'WITHDRAWAL'"),
        ("amount", "DECIMAL(14,2)", "", "NOT NULL", "Giá trị số tiền giao dịch (dương nếu cộng, âm nếu trừ)"),
        ("balance_before", "DECIMAL(14,2)", "", "NOT NULL", "Số dư ví tại thời điểm ngay trước giao dịch"),
        ("balance_after", "DECIMAL(14,2)", "", "NOT NULL", "Số dư ví tại thời điểm ngay sau khi cập nhật giao dịch"),
        ("reference_id", "VARCHAR(64)", "", "NULL", "Mã tham chiếu đối soát (mã booking, mã nạp hoặc mã rút)"),
        ("notes", "VARCHAR(255)", "", "NULL", "Diễn giải chi tiết nội dung bút toán kế toán"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm ghi nhận bút toán bất biến")
    ])
    table_counter += 1

    # 17. payment_deposits
    add_db_spec_table(doc, table_counter, "payment_deposits", "Giao dịch nạp tiền qua cổng VietQR", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh đơn nạp tiền"),
        ("user_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới user_profiles (người nạp)"),
        ("amount", "DECIMAL(14,2)", "", "NOT NULL", "Số tiền yêu cầu nạp vào ví"),
        ("payment_code", "VARCHAR(32)", "", "NOT NULL UNIQUE", "Mã nội dung chuyển khoản VietQR sinh tự động (PAW<id>)"),
        ("status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái nạp tiền: 'PENDING', 'SUCCESS', 'EXPIRED'"),
        ("bank_tran_id", "VARCHAR(120)", "", "NULL UNIQUE", "Mã giao dịch ngân hàng đối soát do SePay webhook truyền sang"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm tạo yêu cầu nạp tiền"),
        ("completed_at", "DATETIME", "", "NULL", "Thời điểm nhận webhook và cộng tiền thành công vào ví")
    ])
    table_counter += 1

    # 18. withdrawal_requests
    add_db_spec_table(doc, table_counter, "withdrawal_requests", "Yêu cầu rút tiền của đối tác", [
        ("id", "BIGINT AUTO_INCREMENT", "PK", "NOT NULL", "Mã định danh yêu cầu rút tiền"),
        ("provider_id", "BIGINT", "FK", "NOT NULL", "Khóa ngoại liên kết tới providers (đối tác yêu cầu)"),
        ("amount", "DECIMAL(14,2)", "", "NOT NULL", "Số tiền yêu cầu rút khỏi ví khả dụng"),
        ("bank_name", "VARCHAR(100)", "", "NOT NULL", "Tên ngân hàng thụ hưởng của đối tác"),
        ("account_number", "VARCHAR(50)", "", "NOT NULL", "Số tài khoản ngân hàng thụ hưởng"),
        ("account_holder", "VARCHAR(120)", "", "NOT NULL", "Tên chủ tài khoản ngân hàng"),
        ("status", "ENUM", "", "NOT NULL DEFAULT 'PENDING'", "Trạng thái duyệt rút tiền: 'PENDING', 'APPROVED', 'REJECTED'"),
        ("admin_note", "VARCHAR(255)", "", "NULL", "Ghi chú của Quản trị viên khi duyệt hoặc từ chối"),
        ("created_at", "DATETIME", "", "NOT NULL DEFAULT CURRENT_TIMESTAMP", "Thời điểm gửi yêu cầu rút tiền"),
        ("processed_at", "DATETIME", "", "NULL", "Thời điểm Quản trị viên xử lý yêu cầu")
    ])
