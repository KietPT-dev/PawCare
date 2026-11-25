import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

FONT_NAME = 'Times New Roman'
FONT_SIZE_BODY = Pt(13)
FONT_SIZE_H1 = Pt(14)
FONT_SIZE_H2 = Pt(13)
FONT_SIZE_H3 = Pt(13)
FONT_SIZE_TABLE = Pt(11)
FONT_SIZE_CAPTION = Pt(12)

COLOR_PRIMARY = RGBColor(0, 0, 0)
COLOR_MUTED = RGBColor(80, 80, 80)
SHADING_HEADER = "F2F2F2"
BORDER_COLOR = "CCCCCC"

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    """Set cell margins in dxa (1 pt = 20 dxa)"""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_table_borders(table, color=BORDER_COLOR, sz="4", val="single"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:bottom w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:left w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:right w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideH w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
            <w:insideV w:val="{val}" w:sz="{sz}" w:space="0" w:color="{color}"/>
        </w:tblBorders>
    ''')
    tblPr.append(borders)

def set_cell_shading(cell, color_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{color_hex}"/>')
    tcPr.append(shd)

def add_heading_1(doc, text):
    p = doc.add_paragraph(style='Heading 1')
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.line_spacing = 1.15
    run = p.add_run(text)
    run.font.name = FONT_NAME
    run.font.size = FONT_SIZE_H1
    run.font.bold = True
    run.font.color.rgb = COLOR_PRIMARY
    return p

def add_heading_2(doc, text):
    p = doc.add_paragraph(style='Heading 2')
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(11)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.line_spacing = 1.15
    run = p.add_run(text)
    run.font.name = FONT_NAME
    run.font.size = FONT_SIZE_H2
    run.font.bold = True
    run.font.color.rgb = COLOR_PRIMARY
    return p

def add_heading_3(doc, text):
    p = doc.add_paragraph(style='Heading 3')
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    p.paragraph_format.line_spacing = 1.15
    run = p.add_run(text)
    run.font.name = FONT_NAME
    run.font.size = FONT_SIZE_H3
    run.font.bold = True
    run.font.italic = False
    run.font.color.rgb = COLOR_PRIMARY
    return p

def add_body_p(doc, text, bold=False, italic=False):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.first_line_indent = Inches(0.3)
    run = p.add_run(text)
    run.font.name = FONT_NAME
    run.font.size = FONT_SIZE_BODY
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = COLOR_PRIMARY
    return p

def add_bullet_p(doc, text, bold_prefix="", indent=0.4):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.left_indent = Inches(indent)
    p.paragraph_format.first_line_indent = Inches(-0.2)
    
    r_bullet = p.add_run("• ")
    r_bullet.font.name = FONT_NAME
    r_bullet.font.size = FONT_SIZE_BODY
    r_bullet.font.bold = True
    
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = FONT_NAME
        r_pre.font.size = FONT_SIZE_BODY
        r_pre.font.bold = True
        r_pre.font.color.rgb = COLOR_PRIMARY
        
    run = p.add_run(text)
    run.font.name = FONT_NAME
    run.font.size = FONT_SIZE_BODY
    run.font.color.rgb = COLOR_PRIMARY
    return p

def add_image_figure(doc, img_path, caption_text, width_inches=5.8):
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(8)
    p_img.paragraph_format.space_after = Pt(4)
    p_img.paragraph_format.keep_with_next = True
    run_img = p_img.add_run()
    run_img.add_picture(img_path, width=Inches(width_inches))
    
    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(2)
    p_cap.paragraph_format.space_after = Pt(10)
    run_cap = p_cap.add_run(caption_text)
    run_cap.font.name = FONT_NAME
    run_cap.font.size = FONT_SIZE_CAPTION
    run_cap.font.italic = True
    run_cap.font.color.rgb = COLOR_PRIMARY
    return p_img, p_cap

def add_table_caption(doc, caption_text):
    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(10)
    p_cap.paragraph_format.space_after = Pt(4)
    p_cap.paragraph_format.keep_with_next = True
    run_cap = p_cap.add_run(caption_text)
    run_cap.font.name = FONT_NAME
    run_cap.font.size = FONT_SIZE_CAPTION
    run_cap.font.bold = True
    run_cap.font.color.rgb = COLOR_PRIMARY
    return p_cap

def format_custom_table(table, col_widths, col_alignments):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table)
    
    header_tr = table.rows[0]._tr.get_or_add_trPr()
    header_tr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))
    
    for r_idx, row in enumerate(table.rows):
        trPr = row._tr.get_or_add_trPr()
        trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        
        for c_idx, cell in enumerate(row.cells):
            cell.width = Inches(col_widths[c_idx])
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            
            p = cell.paragraphs[0]
            p.paragraph_format.line_spacing = 1.15
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.alignment = col_alignments[c_idx] if r_idx > 0 else WD_ALIGN_PARAGRAPH.CENTER
            
            if r_idx == 0:
                set_cell_shading(cell, SHADING_HEADER)
                for r in p.runs:
                    r.font.name = FONT_NAME
                    r.font.size = FONT_SIZE_TABLE
                    r.font.bold = True
            else:
                for r in p.runs:
                    r.font.name = FONT_NAME
                    r.font.size = FONT_SIZE_TABLE

def add_use_case_table(doc, uc_code, uc_name, actor, desc, pre_cond, main_flow, alt_flow, post_cond):
    """Formats an individual Use Case table cleanly matching the academic style."""
    caption_text = f"Bảng 3.{uc_code.replace('UC-', '')} – Đặc tả Use Case {uc_name}"
    # Wait, caption numbering will be handled cleanly
    add_table_caption(doc, caption_text)
    
    table = doc.add_table(rows=6, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(table)
    
    col_widths = [1.8, 4.4]
    fields = [
        ("Tác nhân chính", actor),
        ("Mục tiêu / Mô tả", desc),
        ("Tiền điều kiện", pre_cond),
        ("Luồng sự kiện chính", main_flow),
        ("Luồng thay thế & ngoại lệ", alt_flow),
        ("Hậu điều kiện", post_cond)
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
    return table
