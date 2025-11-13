# pdf_hybrid_converter_v9_kor.py
# 하이브리드 PDF->DOCX v9 (드로잉 + 임베디드 이미지 전략)
#
# 전략:
#  - 1. 벡터 드로잉 영역과 2. 임베디드 비트맵 이미지를 *모두* 찾습니다.
#  - 1. get_drawing_regions(): fitz.get_drawings()를 사용해 벡터 클러스터를 찾아 렌더링합니다 (v8 방식).
#  - 2. get_embedded_images(): fitz.get_images()를 사용해 기존 비트맵 이미지를 추출합니다.
#  - 두 목록을 `all_graphic_elements`로 결합합니다.
#  - 이 그래픽 영역 내부에 있는 텍스트 블록은 필터링합니다.
#  - 모든 요소(텍스트 + 이미지)를 y축 순서대로 DOCX에 삽입합니다.
#
# 사용법: python pdf_hybrid_converter_v9_kor.py input.pdf output.docx
#
import sys, os, io, math, traceback
import fitz  # pymupdf
import docx
from docx.shared import Inches, Pt

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

def get_drawing_regions(page, dpi=300, min_area_pt=500, merge_margin=10):
    """
    (v8) fitz.get_drawings()를 사용해 벡터 드로잉 영역(차트, 표 등)을
    클러스터링하여 감지합니다.
    반환값: dict 리스트 [{"bbox": fitz.IRect, "data": image_bytes, "source": "drawing"}]
    """
    drawings = page.get_drawings()
    if not drawings:
        return []

    # 1. 모든 개별 경로(path)의 바운딩 박스를 가져옵니다.
    paths = [d["rect"] for d in drawings if d["rect"].get_area() > 0]
    if not paths:
        return []

    # 2. 가깝거나 교차하는 사각형들을 클러스터링(병합)합니다.
    rects = list(paths)
    merged = True
    while merged:
        merged = False
        i = 0
        while i < len(rects):
            j = i + 1
            while j < len(rects):
                # 약간의 여백(margin)을 두고 교차 검사
                r1_inflated = rects[i].irect + (-merge_margin, -merge_margin, merge_margin, merge_margin)
                if r1_inflated.intersects(rects[j]):
                    # rects[i]와 rects[j]를 병합
                    rects[i] = rects[i] | rects[j]
                    # rects[j] 제거
                    rects.pop(j)
                    merged = True # 병합이 발생했음을 알림
                else:
                    j += 1
            i += 1
    
    # 3. 최종 클러스터(사각형)들을 각각 이미지로 렌더링합니다.
    final_regions = []
    mat = fitz.Matrix(dpi/72.0, dpi/72.0)
    
    for rect in rects:
        # 너무 작은 클러스터는 무시
        if rect.get_area() < min_area_pt:
            continue
            
        # 캡처 영역에 약간의 패딩(여백) 추가
        clip_rect = (rect.irect + (-5, -5, 5, 5)).normalize()
        # 페이지 경계 안에 있도록 보장
        clip_rect = fitz.Rect.intersect(clip_rect, page.rect)
        
        if clip_rect.is_empty or clip_rect.is_infinite:
            continue
            
        try:
            # get_pixmap의 clip 인자에는 float 타입의 Rect가 필요
            clip_rect_float = fitz.Rect(clip_rect)
            pix = page.get_pixmap(matrix=mat, clip=clip_rect_float, alpha=False)
            # 다이어그램의 손실 없는 렌더링을 위해 PNG 사용
            img_bytes = pix.tobytes("png")
            final_regions.append({
                "bbox": clip_rect.irect, # IRect(정수형) 버전으로 bbox 저장
                "data": img_bytes, 
                "source": "drawing_render"
            })
        except Exception as e:
            print(f"  ⚠ 드로잉 렌더링 오류 (clip={clip_rect}): {e}")

    return final_regions

def get_embedded_images(page, doc):
    """
    (v9) page.get_images()를 사용해 임베디드 비트맵 이미지를 추출합니다.
    반환값: dict 리스트 [{"bbox": fitz.IRect, "data": image_bytes, "source": "embedded"}]
    """
    img_list = page.get_images(full=True)
    final_regions = []

    for img_info in img_list:
        xref = img_info[0] # 이미지의 고유 ID
        if xref == 0:
            continue
            
        try:
            # 페이지에서 이미지의 바운딩 박스(위치) 가져오기
            bbox = page.get_image_bbox(img_info)
            if not bbox.is_valid or bbox.is_empty:
                continue

            # 원본 이미지 바이트 추출
            img_data = doc.extract_image(xref)
            img_bytes = img_data["image"]
            
            final_regions.append({
                "bbox": bbox.irect, # IRect(정수형) 버전으로 bbox 저장
                "data": img_bytes, 
                "source": "embedded_image"
            })
        except Exception as e:
            print(f"  ⚠ 임베디드 이미지 추출 오류 (xref={xref}): {e}")
            
    return final_regions

def convert_pdf_to_word_v9(pdf_path, word_path, dpi=300, max_width_in=6.5, debug_dir="./debug_v9"):
    print(f"--- PDF→Word v9 (하이브리드) 시작 ---")
    print(f"입력: {pdf_path}")
    pdf = fitz.open(pdf_path)
    doc = docx.Document()
    pages = pdf.page_count
    print(f"총 페이지: {pages}")

    for pnum in range(pages):
        page = pdf.load_page(pnum)
        print(f"\n페이지 {pnum+1}/{pages} 처리중...")
        
        # 1. 모든 그래픽 영역 감지
        # (v8) 벡터 드로잉 찾기
        drawing_regions = get_drawing_regions(page, dpi=dpi, merge_margin=10)
        print(f"  드로잉(벡터) 영역 감지: {len(drawing_regions)}")
        
        # (v9) 임베디드 비트맵 이미지 찾기
        image_regions = get_embedded_images(page, pdf) # 메인 doc 객체 전달
        print(f"  임베디드(비트맵) 이미지 감지: {len(image_regions)}")

        all_graphic_elements = drawing_regions + image_regions
        all_graphic_rects = [r["bbox"] for r in all_graphic_elements] # IRect (정수형 사각형) 목록

        # 2. 모든 텍스트 블록 가져오기
        text_blocks = page.get_text("blocks")  # (x0,y0,x1,y1,text,...)

        # 3. 요소 목록 생성 (텍스트 + 그래픽)
        elements = []

        # 텍스트 블록 추가 (그래픽 영역 내부에 있는 텍스트는 *필터링*)
        for b in text_blocks:
            x0, y0, x1, y1 = b[:4]
            txt = b[4].strip()
            if not txt:
                continue
            
            block_rect = fitz.Rect(x0, y0, x1, y1)
            is_inside_graphic = False
            
            # 이 텍스트 블록이 그래픽 영역 내부에 완전히 포함되는지 확인
            for graphic_rect in all_graphic_rects: # graphic_rect는 IRect
                if (graphic_rect + (-2,-2,2,2)).contains(block_rect): # 약간의 여유분
                    is_inside_graphic = True
                    # print(f"  텍스트 필터링: '{txt[:20]}...' (그림 영역에 포함됨)")
                    break
            
            if not is_inside_graphic:
                elements.append({"type":"text", "bbox": block_rect, "data": txt})

        # 모든 그래픽 요소를 목록에 추가
        os.makedirs(debug_dir, exist_ok=True)
        for idx, r in enumerate(all_graphic_elements):
            debug_path = os.path.join(debug_dir, f"page{pnum+1}_graphic{idx+1}_{r['source']}.png")
            try:
                # 디버그용 사본 저장
                with open(debug_path, "wb") as f_crop:
                    f_crop.write(r["data"])
                
                r.update({
                    "type": "image",
                    "debug_path": debug_path
                })
                elements.append(r)
                
            except Exception as e:
                print(f"  ⚠ 디버그 이미지 저장 실패: {e}")

        # 4. 모든 요소를 y축(세로) 위치, 그 다음 x축(가로) 위치로 정렬
        elements.sort(key=lambda el:(round(el["bbox"][1],1), el["bbox"][0]))

        # 5. 순서대로 DOCX에 삽입
        for el in elements:
            if el["type"] == "text":
                # 줄바꿈 유지
                for line in el["data"].splitlines():
                    doc.add_paragraph(line)
            
            elif el["type"] == "image":
                x0, y0, x1, y1 = el["bbox"]
                width_pt = x1 - x0
                # 페이지 최대 너비 제한
                width_in = clamp(width_pt / 72.0, 0.5, max_width_in)
                try:
                    para = doc.add_paragraph()
                    run = para.add_run()
                    
                    img_io = None
                    # docx 삽입을 위해 바이트에서 이미지 유형 확인
                    if el["data"].startswith(b'\x89PNG'):
                        img_io = io.BytesIO(el["data"])
                    else:
                        # 다른 포맷(PDF 네이티브 포맷 등)을 PNG로 변환 시도
                        try:
                            pil_img = Image.open(io.BytesIO(el["data"]))
                            img_io = io.BytesIO()
                            pil_img.save(img_io, format='PNG')
                            img_io.seek(0)
                        except Exception:
                            # PIL 변환 실패 시 원본 바이트 사용 (docx에서 실패할 수 있음)
                            print(f"  ⚠ PIL 변환 실패: {el['debug_path']}. 원본 바이트 시도.")
                            img_io = io.BytesIO(el["data"])

                    run.add_picture(img_io, width=Inches(width_in))
                    para.space_after = Pt(4) # 단락 뒤 간격
                except Exception as e:
                    print(f"  ⚠ 이미지 삽입 실패 ({el.get('debug_path','?')}): {e}")

        if pnum < pages - 1:
            doc.add_page_break()

    doc.save(word_path)
    print(f"\n완료: {word_path}")
    print(f"디버그 이미지들은 '{os.path.abspath(debug_dir)}'에 저장됩니다 (확인하세요).")

# --- v9.1: 이미지 형식 변환을 위해 PIL 의존성 추가 ---
# pymupdf가 추출할 수 있는 non-PNG/JPG 포맷 변환에 PIL 필요
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
        print("Usage: python pdf_hybrid_converter_v9_kor.py <input.pdf> <output.docx>")
        sys.exit(1)
    
    # 디버그 디렉토리 설정 (옵션)
    debug_path = "./debug_v9"
    if len(sys.argv) > 3:
        debug_path = sys.argv[3]
        
    convert_pdf_to_word_v9(pdf_path=sys.argv[1], 
                           word_path=sys.argv[2], 
                           debug_dir=debug_path)