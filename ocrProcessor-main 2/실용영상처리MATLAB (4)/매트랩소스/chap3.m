%% 산술 연산 함수 수정(p82)

clc;clear all;
x=imread('로겟발사.pgm'); % 영상을 읽음
x1=imadd(x,100); % 읽은 영상의 각 픽셀에10 0을 더함
subplot(1,2,1), imshow(x);
subplot(1,2,2), imshow(x1);

%% 히스토그램 평활화 연산(흑백영상)(p83)
clc;clear all;
x=imread('로겟발사.pgm'); % 영상을 읽음
x1=histeq(x); % 히스토그램 평활화
subplot(2,2,1); imshow(x);
subplot(2,2,2); imshow(x1);
subplot(2,2,3); imhist(x); %영상 x에 대한 히스토그램
subplot(2,2,4); imhist(x1); %영상 x1에 대한 히스토그램

%% 두 영상에 대한 덧셈 연산(p84)

clc;clear all;
a=imread('모나리자.pgm'); % 영상을 읽음
b=imread('모나리자-mask.pgm'); % 마스크 영상을 읽음
ab=a+b;
ab(find(ab>=255))=255;
subplot(1,3,1); imshow(a,[]);
subplot(1,3,2); imshow(b,[]);
subplot(1,3,3); imshow(uint8(ab),[]); % 8비트 영상으로 출력

%% 회선 기법을 이용한 선명화 연산(p88)

clc;clear all;
a=imread('모나리자.pgm'); % 영상을 읽음
s=size(a); % 영a상와 같은 크기를 같도록 설정
a1=zeros(size(a)+2);
a1(2:s(1)+1,2:s(2)+1)=a;
mask1=[0 -1 0; -1 5 -1 ; 0 -1 0]; % 회선기법에 적용될 마스크 영상
a1=filter2(mask1,a1,'valid'); % 마스크 영상을 이용하여 회선처리
a1=uint8(a1);
subplot(1,2,1), imshow(a) % 영상을 화면에 디스플레이
subplot(1,2,2), imshow(a1);

%% 자동차 번호 인식을 위한 선명화(p89)

clc;clear all;
a=imread('자동차-흐림.pgm'); % 영상을 읽음
s=size(a);
a1=zeros(size(a)+2);
a1(2:s(1)+1,2:s(2)+1)=a;
mask1=[0 -1 0; -1 5 -1 ; 0 -1 0]; % 회선기법에 적용될 마스크 영상
a1=filter2(mask1,a1,'valid'); %a 1 영상에 mask1를 ‘valid’ 옵션으로 필터링
a1=uint8(a1);
subplot(1,2,1), imshow(a);
subplot(1,2,2), imshow(a1);

%% 회선 기법을 이용한 영상 흐리게 하기(p90)

clc; clear all;
a=imread('모나리자.pgm'); % 영상을 읽음
s=size(a);
a1=zeros(size(a)+2);
a1(2:s(1)+1,2:s(2)+1)=a;
mask1=ones(3,3)/9; % 평균필터
a1=filter2(mask1,a1,'valid'); % ignore edge 처리
a1=uint8(a1);
subplot(1,2,1), imshow(a) ; % 화면에 디스플레이
subplot(1,2,2), imshow(a1);

%% 중간값 필터 적용(p92)

clc;clear all;
fid = fopen('Lenna-임펄스잡음.raw'); % raw 형식의 파일은 파일로 읽음
size=[256,256];
b=fread(fid,size);
status=fclose(fid);
y=ordfilt2(b,5,ones(3,3)); % 중간값 필터 적용
y=uint8(y); subplot(1,2,1)
b1=imrotate(double(b), 270); % 영상을 270도 회전
imshow(b1,[]) % 화면에 디스플레이
subplot(1,2,2); 
y1=imrotate(y, 270);
imshow(y1,[]);

%% 경계선 검출(p93)

clc;clear all;
a=imread('강아지.pgm');
sobelmask1=[-1 -2 -1; 0 0 0; 1 2 1]; % sobel 필터
a1=filter2(sobelmask1,a);
a1=uint8(a1);
subplot(1,2,1), imshow(a);
subplot(1,2,2), imshow(a1);














