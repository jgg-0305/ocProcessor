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


function run_converter_with_check()
% 환경 점검 + 시간 측정 + 로그 기록까지 수행하는 확장 런처
    fprintf('=== PDF -> Word 변환 도구 (MATLAB wrapper) ===\n');

    info = check_python_environment();
    if ~info.ok
        fprintf('\n[경고] 필수 Python 모듈이 없어서 변환이 실패할 수 있습니다.\n');
        fprintf('       fitz(pymupdf) / python-docx 를 먼저 설치해 주세요.\n');
    end

    choice = questdlg('단일 파일만 변환할까요, 폴더 전체를 변환할까요?', ...
                      '변환 모드 선택', ...
                      '단일 파일','폴더 전체','취소','단일 파일');
    if strcmp(choice,'취소')
        disp('사용자에 의해 취소되었습니다.');
        return;
    end

    tStart = tic;
    write_log('--- 변환 시작 ---');

    try
        switch choice
            case '단일 파일'
                run_converter(); 

            case '폴더 전체'
                batch_convert_folder();
        end

        elapsed = toc(tStart);
        msg = sprintf('변환 작업 전체 완료 (%.2f 초 소요)', elapsed);
        fprintf('%s\n', msg);
        write_log(msg);

    catch ME
        warning('변환 중 오류 발생: %s', ME.message);
        write_log(['[오류] ' ME.message]);
    end
end

function info = check_python_environment()
% MATLAB-Python 연동 및 필수 모듈 존재 여부를 점검
    info = struct('ok',false,'pythonExe','', 'hasFitz',false,'hasDocx',false);

    fprintf('\n[환경 점검] MATLAB-Python 연동 상태 확인 중...\n');
    try
        pe = pyenv;
        info.pythonExe = char(pe.Executable);
        fprintf(' - Python 실행 파일: %s\n', info.pythonExe);
    catch
        warning('Python 환경(pyenv)을 찾을 수 없습니다.');
        return;
    end

    % fitz(pymupdf) 모듈 확인
    try
        py.importlib.import_module('fitz');
        info.hasFitz = true;
        fprintf(' - pymupdf(fitz) 모듈: OK\n');
    catch
        warning('pymupdf(fitz) 모듈이 설치되어 있지 않습니다.');
    end

    % python-docx 모듈 확인
    try
        py.importlib.import_module('docx');
        info.hasDocx = true;
        fprintf(' - python-docx(docx) 모듈: OK\n');
    catch
        warning('python-docx(docx) 모듈이 설치되어 있지 않습니다.');
    end

    info.ok = info.hasFitz && info.hasDocx;
    if info.ok
        fprintf(' => 환경 점검 완료. 변환을 진행할 수 있습니다.\n');
    else
        fprintf(' => 일부 모듈이 없지만, 변환을 시도할 수는 있습니다.\n');
    end
end

function batch_convert_folder()
% 선택한 폴더 안의 모든 PDF를 한 번에 변환
    fprintf('\n[배치 변환] 폴더 전체 PDF를 변환합니다.\n');
    folder = uigetdir(pwd,'PDF가 들어있는 폴더 선택');
    if isequal(folder,0)
        disp('취소됨');
        return;
    end

    files = dir(fullfile(folder,'*.pdf'));
    if isempty(files)
        disp('선택한 폴더에 PDF 파일이 없습니다.');
        return;
    end

    fprintf('총 %d개의 PDF를 변환합니다.\n', numel(files));
    write_log(sprintf('--- 배치 변환 시작 (%d개 파일) ---', numel(files)));

    for k = 1:numel(files)
        fprintf('\n(%d / %d) %s 변환 중...\n', k, numel(files), files(k).name);
        fullPath = fullfile(folder, files(k).name);
        try
            run_converter_single(fullPath);
            write_log(['OK : ' files(k).name]);
        catch ME
            warning('파일 변환 중 오류: %s', ME.message);
            write_log(['FAIL : ' files(k).name ' - ' ME.message]);
        end
    end

    write_log('--- 배치 변환 종료 ---');
end

function run_converter_single(fullFilePath)
% 특정 PDF 경로 하나를 받아서 변환 (배치용)
    [pathname, name, ext] = fileparts(fullFilePath);
    if ~strcmpi(ext,'.pdf')
        error('PDF 파일이 아닙니다: %s', fullFilePath);
    end

    pe = pyenv;
    pythonExe = string(pe.Executable);
    pythonScriptPath = fullfile(fileparts(mfilename('fullpath')), 'pdf_hybrid_converter.py');
    outputFileNameWord = fullfile(pathname, [name, '_v5.docx']);

    pythonExe        = strrep(pythonExe,        '\', '\\');
    pythonScriptPath = strrep(pythonScriptPath, '\', '\\');
    fullFilePathEsc  = strrep(fullFilePath,     '\', '\\');
    outputFileNameWord = strrep(outputFileNameWord, '\', '\\');

    command = sprintf('chcp 65001 > NUL & "%s" "%s" "%s" "%s"', ...
                      pythonExe, pythonScriptPath, fullFilePathEsc, outputFileNameWord);

    fprintf('  -> 시스템 명령: %s\n', command);
    [status, cmdout] = system(command, '-echo');

    if status ~= 0
        error('시스템 명령 실행 오류: %s', cmdout);
    else
        fprintf('  -> %s 변환 완료.\n', outputFileNameWord);
    end
end

function write_log(msg)
% 변환 작업 로그를 converter_log.txt에 기록
    logFile = fullfile(fileparts(mfilename('fullpath')), 'converter_log.txt');
    fid = fopen(logFile, 'a', 'n', 'UTF-8');
    if fid == -1
        warning('로그 파일을 열 수 없습니다.');
        return;
    end
    t = datestr(now,'yyyy-mm-dd HH:MM:SS');
    fprintf(fid,'[%s] %s\n', t, msg);
    fclose(fid);
end