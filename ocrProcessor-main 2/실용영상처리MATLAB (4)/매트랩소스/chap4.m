%% 침식연산 실습(p106)

clc; clear all;
i=imread('bolts(이진).pgm');
k=ones(3,3); % 3x3 의 kernel
ie=imerode(i,k); % 침식
subplot(1,2,1); imshow(i),title('< 원본 >','Fontweight','bold')
subplot(1,2,2); imshow(ie),title('< 침식(Erosion) >','Fontweight','bold')

%% 팽창 연산 실습 (p107)
clc; clear all;
i=imread('bolts(이진).pgm');
k=ones(3,3); % 3x3 의 kernel
id=imdilate(i,k); % 팽창연산
subplot(1,2,1); 
imshow(i),title('< 원본 >','Fontweight','bold')
subplot(1,2,2);
imshow(id),title('< 팽창(Dilation) >','Fontweight','bold')

%% 열림 연산 실습 (p108) 

clc; clear all;
i=imread('twopills.pgm');
s=imread('세포(역상-이진).pgm');
k=ones(3,3); % 3x3의 kernel
o=imopen(i,k); % 열림 연산
c=imclose(s,k); % 닫힘 연산
subplot(2,2,1); imshow(i),title('< 원본 >','Fontweight','bold')
subplot(2,2,2);
imshow(o),title('< 열림 연산(Opening) >','Fontweight','bold')
subplot(2,2,3); imshow(s),title('< 원본 >','Fontweight','bold')
subplot(2,2,4);
imshow(c),title('< 열림 연산(Opening) >','Fontweight','bold')

%% 닫힘 연산 실습 (p109)

clc; clear all;
i2=imread('bolts(이진).pgm');
k=ones(3,3); % 3x3의 kernel
c=imclose(i2,k); % 닫힘 연산
subplot(1,2,1); imshow(i2),title('< 원본 >','Fontweight','bold')
subplot(1,2,2);
imshow(c),title('< 닫힘 연산(closing) >','Fontweight','bold')






