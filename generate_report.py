# -*- coding: utf-8 -*-
import os
import docx
from docx.shared import Pt, Inches
from docx_helpers import FONT_NAME
from content_preliminary import (
    build_supervisor_review_page, build_acknowledgements_page,
    build_abbreviations_page, build_list_of_figures,
    build_list_of_tables, build_table_of_contents
)
from content_chapter1 import build_chapter_1
from content_chapter2 import build_chapter_2
from content_chapter3_part1 import build_chapter_3_part1
from content_chapter3_usecases import build_chapter_3_usecases
from content_chapter3_part2 import build_chapter_3_part2
from content_chapter4 import build_chapter_4
from content_chapter5 import build_chapter_5
from content_chapter6 import build_chapter_6
from content_references import build_references

def update_line(p, label, val):
    p.text = ''
    r0 = p.add_run(label)
    r0.font.name = FONT_NAME
    r0.font.bold = True
    r0.font.size = Pt(13)
    r1 = p.add_run(val)
    r1.font.name = FONT_NAME
    r1.font.bold = False
    r1.font.size = Pt(13)

def generate_report():
    print("=== BẮT ĐẦU TẠO BÁO CÁO ĐỒ ÁN TỐT NGHIỆP PAWCARE ===")
    template_path = 'downloads_staging/Hồng Ân_23030360_DATN.docx'
    output_path = 'PawCare_Bao_Cao_Do_An_Tot_Nghiep.docx'
    
    print(f"1. Đang mở tài liệu mẫu: {template_path}")
    doc = docx.Document(template_path)
    body = doc._body._element
    
    # Update Cover Page
    print("2. Đang cập nhật trang bìa sang đề tài PawCare...")
    p9 = doc.paragraphs[9]
    p9.text = ''
    r9 = p9.add_run("XÂY DỰNG NỀN TẢNG WEB VÀ ỨNG DỤNG DI ĐỘNG ĐẶT DỊCH VỤ CHĂM SÓC THÚ CƯNG PAWCARE KẾT HỢP QUẢN LÝ QUY TRÌNH NGHIỆP VỤ")
    r9.font.name = FONT_NAME
    r9.font.bold = True
    r9.font.size = Pt(14)
    
    update_line(doc.paragraphs[11], "Giảng viên hướng dẫn\t: ", "........................................................")
    update_line(doc.paragraphs[12], "Sinh viên thực hiện\t: ", "........................................................")
    update_line(doc.paragraphs[13], "Mã sinh viên\t: ", "....................................")
    update_line(doc.paragraphs[14], "Ngành\t: ", "Công nghệ thông tin")
    update_line(doc.paragraphs[15], "Trình độ đào tạo\t: ", "Đại học")
    update_line(doc.paragraphs[16], "Chuyên ngành đào tạo\t: ", "Kỹ thuật phần mềm")
    update_line(doc.paragraphs[17], "Lớp\t: ", "........................")
    update_line(doc.paragraphs[18], "Niên khoá\t: ", "2023 – 2027")
    
    p23 = doc.paragraphs[23]
    p23.text = ''
    r23 = p23.add_run("Bà Rịa - Vũng Tàu, năm 2026")
    r23.font.name = FONT_NAME
    r23.font.italic = True
    r23.font.size = Pt(13)
    
    # Remove body elements after paragraph 23 while preserving sectPr
    print("3. Đang dọn dẹp nội dung cũ của tài liệu mẫu và giữ nguyên thuộc tính trang...")
    sectPr = body.xpath('w:sectPr')[0]
    children_to_remove = [child for i, child in enumerate(body) if i > 23 and child is not sectPr]
    for child in children_to_remove:
        body.remove(child)
        
    doc.add_page_break()
    
    # Preliminary sections
    print("4. Đang xây dựng các trang đầu (Nhận xét GVHD, Lời cảm ơn, Mục lục, Danh mục viết tắt, Danh mục ảnh, Danh mục bảng)...")
    build_supervisor_review_page(doc)
    build_acknowledgements_page(doc)
    build_table_of_contents(doc)
    build_abbreviations_page(doc)
    build_list_of_figures(doc)
    build_list_of_tables(doc)
    
    # Chapter 1
    print("5. Đang xây dựng Chương 1: Tổng quan về đề tài...")
    build_chapter_1(doc)
    doc.add_page_break()
    
    # Chapter 2
    print("6. Đang xây dựng Chương 2: Cơ sở lý thuyết...")
    build_chapter_2(doc)
    doc.add_page_break()
    
    # Chapter 3
    print("7. Đang xây dựng Chương 3: Phân tích thiết kế hệ thống...")
    print("   - 3.1 Khảo sát hệ thống, 3.2 Tác nhân, 3.3.1 Sơ đồ Use Case...")
    build_chapter_3_part1(doc)
    print("   - 3.3.2 Đặc tả Use Case 33 ca sử dụng...")
    build_chapter_3_usecases(doc)
    print("   - 3.3.3 Sơ đồ tuần tự (18 sơ đồ), 3.3.4 BPMN 2.0, 3.4 Thiết kế CSDL (ERD & 18 bảng)...")
    build_chapter_3_part2(doc)
    doc.add_page_break()
    
    # Chapter 4
    print("8. Đang xây dựng Chương 4: Thiết kế giao diện...")
    build_chapter_4(doc)
    doc.add_page_break()
    
    # Chapter 5
    print("9. Đang xây dựng Chương 5: Kiểm thử và đánh giá...")
    build_chapter_5(doc)
    doc.add_page_break()
    
    # Chapter 6
    print("10. Đang xây dựng Chương 6: Kết luận và hướng phát triển...")
    build_chapter_6(doc)
    doc.add_page_break()
    
    # References
    print("11. Đang xây dựng Tài liệu tham khảo...")
    build_references(doc)
    
    # Save
    print(f"12. Đang lưu tài liệu hoàn chỉnh thành file: {output_path}...")
    doc.save(output_path)
    file_size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"=== TẠO THÀNH CÔNG! Dung lượng file: {file_size_mb:.2f} MB ===")

if __name__ == '__main__':
    generate_report()
