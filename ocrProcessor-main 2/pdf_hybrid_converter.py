# pdf_hybrid_converter_v14_kor.py
# 하이브리드 PDF->DOCX v14 (이미지 + 하이브리드 표 + 벡터 박스)
#
# 전략: 3가지 엔진 결합 + 중복 제거
#  - 1. find_image_elements: 비트맵 이미지 -> '이미지'로 삽입
#  - 2. find_tables_hybrid:
#     - (A) 데이터 표 -> '다중 셀 표'로 삽입
#     - (B) 1줄 박스 -> '1x1 표'로 삽입
#  - 3. find_drawing_bboxes: 기타 벡터 박스 -> '1x1 표'로 삽입
#  - 4. (2)와 (3)의 결과를 중복 제거하여 통합
#
# 사용법: python pdf_hybrid_converter_v14_kor.py input.pdf output.docx
#
import sys, os, io, math, traceback
import fitz  # pymupdf
import docx
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH

# MATLAB 연동을 위한 UTF-8 표준 출력 설정
try:
    import sys as _sys, io as _io
    _sys.stdout = _io.TextIOWrapper(_sys.stdout.buffer, encoding='utf-8')
    _sys.stderr = _io.TextIOWrapper(_sys.stderr.buffer, encoding='utf-8')
except Exception:
    pass

def pixels_to_inches(px, dpi):
    return px / dpi

def clamp(x, a, b): return max(a, min(b, x))

# --- [엔진 1: v9] 임베디드 이미지 감지 함수 ---
def find_image_elements(page, doc):
    """ (v9) 임베디드 비트맵 이미지를 '이미지'로 추출 (예: 1페이지 플로우차트) """
    img_list = page.get_images(full=True)
    final_elements = []
    for img_info in img_list:
        xref = img_info[0]
        if xref == 0: continue
        try:
            bbox_data = page.get_image_bbox(img_info)
            bbox_rect = None
            if isinstance(bbox_data, (tuple, list)) and len(bbox_data) == 4:
                bbox_rect = fitz.Rect(bbox_data)
            elif isinstance(bbox_data, fitz.Rect):
                bbox_rect = bbox_data
            else:
                print(f"  [!] 알 수 없는 이미지 bbox 타입, 건너뜀: {type(bbox_data)}")
                continue

            if not bbox_rect.is_valid or bbox_rect.is_empty:
                continue
                
            img_data = doc.extract_image(xref)
            img_bytes = img_data["image"]
            final_elements.append({
                "type": "image", # -> 이미지로 처리
                "bbox": bbox_rect.irect, 
                "data": img_bytes, 
                "source": "embedded_image"
            })
        except Exception as e:
            print(f"  [!] 임베디드 이미지 추출 오류 (xref={xref}): {e}")
    return final_elements

# --- [엔진 2: v13] '하이브리드 표' 감지 함수 ---
def find_tables_hybrid(page):
    """ (v13) '데이터 표'와 '장식용 박스'를 구분하여 감지 """
    tables = page.find_tables()
    final_elements = []
    
    for tab in tables:
        try:
            bbox_data = tab.bbox 
            bbox_rect = None
            if isinstance(bbox_data, (tuple, list)) and len(bbox_data) == 4:
                bbox_rect = fitz.Rect(bbox_data)
            elif isinstance(bbox_data, fitz.Rect):
                bbox_rect = bbox_data
            else:
                print(f"  [!] 알 수 없는 표 bbox 타입, 건너뜀: {type(bbox_data)}")
                continue

            if bbox_rect.is_empty or not bbox_rect.is_valid:
                continue
            
            # --- [v13] 하이브리드 로직 분기 ---
            if tab.row_count > 1:
                # A. '데이터 표' (예: '패스1/패스2') -> 원본 구조 복원 시도
                cells_data = []
                extracted_rows = tab.extract()
                if not extracted_rows: continue
                
                clean_rows = []
                max_cols = 0
                for r_idx, row in enumerate(extracted_rows):
                    if row:
                        clean_row = [str(cell).strip() if cell else "" for cell in row]
                        max_cols = max(max_cols, len(clean_row))
                        clean_rows.append(clean_row)
                
                if not clean_rows or max_cols == 0: continue
                
                final_cells_data = []
                for r_idx, row in enumerate(clean_rows):
                    row_data = row + [""] * (max_cols - len(row)) # 빈 셀 채우기
                    for c_idx, text in enumerate(row_data):
                        final_cells_data.append( (r_idx, c_idx, text) )

                final_elements.append({
                    "type": "data_table", # -> '다중 셀 표'로 처리
                    "bbox": bbox_rect.irect,
                    "data": (len(clean_rows), max_cols, final_cells_data),
                    "source": "table_data"
                })
            
            elif tab.row_count == 1:
                # B. '장식용 박스' (예: '세그먼트 기법') -> 1x1 표로 처리
                final_elements.append({
                    "type": "box_table", # -> '1x1 표'로 처리
                    "bbox": bbox_rect.irect,
                    "source": "table_box"
                })
            
        except Exception as e:
            print(f"  [!] 표 감지 처리 오류: {e}")
            
    return final_elements

# --- [엔진 3: v12.1] *모든* 벡터 '박스' 좌표 감지 함수 ---
def find_drawing_bboxes(page, min_area_pt=50, merge_margin=10):
    """ (v12.1) fitz.get_drawings()를 사용해 '모든 드로잉' 영역의 '좌표(bbox)'만 가져옵니다. """
    drawings = page.get_drawings()
    if not drawings: return []
    
    paths = [d["rect"] for d in drawings if d["rect"].get_area() > 0]
    if not paths: return []

    rects = list(paths)
    merged = True
    while merged:
        merged = False
        i = 0
        while i < len(rects):
            j = i + 1
            while j < len(rects):
                r1_inflated = rects[i].irect + (-merge_margin, -merge_margin, merge_margin, merge_margin)
                if r1_inflated.intersects(rects[j]):
                    rects[i] = rects[i] | rects[j]
                    rects.pop(j)
                    merged = True
                else:
                    j += 1
            i += 1
    
    final_bboxes = []
    for rect in rects:
        if rect.get_area() < min_area_pt: 
            continue
        
        final_bboxes.append({
            "type": "box_table", # -> '1x1 표'로 처리
            "bbox": rect.irect, 
            "source": "drawing_box"
        })
    return final_bboxes


# --- [v14] 메인 변환 함수 ---
def convert_pdf_to_word_v14(pdf_path, word_path, dpi=200, max_width_in=6.5, debug_dir="./debug_v14"):
    print(f"--- PDF->Word v14 (최종 전략) 시작 ---")
    print(f"입력: {pdf_path}")
    pdf = fitz.open(pdf_path)
    doc = docx.Document()
    pages = pdf.page_count
    print(f"총 페이지: {pages}")

    for pnum in range(pages):
        page = pdf.load_page(pnum)
        print(f"\n페이지 {pnum+1}/{pages} 처리중...")
        
        # 1. 모든 비-텍스트 요소 감지
        
        # 엔진 1: 비트맵 이미지 (-> 이미지)
        image_elements = find_image_elements(page, pdf)
        print(f"  임베디드(비트맵) 이미지 감지: {len(image_elements)}")
        
        # 엔진 2: 데이터 표 + 장식용 박스 (-> 표)
        table_elements = find_tables_hybrid(page)
        print(f"  표/박스(Table) 영역 감지: {len(table_elements)}")

        # 엔진 3: 기타 벡터 박스 (-> 1x1 표)
        drawing_elements = find_drawing_bboxes(page, min_area_pt=50)
        print(f"  드로잉(벡터 박스) 영역 감지: {len(drawing_elements)}")

        # 2. 모든 요소 목록 및 필터링 영역 정의
        all_elements = []
        all_filter_rects = [] # 텍스트를 필터링할 영역 (이미지 + 표 + 박스)

        # 이미지 요소를 추가
        for el in image_elements:
            all_elements.append(el)
            all_filter_rects.append(el["bbox"])

        # 편집 가능한 표/박스 요소를 추가 (엔진 2 + 엔진 3)
        editable_boxes = table_elements + drawing_elements
        
        # [v14] 중복 제거 로직
        final_editable_boxes = []
        if editable_boxes:
            # bbox 기준으로 정렬 (더 큰 박스가 먼저 오도록)
            editable_boxes.sort(key=lambda b: -fitz.Rect(b["bbox"]).get_area())
            
            for box_a in editable_boxes:
                is_contained = False
                for box_b in final_editable_boxes: # 이미 추가된 (더 큰) 박스들과 비교
                    if fitz.Rect(box_b["bbox"]).contains(box_a["bbox"]):
                        is_contained = True # A가 이미 추가된 B에 포함되면 A는 탈락
                        break
                if not is_contained:
                    final_editable_boxes.append(box_a)
        
        print(f"  중복제거 후 편집가능 박스: {len(final_editable_boxes)}")
        
        for el in final_editable_boxes:
            all_elements.append(el)
            all_filter_rects.append(el["bbox"])

        # 3. 텍스트 블록 가져오기 (필터링)
        text_blocks = page.get_text("blocks")
        for b in text_blocks:
            x0, y0, x1, y1 = b[:4]
            txt = b[4].strip()
            if not txt: continue
            
            block_rect = fitz.Rect(x0, y0, x1, y1)
            is_inside_other_element = False
            
            for filter_rect in all_filter_rects:
                if (filter_rect + (-2,-2,2,2)).contains(block_rect):
                    is_inside_other_element = True
                    break
            
            if not is_inside_other_element:
                all_elements.append({"type":"text", "bbox": block_rect, "data": txt})

        # 4. 모든 요소를 y축(세로) 위치, 그 다음 x축(가로) 위치로 정렬
        all_elements.sort(key=lambda el:(round(el["bbox"][1],1), el["bbox"][0]))

        # 5. 순서대로 DOCX에 삽입
        os.makedirs(debug_dir, exist_ok=True)
        for el in all_elements:
            if el["type"] == "text":
                for line in el["data"].splitlines():
                    doc.add_paragraph(line)
            
            elif el["type"] == "image":
                x0, y0, x1, y1 = el["bbox"]
                width_pt = x1 - x0
                width_in = clamp(width_pt / 72.0, 0.5, max_width_in)
                try:
                    para = doc.add_paragraph()
                    run = para.add_run()
                    img_io = None
                    if el["data"].startswith(b'\x89PNG'):
                        img_io = io.BytesIO(el["data"])
                    else:
                        try:
                            pil_img = Image.open(io.BytesIO(el["data"]))
                            img_io = io.BytesIO()
                            pil_img.save(img_io, format='PNG')
                            img_io.seek(0)
                        except Exception:
                            print(f"  [!] PIL 변환 실패: 원본 바이트 시도.")
                            img_io = io.BytesIO(el["data"])
                    
                    debug_path = os.path.join(debug_dir, f"page{pnum+1}_img_{el['bbox'][0]}.png")
                    with open(debug_path, "wb") as f: f.write(img_io.getvalue())
                    
                    run.add_picture(img_io, width=Inches(width_in))
                    para.space_after = Pt(4)
                except Exception as e:
                    print(f"  [!] 이미지 삽입 실패: {e}")

            # [v13] A. '데이터 표' (다중 셀) 삽입
            elif el["type"] == "data_table":
                try:
                    (rows, cols, cells_data) = el["data"]
                    if rows == 0 or cols == 0: continue
                        
                    table = doc.add_table(rows=rows, cols=cols)
                    table.style = 'Table Grid'
                    
                    for (r, c, text) in cells_data:
                        if r < rows and c < cols:
                            table.cell(r, c).text = text
                            
                    doc.add_paragraph()
                    
                except Exception as e:
                    print(f"  [!] '데이터 표' 삽입 실패: {e}")

            # [v13/v14] B. '장식용 박스' (1x1 셀) 삽입
            elif el["type"] == "box_table":
                try:
                    table_bbox_float = fitz.Rect(el["bbox"])
                    
                    box_text = page.get_text(clip=table_bbox_float, sort=True, flags=0).strip()

                    if not box_text:
                        # [v14] 텍스트가 없는 순수 드로잉 박스(예: 하이라이트)는 무시
                        continue
                        
                    table = doc.add_table(rows=1, cols=1)
                    table.style = 'Table Grid'
                    
                    cell = table.cell(0, 0)
                    cell.text = ""
                    lines = box_text.split('\n')
                    cell.paragraphs[0].text = lines[0]
                    for line in lines[1:]:
                        cell.add_paragraph(line)
                    
                    doc.add_paragraph()
                    
                except Exception as e:
                    print(f"  [!] '1x1 표' 삽입 실패: {e}")


        if pnum < pages - 1:
            doc.add_page_break()

    doc.save(word_path)
    print(f"\n완료: {word_path}")
    print(f"디버그 파일들은 '{os.path.abspath(debug_dir)}'에 저장됩니다 (확인하세요).")

# --- v9.1: 이미지 형식 변환을 위해 PIL 의존성 추가 ---
try:
    from PIL import Image
except ImportError:
    print("---------------------------------------------------------")
    print("  오류: 'Pillow' 라이브러리가 필요합니다.")
    print("  MATLAB 터미널에서 다음을 실행하세요:")
    print("  !pip install Pillow")
    print("---------------------------------------------------------")
    sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python pdf_hybrid_converter_v14_kor.py <input.pdf> <output.docx>")
        sys.exit(1)
    
    debug_path = "./debug_v14"
    if len(sys.argv) > 3:
        debug_path = sys.argv[3]
        
    convert_pdf_to_word_v14(pdf_path=sys.argv[1], 
                            word_path=sys.argv[2], 
                            debug_dir=debug_path)
