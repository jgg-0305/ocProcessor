%% 픽셀 복제를 영상의 확대(p124)

clc;clear all;close all;
x=imread('Lenna-64x64.pgm');
x1=imresize(x,3,'nearest'); % 픽셀 복제
imshowpair(x,x1,'montage'); 
% 한 화면에 두 영상의 실제 크기로 출력

%% 양선형 보간을 이용한 확대 (p124)
clc;clear all;close all
x=imread('Lenna-64x64.pgm');
x1=imresize(x,3,'bilinear'); % 픽셀 양선형 보간
imshowpair(x,x1,'montage'); 

%% 서브샘플링을 이용한 축소(p125)

clc;clear all
x=imread('lines.pgm');
s=size(x);
k=x(3:3:s(1),3:3:s(2));
imshowpair(x,k,'montage');

%% 평균값 필터링을 이용한 축소(p126)

clc;clear all;close all
x=imread('lines.pgm');
a=fspecial('average',[3 3]);
k=filter2(a,x);
k=uint8(k);
s=size(k);
k1=k(3:3:s(1),3:3:s(2));
imshowpair(x,k1,'montage');

%% 반시계 방향으로 30도 회전(p127)

clc;clear all;close all
x=imread('화성탐사선.pgm');
x1=imrotate(x,30);
imshowpair(x,x1,'montage');

%% 좌우대칭(p128)

clc;clear all;close all
x=imread('로겟발사.pgm'); % 교제 수정 필요 ( 화성탐사선 --> 로겟 발사)
x1=fliplr(x); % 영상을 좌우대칭
imshowpair(x,x1,'montage');

%% 상하대칭(p129)

clc;clear all;close all
x=imread('로겟발사.pgm'); % 교제 수정 필요 ( 화성탐사선 --> 로겟 발사)
x1=flipud(x); % 영상을 상하대칭
imshowpair(x,x1,'montage');

%% 벡터에 의한 이동 imtranslate(p130)

I = imread('pout.tif'); % 영상을 읽음
J = imtranslate(I,[5.3, -10.1],'FillValues',255); 
% 영상을 이동시키는 함수
figure, imshow(I); % 원본 영상
figure, imshow(J); % translate시킨 영상

%% 벡터에 의한 이동 impyramid (p131)]

I0 = imread('cameraman.tif');
I1 = impyramid(I0, 'reduce');
I2 = impyramid(I1, 'reduce');
I3 = impyramid(I2, 'reduce');
imshow(I0)
figure, imshow(I1)
figure, imshow(I2)
figure, imshow(I3)

%% 벡터에 의한 이동imwarp (p132)

I = imread('cameraman.tif');
imshow(I)
tform = affine2d([1 0 0; .5 1 0; 0 0 1])
J = imwarp(I,tform);
figure, imshow(J);










