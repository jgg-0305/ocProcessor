%% 이미지 데이터 읽기(p28)

A = imread('ngc6543a.jpg'); % ngc6543.jpg 영상을 읽는다.
[A, map] = imread('trees.tif'); % Indexed Images인 trees.tif 영상을 읽는다.
% 여기ma서p은 indexed 영상의 컬러맵임.
RGB = imread('football.jpg'); % football.jpg가 Truecolor Images이면
R=RGB(:,:,1); %3 차원 배열로 읽어지며, R,G,B 순이다.
G=RGB(:,:,2);
B=RGB(:,:,3);
I = dicomread('CT-MONO2-16-ankle.dcm'); % 의료 영상을 읽는다.

%% 이미지 데이터 쓰기(p29)

A = imread('ngc6543a.jpg'); % 영상을 읽는다.
imwrite(A, 'ngc6543b.tif'); % 영상을 tif 형식으로 저장한다.
[A,map] = imread('trees.tif'); % Indexed Images인 trees.tif 영상을 읽는다.
% 여기ma서p은 indexed 영상의 컬러맵이다.
imwrite(A,map, 'trees.png'); % Indexed 영상으로 저장한다.
X = dicomread('CT-MONO2-16-ankle.dcm'); % 의료 영상을 읽는다.
metadata = dicominfo('CT-MONO2-16-ankle.dcm'); % CT의 정보 포함
dicomwrite(X, 'ct_file.dcm', metadata); % CT의 정보를 포함해서 저장한다.

%% 영상의 확대 축소 디스플레이(p30) 

moon = imread('moon.tif');
imshow(moon); %①
imshow('moon.tif'); %① 번과 동일한 영상 디스플레이
imshow(moon, 'InitialMagnification', 150); %③→ ①번 영상의 150% 확대 디스플레이
imshow(moon, 'InitialMagnification', 50);% ④→ ①번 영상의 50% 축소 디스플레이

%% 여러 이미지를 하나의 그림창에 디스플레이하기 (p32)

[X1,map1]=imread('forest.tif');
[X2,map2]=imread('trees.tif');
subplot(1,2,1), imshow(X1,map1);
subplot(1,2,2), imshow(X2,map2);

%% 이진 영상의 디스플레이(p35)

BW = imread('circles.png');
imshow(BW); figure; imshow(~BW);

%% Truecolor Images의 색깔별 화면 디스플레이(p36)

RGB = imread('peppers.png');
subplot(2,2,1), imshow(RGB);
subplot(2,2,2), imshow(RGB(:,:,1));
subplot(2,2,3), imshow(RGB(:,:,2));
subplot(2,2,4), imshow(RGB(:,:,3));



