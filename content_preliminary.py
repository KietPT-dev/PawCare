# -*- coding: utf-8 -*-
from docx_helpers import (
    add_heading_1, add_heading_2, add_body_p, 
    add_table_caption, format_custom_table, FONT_NAME, COLOR_PRIMARY, COLOR_MUTED
)
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def add_dotted_line_p(doc, count=16):
    for _ in range(count):
        p = doc.add_paragraph()
        p.paragraph_format.line_spacing = 1.3
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run("................................................................................................................................................................")
        r.font.name = FONT_NAME
        r.font.size = Pt(11)
        r.font.color.rgb = COLOR_MUTED

def add_toc_line(doc, title, page_str, level=1):
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(1)
    
    # Indentation by level
    if level == 1:
        p.paragraph_format.left_indent = Inches(0.0)
    elif level == 2:
        p.paragraph_format.left_indent = Inches(0.25)
    elif level == 3:
        p.paragraph_format.left_indent = Inches(0.5)
        
    pPr = p._p.get_or_add_pPr()
    tabs = parse_xml(f'''
        <w:tabs {nsdecls("w")}>
            <w:tab w:val="right" w:leader="dot" w:pos="8800"/>
        </w:tabs>
    ''')
    pPr.append(tabs)
    
    r_title = p.add_run(title)
    r_title.font.name = FONT_NAME
    r_title.font.size = Pt(12 if level == 1 else 11)
    r_title.font.bold = (level == 1)
    r_title.font.color.rgb = COLOR_PRIMARY
    
    r_tab = p.add_run("\t")
    
    r_page = p.add_run(str(page_str))
    r_page.font.name = FONT_NAME
    r_page.font.size = Pt(12 if level == 1 else 11)
    r_page.font.bold = (level == 1)
    r_page.font.color.rgb = COLOR_PRIMARY
    return p

def build_supervisor_review_page(doc):
    add_heading_1(doc, "NHẬN XÉT CỦA GIẢNG VIÊN HƯỚNG DẪN")
    add_dotted_line_p(doc, count=14)
    
    p_date = doc.add_paragraph()
    p_date.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_date.paragraph_format.space_before = Pt(18)
    p_date.paragraph_format.space_after = Pt(4)
    r_date = p_date.add_run("Bà Rịa - Vũng Tàu, ngày …. tháng … năm 20…")
    r_date.font.name = FONT_NAME
    r_date.font.size = Pt(12)
    r_date.font.italic = True
    
    p_sign = doc.add_paragraph()
    p_sign.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_sign.paragraph_format.space_before = Pt(4)
    p_sign.paragraph_format.space_after = Pt(40)
    r_sign = p_sign.add_run("Giảng viên hướng dẫn\n(Ký và ghi rõ họ tên)\n\n\n\n\n........................................................")
    r_sign.font.name = FONT_NAME
    r_sign.font.size = Pt(12)
    r_sign.font.bold = True
    
    doc.add_page_break()

def build_acknowledgements_page(doc):
    add_heading_1(doc, "LỜI CẢM ƠN")
    
    add_body_p(doc,
        "Để hoàn thành đồ án tốt nghiệp này, trước hết em xin gửi lời cảm ơn chân thành và sâu sắc nhất tới toàn thể quý Thầy, Cô "
        "Khoa Công nghệ – Kỹ thuật, Trường Đại học Bà Rịa – Vũng Tàu, những người đã luôn tận tâm truyền đạt tri thức, "
        "truyền cảm hứng và dìu dắt chúng em trong suốt những năm tháng học tập và rèn luyện dưới mái trường đại học mến yêu."
    )
    add_body_p(doc,
        "Đặc biệt, em xin bày tỏ lòng biết ơn sâu sắc và chân thành nhất tới Giảng viên hướng dẫn, người đã luôn dành nhiều thời gian "
        "quý báu, tận tình chỉ dẫn, định hướng khoa học và động viên em vượt qua những khó khăn, thử thách trong suốt quá trình "
        "nghiên cứu và triển khai đề tài \"Xây dựng nền tảng Web và ứng dụng di động đặt dịch vụ chăm sóc thú cưng PawCare kết hợp quản lý quy trình nghiệp vụ\"."
    )
    add_body_p(doc,
        "Em cũng xin gửi lời cảm ơn chân thành tới gia đình, người thân và bạn bè đã luôn là điểm tựa tinh thần vững chắc, "
        "luôn động viên, hỗ trợ và đồng hành cùng em trong suốt quá trình học tập và hoàn thiện đồ án."
    )
    add_body_p(doc,
        "Mặc dù đã nỗ lực hết mình với tinh thần học hỏi cao nhất, song do giới hạn về thời gian và kinh nghiệm thực tế, "
        "báo cáo chắc chắn khó tránh khỏi những thiếu sót nhất định. Kính mong nhận được những ý kiến đóng góp quý báu từ quý Thầy, Cô "
        "trong Hội đồng chấm thi để đề tài được hoàn thiện hơn nữa và có thể ứng dụng hiệu quả vào thực tiễn."
    )
    add_body_p(doc, "Em xin chân thành cảm ơn!")
    
    p_date = doc.add_paragraph()
    p_date.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_date.paragraph_format.space_before = Pt(18)
    p_date.paragraph_format.space_after = Pt(4)
    r_date = p_date.add_run("Bà Rịa - Vũng Tàu, ngày …. tháng … năm 20…")
    r_date.font.name = FONT_NAME
    r_date.font.size = Pt(12)
    r_date.font.italic = True
    
    p_sign = doc.add_paragraph()
    p_sign.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p_sign.paragraph_format.space_before = Pt(4)
    p_sign.paragraph_format.space_after = Pt(20)
    r_sign = p_sign.add_run("Sinh viên thực hiện\n(Ký và ghi rõ họ tên)\n\n\n\n\n........................................................")
    r_sign.font.name = FONT_NAME
    r_sign.font.size = Pt(12)
    r_sign.font.bold = True
    
    doc.add_page_break()

def build_abbreviations_page(doc):
    add_heading_1(doc, "DANH MỤC TỪ VIẾT TẮT")
    
    table = doc.add_table(rows=15, cols=4)
    headers = ["STT", "Ký hiệu viết tắt", "Tên đầy đủ (Tiếng Anh / Tiếng Việt)", "Ý nghĩa giải thích"]
    for i, h in enumerate(headers): table.rows[0].cells[i].paragraphs[0].text = h
    
    abbr_data = [
        ("1", "API", "Application Programming Interface", "Giao diện lập trình ứng dụng, định nghĩa các giao thức trao đổi dữ liệu."),
        ("2", "BPM", "Business Process Management", "Quản lý quy trình nghiệp vụ trong tổ chức doanh nghiệp."),
        ("3", "BPMN", "Business Process Model and Notation", "Chuẩn ký hiệu đồ họa quốc tế về mô hình hóa quy trình nghiệp vụ."),
        ("4", "CSDL", "Cơ sở dữ liệu (Database)", "Tập hợp các dữ liệu có cấu trúc liên quan được lưu trữ trên máy tính."),
        ("5", "ERD", "Entity-Relationship Diagram", "Sơ đồ biểu diễn mối quan hệ giữa các thực thể trong cơ sở dữ liệu."),
        ("6", "FDD", "Functional Decomposition Diagram", "Sơ đồ phân rã chức năng hệ thống theo các cấp độ phân cấp."),
        ("7", "JWT", "JSON Web Token", "Tiêu chuẩn mở (RFC 7519) truyền tải thông tin an toàn dưới dạng đối tượng JSON."),
        ("8", "REST", "Representational State Transfer", "Kiểu kiến trúc phần mềm tiêu chuẩn cho các hệ thống siêu phương tiện phân tán."),
        ("9", "RBAC", "Role-Based Access Control", "Mô hình kiểm soát truy cập và phân quyền dữ liệu dựa trên vai trò người dùng."),
        ("10", "SDK", "Software Development Kit", "Bộ công cụ phát triển phần mềm cung cấp các thư viện và trình biên dịch."),
        ("11", "UI / UX", "User Interface / User Experience", "Giao diện người dùng và Trải nghiệm người dùng phần mềm."),
        ("12", "UML", "Unified Modeling Language", "Ngôn ngữ mô hình hóa thống nhất trong công nghệ phần mềm hướng đối tượng."),
        ("13", "TC", "Test Case", "Kịch bản kiểm thử phần mềm với dữ liệu đầu vào và kết quả mong đợi."),
        ("14", "VietQR", "Vietnam Quick Response", "Tiêu chuẩn quốc gia về mã phản hồi nhanh trong thanh toán do NAPAS ban hành.")
    ]
    for r_i, row in enumerate(abbr_data):
        for c_i, val in enumerate(row): table.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(table, [0.6, 1.3, 2.3, 2.0], [WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])
    
    doc.add_page_break()

def build_list_of_figures(doc):
    add_heading_1(doc, "DANH MỤC ẢNH")
    
    figures = [
        ("Hình 3.1. Mô hình phân rã chức năng Cấp 3 – Phân hệ Khách hàng (Ứng dụng di động)", "17"),
        ("Hình 3.2. Mô hình phân rã chức năng Cấp 3 – Phân hệ Đối tác (Website đối tác)", "18"),
        ("Hình 3.3. Mô hình phân rã chức năng Cấp 3 – Phân hệ Quản trị viên (Website quản trị)", "19"),
        ("Hình 3.4. Mô hình phân rã chức năng Cấp 3 – Phân hệ Chức năng hệ thống tự động", "20"),
        ("Hình 3.5. Sơ đồ Use Case Tổng quát hệ thống PawCare", "22"),
        ("Hình 3.6. Sơ đồ Use Case Phân hệ Khách hàng (Customer)", "23"),
        ("Hình 3.7. Sơ đồ Use Case Phân hệ Đối tác (Provider)", "24"),
        ("Hình 3.8. Sơ đồ Use Case Phân hệ Quản trị viên (Administrator)", "25"),
        ("Hình 3.9. Sơ đồ tuần tự Đăng ký tài khoản (Khách hàng)", "40"),
        ("Hình 3.10. Sơ đồ tuần tự Quản lý thú cưng (Khách hàng)", "41"),
        ("Hình 3.11. Sơ đồ tuần tự Tìm kiếm dịch vụ (Khách hàng)", "42"),
        ("Hình 3.12. Sơ đồ tuần tự Xem thông tin dịch vụ (Khách hàng)", "43"),
        ("Hình 3.13. Sơ đồ tuần tự Tạo booking (Khách hàng)", "44"),
        ("Hình 3.14. Sơ đồ tuần tự Đánh giá dịch vụ (Khách hàng)", "45"),
        ("Hình 3.15. Sơ đồ tuần tự Quản lý phân quyền tài khoản người dùng (Đối tác)", "46"),
        ("Hình 3.16. Sơ đồ tuần tự Thiết lập lịch làm việc khả dụng (Đối tác)", "47"),
        ("Hình 3.17. Sơ đồ tuần tự Quản lý Booking (Đối tác)", "48"),
        ("Hình 3.18. Sơ đồ tuần tự Xem doanh thu và báo cáo (Đối tác)", "49"),
        ("Hình 3.19. Sơ đồ tuần tự Quản lý hồ sơ đối tác (Đối tác)", "50"),
        ("Hình 3.20. Sơ đồ tuần tự Phản hồi đánh giá (Đối tác)", "51"),
        ("Hình 3.21. Sơ đồ tuần tự Quản lý tài khoản người dùng (Quản trị viên)", "52"),
        ("Hình 3.22. Sơ đồ tuần tự Giám sát Booking (Quản trị viên)", "53"),
        ("Hình 3.23. Sơ đồ tuần tự Xem doanh thu và báo cáo (Quản trị viên)", "54"),
        ("Hình 3.24. Sơ đồ tuần tự Duyệt hồ sơ đối tác (Quản trị viên)", "55"),
        ("Hình 3.25. Sơ đồ tuần tự Quản lý danh mục (Quản trị viên)", "56"),
        ("Hình 3.26. Sơ đồ tuần tự Xử lý khiếu nại và kiểm duyệt đánh giá (Quản trị viên)", "57"),
        ("Hình 3.27. Sơ đồ quy trình BPMN 01: Đăng ký và xét duyệt hồ sơ đối tác", "58"),
        ("Hình 3.28. Sơ đồ quy trình BPMN 02: Vòng đời booking và thực hiện dịch vụ hai chiều", "59"),
        ("Hình 3.29. Sơ đồ thực thể kết hợp (ERD) cơ sở dữ liệu hệ thống PawCare", "61"),
        ("Hình 4.1. Bản đồ luồng điều hướng màn hình hệ thống PawCare (UI Sitemap)", "72")
    ]
    for title, page in figures:
        add_toc_line(doc, title, page, level=2)
        
    doc.add_page_break()

def build_list_of_tables(doc):
    add_heading_1(doc, "DANH MỤC BẢNG")
    
    tables_list = [
        ("Bảng 3.1. So sánh tổng hợp các hệ thống dịch vụ thú cưng hiện có và PawCare", "16"),
        ("Bảng 3.2. Mô tả các nhóm chức năng Phân hệ Khách hàng (Ứng dụng di động)", "17"),
        ("Bảng 3.3. Mô tả các nhóm chức năng Phân hệ Đối tác (Website đối tác)", "18"),
        ("Bảng 3.4. Mô tả các nhóm chức năng Phân hệ Quản trị viên (Website quản trị)", "19"),
        ("Bảng 3.5. Mô tả Phân hệ Chức năng hệ thống tự động (Automated Subsystem)", "20"),
        ("Bảng 3.6. UC-C01 – Đặc tả Use Case Quản lý tài khoản", "26"),
        ("Bảng 3.7. UC-C02 – Đặc tả Use Case Quản lý thú cưng", "26"),
        ("Bảng 3.8. UC-C03 – Đặc tả Use Case Tìm kiếm lọc và nhận đề xuất", "27"),
        ("Bảng 3.9. UC-C04 – Đặc tả Use Case Xem thông tin đối tác và dịch vụ", "27"),
        ("Bảng 3.10. UC-C05 – Đặc tả Use Case Tạo booking", "28"),
        ("Bảng 3.11. UC-C06 – Đặc tả Use Case Theo dõi hủy và đổi lịch booking", "28"),
        ("Bảng 3.12. UC-C07 – Đặc tả Use Case Thanh toán mô phỏng", "29"),
        ("Bảng 3.13. UC-C08 – Đặc tả Use Case Đánh giá và gửi khiếu nại", "29"),
        ("Bảng 3.14. UC-C09 – Đặc tả Use Case Xem thông báo và ghi chú", "30"),
        ("Bảng 3.15. UC-P01 – Đặc tả Use Case Quản lý hồ sơ đối tác", "30"),
        ("Bảng 3.16. UC-P02 – Đặc tả Use Case Quản lý dịch vụ", "31"),
        ("Bảng 3.17. UC-P03 – Đặc tả Use Case Quản lý nhân viên", "31"),
        ("Bảng 3.18. UC-P04 – Đặc tả Use Case Thiết lập lịch và khả dụng", "32"),
        ("Bảng 3.19. UC-P05 – Đặc tả Use Case Tiếp nhận và xử lý booking", "32"),
        ("Bảng 3.20. UC-P06 – Đặc tả Use Case Thực hiện dịch vụ", "33"),
        ("Bảng 3.21. UC-P07 – Đặc tả Use Case Xem thông tin khách hàng và thú cưng", "33"),
        ("Bảng 3.22. UC-P08 – Đặc tả Use Case Xem đánh giá và phản hồi khiếu nại", "34"),
        ("Bảng 3.23. UC-P09 – Đặc tả Use Case Xem doanh thu và báo cáo", "34"),
        ("Bảng 3.24. UC-A01 – Đặc tả Use Case Xem dashboard", "35"),
        ("Bảng 3.25. UC-A02 – Đặc tả Use Case Quản lý tài khoản", "35"),
        ("Bảng 3.26. UC-A03 – Đặc tả Use Case Xét duyệt hồ sơ đối tác", "36"),
        ("Bảng 3.27. UC-A04 – Đặc tả Use Case Quản lý trạng thái đối tác", "36"),
        ("Bảng 3.28. UC-A05 – Đặc tả Use Case Quản lý danh mục dịch vụ", "37"),
        ("Bảng 3.29. UC-A06 – Đặc tả Use Case Giám sát booking", "37"),
        ("Bảng 3.30. UC-A07 – Đặc tả Use Case Giám sát giao dịch mô phỏng", "38"),
        ("Bảng 3.31. UC-A08 – Đặc tả Use Case Xử lý khiếu nại và kiểm duyệt đánh giá", "38"),
        ("Bảng 3.32. UC-A09 – Đặc tả Use Case Xem báo cáo và thống kê", "39"),
        ("Bảng 3.33. UC-S01 – Đặc tả Use Case Gợi ý đối tác theo quy tắc", "39"),
        ("Bảng 3.34. UC-S02 – Đặc tả Use Case Kiểm tra điều kiện booking", "40"),
        ("Bảng 3.35. UC-S03 – Đặc tả Use Case Quản lý vòng đời booking", "40"),
        ("Bảng 3.36. UC-S04 – Đặc tả Use Case Tạo thông báo tự động", "41"),
        ("Bảng 3.37. UC-S05 – Đặc tả Use Case Xử lý giao dịch mô phỏng", "41"),
        ("Bảng 3.38. UC-S06 – Đặc tả Use Case Phân quyền và kiểm soát dữ liệu", "42"),
        ("Bảng 3.39. Ma trận truy vết Use Case hệ thống PawCare", "43"),
        ("Bảng 3.40. Đặc tả cấu trúc bảng user_profiles", "62"),
        ("Bảng 3.41. Đặc tả cấu trúc bảng providers", "63"),
        ("Bảng 3.42. Đặc tả cấu trúc bảng provider_documents", "63"),
        ("Bảng 3.43. Đặc tả cấu trúc bảng pets", "64"),
        ("Bảng 3.44. Đặc tả cấu trúc bảng service_categories", "64"),
        ("Bảng 3.45. Đặc tả cấu trúc bảng services", "65"),
        ("Bảng 3.46. Đặc tả cấu trúc bảng staff", "65"),
        ("Bảng 3.47. Đặc tả cấu trúc bảng staff_schedules", "66"),
        ("Bảng 3.48. Đặc tả cấu trúc bảng bookings", "66"),
        ("Bảng 3.49. Đặc tả cấu trúc bảng booking_status_history", "67"),
        ("Bảng 3.50. Đặc tả cấu trúc bảng payments", "67"),
        ("Bảng 3.51. Đặc tả cấu trúc bảng reviews", "68"),
        ("Bảng 3.52. Đặc tả cấu trúc bảng notifications", "68"),
        ("Bảng 3.53. Đặc tả cấu trúc bảng complaints", "69"),
        ("Bảng 3.54. Đặc tả cấu trúc bảng wallets", "69"),
        ("Bảng 3.55. Đặc tả cấu trúc bảng wallet_transactions", "70"),
        ("Bảng 3.56. Đặc tả cấu trúc bảng payment_deposits", "70"),
        ("Bảng 3.57. Đặc tả cấu trúc bảng withdrawal_requests", "71"),
        ("Bảng 5.1. Danh mục 20 ca kiểm thử tích hợp đầu cuối của hệ thống PawCare", "77"),
        ("Bảng 5.22. Tổng hợp kết quả kiểm thử theo phân hệ chức năng", "85")
    ]
    for title, page in tables_list:
        add_toc_line(doc, title, page, level=2)
        
    doc.add_page_break()

def build_table_of_contents(doc):
    add_heading_1(doc, "MỤC LỤC")
    
    toc_items = [
        ("NHẬN XÉT CỦA GIẢNG VIÊN HƯỚNG DẪN", "2", 1),
        ("LỜI CẢM ƠN", "3", 1),
        ("MỤC LỤC", "4", 1),
        ("DANH MỤC TỪ VIẾT TẮT", "5", 1),
        ("DANH MỤC ẢNH", "6", 1),
        ("DANH MỤC BẢNG", "7", 1),
        ("CHƯƠNG 1. TỔNG QUAN VỀ ĐỀ TÀI", "8", 1),
        ("1.1. Lý do chọn đề tài", "8", 2),
        ("1.2. Mục tiêu đề tài", "9", 2),
        ("1.3. Đối tượng và phạm vi nghiên cứu", "10", 2),
        ("1.3.1. Đối tượng nghiên cứu", "10", 3),
        ("1.3.2. Phạm vi nghiên cứu", "10", 3),
        ("1.4. Phương pháp nghiên cứu", "11", 2),
        ("1.5. Ý nghĩa của đề tài", "11", 2),
        ("CHƯƠNG 2. CƠ SỞ LÝ THUYẾT", "12", 1),
        ("2.1. Framework Spring Boot và Kiến trúc Backend RESTful API", "12", 2),
        ("2.1.1. Khái niệm và quá trình phát triển của Spring Boot", "12", 3),
        ("2.1.2. Các đặc điểm kỹ thuật nổi bật của Spring Boot", "12", 3),
        ("2.1.3. Kiến trúc RESTful API và chuẩn OpenAPI Specification", "13", 3),
        ("2.1.4. Ứng dụng trong hệ thống PawCare", "13", 3),
        ("2.2. Nền tảng Quản lý Quy trình Nghiệp vụ Bonita BPM và Chuẩn BPMN 2.0", "13", 2),
        ("2.2.1. Khái niệm BPM và Chuẩn ký hiệu BPMN 2.0", "13", 3),
        ("2.2.2. Nền tảng Bonita BPM Community 2025.2", "14", 3),
        ("2.2.3. Cơ chế REST API Extension và Scripting Groovy", "14", 3),
        ("2.2.4. Ứng dụng trong hệ thống PawCare", "14", 3),
        ("2.3. Công nghệ Phát triển Ứng dụng Di động Đa nền tảng Flutter", "15", 2),
        ("2.3.1. Khái niệm và kiến trúc của Flutter", "15", 3),
        ("2.3.2. Triết lý \"Everything is a Widget\" và Cây Widget (Widget Tree)", "15", 3),
        ("2.3.3. Ứng dụng trong hệ thống PawCare", "15", 3),
        ("2.4. Công nghệ Xây dựng Giao diện Web: React và Vite", "15", 2),
        ("2.4.1. Khái niệm và kiến trúc của thư viện React", "15", 3),
        ("2.4.2. Công cụ xây dựng thế hệ mới Vite", "16", 3),
        ("2.4.3. Ứng dụng trong hệ thống PawCare", "16", 3),
        ("2.5. Hệ Quản trị Cơ sở Dữ liệu MySQL và Mô hình Giao dịch Tài chính", "16", 2),
        ("2.5.1. Khái niệm và đặc tính của MySQL 8.0", "16", 3),
        ("2.5.2. Mô hình Sổ cái kép (Double-entry Ledger) và Cơ chế Ký quỹ (Escrow)", "16", 3),
        ("2.5.3. Mẫu thiết kế Transactional Outbox Pattern", "17", 3),
        ("2.6. Các Công nghệ và Kỹ thuật Hỗ trợ", "17", 2),
        ("2.6.1. Xác thực và Phân quyền dựa trên JWT và RBAC", "17", 3),
        ("2.6.2. Tiêu chuẩn Thanh toán số VietQR và Xử lý Webhook SePay", "17", 3),
        ("CHƯƠNG 3. PHÂN TÍCH THIẾT KẾ HỆ THỐNG", "18", 1),
        ("3.1. Khảo sát hệ thống", "18", 2),
        ("3.1.1. Khảo sát quy trình nghiệp vụ hiện tại", "18", 3),
        ("3.1.2. Khảo sát các hệ thống hiện có", "18", 3),
        ("3.1.3. Mô tả bài toán và mục tiêu chức năng", "19", 3),
        ("3.2. Xác định tác nhân hệ thống", "21", 2),
        ("3.3. Phân tích thiết kế hệ thống với biểu đồ UML", "22", 2),
        ("3.3.1. Sơ đồ Use Case", "22", 3),
        ("3.3.2. Đặc tả Use Case cho các chức năng", "26", 3),
        ("3.3.3. Sơ đồ tuần tự (Sequence Diagram)", "44", 3),
        ("3.3.4. Mô hình hóa quy trình nghiệp vụ với chuẩn BPMN 2.0", "58", 3),
        ("3.4. Thiết kế cơ sở dữ liệu", "60", 2),
        ("3.4.1. Sơ đồ thực thể kết hợp (ERD)", "60", 3),
        ("3.4.2. Đặc tả các bảng cơ sở dữ liệu", "62", 3),
        ("CHƯƠNG 4. THIẾT KẾ GIAO DIỆN", "72", 1),
        ("4.1. Kiến trúc bản đồ màn hình hệ thống (UI Sitemap)", "72", 2),
        ("4.2. Giao diện ứng dụng di động dành cho Khách hàng (Flutter)", "73", 2),
        ("4.3. Giao diện Cổng thông tin dành cho Đối tác (React Web Portal)", "74", 2),
        ("4.4. Giao diện Cổng thông tin Quản trị viên (Bonita BPM Portal)", "75", 2),
        ("CHƯƠNG 5. KIỂM THỬ VÀ ĐÁNH GIÁ", "76", 1),
        ("5.1. Mục tiêu và phạm vi kiểm thử", "76", 2),
        ("5.2. Môi trường và công cụ kiểm thử", "76", 2),
        ("5.3. Chiến lược và các cấp độ kiểm thử", "76", 2),
        ("5.4. Kịch bản kiểm thử (Test Cases) và Kết quả thực tế", "77", 2),
        ("5.5. Đánh giá kết quả kiểm thử", "84", 2),
        ("CHƯƠNG 6. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN", "86", 1),
        ("6.1. Kết luận", "86", 2),
        ("6.2. Hạn chế của đề tài", "87", 2),
        ("6.3. Hướng phát triển trong tương lai", "87", 2),
        ("TÀI LIỆU THAM KHẢO", "88", 1)
    ]
    for title, page, lvl in toc_items:
        add_toc_line(doc, title, page, level=lvl)
        
    doc.add_page_break()
