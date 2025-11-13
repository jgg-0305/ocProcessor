function run_converter()
    [filename, pathname] = uigetfile({'*.pdf','PDF 파일 (*.pdf)'}, 'PDF 파일 선택');
    if isequal(filename,0)
        disp('취소됨'); return;
    end
    fullFilePath = fullfile(pathname, filename);
    [~, name, ~] = fileparts(fullFilePath);
    outputFileNameWord = fullfile(pathname, [name, '_v5.docx']);

    pe = pyenv;
    pythonExe = string(pe.Executable);
    pythonScriptPath = fullfile(fileparts(mfilename('fullpath')), 'pdf_hybrid_converter.py');

    % 슬래시 이스케이프
    pythonExe = strrep(pythonExe, '\', '\\');
    pythonScriptPath = strrep(pythonScriptPath, '\', '\\');
    fullFilePath = strrep(fullFilePath, '\', '\\');
    outputFileNameWord = strrep(outputFileNameWord, '\', '\\');

    command = sprintf('chcp 65001 > NUL & "%s" "%s" "%s" "%s"', ...
                      pythonExe, pythonScriptPath, fullFilePath, outputFileNameWord);

    disp('Python 변환 실행 중...');
    [status, cmdout] = system(command, '-echo');

    if status == 0
        disp([' 변환 완료: ', outputFileNameWord]);
    else
        disp(' 변환 중 오류 발생:');
        disp(cmdout);
    end
end
