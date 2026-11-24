# -*- coding: utf-8 -*-
import json
import os
from docx_helpers import (
    add_heading_2, add_heading_3, add_body_p, 
    add_bullet_p, add_table_caption, format_custom_table, set_table_borders,
    set_cell_margins, set_cell_shading, FONT_NAME, FONT_SIZE_TABLE
)
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def add_detailed_usecase_table(doc, table_num, uc):
    caption_text = f"Bảng 3.{table_num}. {uc['code']} – Đặc tả Use Case {uc['name']}"
    add_table_caption(doc, caption_text)
    
    table = doc.add_table(rows=6, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table)
    
    col_widths = [1.8, 4.4]
    fields = [
        ("Tác nhân chính", uc['actor']),
        ("Mục tiêu / Mô tả", uc['goal']),
        ("Tiền điều kiện", uc['pre']),
        ("Luồng sự kiện chính", uc['main']),
        ("Luồng thay thế và ngoại lệ", uc['alt']),
        ("Hậu điều kiện", uc['post'])
    ]
    
    for r_idx, (f_name, f_val) in enumerate(fields):
        row = table.rows[r_idx]
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        
        c0, c1 = row.cells[0], row.cells[1]
        c0.width = Inches(col_widths[0])
        c1.width = Inches(col_widths[1])
        c0.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        c1.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        set_cell_margins(c0, top=70, bottom=70, left=100, right=100)
        set_cell_margins(c1, top=70, bottom=70, left=100, right=100)
        set_cell_shading(c0, "F8F8F8")
        
        p0 = c0.paragraphs[0]
        p0.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p0.paragraph_format.line_spacing = 1.15
        p0.paragraph_format.space_before = Pt(0)
        p0.paragraph_format.space_after = Pt(0)
        r0 = p0.add_run(f_name)
        r0.font.name = FONT_NAME
        r0.font.size = FONT_SIZE_TABLE
        r0.font.bold = True
        
        p1 = c1.paragraphs[0]
        p1.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p1.paragraph_format.line_spacing = 1.15
        p1.paragraph_format.space_before = Pt(0)
        p1.paragraph_format.space_after = Pt(0)
        r1 = p1.add_run(f_val)
        r1.font.name = FONT_NAME
        r1.font.size = FONT_SIZE_TABLE

    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_before = Pt(0)
    p_after.paragraph_format.space_after = Pt(6)

def build_chapter_3_usecases(doc):
    add_heading_3(doc, "3.3.2. Đặc tả Use Case cho các chức năng")
    
    add_body_p(doc,
        "Đặc tả Use Case là tài liệu mô tả chi tiết từng kịch bản tương tác giữa người dùng và hệ thống, "
        "làm cơ sở cốt lõi để xây dựng các API endpoints, kiểm thử hệ thống và hiện thực hóa các màn hình giao diện. "
        "Toàn bộ 33 Use Cases dưới đây được kế thừa nguyên văn và đầy đủ từ tài liệu đặc tả chính thức của dự án PawCare, "
        "đảm bảo giữ nguyên vẹn mã số, tác nhân, tiền điều kiện, luồng sự kiện chính, luồng ngoại lệ và hậu điều kiện."
    )
    
    add_body_p(doc, "Quy ước và giả định nghiệp vụ chung của hệ thống PawCare:", bold=True)
    add_bullet_p(doc, "Chuỗi trạng thái booking chuẩn: PENDING → CONFIRMED → CHECKED_IN → IN_SERVICE → SERVICE_DONE → COMPLETED. Nhánh kết thúc sớm gồm REJECTED (Đối tác từ chối) hoặc CANCELLED (Khách hủy trước giờ hẹn).")
    add_bullet_p(doc, "Đối tác bắt buộc phải nhập lý do giải trình khi từ chối một yêu cầu booking.")
    add_bullet_p(doc, "Khách hàng chỉ được phép đánh giá khi booking đã hoàn tất (COMPLETED); mỗi booking chỉ có tối đa một đánh giá (review).")
    add_bullet_p(doc, "Hủy hoặc đổi lịch chỉ được thực hiện khi booking chưa bắt đầu và đáp ứng các mốc thời gian trong chính sách cấu hình hệ thống.")
    add_bullet_p(doc, "Thanh toán trong phạm vi đề tài là thanh toán thử nghiệm tích hợp nạp tiền VietQR và ví nội bộ, không tích hợp cổng ngân hàng thực tế.")
    add_bullet_p(doc, "Phân hệ Hệ thống tự động không phải là một tác nhân con người mà là các module xử lý nghiệp vụ chạy nền được kích hoạt theo sự kiện.")

    json_path = os.path.join(os.path.dirname(__file__), 'downloads_staging/usecases_data.json')
    with open(json_path, 'r', encoding='utf-8') as f:
        ucs = json.load(f)

    # 3.3.2.1 Khách hàng: UC-C01 to UC-C09 -> Table 3.6 to Table 3.14
    add_body_p(doc, "3.3.2.1. Nhóm Use Case Khách hàng (Ứng dụng di động)", bold=True)
    table_counter = 6
    for uc in ucs:
        if uc['code'].startswith('UC-C'):
            add_detailed_usecase_table(doc, table_counter, uc)
            table_counter += 1

    # 3.3.2.2 Đối tác: UC-P01 to UC-P09 -> Table 3.15 to Table 3.23
    add_body_p(doc, "3.3.2.2. Nhóm Use Case Đối tác (Website đối tác)", bold=True)
    for uc in ucs:
        if uc['code'].startswith('UC-P'):
            add_detailed_usecase_table(doc, table_counter, uc)
            table_counter += 1

    # 3.3.2.3 Quản trị viên: UC-A01 to UC-A09 -> Table 3.24 to Table 3.32
    add_body_p(doc, "3.3.2.3. Nhóm Use Case Quản trị viên (Website quản trị)", bold=True)
    for uc in ucs:
        if uc['code'].startswith('UC-A'):
            add_detailed_usecase_table(doc, table_counter, uc)
            table_counter += 1

    # 3.3.2.4 Hệ thống tự động: UC-S01 to UC-S06 -> Table 3.33 to Table 3.38
    add_body_p(doc, "3.3.2.4. Nhóm Use Case Hệ thống tự động (Automated Subsystem)", bold=True)
    for uc in ucs:
        if uc['code'].startswith('UC-S'):
            add_detailed_usecase_table(doc, table_counter, uc)
            table_counter += 1

    # 3.3.2.5 Ma trận truy vết Use Case -> Table 3.39
    add_body_p(doc, "3.3.2.5. Ma trận truy vết Use Case (Traceability Matrix)", bold=True)
    add_table_caption(doc, f"Bảng 3.{table_counter}. Ma trận truy vết Use Case hệ thống PawCare")
    
    tbl_trace = doc.add_table(rows=5, cols=3)
    trace_heads = ["Nhóm tác nhân", "Danh sách Use Case", "Đầu ra triển khai thực tế"]
    for i, h in enumerate(trace_heads): tbl_trace.rows[0].cells[i].paragraphs[0].text = h
    trace_data = [
        ("Khách hàng", "UC-C01; UC-C02; UC-C03; UC-C04; UC-C05; UC-C06; UC-C07; UC-C08; UC-C09", "Mobile App (Flutter): Quản lý tài khoản, thú cưng, khám phá, đặt lịch, thanh toán ví/VietQR, phản hồi."),
        ("Đối tác", "UC-P01; UC-P02; UC-P03; UC-P04; UC-P05; UC-P06; UC-P07; UC-P08; UC-P09", "Provider Web (React): Hồ sơ đối tác, dịch vụ, nhân viên, lịch làm việc, tiếp nhận booking, báo cáo."),
        ("Quản trị viên", "UC-A01; UC-A02; UC-A03; UC-A04; UC-A05; UC-A06; UC-A07; UC-A08; UC-A09", "Admin Portal (Bonita BPM): Bảng điều khiển, thẩm định hồ sơ, danh mục dịch vụ, giám sát, đối soát."),
        ("Hệ thống tự động", "UC-S01; UC-S02; UC-S03; UC-S04; UC-S05; UC-S06", "Public API Backend: Luật nghiệp vụ, kiểm tra chống trùng slot, máy trạng thái, bắn thông báo, RBAC.")
    ]
    for r_i, row in enumerate(trace_data):
        for c_i, val in enumerate(row): tbl_trace.rows[r_i + 1].cells[c_i].paragraphs[0].text = val
    format_custom_table(tbl_trace, [1.5, 2.3, 2.4], [WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT, WD_ALIGN_PARAGRAPH.LEFT])
    
    add_body_p(doc, 
        f"Tổng cộng hệ thống PawCare sở hữu 33 Use Cases chi tiết bao phủ toàn diện 4 phân hệ. "
        f"Mỗi Use Case đều được kiểm chứng và liên kết chặt chẽ với các endpoint của Public API và giao diện tương ứng."
    )
