# pdf_hybrid_converter_v18_kor.py
# 하이브리드 PDF->DOCX v18 (이미지 크기 원본 반영)
#
# [주요 기능 및 알고리즘 요약]
# 1. 하이브리드 객체 추출: 텍스트, 이미지, 표, 도형(Box)을 각각 별도 엔진으로 추출
# 2. 공간 분석(Spatial Analysis): 요소들의 좌표(BBox)를 분석하여 중복 제거 및 배치 순서 결정
# 3. 2단 레이아웃 감지: 문서 중앙을 기준으로 좌/우 텍스트 블록을 분리하여 Word 표(Table)로 구조화
# 4. 동적 이미지 리사이징: PDF 내부 좌표계(Point)를 Word 단위(Inch)로 변환하여 원본 비율 유지

import sys, os, io, fitz  # pymupdf
import docx
from docx.shared import Inches, Pt # Word 크기 단위를 다루기 위한 모듈
from docx.enum.text import WD_ALIGN_PARAGRAPH

# --- [시스템 설정] 인코딩 호환성 처리 ---
# MATLAB이나 일부 Windows 콘솔은 기본 인코딩이 cp949인 경우가 많아
# 한글 출력 시 오류가 납니다. 강제로 UTF-8로 입출력을 고정합니다.
try:
    import sys as _sys, io as _io
    _sys.stdout = _io.TextIOWrapper(_sys.stdout.buffer, encoding='utf-8')
    _sys.stderr = _io.TextIOWrapper(_sys.stderr.buffer, encoding='utf-8')
except Exception:
    pass

# --- [Helper] 텍스트 정제 함수 ---
# PDF의 글머리 기호(•, - 등)는 텍스트로 그냥 두면 Word의 자동 목록 기능과 충돌하거나 안 예쁩니다.
# 이를 감지해서 기호를 지우고, 대신 Word의 스타일('List Bullet')을 적용하라는 신호를 보냅니다.
def clean_text_and_style(text):
    bullets = ['•', '-', 'o', '·', '➢', '', 'v', '', '\uf0b7'] 
    clean_txt = text.strip()
    for b in bullets:
        if clean_txt.startswith(b):
            # 기호 길이만큼 자르고(slice), 스타일 명을 반환
            return clean_txt[len(b):].strip(), 'List Bullet'
    return clean_txt, None

# --- [핵심] 2단 레이아웃 감지 및 분할 함수 ---
def detect_layout_and_split(page, text_blocks, page_width, page_height):
    center_x = page_width / 2  # 페이지의 정중앙 X좌표
    margin = 15  # 중앙선 판별 시 약간의 오차(여백)를 허용하기 위함
    
    # 1. 블록들을 위에서 아래로(Y좌표 기준) 정렬 (문서의 읽는 순서)
    sorted_blocks = sorted(text_blocks, key=lambda b: b[1])
    if not sorted_blocks: return False, [], [], [], []

    # 2. "1단 블록(헤더/푸터)" 찾기
    # 블록이 중앙선(center_x)을 기준으로 왼쪽~오른쪽을 모두 덮고 있으면 'Crossing'으로 판단
    crossing_indices = []
    for i, b in enumerate(sorted_blocks):
        x0, y0, x1, y1 = b[:4] # b[0]:x0, b[1]:y0, b[2]:x1, b[3]:y1
        # 왼쪽 끝이 중앙보다 왼쪽(Left)이고, 오른쪽 끝이 중앙보다 오른쪽(Right)이면 -> 가로지름
        if x0 < center_x - margin and x1 > center_x + margin:
            crossing_indices.append(i)
            
    # 3. 본문 영역(Body) 탐색
    # 가로지르는 블록들(헤더 등) 사이에 있는 "가장 넓은 구간"을 2단 본문 영역으로 추정
    if not crossing_indices:
        # 가로지르는 게 하나도 없으면 전체가 본문 후보
        start_idx = 0; end_idx = len(sorted_blocks)
    else:
        gaps = [] # (시작인덱스, 끝인덱스) 튜플을 저장할 리스트
        prev = -1
        # 인덱스 차이를 계산해서 덩어리(Gap)를 찾음
        for curr in crossing_indices + [len(sorted_blocks)]:
            if curr - prev - 1 > 0: gaps.append((prev + 1, curr))
            prev = curr
        
        # 2단 분리가 불가능하거나 텍스트가 없으면 그냥 1단으로 처리
        if not gaps: return False, sorted_blocks, [], [], []
        
        # 가장 블록이 많은 구간을 메인 본문으로 선택
        gaps.sort(key=lambda x: x[1] - x[0], reverse=True)
        start_idx, end_idx = gaps[0]
        if (end_idx - start_idx) < 2: return False, sorted_blocks, [], [], []

    # 4. 영역 확정
    top_blocks = sorted_blocks[:start_idx]      # 헤더 영역
    body_candidates = sorted_blocks[start_idx:end_idx] # 본문 영역
    bottom_blocks = sorted_blocks[end_idx:]     # 푸터 영역
    
    # 5. 본문 좌/우 분리 (Spatial Classification)
    left_blocks = []
    right_blocks = []
    for b in body_candidates:
        x0, y0, x1, y1 = b[:4]
        # 블록의 끝(x1)이 중앙보다 왼쪽이면 -> 왼쪽 단
        if x1 < center_x + margin: left_blocks.append(b)
        # 블록의 시작(x0)이 중앙보다 오른쪽이면 -> 오른쪽 단
        elif x0 > center_x - margin: right_blocks.append(b)
        # 애매하면 왼쪽으로 (기본값)
        else: left_blocks.append(b)

    # 한쪽 단이 텅 비었으면 굳이 2단으로 나눌 필요 없음 -> False 반환
    if len(left_blocks) == 0 or len(right_blocks) == 0:
        return False, sorted_blocks, [], [], []
        
    return True, top_blocks, left_blocks, right_blocks, bottom_blocks


# --- [엔진 1] 이미지 추출 ---
def find_image_elements(page, doc):
    img_list = page.get_images(full=True) # 페이지 내 이미지 리스트 반환
    final = []
    for img in img_list:
        try:
            xref = img[0] # 리소스 ID
            if xref == 0: continue
            
            # 중요: 이미지 자체 데이터만으론 위치를 모름. 
            # get_image_bbox를 통해 이 이미지가 페이지의 어디(x,y,w,h)에 그려지는지 알아냄
            bbox = page.get_image_bbox(img)
            if not bbox: continue
            
            r = fitz.Rect(bbox)
            if not r.is_valid or r.is_empty: continue
            final.append({"type": "image", "bbox": r.irect, "data": doc.extract_image(xref)["image"]})
        except: pass
    return final

# --- [엔진 2] 표 추출 ---
def find_tables_hybrid(page):
    # PyMuPDF의 알고리즘으로 표를 감지
    tables = page.find_tables()
    final = []
    for tab in tables:
        # 행(row)이 2개 이상이고 유효한 표만 추출
        if tab.bbox and fitz.Rect(tab.bbox).is_valid and tab.row_count > 1:
            ext = tab.extract() # 텍스트 데이터를 2차원 리스트([[값,값],[값,값]])로 변환
            if ext: final.append({"type": "data_table", "bbox": fitz.Rect(tab.bbox).irect, "data": ext})
    return final

# --- [엔진 3] 박스(도형) 추출 ---
# 단순한 선이나 사각형도 '정보'를 담고 있는 경우가 많음 (예: 주의사항 박스)
def find_drawing_bboxes(page):
    drawings = page.get_drawings()
    # 너무 작은 점이나 선은 무시하고, 면적이 100 이상인 사각형만 취급
    rects = [d["rect"] for d in drawings if d["rect"].get_area() > 100]
    unique = []
    
    # 중복 제거 (겹치는 박스가 여러 개 그려진 경우 하나로 합침)
    for r in rects:
        dup = False
        for u in unique:
            # 기존 박스(u)와 현재 박스(r)가 80% 이상 겹치면 중복으로 간주
            if u.intersects(r) and (u.intersect(r).get_area() / r.get_area() > 0.8):
                dup = True; break
        if not dup: unique.append(r)
    return [{"type": "box_table", "bbox": r.irect} for r in unique]

# --- [기능] 이미지 자동 크기 조절 (v18 핵심) ---
def insert_image_auto_size(paragraph, img_obj):
    try:
        # BBox: (x0, y0, x1, y1)
        x0, y0, x1, y1 = img_obj["bbox"]
        width_pt = x1 - x0          # PDF 상의 너비 (Point 단위)
        width_in = width_pt / 72.0  # 1 inch = 72 point 공식 적용
        
        # Word 문서 폭에 맞게 안전장치(Clamp) 적용
        # 최소 0.2인치 ~ 최대 6.5인치(A4 여백 고려)
        width_in = max(0.2, min(width_in, 6.5))
        
        run = paragraph.add_run()
        # Word에 이미지 스트림과 계산된 너비를 전달
        run.add_picture(io.BytesIO(img_obj["data"]), width=Inches(width_in))
    except Exception as e:
        print(f"  [!] 이미지 삽입 오류: {e}")

# --- 메인 실행 함수 ---
def convert_pdf_to_word_v18(pdf_path, word_path):
    print(f"--- PDF->Word v18 시작 ---")
    doc = fitz.open(pdf_path)
    docx_doc = docx.Document()
    
    for pnum, page in enumerate(doc):
        w, h = page.rect.width, page.rect.height
        
        # 1. 3가지 엔진으로 모든 시각 요소 추출
        images = find_image_elements(page, doc)
        tables = find_tables_hybrid(page)
        boxes = find_drawing_bboxes(page)
        
        # 2. 텍스트 추출 전처리 (중복 방지 필터 생성)
        filter_rects = [fitz.Rect(el["bbox"]) for el in images + tables + boxes]
        
        text_blocks = []
        for b in page.get_text("blocks"):
            r = fitz.Rect(b[:4]) # 텍스트의 위치
            is_in = False
            # 텍스트가 이미지/표/박스 안에 있으면 추출하지 않음 (중복 방지)
            for fr in filter_rects:
                if fr.contains(r): is_in = True; break
            if not is_in and b[4].strip(): # 내용이 있고, 포함되지 않은 경우만
                text_blocks.append(b)

        # 3. 레이아웃 판단 (2단 vs 1단)
        is_2col, top_b, left_b, right_b, bot_b = detect_layout_and_split(page, text_blocks, w, h)
        
        # 블록 출력 헬퍼 함수
        def render_blocks(block_list):
            block_list.sort(key=lambda b: b[1]) # Y축 정렬
            for b in block_list:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = docx_doc.add_paragraph(txt)
                    if style: p.style = style # 'List Bullet' 등 스타일 적용
        
        # [Case A] 2단 레이아웃인 경우
        if is_2col:
            # 헤더 영역 처리
            header_limit_y = top_b[-1][3] if top_b else 100
            # 헤더 영역에 있는 이미지만 골라서 먼저 박음
            top_imgs = [img for img in images if img["bbox"][1] < header_limit_y]
            
            for img in top_imgs:
                p = docx_doc.add_paragraph()
                insert_image_auto_size(p, img)
            
            render_blocks(top_b)
            
            # 본문 영역: 1x2 투명 표를 만들어서 좌우 배치 구현
            table = docx_doc.add_table(rows=1, cols=2)
            table.autofit = False # 표 너비가 글자 수에 따라 찌그러지지 않도록 고정
            
            # 왼쪽 칸 채우기
            cell_l = table.cell(0, 0)
            left_b.sort(key=lambda b: b[1])
            for b in left_b:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = cell_l.add_paragraph(txt)
                    if style: p.style = style
            
            # 오른쪽 칸 채우기
            cell_r = table.cell(0, 1)
            right_b.sort(key=lambda b: b[1])
            for b in right_b:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = cell_r.add_paragraph(txt)
                    if style: p.style = style
            
            docx_doc.add_paragraph() # 간격 띄우기
            render_blocks(bot_b) # 푸터 처리

        # [Case B] 1단 레이아웃인 경우 (일반적인 문서)
        else:
            # 모든 요소를 하나의 리스트에 담습니다. (타입, 객체, Y좌표)
            all_items = []
            for img in images: all_items.append({'type':'img', 'obj':img, 'y':img['bbox'][1]})
            for tab in tables: all_items.append({'type':'tab', 'obj':tab, 'y':tab['bbox'][1]})
            for box in boxes:  all_items.append({'type':'box', 'obj':box, 'y':box['bbox'][1]})
            for txt in text_blocks: all_items.append({'type':'txt', 'obj':txt, 'y':txt[1]})
            
            # 중요: Y좌표(높이) 순서대로 정렬해야 문서 순서가 꼬이지 않습니다.
            all_items.sort(key=lambda x: x['y'])
            
            for item in all_items:
                if item['type'] == 'txt':
                    txt, style = clean_text_and_style(item['obj'][4])
                    if txt:
                        p = docx_doc.add_paragraph(txt)
                        if style: p.style = style
                        
                elif item['type'] == 'img':
                    p = docx_doc.add_paragraph()
                    insert_image_auto_size(p, item['obj']) # 이미지 삽입
                    
                elif item['type'] == 'tab':
                    data = item['obj']['data']
                    if not data: continue
                    # Word 표 생성
                    t = docx_doc.add_table(rows=len(data), cols=len(data[0]))
                    t.style = 'Table Grid'
                    for r, row in enumerate(data):
                        for c, val in enumerate(row):
                             if val: t.cell(r, c).text = str(val)
                    docx_doc.add_paragraph()
                    
                elif item['type'] == 'box':
                    # 박스 영역 안의 텍스트를 다시 긁어옴(clipping)
                    box_rect = fitz.Rect(item['obj']['bbox'])
                    box_text = page.get_text(clip=box_rect).strip()
                    if not box_text: continue
                    
                    # 1x1 표로 박스 테두리 표현
                    t = docx_doc.add_table(rows=1, cols=1)
                    t.style = 'Table Grid'
                    txt, style = clean_text_and_style(box_text)
                    cell = t.cell(0,0)
                    p = cell.paragraphs[0]; p.text = txt
                    if style: p.style = style
                    docx_doc.add_paragraph()

        # 마지막 페이지가 아니면 페이지 나누기 추가
        if pnum < len(doc) - 1:
            docx_doc.add_page_break()

    docx_doc.save(word_path)
    print(f"완료: {word_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python ... <input.pdf> <output.docx>")
        sys.exit(1)
    convert_pdf_to_word_v18(sys.argv[1], sys.argv[2])

