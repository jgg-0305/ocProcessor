import tkinter as tk
from tkinter import filedialog
import os
import sys
import subprocess

def run_converter_py():
    """
    MATLAB의 run_converter.m 스크립트 기능을 Python으로 대체합니다.
    1. GUI로 PDF 파일 선택
    2. pdf_hybrid_converter.py 스크립트 실행
    3. 결과 출력
    """
    
    # 1. GUI 파일 탐색기 설정 (MATLAB의 uigetfile)
    root = tk.Tk()
    root.withdraw() # 메인 tkinter 창 숨기기
    
    print("PDF 파일 선택 창을 엽니다...")
    full_file_path = filedialog.askopenfilename(
        title="PDF 파일 선택",
        filetypes=(("PDF 파일", "*.pdf"), ("모든 파일", "*.*"))
    )
    
    # 2. 사용자가 '취소'를 눌렀는지 확인 (MATLAB의 isequal(filename,0))
    if not full_file_path:
        print("취소됨.")
        return

    # 3. 입/출력 경로 생성 (MATLAB의 fileparts 및 fullfile)
    pathname = os.path.dirname(full_file_path)
    filename = os.path.basename(full_file_path)
    name, _ = os.path.splitext(filename)
    
    output_file_name_word = os.path.join(pathname, f"{name}_v5.docx")

    # 4. 실행할 Python 스크립트 경로 설정
    # (MATLAB의 pe.Executable -> sys.executable)
    python_exe = sys.executable  # 현재 사용 중인 Python 인터프리터 경로
    
    # (MATLAB의 mfilename('fullpath') -> __file__)
    # 이 스크립트(run_converter.py)가 있는 폴더
    script_dir = os.path.dirname(os.path.abspath(__file__)) 
    python_script_path = os.path.join(script_dir, "pdf_hybrid_converter.py")

    # 5. 시스템 명령어 생성 (MATLAB의 sprintf)
    # [중요] list 형태로 전달하면 경로에 공백이 있어도 안전하게 처리됩니다.
    command = [
        python_exe,
        python_script_path,
        full_file_path,
        output_file_name_word
    ]

    print("Python 변환 실행 중...")
    print(f"명령어: {' '.join(command)}")

    # 6. 스크립트 실행 (MATLAB의 system(command, '-echo'))
    # text=True, encoding='utf-8' : MATLAB의 'chcp 65001'과 유사한 효과 (출력 인코딩)
    result = subprocess.run(
        command, 
        capture_output=True, 
        text=True, 
        encoding='utf-8',
        errors='ignore' # 인코딩 오류 시 무시
    )

    # 7. 결과 출력 (MATLAB의 disp)
    if result.returncode == 0:
        print(f"\n변환 완료: {output_file_name_word}")
        print("--- 스크립트 출력 ---")
        print(result.stdout)
    else:
        print("\n[!] 변환 중 오류 발생:")
        print("--- STDOUT (일반 출력) ---")
        print(result.stdout)
        print("--- STDERR (오류 출력) ---")
        print(result.stderr)

if __name__ == "__main__":
    run_converter_py()