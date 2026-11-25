# -*- coding: utf-8 -*-
from docx_helpers import add_heading_1, add_body_p, FONT_NAME, COLOR_PRIMARY
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH

def build_references(doc):
    add_heading_1(doc, "TÀI LIỆU THAM KHẢO")
    
    references_data = [
        ("[1]", "Object Management Group (OMG). (2011). Business Process Model and Notation (BPMN) Version 2.0. OMG Document Number: formal/2011-01-03. Retrieved from OMG Specification: https://www.omg.org/spec/BPMN/2.0/"),
        ("[2]", "Bonitasoft. (2025). Bonita Documentation: Business Process Management and Low-Code Application Platform. Retrieved from Bonitasoft Documentation: https://documentation.bonitasoft.com/"),
        ("[3]", "Walls, C. (2022). Spring in Action (6th Edition). Shelter Island, NY: Manning Publications. ISBN: 9781617297571."),
        ("[4]", "VMware Tanzu. (2025). Spring Boot Reference Documentation (Version 3.x). Retrieved from Spring Framework Documentation: https://docs.spring.io/spring-boot/docs/current/reference/html/"),
        ("[5]", "Windmill, E. (2020). Flutter in Action. Shelter Island, NY: Manning Publications. ISBN: 9781617296147."),
        ("[6]", "Google Developers. (2025). Flutter Documentation: Multi-Platform UI Toolkit. Retrieved from Flutter Official Website: https://docs.flutter.dev/"),
        ("[7]", "React Core Team. (2025). React Documentation: The Library for Web and Native User Interfaces. Retrieved from React Official Website: https://react.dev/"),
        ("[8]", "Vite Core Team. (2025). Vite: Next Generation Frontend Tooling. Retrieved from Vite Official Website: https://vite.dev/"),
        ("[9]", "Oracle Corporation. (2025). MySQL 8.0 Reference Manual. Oracle Corporation. Retrieved from MySQL Documentation: https://dev.mysql.com/doc/refman/8.0/en/"),
        ("[10]", "Jones, M., Bradley, J., & Sakimura, N. (2015). JSON Web Token (JWT). RFC 7519, Internet Engineering Task Force (IETF). Retrieved from IETF Datatracker: https://datatracker.ietf.org/doc/html/rfc7519"),
        ("[11]", "National Payment Corporation of Vietnam (NAPAS). (2021). Tiêu chuẩn cơ sở về mã phản hồi nhanh (VietQR) trong thanh toán tại Việt Nam. Hà Nội: Công ty Cổ phần Thanh toán Quốc gia Việt Nam. Retrieved from NAPAS: https://napas.com.vn/"),
        ("[12]", "Euromonitor International. (2024). Pet Care in Vietnam: Country Report and Market Dynamics. London: Euromonitor Passport Database."),
        ("[13]", "Pet Fair Asia. (2024). Southeast Asia Pet Industry White Paper: Growth Drivers and Digital Trends in Pet Services. Shanghai: Pet Fair Asia Research."),
        ("[14]", "Pressman, R. S., & Maxim, B. R. (2020). Software Engineering: A Practitioner's Approach (9th Edition). New York, NY: McGraw-Hill Education. ISBN: 9781259872976."),
        ("[15]", "Martin, R. C. (2017). Clean Architecture: A Craftsman's Guide to Software Structure and Design. Boston, MA: Prentice Hall. ISBN: 9780134494166.")
    ]
    
    for tag, ref_text in references_data:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.left_indent = Inches(0.4)
        p.paragraph_format.first_line_indent = Inches(-0.4)
        
        r_tag = p.add_run(f"{tag} ")
        r_tag.font.name = FONT_NAME
        r_tag.font.size = Pt(12)
        r_tag.font.bold = True
        r_tag.font.color.rgb = COLOR_PRIMARY
        
        r_text = p.add_run(ref_text)
        r_text.font.name = FONT_NAME
        r_text.font.size = Pt(12)
        r_text.font.color.rgb = COLOR_PRIMARY
