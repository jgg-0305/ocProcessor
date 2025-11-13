function ocrProcessor()
    % --- 1. 파일 선택 ---
    [filename, pathname] = uigetfile({'*.jpg;*.png;*.pdf', '이미지 및 PDF 파일 (*.jpg, *.png, *.pdf)';
                                      '*.jpg', 'JPEG 이미지 (*.jpg)';
                                      '*.png', 'PNG 이미지 (*.png)';
                                      '*.pdf', 'PDF 문서 (*.pdf)'}, ...
                                     '처리할 파일 선택');
    if isequal(filename, 0)
        disp('파일 선택이 취소되었습니다.'); return;
    end
    fullFilePath = fullfile(pathname, filename);
    [~, name, ext] = fileparts(fullFilePath);
    fprintf('선택된 파일: %s\n', fullFilePath);
    
    docContent = struct('type', {}, 'data', {});
    tempImageFiles = {}; 

    % --- 2. 파일 타입별 처리 ---
    try
        switch lower(ext)
            case {'.jpg', '.png'}
                % === 이미지 파일 처리 (OCR) ===
                fprintf('이미지 파일 OCR 처리 시작...\n');
                img = imread(fullFilePath);
                try
                    ocrResult = ocr(img, 'Language', 'Korean');
                    docContent(1).type = 'text';
                    docContent(1).data = ocrResult.Text;
                    fprintf('이미지 OCR 완료.\n');
                catch ME
                    if strcmp(ME.identifier, 'vision:ocr:languageDataNotFound')
                        warning('Korean 언어 데이터가 없거나 설치되지 않았습니다. 영어로 OCR을 시도합니다.');
                        ocrResult = ocr(img);
                        docContent(1).type = 'text';
                        docContent(1).data = ocrResult.Text;
                    else
                        rethrow(ME);
                    end
                end

            case '.pdf'
                % === PDF 파일 처리 (페이지별 하이브리드) ===
                fprintf('PDF 파일 처리 시작...\n');
                
                % PDFBox 라이브러리 로드
                pdfboxJarPath = fullfile(fileparts(mfilename('fullpath')), 'pdfbox-app-3.0.2.jar');
                if ~exist(pdfboxJarPath, 'file')
                    error('PDFBox JAR 파일이 같은 폴더에 없거나 파일명이 다릅니다. %s 경로를 확인하세요.', pdfboxJarPath);
                end
                javaaddpath(pdfboxJarPath);

                % Java 클래스 임포트
                import org.apache.pdfbox.pdmodel.PDDocument;
                import org.apache.pdfbox.text.PDFTextStripper;
                import org.apache.pdfbox.rendering.PDFRenderer;
                import javax.imageio.ImageIO;
                import java.io.File;
                import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject; %  삽입된 이미지용 클래스
                import org.apache.pdfbox.cos.COSName;

                pdfDoc = PDDocument.load(java.io.File(fullFilePath));
                renderer = PDFRenderer(pdfDoc);
                stripper = PDFTextStripper();
                
                numPages = pdfDoc.getNumberOfPages();
                fprintf('총 %d 페이지의 PDF를 페이지별로 처리합니다...\n', numPages);

                for i = 0:numPages-1
                    currentPage = i + 1;
                    fprintf('  페이지 %d/%d 처리 중...\n', currentPage, numPages);
                    
                    % 현재 페이지만 텍스트 추출 시도
                    stripper.setStartPage(currentPage);
                    stripper.setEndPage(currentPage);
                    pageText = string(stripper.getText(pdfDoc));
                    
                    % 페이지별로 텍스트/이미지 판단
                    if strlength(pageText) < 50 % 50자 미만이면 '이미지 페이지'로 간주
                        fprintf('    -> (이미지 페이지로 간주) 페이지를 이미지로 렌더링합니다.\n');
                        
                        % 페이지를 이미지로 렌더링 (300 DPI)
                        bufferedImage = renderer.renderImageWithDPI(i, 300);
                        
                        % 임시 이미지 파일로 저장
                        tempImgPath = fullfile(tempdir, [name, '_page_', num2str(currentPage), '.png']);
                        tempImgFile = java.io.File(tempImgPath);
                        ImageIO.write(bufferedImage, 'png', tempImgFile);
                        
                        % 결과 구조체에 'image' 타입과 '파일 경로' 저장
                        docContent(end+1).type = 'image';
                        docContent(end).data = tempImgPath;
                        tempImageFiles{end+1} = tempImgPath; % 삭제 목록에 추가
                        
                    else
                        % 50자 이상이면 '텍스트 페이지'로 간주
                        fprintf('    -> (텍스트 페이지로 간주) 텍스트 및 삽입된 이미지 추출...\n');
                        
                        % 1. 텍스트 저장
                        docContent(end+1).type = 'text';
                        docContent(end).data = pageText;
                        
                        % 2. 삽입된 이미지 추출
                        page = pdfDoc.getPage(i);
                        resources = page.getResources();
                        cosNames = resources.getXObjectNames().iterator();
                        imgCounter = 0;
                        
                        while cosNames.hasNext()
                            cosName = cosNames.next();
                            if ~isempty(cosName)
                                xobject = resources.getXObject(cosName);
                                % PDImageXObject 타입인지 확인
                                if isa(xobject, 'org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject')
                                    imgCounter = imgCounter + 1;
                                    fprintf('    -> ... 삽입된 이미지 %d 발견 및 저장 ...\n', imgCounter);
                                    
                                    pdImage = xobject;
                                    bufferedImage = pdImage.getOpaqueImage(); % 더 안정적인 이미지 추출
                                    
                                    % 임시 파일로 저장
                                    tempImgPath = fullfile(tempdir, [name, '_page_', num2str(currentPage), '_img_', num2str(imgCounter), '.png']);
                                    tempImgFile = java.io.File(tempImgPath);
                                    ImageIO.write(bufferedImage, 'png', tempImgFile);
                                    
                                    % 결과 구조체에 'image' 타입과 '파일 경로' 저장
                                    docContent(end+1).type = 'image';
                                    docContent(end).data = tempImgPath;
                                    tempImageFiles{end+1} = tempImgPath; % 삭제 목록에 추가
                                end
                            end
                        end
                    end
                end
                
                pdfDoc.close();

            otherwise
                disp('지원하지 않는 파일 형식입니다. .jpg, .png, .pdf 파일만 지원합니다.');
                return;
        end

    catch e
        disp('파일 처리 중 오류 발생:');
        disp(e.message);
        if exist('pdfDoc', 'var') && ~isempty(pdfDoc) && ~pdfDoc.isClosed()
            pdfDoc.close();
        end
        % 임시 파일 정리
        cleanupTempFiles(tempImageFiles);
        return;
    end

    % --- 3. 결과 출력 ---
    fprintf('\n--- 처리 결과 (요약) --- \n');
    for i = 1:numel(docContent)
        fprintf('  파트 %d: %s (%d 바이트)\n', i, docContent(i).type, strlength(docContent(i).data));
    end

    % --- 4. Word 파일로 저장 ---
    saveChoice = input('\n처리된 결과를 Word 파일로 저장하시겠습니까? (y/n): ', 's');
    if lower(saveChoice) ~= 'y'
        fprintf('파일 저장을 건너뜁니다.\n');
        cleanupTempFiles(tempImageFiles); % 임시 파일 정리
        return;
    end

    outputFileNameWord = fullfile(pathname, [name, '_processed.docx']);
    if ~ispc || ~isWordInstalled()
        warning('Word 파일 저장은 Windows + MS Word 환경에서만 지원됩니다.');
        cleanupTempFiles(tempImageFiles); % 임시 파일 정리
        return;
    end
    
    try
        fprintf('Word 파일을 저장하는 중입니다 (Word가 백그라운드에서 실행됩니다)...\n');
        wordApp = actxserver('Word.Application');
        wordApp.Visible = false;
        document = wordApp.Documents.Add;
        selection = wordApp.Selection;
        
        % docContent 구조체를 순회하며 저장
        for i = 1:numel(docContent)
            contentType = docContent(i).type;
            contentData = docContent(i).data;
            
            if strcmp(contentType, 'text')
                % 텍스트 삽입
                selection.TypeText(contentData);
                selection.TypeParagraph(); % 새 문단
            
            elseif strcmp(contentType, 'image')
                % 이미지 삽입
                try
                    selection.InlineShapes.AddPicture(contentData);
                    selection.TypeParagraph(); % 새 문단
                catch imgE
                   fprintf('    -> 경고: Word에 이미지 삽입 실패 (%s): %s\n', contentData, imgE.message);
                end
            end
        end
        
        document.SaveAs2(outputFileNameWord);
        document.Close(false);
        wordApp.Quit;
        release(document);
        release(wordApp);
        
        fprintf('결과가 다음 Word 파일에 저장되었습니다: %s\n', outputFileNameWord);
        
    catch e
        fprintf('Word 파일 저장 중 오류 발생:\n');
        disp(e.message);
        if exist('wordApp', 'var')
            wordApp.Quit;
            release(wordApp);
        end
    end
    
    % --- 5. 임시 파일 정리 ---
    cleanupTempFiles(tempImageFiles);

end
% === ocrProcessor 메인 함수 끝 ===


% --- 헬퍼 함수 1: Word 설치 확인 ---
function installed = isWordInstalled()
    installed = true;
    try
        tempWordApp = actxserver('Word.Application');
        tempWordApp.Quit;
        release(tempWordApp);
    catch
        installed = false;
    end
end

% --- 헬퍼 함수 2: 임시 이미지 파일 삭제 ---
function cleanupTempFiles(fileList)
    if isempty(fileList)
        return;
    end
    fprintf('임시 이미지 파일을 정리합니다...\n');
    for i = 1:numel(fileList)
        if exist(fileList{i}, 'file')
            try
                delete(fileList{i});
            catch ME
                warning('임시 파일 삭제 실패 (%s): %s', fileList{i}, ME.message);
            end
        end
    end
end