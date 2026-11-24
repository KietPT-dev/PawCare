# -*- coding: utf-8 -*-
from docx_helpers import (
    add_heading_1, add_heading_2, add_heading_3, add_body_p, 
    add_bullet_p, add_image_figure, add_table_caption, format_custom_table
)
from docx.enum.text import WD_ALIGN_PARAGRAPH

def build_chapter_3_part1(doc):
    add_heading_1(doc, "CHƯƠNG 3. PHÂN TÍCH THIẾT KẾ HỆ THỐNG")
    
    add_body_p(doc,
        "Phân tích và thiết kế hệ thống là giai đoạn mang tính bản lề trong toàn bộ chu trình phát triển phần mềm. "
        "Mục tiêu của chương này là chuyển hóa toàn bộ các nhu cầu thực tế của thị trường và các bên liên quan (stakeholders) "
        "thành một bản thiết kế kỹ thuật chính xác, nhất quán và có tính khả thi cao. Chương 3 được triển khai dựa trên các tài liệu "
        "nghiên cứu thực tế của dự án PawCare, bao gồm: khảo sát quy trình và đối thủ cạnh tranh, mô hình phân rã chức năng (FDD), "
        "xác định tác nhân, hệ thống biểu đồ Use Case và biểu đồ tuần tự UML chuẩn hóa từ StarUML, quy trình nghiệp vụ BPMN 2.0, "
        "và thiết kế cơ sở dữ liệu quan hệ chi tiết."
    )

    # 3.1 Khảo sát hệ thống
    add_heading_2(doc, "3.1. Khảo sát hệ thống")
    add_heading_3(doc, "3.1.1. Khảo sát quy trình nghiệp vụ hiện tại")
    add_body_p(doc,
        "Hiện nay, dịch vụ chăm sóc thú cưng tại các đô thị ở Việt Nam hoạt động chủ yếu theo mô hình cửa hàng vật lý độc lập (pet shop / pet spa) "
        "hoặc các cá nhân làm nghề tự do (freelancer grooming/sitting). Khảo sát quy trình nghiệp vụ thực tế ghi nhận các bước cơ bản sau:"
    )
    add_bullet_p(doc,
        "Khách hàng có nhu cầu thường tìm kiếm thông tin cơ sở qua mạng xã hội (Facebook Groups, Zalo, TikTok) hoặc người quen giới thiệu. "
        "Sau đó, khách hàng liên hệ trực tiếp qua tin nhắn hoặc gọi điện thoại để hỏi giá và đặt giờ hẹn.",
        bold_prefix="Bước 1 - Tiếp cận và tư vấn: "
    )
    add_bullet_p(doc,
        "Nhân viên cửa hàng kiểm tra sổ tay hoặc file Excel ghi lịch trực của cơ sở để xác nhận xem khung giờ khách yêu cầu có nhân viên rảnh hay không. "
        "Nếu trùng lịch, nhân viên phải thương lượng giờ hẹn khác. Quá trình trao đổi qua lại này thường kéo dài, dễ bị ngắt quãng hoặc sót thông tin.",
        bold_prefix="Bước 2 - Xác nhận lịch hẹn: "
    )
    add_bullet_p(doc,
        "Chủ nuôi đưa thú cưng đến cửa hàng theo lịch hẹn. Nhân viên tiếp nhận thú cưng bằng quan sát cảm tính, ghi chép nhanh yêu cầu vào một mẩu giấy "
        "hoặc phiếu tiếp nhận giấy. Nếu phát hiện thú cưng có bệnh lý ngoài da hoặc quá hung dữ, việc từ chối phục vụ tại chỗ thường dẫn đến tranh cãi.",
        bold_prefix="Bước 3 - Tiếp nhận thú cưng (Check-in): "
    )
    add_bullet_p(doc,
        "Kỹ thuật viên thực hiện các công đoạn chăm sóc (tắm, sấy, vệ sinh móng, cắt tỉa lông). Khách hàng phải ngồi chờ trực tiếp tại tiệm "
        "hoặc ra ngoài và không hề biết được tiến độ dịch vụ hiện tại đã xong đến công đoạn nào, gây tâm lý lo lắng và sốt ruột.",
        bold_prefix="Bước 4 - Thực hiện dịch vụ: "
    )
    add_bullet_p(doc,
        "Sau khi hoàn thành, nhân viên gọi điện cho khách hàng đến đón. Khách thanh toán bằng tiền mặt hoặc chuyển khoản ngân hàng cá nhân. "
        "Việc lưu trữ lịch sử chăm sóc và phản hồi chất lượng hầu như không được quản lý tập trung.",
        bold_prefix="Bước 5 - Bàn giao và thanh toán: "
    )
    add_body_p(doc,
        "Từ quy trình trên, có thể rút ra các hạn chế cố hữu: (1) Năng suất phục vụ bị giới hạn do phụ thuộc vào con người trao đổi thủ công; "
        "(2) Nguy cơ xung đột lịch rất cao khi lượng khách tăng đột biến; (3) Thiếu nhật ký trạng thái dịch vụ minh bạch có sự xác nhận của hai bên; "
        "và (4) Rủi ro tài chính khi thanh toán trực tiếp không có cơ chế trung gian bảo đảm quyền lợi."
    )

    add_heading_3(doc, "3.1.2. Khảo sát các hệ thống hiện có")
    add_body_p(doc,
        "Nhằm xác định rõ vị thế cạnh tranh và định hình các tính năng khác biệt cho PawCare, nhóm nghiên cứu đã tiến hành khảo sát, "
        "đối chiếu chuyên sâu các nền tảng công nghệ về thú cưng phổ biến trên thế giới cũng như tại Việt Nam:"
    )
    add_bullet_p(doc,
        "Rover là nền tảng kết nối dịch vụ thú cưng trực tuyến số 1 tại Mỹ và Châu Âu, tập trung mạnh vào dịch vụ trông giữ (dog boarding, pet sitting) "
        "và dắt chó đi dạo (dog walking). Điểm mạnh của Rover là giao diện trực quan, hệ thống đánh giá uy tín có xác minh, tích hợp bảo hiểm thú cưng "
        "(The Rover Guarantee) và thanh toán bảo mật. Tuy nhiên, điểm yếu là mô hình Rover thiết kế thuần túy cho cá nhân (peer-to-peer), chưa tối ưu "
        "cho các cơ sở/spa chuyên nghiệp có nhiều nhân viên kỹ thuật và nhiều ca trực phân ca phức tạp; chi phí hoa hồng của sàn rất cao (từ 15% đến 20%).",
        bold_prefix="Nền tảng Rover (Mỹ): "
    )
    add_bullet_p(doc,
        "Tập trung chuyên biệt vào dịch vụ dắt chó đi dạo tức thì (on-demand dog walking) theo mô hình Uber. Ứng dụng tích hợp GPS theo dõi lộ trình thời gian thực, "
        "báo cáo \"Pee & Poo report\" kèm ảnh sinh động. Tuy nhiên, Wag! bị giới hạn về tính đa dạng của dịch vụ, hầu như không hỗ trợ đặt lịch spa grooming chuyên sâu, "
        "và không có cơ chế quản lý quy trình doanh nghiệp [13].",
        bold_prefix="Nền tảng Wag! (Mỹ): "
    )
    add_bullet_p(doc,
        "Nền tảng marketplace dịch vụ thú cưng phát triển mạnh mẽ tại thị trường Úc và New Zealand. Tương tự Rover, Mad Paws chú trọng vào dịch vụ giữ thú cưng "
        "tại nhà nhưng quy trình điều phối trạng thái dịch vụ còn đơn giản, thiếu công cụ cho các đối tác quản lý ca trực của nhân viên cấp dưới.",
        bold_prefix="Nền tảng Mad Paws / Collar (Úc): "
    )
    add_bullet_p(doc,
        "Hệ sinh thái bán lẻ sản phẩm và phòng khám/spa thú cưng hàng đầu Việt Nam hiện nay. Pet Mart và 2Vet sở hữu chuỗi cửa hàng vật lý rộng khắp, "
        "nhưng hệ thống công nghệ chủ yếu là website thương mại điện tử bán hàng hóa vật lý và phần mềm POS quản lý kho nội bộ. Khách hàng muốn đặt dịch vụ spa "
        "vẫn phải gọi hotline hoặc nhắn tin fanpage, chưa có ứng dụng di động cho phép khách tự chọn kỹ thuật viên, xem slot trống thời gian thực và tự động ký quỹ.",
        bold_prefix="Thực trạng tại Việt Nam (Pet Mart, 2Vet, Pet City): "
    )

    # Comparative Table
    add_table_caption(doc, "Bảng 3.1. So sánh tổng hợp các hệ thống dịch vụ thú cưng hiện có và đề xuất của PawCare")
    tbl_comp = doc.add_table(rows=6, cols=6)
    comp_headers = ["Tiêu chí so sánh", "Rover (Mỹ)", "Wag! (Mỹ)", "Mad Paws (Úc)", "Pet Mart (VN)", "Hệ thống PawCare"]
    for c_i, h in enumerate(comp_headers):
        tbl_comp.rows[0].cells[c_i].paragraphs[0].text = h
        
    comp_data = [
        ("Mô hình hoạt động", "C2C / P2P Marketplace", "On-demand Service", "C2C Marketplace", "Chuỗi bán lẻ B2C", "B2C & C2C Marketplace"),
        ("Đặt lịch thời gian thực", "Có (Trao đổi tin nhắn)", "Có (On-demand tức thì)", "Có (Trao đổi tin nhắn)", "Không (Gọi hotline / Zalo)", "Có (Khóa slot thời gian thực)"),
        ("Quản lý nhân viên & ca trực", "Hạn chế (Chỉ cá nhân)", "Không có", "Hạn chế (Chỉ cá nhân)", "Nội bộ (POS cửa hàng)", "Có (Quản lý đa kỹ thuật viên)"),
        ("Quy trình BPMN & Xác nhận 2 chiều", "Không có", "Không có", "Không có", "Không có", "Có (BPMN 2.0 Bonita Engine)"),
        ("Ký quỹ Escrow & Thanh toán số", "Có (Stripe/Thẻ quốc tế)", "Có (Thẻ tín dụng)", "Có (Thẻ tín dụng)", "Không (Tiền mặt / Chuyển khoản)", "Có (Ví nội bộ & VietQR SePay)")
    ]
    for r_i, row in enumerate(comp_data):
        for c_i, val in enumerate(row):
            tbl_comp.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
            
    format_custom_table(tbl_comp, [1.4, 0.9, 0.9, 0.9, 1.0, 1.2], 
                        [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, 
                         WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT])

    add_body_p(doc,
        "Từ bảng phân tích so sánh trên, giải pháp PawCare định vị một hướng đi đột phá tại thị trường Việt Nam: "
        "kết hợp tính linh hoạt của mô hình Marketplace đa kênh với sự chuẩn hóa nghiêm ngặt của Quản lý Quy trình Nghiệp vụ (BPMN 2.0), "
        "mang lại giải pháp toàn diện cho cả khách hàng, đối tác cơ sở và quản trị viên."
    )

    # 3.1.3 Mô tả bài toán và mục tiêu chức năng
    add_heading_3(doc, "3.1.3. Mô tả bài toán và mục tiêu chức năng")
    add_body_p(doc,
        "Bài toán tổng quát mà hệ thống PawCare giải quyết là thiết lập một môi trường số hóa trung gian tin cậy, tự động hóa chu trình "
        "kết nối, kiểm tra tính khả dụng, điều phối thực thi và đối soát giao dịch dịch vụ chăm sóc thú cưng. "
        "Dựa trên tài liệu mô hình phân rã chức năng chính thức của dự án, hệ thống PawCare được chia thành 4 phân hệ lớn ở Cấp 1, "
        "mỗi phân hệ bao gồm 9 nhóm chức năng Cấp 2 và được phân rã chi tiết thành các chức năng con Cấp 3:"
    )

    # Insert 4 FDD Images
    add_image_figure(doc, "downloads_staging/Phan_ra_chuc_nang_cap_3_khach_hang_PawCare.png", 
                     "Hình 3.1. Mô hình phân rã chức năng Cấp 3 – Phân hệ Khách hàng (Ứng dụng di động)", 6.0)
    add_image_figure(doc, "downloads_staging/Phan_ra_chuc_nang_cap_3_doi_tac_PawCare.png", 
                     "Hình 3.2. Mô hình phân rã chức năng Cấp 3 – Phân hệ Đối tác (Website đối tác)", 6.0)
    add_image_figure(doc, "downloads_staging/Phan_ra_chuc_nang_cap_3_quan_tri_vien_PawCare.png", 
                     "Hình 3.3. Mô hình phân rã chức năng Cấp 3 – Phân hệ Quản trị viên (Website quản trị)", 6.0)
    add_image_figure(doc, "downloads_staging/FDD_day_du_he_thong_tu_dong_PawCare.png", 
                     "Hình 3.4. Mô hình phân rã chức năng Cấp 3 – Phân hệ Chức năng hệ thống tự động", 6.0)

    # Tables for functional groups
    add_table_caption(doc, "Bảng 3.2. Mô tả các nhóm chức năng Phân hệ Khách hàng (Ứng dụng di động)")
    tbl_c = doc.add_table(rows=10, cols=3)
    c_heads = ["STT", "Nhóm chức năng (Cấp 2)", "Chi tiết các chức năng con (Cấp 3)"]
    for i, h in enumerate(c_heads): tbl_c.rows[0].cells[i].paragraphs[0].text = h
    c_data = [
        ("1", "1.1 Quản lý tài khoản", "1.1.1 Đăng ký tài khoản; 1.1.2 Đăng nhập/Đăng xuất; 1.1.3 Cập nhật hồ sơ cá nhân; 1.1.4 Đổi/Khôi phục mật khẩu"),
        ("2", "1.2 Quản lý thú cưng", "1.2.1 Xem danh sách thú cưng; 1.2.2 Thêm mới hồ sơ thú cưng; 1.2.3 Cập nhật tiền sử sức khỏe/tiêm chủng; 1.2.4 Lưu trữ hoặc xóa hồ sơ"),
        ("3", "1.3 Tìm kiếm, lọc, đề xuất", "1.3.1 Tìm kiếm đối tác/dịch vụ; 1.3.2 Lọc theo danh mục, giá, khu vực; 1.3.3 Lọc theo đánh giá và lịch rảnh; 1.3.4 Nhận danh sách đề xuất"),
        ("4", "1.4 Xem thông tin dịch vụ", "1.4.1 Xem chi tiết hồ sơ đối tác; 1.4.2 Xem bảng giá, thời lượng; 1.4.3 Xem khu vực và khung giờ khả dụng; 1.4.4 Đọc đánh giá nhận xét"),
        ("5", "1.5 Tạo booking", "1.5.1 Chọn dịch vụ và thú cưng; 1.5.2 Chọn ngày giờ khả dụng; 1.5.3 Nhập ghi chú chăm sóc đặc biệt; 1.5.4 Gửi yêu cầu đặt lịch"),
        ("6", "1.6 Theo dõi booking", "1.6.1 Xem trạng thái thời gian thực; 1.6.2 Xem lịch sử booking; 1.6.3 Hủy booking theo chính sách; 1.6.4 Đổi lịch booking"),
        ("7", "1.7 Thanh toán mô phỏng", "1.7.1 Chọn phương thức thanh toán VietQR/Ví; 1.7.2 Xem tổng tiền & khấu trừ ví; 1.7.3 Xem lịch sử giao dịch; 1.7.4 Xem trạng thái giao dịch"),
        ("8", "1.8 Đánh giá và khiếu nại", "1.8.1 Chấm điểm số sao (1-5); 1.8.2 Viết nhận xét chi tiết; 1.8.3 Gửi khiếu nại tranh chấp; 1.8.4 Theo dõi tiến trình xử lý khiếu nại"),
        ("9", "1.9 Thông báo và ghi chú", "1.9.1 Nhận thông báo biến động trạng thái; 1.9.2 Nhận thông báo nhắc lịch/đánh giá; 1.9.3 Gửi ghi chú chăm sóc; 1.9.4 Xem danh sách thông báo")
    ]
    for r_i, row in enumerate(c_data):
        for c_i, val in enumerate(row): tbl_c.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(tbl_c, [0.6, 2.0, 3.6], [WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    add_table_caption(doc, "Bảng 3.3. Mô tả các nhóm chức năng Phân hệ Đối tác (Website đối tác)")
    tbl_p = doc.add_table(rows=10, cols=3)
    for i, h in enumerate(c_heads): tbl_p.rows[0].cells[i].paragraphs[0].text = h
    p_data = [
        ("1", "2.1 Hồ sơ đối tác", "2.1.1 Đăng ký hồ sơ đối tác; 2.1.2 Cập nhật thông tin cơ sở/liên hệ; 2.1.3 Tải ảnh đại diện/giờ hoạt động; 2.1.4 Theo dõi trạng thái xét duyệt"),
        ("2", "2.2 Quản lý dịch vụ", "2.2.1 Thêm/Sửa/Ẩn dịch vụ; 2.2.2 Thiết lập đơn giá; 2.2.3 Cấu hình thời lượng thực hiện; 2.2.4 Gán danh mục chuẩn/điều kiện nhận"),
        ("3", "2.3 Quản lý nhân viên", "2.3.1 Thêm/Sửa/Ngừng hoạt động nhân viên; 2.3.2 Khai báo kỹ năng chuyên môn; 2.3.3 Xem danh sách nhân viên; 2.3.4 Phân công dịch vụ phù hợp"),
        ("4", "2.4 Lịch và khả dụng", "2.4.1 Thiết lập ca làm việc; 2.4.2 Cấu hình ngày nghỉ lễ/nghỉ phép; 2.4.3 Kiểm tra trạng thái rảnh/bận; 2.4.4 Khóa/mở khung giờ khả dụng"),
        ("5", "2.5 Tiếp nhận booking", "2.5.1 Xem và lọc danh sách booking PENDING; 2.5.2 Xem thông tin khách & thú cưng; 2.5.3 Chấp nhận booking; 2.5.4 Từ chối kèm lý do bắt buộc"),
        ("6", "2.6 Thực hiện dịch vụ", "2.6.1 Phân công kỹ thuật viên phụ trách; 2.6.2 Cập nhật CHECKED_IN; 2.6.3 Cập nhật IN_SERVICE kèm ghi chú; 2.6.4 Cập nhật SERVICE_DONE kết quả"),
        ("7", "2.7 Quản lý khách hàng/thú cưng", "2.7.1 Tra cứu thông tin liên hệ khách; 2.7.2 Xem hồ sơ bệnh án thú cưng; 2.7.3 Tiếp nhận yêu cầu chăm sóc; 2.7.4 Xem lịch sử phục vụ trước"),
        ("8", "2.8 Đánh giá và khiếu nại", "2.8.1 Xem đánh giá của khách hàng; 2.8.2 Tiếp nhận thông báo khiếu nại; 2.8.3 Gửi phản hồi giải trình; 2.8.4 Xem phán quyết xử lý của Admin"),
        ("9", "2.9 Doanh thu và báo cáo", "2.9.1 Xem doanh thu ví và tiền ký quỹ; 2.9.2 Xem lịch sử giao dịch sổ cái; 2.9.3 Thống kê số lượng booking; 2.9.4 Lập báo cáo hiệu suất")
    ]
    for r_i, row in enumerate(p_data):
        for c_i, val in enumerate(row): tbl_p.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(tbl_p, [0.6, 2.0, 3.6], [WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    add_table_caption(doc, "Bảng 3.4. Mô tả các nhóm chức năng Phân hệ Quản trị viên (Website quản trị)")
    tbl_a = doc.add_table(rows=10, cols=3)
    for i, h in enumerate(c_heads): tbl_a.rows[0].cells[i].paragraphs[0].text = h
    a_data = [
        ("1", "3.1 Dashboard", "3.1.1 Bảng chỉ số tổng quan hệ thống; 3.1.2 Giám sát booking theo trạng thái; 3.1.3 Thống kê đối tác hoạt động; 3.1.4 Giám sát tổng dòng tiền"),
        ("2", "3.2 Quản lý tài khoản", "3.2.1 Tra cứu danh sách người dùng; 3.2.2 Khóa/Mở khóa tài khoản vi phạm; 3.2.3 Cập nhật vai trò/trạng thái; 3.2.4 Xem nhật ký bảo mật"),
        ("3", "3.3 Xét duyệt đối tác", "3.3.1 Thẩm định hồ sơ và tài liệu pháp lý; 3.3.2 Phê duyệt (APPROVED); 3.3.3 Từ chối hồ sơ kèm lý do; 3.3.4 Yêu cầu bổ sung tài liệu"),
        ("4", "3.4 Trạng thái đối tác", "3.4.1 Quản lý danh sách đối tác; 3.4.2 Tạm ngưng hoạt động (SUSPEND); 3.4.3 Kích hoạt lại đối tác; 3.4.4 Theo dõi hồ sơ cần xử lý định kỳ"),
        ("5", "3.5 Danh mục dịch vụ", "3.5.1 Thêm mới danh mục chuẩn; 3.5.2 Chỉnh sửa thông tin danh mục; 3.5.3 Ẩn danh mục theo ràng buộc; 3.5.4 Chuẩn hóa phân loại dịch vụ"),
        ("6", "3.6 Giám sát booking", "3.6.1 Xem và lọc toàn bộ booking; 3.6.2 Xem nhật ký chuyển trạng thái; 3.6.3 Theo dõi đơn hủy/lỗi vận hành; 3.6.4 Can thiệp hỗ trợ vận hành"),
        ("7", "3.7 Giao dịch mô phỏng", "3.7.1 Giám sát lịch sử giao dịch ví; 3.7.2 Lọc trạng thái nạp tiền/ký quỹ; 3.7.3 Đối soát tiền ký quỹ theo booking; 3.7.4 Xử lý duyệt rút tiền"),
        ("8", "3.8 Khiếu nại và đánh giá", "3.8.1 Tiếp nhận phân loại khiếu nại; 3.8.2 Yêu cầu thông tin hai bên; 3.8.3 Phán quyết hoàn tiền/chia sẻ doanh thu; 3.8.4 Kiểm duyệt đánh giá"),
        ("9", "3.9 Báo cáo và thống kê", "3.9.1 Thống kê tăng trưởng người dùng; 3.9.2 Thống kê tỷ lệ hoàn thành booking; 3.9.3 Báo cáo doanh thu & phí sàn; 3.9.4 Phân tích chỉ số đánh giá")
    ]
    for r_i, row in enumerate(a_data):
        for c_i, val in enumerate(row): tbl_a.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(tbl_a, [0.6, 2.0, 3.6], [WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    add_table_caption(doc, "Bảng 3.5. Mô tả Phân hệ Chức năng hệ thống tự động (Automated Subsystem)")
    tbl_s = doc.add_table(rows=7, cols=3)
    for i, h in enumerate(c_heads): tbl_s.rows[0].cells[i].paragraphs[0].text = h
    s_data = [
        ("1", "4.1 Gợi ý theo quy tắc", "4.1.1 Kiểm tra khớp dịch vụ yêu cầu; 4.1.2 Kiểm tra lịch khả dụng; 4.1.3 Đánh giá phù hợp giống/loài thú cưng; 4.1.4 Tính điểm xếp hạng đề xuất"),
        ("2", "4.2 Kiểm tra booking", "4.2.1 Kiểm tra điều kiện nhận dịch vụ; 4.2.2 Kiểm tra chống trùng lịch nhân viên; 4.2.3 Khóa giá dịch vụ tại thời điểm đặt; 4.2.4 Sinh mã booking định danh"),
        ("3", "4.3 Quản lý trạng thái", "4.3.1 Điều phối PENDING -> CONFIRMED; 4.3.2 Điều phối CHECKED_IN -> IN_SERVICE; 4.3.3 Điều phối SERVICE_DONE -> COMPLETED; 4.3.4 Kích hoạt REJECTED/CANCELLED"),
        ("4", "4.4 Thông báo tự động", "4.4.1 Bắn thông báo tạo booking mới; 4.4.2 Thông báo chấp nhận/từ chối; 4.4.3 Nhắc lịch hẹn trước giờ phục vụ; 4.4.4 Nhắc đánh giá chất lượng"),
        ("5", "4.5 Giao dịch mô phỏng", "4.5.1 Tạo bản ghi nạp tiền/ký quỹ; 4.5.2 Cập nhật trạng thái số dư ví; 4.5.3 Tự động khấu trừ và giải phóng ký quỹ; 4.5.4 Lưu vết sổ cái bất biến"),
        ("6", "4.6 Kiểm soát dữ liệu", "4.6.1 Kiểm tra quyền hạn theo vai trò (RBAC); 4.6.2 Ghi log lịch sử thay đổi trạng thái; 4.6.3 Ghi nhật ký kiểm toán (Audit Log); 4.6.4 Bảo vệ dữ liệu nhạy cảm")
    ]
    for r_i, row in enumerate(s_data):
        for c_i, val in enumerate(row): tbl_s.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(tbl_s, [0.6, 2.0, 3.6], [WD_ALIGN_PARAGRAPH.CENTER, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])

    # 3.2 Xác định tác nhân hệ thống
    add_heading_2(doc, "3.2. Xác định tác nhân hệ thống")
    add_body_p(doc,
        "Dựa trên các phân tích nghiệp vụ thực tế và tài liệu đặc tả của PawCare, hệ thống xác định 3 tác nhân con người "
        "và 1 phân hệ xử lý nền tự động. Mỗi tác nhân được định nghĩa rõ ràng về vai trò, thẩm quyền và mục tiêu sử dụng:"
    )
    add_bullet_p(doc,
        "Là những chủ nuôi chó, mèo hoặc thú cưng có nhu cầu tìm kiếm, đặt lịch chăm sóc và sử dụng dịch vụ trên nền tảng. "
        "Khách hàng sử dụng ứng dụng di động để: đăng ký/đăng nhập, quản lý hồ sơ thú cưng cá nhân, tra cứu dịch vụ, "
        "đặt lịch hẹn theo khung giờ thực tế, thanh toán đặt cọc qua ví điện tử, giám sát tiến độ thực hiện dịch vụ hai chiều, "
        "và thực hiện quyền đánh giá hoặc mở khiếu nại tranh chấp sau khi dịch vụ kết thúc.",
        bold_prefix="Tác nhân Khách hàng (Customer): "
    )
    add_bullet_p(doc,
        "Là các cá nhân hành nghề chuyên nghiệp hoặc các cơ sở, spa thú cưng có tư cách pháp lý và cơ sở vật chất cung ứng dịch vụ. "
        "Đối tác sử dụng Cổng thông tin Web đối tác để: nộp hồ sơ đăng ký và chứng chỉ hành nghề, cấu hình danh mục dịch vụ và bảng giá, "
        "quản lý danh sách kỹ thuật viên, thiết lập lịch làm việc và khung giờ khả dụng (availability slots), tiếp nhận và phê duyệt booking, "
        "cập nhật tiến độ phục vụ (Check-in, In-service, Service Done), theo dõi số dư ví doanh thu và gửi đề xuất rút tiền.",
        bold_prefix="Tác nhân Đối tác (Provider): "
    )
    add_bullet_p(doc,
        "Là nhân sự vận hành cấp cao của đơn vị sở hữu nền tảng PawCare. Quản trị viên sử dụng Cổng Web quản trị tích hợp Bonita BPM để: "
        "thẩm định và xét duyệt hồ sơ đối tác mới, chuẩn hóa danh mục dịch vụ thú cưng toàn hệ thống, giám sát toàn diện tình trạng "
        "vận hành các đơn booking, phân xử các khiếu nại tranh chấp giữa khách hàng và đối tác để giải phóng hoặc hoàn tiền ký quỹ, "
        "giám sát an toàn hệ thống và phê duyệt các yêu cầu rút tiền.",
        bold_prefix="Tác nhân Quản trị viên (Administrator): "
    )
    add_bullet_p(doc,
        "Tài liệu phân tích và thiết kế của PawCare đặc biệt lưu ý: Phân hệ \"Chức năng hệ thống tự động\" không phải là một tác nhân con người "
        "(Actor) thứ tư trong mô hình tương tác, mà là một mô-đun phần mềm xử lý nền (Background Service / Workflow Engine) được kích hoạt "
        "dựa trên các sự kiện nghiệp vụ (Event-driven). Hệ thống tự động đảm nhận các vai trò: tính toán điểm xếp hạng đề xuất theo thuật toán đa tiêu chí, "
        "kiểm tra xung đột trùng lịch, thực thi máy trạng thái booking, tự động gửi thông báo, và ghi nhật ký kiểm toán bất biến.",
        bold_prefix="Phân hệ Chức năng Hệ thống tự động (Automated Subsystem): "
    )

    # 3.3.1 Sơ đồ Use Case
    add_heading_2(doc, "3.3. Phân tích thiết kế hệ thống với biểu đồ UML")
    add_heading_3(doc, "3.3.1. Sơ đồ Use Case")
    add_body_p(doc,
        "Biểu đồ Use Case (Use Case Diagram - UCD) là công cụ quan trọng hàng đầu trong ngôn ngữ UML, giúp biểu diễn trực quan "
        "mối quan hệ giữa các tác nhân (Actors) và các ca sử dụng (Use Cases) mà hệ thống cung cấp. Toàn bộ các biểu đồ Use Case dưới đây "
        "được trích xuất trực tiếp từ file thiết kế chính thức pawcare_ucd.mdj bằng công cụ StarUML chuyên nghiệp:"
    )

    # UCD Images
    add_image_figure(doc, "downloads_staging/exported_diagrams/UseCaseTongQuat.png", 
                     "Hình 3.5. Sơ đồ Use Case Tổng quát hệ thống PawCare", 6.0)
    add_body_p(doc,
        "Hình 3.5 mô tả bức tranh tổng thể về các chức năng cốt lõi của PawCare và sự phân định quyền hạn giữa các tác nhân. "
        "Tác nhân Quản trị viên đảm nhận nhóm chức năng quản trị hệ thống cấp cao (Quản lý tài khoản, Xét duyệt hồ sơ đối tác, "
        "Quản lý danh mục dịch vụ, Xử lý khiếu nại tranh chấp và Giám sát vận hành). Tác nhân Đối tác sở hữu nhóm chức năng quản lý cơ sở "
        "(Quản lý dịch vụ, Quản lý nhân viên, Thiết lập lịch làm việc khả dụng, Tiếp nhận và thực hiện booking, Xem doanh thu và Phản hồi đánh giá). "
        "Tác nhân Khách hàng thực hiện các chức năng mua sắm và quản lý cá nhân (Quản lý thú cưng, Tìm kiếm & nhận đề xuất, Tạo booking, "
        "Thanh toán mô phỏng ký quỹ, Theo dõi tiến độ và Gửi đánh giá/khiếu nại). Mọi tác nhân đều kế thừa chức năng Quản lý tài khoản "
        "và Đăng nhập xác thực thông qua quan hệ tổng quát hóa và phụ thuộc <<include>>."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/UseCaseKhachHang.png", 
                     "Hình 3.6. Sơ đồ Use Case Phân hệ Khách hàng (Customer)", 5.8)
    add_body_p(doc,
        "Hình 3.6 đi sâu vào các ca sử dụng trên ứng dụng di động dành cho Khách hàng. Người dùng vãng lai có thể thực hiện Đăng ký tài khoản, "
        "Tìm kiếm và Xem thông tin công khai của các đối tác/dịch vụ. Khi đã đăng nhập thành công vào tài khoản CUSTOMER, khách hàng được cấp quyền "
        "thực hiện chuỗi ca sử dụng: Quản lý hồ sơ thú cưng (UC-C02), Tạo booking (UC-C05), Thanh toán mô phỏng ký quỹ (UC-C07), Theo dõi/hủy/đổi lịch "
        "booking (UC-C06), Đánh giá và gửi khiếu nại (UC-C08), và Xem thông báo (UC-C09)."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/UseCaseDoiTac.png", 
                     "Hình 3.7. Sơ đồ Use Case Phân hệ Đối tác (Provider)", 5.8)
    add_body_p(doc,
        "Hình 3.7 thể hiện các ca sử dụng trên Cổng Web đối tác. Để được phép cung ứng dịch vụ, đối tác phải hoàn thành ca sử dụng Quản lý hồ sơ đối tác "
        "(UC-P01) và được Admin phê duyệt. Sau khi kích hoạt, đối tác thực hiện thiết lập tài nguyên gồm: Quản lý dịch vụ (UC-P02), Quản lý nhân viên (UC-P03), "
        "Thiết lập lịch và khả dụng (UC-P04). Trong giai đoạn vận hành, đối tác thực hiện Tiếp nhận và xử lý booking (UC-P05), Thực hiện dịch vụ theo tiến độ "
        "(UC-P06), Xem thông tin khách hàng và thú cưng (UC-P07), Xem đánh giá và phản hồi khiếu nại (UC-P08), và Xem doanh thu báo cáo (UC-P09)."
    )

    add_image_figure(doc, "downloads_staging/exported_diagrams/UseCaseQuanTriVien.png", 
                     "Hình 3.8. Sơ đồ Use Case Phân hệ Quản trị viên (Administrator)", 5.8)
    add_body_p(doc,
        "Hình 3.8 đặc tả các ca sử dụng quản trị trung tâm của Quản trị viên trên Bonita BPM Portal. Admin sử dụng Dashboard (UC-A01) để nắm bắt "
        "toàn diện chỉ số hệ thống, thực hiện Quản lý tài khoản (UC-A02), Xét duyệt hồ sơ đối tác (UC-A03), Quản lý trạng thái hoạt động của đối tác (UC-A04), "
        "Quản lý danh mục dịch vụ chuẩn (UC-A05), Giám sát booking toàn hệ thống (UC-A06), Giám sát giao dịch mô phỏng (UC-A07), Xử lý khiếu nại và "
        "kiểm duyệt đánh giá (UC-A08), và Xem báo cáo thống kê chuyên sâu (UC-A09)."
    )
