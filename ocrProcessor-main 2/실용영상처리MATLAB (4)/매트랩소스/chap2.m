%% 산술 연산 예(p52)

i = imread('Lenna.jpg'); % 영상을 읽음
i1 = imadd(i,50); % 화소별 덧셈 연산
i2 = imsubtract(i,50); % 화소별 뺄셈 연산
i3 = immultiply(i,2); % 화소별 곱셈 연산
i4 = imdivide(i,2); % 화소별 나눗셈 연산
subplot(2,3,1); imshow(i),title('< 원본 >','Fontweight','bold');
subplot(2,3,2); imshow(i1),title('< Add( +50) >','Fontweight','bold');
subplot(2,3,3); imshow(i2),title('< Subtract( -50) >','Fontweight','bold');
subplot(2,3,4); imshow(i3),title('< Multiply( x2) >','Fontweight','bold');
subplot(2,3,5); imshow(i4),title('< Divide( ÷2) >','Fontweight','bold');

%% 화소단위 산술 연산에 대한 히스토그램 프로그램(p54)

i = imread('Lenna.jpg'); % 영상을 불러옴
i1 = imadd(i,50); % 화소별 덧셈 연산
i2 = imsubtract(i,50); % 화소별 뺄셈 연산
i3 = immultiply(i,1.2); % 화소별 나눗셈 연산
i4 = imdivide(i,1.2); % 화소별 곱셈 연산
subplot(2,3,1); imhist(i),title('< 원본 >','Fontweight','bold');
subplot(2,3,2); imhist(i1),title('< Add( +50) >','Fontweight','bold');
subplot(2,3,3); imhist(i2),title('< Subtract( -50) >','Fontweight','bold');
subplot(2,3,4); imhist(i3),title(' < Multiply( x2) >','Fontweight','bold');
subplot(2,3,5); imhist(i4),title('< Divide( ÷2) >','Fontweight','bold');

%% 히스토그램 평활화 프로그램 ( p56) 

i = imread('Lenna.jpg'); % 영상을 불러옴
i1= histeq(i); % 평활화
subplot(2,3,1); imhist(i),title('< 원본 >','Fontweight','bold');
subplot(2,3,2); imhist(i1),title('< Add( +50) >','Fontweight','bold');
subplot(2,3,3); imhist(i2),title('< Subtract( -50) >','Fontweight','bold');
subplot(2,3,4); imhist(i3),title(' < Multiply( x2) >','Fontweight','bold');
subplot(2,3,5); imhist(i4),title('< Divide( ÷2) >','Fontweight','bold');

%% Lenna 영상 스트레칭 및 스트레칭 함수(p 57)

i=imread('Lenna.jpg');
i1=imadjust(i,[ ],[ ],0.5); % 스트레칭
subplot(1,3,1); imshow(i),title('< 원본 >','Fontweight','bold');
subplot(1,3,2); imshow(i1),title('< 스트레칭 >','Fontweight','bold');
subplot(1,3,3); plot(i,i1,'.');
axis tight ,title('< 스트레칭 함수 >','Fontweight','bold');

%% Lenna 영상의 이진화(p59) 

i=imread('Lenna.jpg');
i1=(i>=128); % 임계값 128 가정
subplot(2,2,1); imshow(i),title('< 원본 >','Fontweight','bold');
subplot(2,2,2); imshow(i1),title('< 임계값 128 >','Fontweight','bold');
subplot(2,2,3); imhist(i),title('< 원본의 Histogram >','Fontweight','bold');
subplot(2,2,4); imhist(i1),title('< 임계값 Histogram >','Fontweight','bold');

%% 두 영상의 덧셈(p 60)

i=imread('Lenna.jpg'); % 두 영상을 불러옴
i1=imread('mask.pgm');
i2= i+i1; % 두 영상의 값을 더함
subplot(1,3,1); imshow(i),title('< 원본1 >','Fontweight','bold');
subplot(1,3,2); imshow(i1),title('< 원본2 >','Fontweight','bold');
subplot(1,3,3); imshow(i2),title('< 덧셈 영상 >','Fontweight','bold');

%% 두 영상의 뺄셈 (p61)

i=imread('gam1.pgm');
i1=imread('gam2.pgm');
i2=imread('gam3.pgm');
i3=imread('gam4.pgm');
s1= i-i1; % 두 영상의 값을 뺌
s2= i2-i3; % 두 영상의 값을 뺌
subplot(2,3,1); imshow(i),title('< 원본1 >','Fontweight','bold');
subplot(2,3,2); imshow(i1),title('< 원본2 >','Fontweight','bold');
subplot(2,3,3); imshow(s1),title('< 뺄셈 영상1 >','Fontweight','bold');
subplot(2,3,4); imshow(i2),title('< 원본3 >','Fontweight','bold');
subplot(2,3,5); imshow(i3),title('< 원본4 >','Fontweight','bold');
subplot(2,3,6); imshow(s2),title('< 뺄셈 영상2 >','Fontweight','bold');

%% 영상의 선형조합 프로그램(p62) 

 I = imread('cameraman.tif'); % 영상을 불러 옴
 J = imlincomb(2,I); %
subplot(1,2,1); imshow(I),title('< 원본 >','Fontweight','bold');
subplot(1,2,2); imshow(J),title('< 선형조합 >','Fontweight','bold');

%% 두 영상의 선형조합2 프로그램(p63)

I = imread('cameraman.tif'); % 영상을 불러 옴
J = uint8(filter2(fspecial('gaussian'), I)); % 가우시안 필터를 적용한 영상
K = imlincomb(1,I,-1,J,128); % K(r,c) = I(r,c) - J(r,c) + 128
subplot(1,3,1); imshow(I),title('< 원본1 >','Fontweight','bold');
subplot(1,3,2); imshow(J),title('< 필터영상>','Fontweight','bold');
subplot(1,3,3); imshow(K),title('< 두 영상의 선형조합 >','Fontweight','bold');

%% 배열의 보수화 ( p64)

 X = uint8([ 255 10 75; 44 225 100]); % 배열을 생성
 X2 = imcomplement(X); % 보수화
 
%% 이진영상의 보수화 (p 64)
 
bw = imread('text.png'); % 이진영상을 불러옴
bw2 = imcomplement(bw); % 이진영상의 보수화
subplot(1,2,1),imshow(bw);
subplot(1,2,2),imshow(bw2);

%% intensity 영상의 보수화( p65)

 I = imread('glass.png'); % intensity 영상을 불러옴
 J = imcomplement(I); % intensity 영상의 보수화
 subplot(1,2,1),imshow(I);
 subplot(1,2,2),imshow(J);
 
%% 영상의 절대차분(p 66) 
 
I = imread('cameraman.tif'); % 영상을 불러옴
J = uint8(filter2(fspecial('gaussian'), I)); % 가우시안 필터영상 생성
K = imabsdiff(I,J); % 영상 I와 영상 J의 절대차분
subplot(1,3,1),imshow(I);
subplot(1,3,2),imshow(J);
subplot(1,3,3),imshow(K,[]);





 
 
 
 
 
 
 
 
 






