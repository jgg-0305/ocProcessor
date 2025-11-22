# pdf_hybrid_converter_v18_kor.py
# 하이브리드 PDF->DOCX v18 (이미지 크기 원본 반영)
#
# [주요 기능 및 알고리즘 요약]
# 1. 하이브리드 객체 추출: 텍스트, 이미지, 표, 도형(Box)을 각각 별도 엔진으로 추출
# 2. 공간 분석(Spatial Analysis): 요소들의 좌표(BBox)를 분석하여 중복 제거 및 배치 순서 결정
# 3. 2단 레이아웃 감지: 문서 중앙을 기준으로 좌/우 텍스트 블록을 분리하여 Word 표(Table)로 구조화
# 4. 동적 이미지 리사이징: PDF 내부 좌표계(Point)를 Word 단위(Inch)로 변환하여 원본 비율 유지

import sys, os, io
import fitz  # PyMuPDF: PDF 처리 핵심 라이브러리
import docx  # python-docx: Word 문서 생성 라이브러리
from docx.shared import Inches, Pt
from docx.enum.text import WD_ALIGN_PARAGRAPH

# --- [설정] MATLAB/Windows 콘솔 호환성 처리 ---
# Windows나 MATLAB 환경에서 실행 시, 콘솔 인코딩 문제로 한글 출력이 깨지는 것을 방지하기 위해
# 표준 입출력(stdout/stderr)을 UTF-8로 강제 설정합니다.
try:
    import sys as _sys, io as _io
    _sys.stdout = _io.TextIOWrapper(_sys.stdout.buffer, encoding='utf-8')
    _sys.stderr = _io.TextIOWrapper(_sys.stderr.buffer, encoding='utf-8')
except Exception:
    pass

# 값 제한 함수 (이미지 크기가 너무 크거나 작지 않게 조정할 때 사용)
def clamp(x, a, b): return max(a, min(b, x))

# --- [Helper] 글머리 기호 정리 및 스타일 반환 알고리즘 ---
# 텍스트 앞의 특수문자(글머리 기호)를 감지하여 텍스트에서 제거하고,
# 대신 Word의 'List Bullet' 스타일을 적용하도록 유도합니다.
def clean_text_and_style(text):
    # 다양한 형태의 글머리 기호 목록 (유니코드 포함)
    bullets = ['•', '-', 'o', '·', '➢', '', 'v', '', '\uf0b7'] 
    clean_txt = text.strip()
    
    for b in bullets:
        if clean_txt.startswith(b):
            # 기호를 제거하고, 텍스트 본문과 스타일 이름을 반환
            return clean_txt[len(b):].strip(), 'List Bullet'
    
    # 일반 텍스트인 경우 스타일 없음(None) 반환
    return clean_txt, None

# --- [Helper] 고급 2단 레이아웃 감지 및 분할 알고리즘 ---
# PDF 페이지가 '헤더 - 2단 본문(좌/우) - 푸터' 구조인지 판별하고 블록을 분류합니다.
def detect_layout_and_split(page, text_blocks, page_width, page_height):
    center_x = page_width / 2  # 페이지의 가로 중앙 좌표
    margin = 15  # 중앙 분리선을 판단하기 위한 여유값 (오차 허용 범위)
    
    # 1. 블록을 위에서 아래로(Y축 기준) 정렬
    sorted_blocks = sorted(text_blocks, key=lambda b: b[1])
    if not sorted_blocks: return False, [], [], [], []

    # 2. "중앙을 가로지르는 블록" 찾기 (헤더나 푸터일 가능성이 높음)
    # x0(좌측)이 중앙보다 왼쪽에 있고, x1(우측)이 중앙보다 오른쪽에 있다면 1단(통짜) 블록임
    crossing_indices = []
    for i, b in enumerate(sorted_blocks):
        x0, y0, x1, y1 = b[:4]
        if x0 < center_x - margin and x1 > center_x + margin:
            crossing_indices.append(i)
            
    # 3. 본문 영역(Body) 식별
    # 중앙을 가로지르는 블록들 사이의 가장 큰 공간(Gap)이 "2단 본문"이 들어갈 영역입니다.
    if not crossing_indices:
        start_idx = 0; end_idx = len(sorted_blocks)
    else:
        gaps = []
        prev = -1
        # 통짜 블록들 사이의 인덱스 구간(Gap)을 모두 찾습니다.
        for curr in crossing_indices + [len(sorted_blocks)]:
            if curr - prev - 1 > 0: gaps.append((prev + 1, curr))
            prev = curr
        if not gaps: return False, sorted_blocks, [], [], []
        
        # 가장 긴 구간(텍스트 블록이 가장 많은 구간)을 본문으로 가정
        gaps.sort(key=lambda x: x[1] - x[0], reverse=True)
        start_idx, end_idx = gaps[0]
        # 본문 블록이 너무 적으면 2단 분리 의미가 없으므로 취소
        if (end_idx - start_idx) < 2: return False, sorted_blocks, [], [], []

    # 4. 영역 분할 (Header / Body / Footer)
    top_blocks = sorted_blocks[:start_idx]      # 상단(헤더)
    body_candidates = sorted_blocks[start_idx:end_idx] # 중간(본문 후보)
    bottom_blocks = sorted_blocks[end_idx:]     # 하단(푸터)
    
    # 5. 본문 영역 좌/우 분리 (Left / Right Column)
    left_blocks = []
    right_blocks = []
    for b in body_candidates:
        x0, y0, x1, y1 = b[:4]
        # 블록의 우측 끝이 중앙선보다 왼쪽이면 -> 왼쪽 컬럼
        if x1 < center_x + margin: left_blocks.append(b)
        # 블록의 좌측 시작이 중앙선보다 오른쪽이면 -> 오른쪽 컬럼
        elif x0 > center_x - margin: right_blocks.append(b)
        # 애매하면 왼쪽으로 배정 (안전장치)
        else: left_blocks.append(b)

    # 한쪽 컬럼이 비어있다면 2단 레이아웃이 아님
    if len(left_blocks) == 0 or len(right_blocks) == 0:
        return False, sorted_blocks, [], [], []
        
    return True, top_blocks, left_blocks, right_blocks, bottom_blocks


# --- [엔진 1] 이미지 추출 및 위치 보정 ---
def find_image_elements(page, doc):
    # 페이지 내 모든 이미지 객체 리스트 가져오기
    img_list = page.get_images(full=True)
    final = []
    for img in img_list:
        try:
            xref = img[0] # 이미지 참조 ID
            if xref == 0: continue
            
            # get_image_bbox: 이미지가 실제로 페이지 어디에 위치하는지(좌표) 확인
            # 단순히 이미지만 추출하면 위치를 알 수 없으므로 이 과정이 필수입니다.
            bbox = page.get_image_bbox(img)
            if not bbox: continue
            
            r = fitz.Rect(bbox)
            if not r.is_valid or r.is_empty: continue
            
            # 좌표(bbox)와 바이너리 데이터(data)를 딕셔너리로 저장
            final.append({"type": "image", "bbox": r.irect, "data": doc.extract_image(xref)["image"]})
        except: pass
    return final

# --- [엔진 2] 표(Table) 추출 (Hybrid) ---
def find_tables_hybrid(page):
    # PyMuPDF의 내장 표 감지 기능 사용
    tables = page.find_tables()
    final = []
    for tab in tables:
        # 유효한 영역이고 행(row)이 1개 이상인 경우만 추출
        if tab.bbox and fitz.Rect(tab.bbox).is_valid and tab.row_count > 1:
            ext = tab.extract() # 표 데이터를 2차원 리스트로 추출
            if ext: final.append({"type": "data_table", "bbox": fitz.Rect(tab.bbox).irect, "data": ext})
    return final

# --- [엔진 3] 박스(도형) 영역 감지 ---
# 텍스트 상자나 강조 박스 등을 감지하여 표처럼 처리하기 위함
def find_drawing_bboxes(page):
    drawings = page.get_drawings()
    # 일정 크기(Area > 100) 이상의 사각형만 필터링
    rects = [d["rect"] for d in drawings if d["rect"].get_area() > 100]
    unique = []
    
    # 중복 영역 제거 (IoU 알고리즘 유사 방식)
    # 이미 등록된 영역과 80% 이상 겹치면 중복으로 간주하고 건너뜀
    for r in rects:
        dup = False
        for u in unique:
            if u.intersects(r) and (u.intersect(r).get_area() / r.get_area() > 0.8):
                dup = True; break
        if not dup: unique.append(r)
        
    return [{"type": "box_table", "bbox": r.irect} for r in unique]

# --- [Helper] 이미지 삽입 함수 (크기 자동 계산 - v18 핵심) ---
def insert_image_auto_size(paragraph, img_obj):
    """ 
    PDF의 이미지 좌표(BBox) 너비를 계산하여 Word에 삽입할 때 인치(Inches) 단위로 변환합니다.
    이전 버전에서는 강제로 크기를 고정했으나, 이 함수는 원본 비율을 최대한 따릅니다.
    """
    try:
        x0, y0, x1, y1 = img_obj["bbox"]
        width_pt = x1 - x0           # PDF 단위 (Point) 너비
        width_in = width_pt / 72.0   # 1 inch = 72 points 변환 공식
        
        # Word 문서 여백을 고려하여 너무 크거나(6.5인치 초과), 너무 작으면(0.2인치 미만) 조정
        width_in = max(0.2, min(width_in, 6.5))
        
        run = paragraph.add_run()
        run.add_picture(io.BytesIO(img_obj["data"]), width=Inches(width_in))
    except Exception as e:
        print(f"  [!] 이미지 삽입 오류: {e}")

# --- 메인 변환 함수 ---
def convert_pdf_to_word_v18(pdf_path, word_path):
    print(f"--- PDF->Word v18 (이미지 크기 자동 최적화) ---")
    doc = fitz.open(pdf_path)
    docx_doc = docx.Document()
    
    for pnum, page in enumerate(doc):
        print(f"Page {pnum+1} 처리...")
        w, h = page.rect.width, page.rect.height
        
        # 1. 모든 요소(이미지, 표, 박스) 추출
        images = find_image_elements(page, doc)
        tables = find_tables_hybrid(page)
        boxes = find_drawing_bboxes(page)
        
        # 필터링용 영역 리스트 (텍스트 중복 방지용)
        filter_rects = [fitz.Rect(el["bbox"]) for el in images + tables + boxes]
        
        # 2. 텍스트 블록 추출 및 필터링
        text_blocks = []
        for b in page.get_text("blocks"):
            r = fitz.Rect(b[:4])
            is_in = False
            # 텍스트가 이미지/표/박스 영역 안에 포함되어 있다면 추출에서 제외 (중복 방지)
            for fr in filter_rects:
                if fr.contains(r): is_in = True; break
            if not is_in and b[4].strip():
                text_blocks.append(b)

        # 3. 레이아웃 분석 (2단 여부 판단)
        is_2col, top_b, left_b, right_b, bot_b = detect_layout_and_split(page, text_blocks, w, h)
        
        # 내부 함수: 텍스트 블록 리스트를 Word 문단으로 출력
        def render_blocks(block_list):
            block_list.sort(key=lambda b: b[1]) # Y축 정렬
            for b in block_list:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = docx_doc.add_paragraph(txt)
                    if style: p.style = style
        
        # 4-A. 2단 레이아웃 처리
        if is_2col:
            print("  -> 2단 레이아웃 적용")
            
            # [Header 처리]
            # 상단 영역(Header)에 속하는 이미지만 선별하여 먼저 삽입
            header_limit_y = top_b[-1][3] if top_b else 100
            top_imgs = [img for img in images if img["bbox"][1] < header_limit_y]
            
            for img in top_imgs:
                p = docx_doc.add_paragraph()
                insert_image_auto_size(p, img) # v18 개선: 크기 자동 계산
            
            render_blocks(top_b) # 헤더 텍스트 출력
            
            # [Body 처리] Word의 1행 2열 표(Table)를 생성하여 레이아웃 구현
            table = docx_doc.add_table(rows=1, cols=2)
            table.autofit = False # 칸 너비 고정 방지
            
            # 왼쪽 컬럼 채우기
            cell_l = table.cell(0, 0)
            left_b.sort(key=lambda b: b[1])
            for b in left_b:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = cell_l.add_paragraph(txt)
                    if style: p.style = style
            
            # 오른쪽 컬럼 채우기
            cell_r = table.cell(0, 1)
            right_b.sort(key=lambda b: b[1])
            for b in right_b:
                txt, style = clean_text_and_style(b[4])
                if txt:
                    p = cell_r.add_paragraph(txt)
                    if style: p.style = style
            
            # [Footer 처리]
            docx_doc.add_paragraph()
            render_blocks(bot_b)

        # 4-B. 1단 레이아웃 처리 (일반 문서)
        else:
            # 모든 요소(텍스트, 이미지, 표, 박스)를 하나의 리스트에 넣고 Y좌표(높이) 순으로 정렬
            # 이를 통해 문서의 흐름(Timeline)대로 요소를 배치함
            all_items = []
            for img in images: all_items.append({'type':'img', 'obj':img, 'y':img['bbox'][1]})
            for tab in tables: all_items.append({'type':'tab', 'obj':tab, 'y':tab['bbox'][1]})
            for box in boxes:  all_items.append({'type':'box', 'obj':box, 'y':box['bbox'][1]})
            for txt in text_blocks: all_items.append({'type':'txt', 'obj':txt, 'y':txt[1]})
            all_items.sort(key=lambda x: x['y']) # 중요: 위에서 아래로 순서 정렬
            
            for item in all_items:
                # 텍스트 처리
                if item['type'] == 'txt':
                    txt, style = clean_text_and_style(item['obj'][4])
                    if txt:
                        p = docx_doc.add_paragraph(txt)
                        if style: p.style = style
                
                # 이미지 처리
                elif item['type'] == 'img':
                    p = docx_doc.add_paragraph()
                    insert_image_auto_size(p, item['obj']) # v18 개선
                
                # 표 처리 (Word 표 생성)
                elif item['type'] == 'tab':
                    data = item['obj']['data']
                    if not data: continue
                    t = docx_doc.add_table(rows=len(data), cols=len(data[0]))
                    t.style = 'Table Grid' # 기본 격자 스타일 적용
                    for r, row in enumerate(data):
                        for c, val in enumerate(row):
                             if val: t.cell(r, c).text = str(val)
                    docx_doc.add_paragraph()
                
                # 박스(도형) 처리
                elif item['type'] == 'box':
                    # 박스 영역 내의 텍스트를 다시 추출 (클리핑)
                    box_rect = fitz.Rect(item['obj']['bbox'])
                    box_text = page.get_text(clip=box_rect).strip()
                    if not box_text: continue
                    
                    # 박스를 1x1 표로 표현하여 테두리 효과 구현
                    t = docx_doc.add_table(rows=1, cols=1)
                    t.style = 'Table Grid'
                    txt, style = clean_text_and_style(box_text)
                    cell = t.cell(0,0)
                    cell.text = ""
                    p = cell.paragraphs[0]; p.text = txt
                    if style: p.style = style
                    docx_doc.add_paragraph()

        # 페이지 나누기 (마지막 페이지 제외)
        if pnum < len(doc) - 1:
            docx_doc.add_page_break()

    docx_doc.save(word_path)
    print(f"완료: {word_path}")

# 스크립트 진입점
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python pdf_hybrid_converter_v18_kor.py <input.pdf> <output.docx>")
        sys.exit(1)
    convert_pdf_to_word_v18(sys.argv[1], sys.argv[2])
