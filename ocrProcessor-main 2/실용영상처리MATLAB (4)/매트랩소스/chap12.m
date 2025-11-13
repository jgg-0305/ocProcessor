%% (354p)

clear all; close all; clc;
% 학습 이미지의 개수
Marker=10; Training=[]; Group =[];
% 표준패턴 읽기 , 2진 영상 만들기 , Traing data 만들기
for N = 1 : Marker
fname = sprintf('E:\\영상처리\\marker_%02d.bmp', N - 1 );
Open_Marker{N} = imread(fname);
T_size =size(Open_Marker{1});
T1 = graythresh(Open_Marker{N});
f2= im2bw(Open_Marker{N},T1);
f3 = imclearborder(f2);
img{N}=bwareaopen(f3,30);
Traing{N} =[ reshape( img{N}, 1, T_size(1)*T_size(2))];
Temp= Traing{N};
Training =[Training ; Temp];
Group = [Group, N ];
subplot(ceil(sqrt(Marker)), ceil(sqrt(Marker)),N);
imshow(Open_Marker{N});
end

%% (355p)

%% Sampling data 만들기1
close all; clc;
in_img = imread('12장-help.pgm');
imshow(in_img,[]);
T2 = graythresh(in_img);
in_img2 = ~im2bw(in_img,T2);
in_img3 = imclearborder(in_img2);
in_img4 = bwareaopen(in_img3,20);
in_img5 = imfill(in_img4,4, 'holes');
in_bimg = bwperim(in_img5,4);

%% (356p)

%% Sampling data 만들기2 ( hough 변환을 이용한 각도 계산)
[H,theta,rho] = hough(in_bimg);
peaks = houghpeaks(H,4);
lines = houghlines(in_bimg,theta,rho,peaks);
figure, imshow(in_bimg); hold on;
for k = 1:numel(lines)
x1(k) = lines(k).point1(1);
y1(k) = lines(k).point1(2);
x2(k) = lines(k).point2(1);
y2(k) = lines(k).point2(2);
plot([x1(k) x2(k)],[y1(k) y2(k)],'Color','g','LineWidth', 2)
if k==1
L_theta = lines(k).theta;
elseif k>=2 && y1(k) > y1(k-1)
L_theta = lines(k).theta;
end
end
hold off

%% (357p)

% 영상의 회전
if L_theta >0
in_rimg = imrotate(in_img4,-(90-L_theta),'bicubic' );
imshow(in_rimg)
else
in_rimg = imrotate(in_img4,L_theta+90,'bicubic');
imshow(in_rimg)
end

%% (358p)

% 선택 영상 저장
close all; clc;
in_simg = regionprops(in_rimg, 'all');
BB =in_simg.BoundingBox;
subImage =~ imcrop(in_rimg,[round(BB(1)),round(BB(2)),...
round(BB(3)), round(BB(4))] );
re_subimg = imresize(subImage,[ T_size(1), T_size(2)]);
size_subimg = size(re_subimg );
Sampling = reshape (re_subimg, 1 ,size_subimg(1)*size_subimg(2));
imshow(re_subimg,[])

%% (359p)

% 거리 근접화 방법 적용
Class = knnclassify(Sampling, Training, Group);
imshowpair( img{Class}, subImage,'montage' );

%% (360p)

clear all; close all; clc;
% 학습 이미지의 개수
Marker=390;
Training=[];
% 표준패턴 읽기 , 2진영상 만들기 , Traing data 만들기
for N = 1 : Marker
fname = sprintf('E:\\영상처리\\face_%01d.bmp', N - 1 );
Open_Marker{N} = imread(fname);
T_size =size(Open_Marker{1});
Traing{N} =reshape(Open_Marker{N}', T_size(1)*T_size(2),1);
Temp= Traing{N};
subplot(ceil(sqrt(Marker)), ceil(sqrt(Marker)),N);
imshow(Open_Marker{N});
Training =[Training Temp];
end

%% (362p)

%% 평균얼굴 계산
close all; clc;
Train_mean = (mean(Training,2));
img = reshape(Train_mean,T_size(2),T_size(1)) ;
imshow( uint8(img'));

%% (362p)

% V : 고유벡터 행렬, b; 고윳값 행렬
A = [];
for i=1 : Marker
temp = double(Training(:,i))- Train_mean;
A = [A temp];
end
L= A' * A;
[V,D]=eig(L);
L_eig_vec = [];
for i = 1 : size(V,2)
if( D(i,i) > 1 )
L_eig_vec = [L_eig_vec V(:,i)];
end
end
% 최종적으로 고유 얼굴 계산 %
eigenfaces = A * L_eig_vec;

%% (363p)

% 추종되는 이미지 벡터 행렬
projectimg = [ ];
for i = 1 : size(eigenfaces,2)
temp = eigenfaces' * A(:,i);
projectimg = [projectimg temp];
end

%% (364p)

%% PCA 분석을 위한 테스트 이미지
fname1 = sprintf('E:\\영상처리\\att_faces\\s24\\%01d.pgm',7);
test_image = imread(fname1);
test_image = test_image(:,:,1);
[r c] = size(test_image);
% (MxN)x1 벡터 만들기
temp = reshape(test_image',r*c,1);
% 평균영상과 뺄셈 영상 만들기
temp = double(temp)-Train_mean;
% 테스트 추종 영상의 고유벡터 행렬 만들기
projtestimg = eigenfaces'*temp;

%% (364p)

euclide_dist = [ ];
for i=1 : size(eigenfaces,2)
temp = (norm(projtestimg-projectimg(:,i)))^2;
euclide_dist = [euclide_dist temp];
end
[euclide_dist_min recognized_index] = min(euclide_dist)

%% (365p)

x=1 : size(eigenfaces,2);
plot(x, euclide_dist); grid on;
figure;
grid off;
imshowpair(test_image,Open_Marker{recognized_index},'montage' );