%% (161p)

xyloObj = VideoReader('xylophone.mp4');
get(xyloObj)
General Settings:
Duration = 4.7000
Name = xylophone.mp4
Path = C:\Program Files\MATLAB\R2014a\toolbox\matlab\audiovideo
Tag =
Type = VideoReader
UserData = []
Video Settings:
BitsPerPixel = 24
FrameRate = 30
Height = 240
NumberOfFrames = 141
VideoFormat = RGB24
Width = 320
clear all, clc;
vidObj = VideoReader('컵움직임추적.avi');
nFrames = vidObj.NumberOfFrames;
for iFrame=1:2:nFrames
I = read(vidObj,iFrame); % get one RGB image
imshow(I,[]); % Display image
pause(0.1);
end

%% (163p)

cam =
webcam with properties:
n ame: 'Dell Camera C250'
Resolution: '320x240'
AvailableResolutions: ('320x240' '160x120' '80x60')
Brightness: 128
C ontrast: 32
G ain: 0

%% (164p)

clear all, clc;
cam = webcam('Dell Camera C250');
preview(cam);
img = snapshot(cam);
imshow(img);
closePreview(cam);

%% (164~166p)

clear all; clc; close all;
vidObj = VideoReader('컵움직임추적.avi');
nFrames = vidObj.NumberOfFrames;
for iFrame=1:2:nFrames
data = read(vidObj,iFrame); % 영상 읽음 (rgb영상)
r =data(:,:,1); % r의 영상을 찾음
g = data(:,:,2);
b = data(:,:,3);
diff_im=r-g/2-b/2;
diff_im = medfilt2(diff_im, [3 3]);
diff_im = im2bw(diff_im,0.18);
diff_im = bwareaopen(diff_im,30);
bw = bwlabel(diff_im, 8);
b1 = bw(1:round(240/3),1:round(320/3));
b2 = bw(1:round(240/3),round(320/3)+1:round(320/3)*2);
b3 = bw(1:round(240/3),round(320/3)*2+1:320);
b4 = bw(round(240/3)+1:round(240/3)*2 ,1:round(320/3));
b5 = bw(round(240/3)+1:round(240/3)*2,round(320/3)+1:round(320/3)*2);
b6 = bw(round(240/3)+1:round(240/3)*2,round(320/3)*2+1:320);
b7 = bw(round(240/3)*2+1:240,1:round(320/3));
b8 = bw(round(240/3)*2+1:240,round(320/3)+1:round(320/3)*2);
b9 = bw(round(240/3)*2+1:240,round(320/3)*2+1:320);
c1 = zeros(size(b1)); [r1,cm1]=size(c1);
c1(1:r1, cm1-2:cm1)=1; c1(r1-2:r1,1:cm1)=1;
c2 = zeros(size(b2)); [r2,cm2]=size(c2);
c2(1:r2, cm2-2:cm2)=1; c2(r2-2:r2,1:cm2)=1;
c3 = zeros(size(b3)); [r3,cm3]=size(c3);
c3(1:r3, cm3-2:cm3)=1; c3(r3-2:r3,1:cm3)=1;
c4 = zeros(size(b4)); [r4,cm4]=size(c4);
c4(1:r4, cm4-2:cm4)=1; c4(r4-2:r4,1:cm4)=1;
c5 = zeros(size(b5)); [r5,cm5]=size(c5);
c5(1:r5, cm5-2:cm5)=1; c5(r5-2:r5,1:cm5)=1;
c6 = zeros(size(b6)); [r6,cm6]=size(c6);
c6(1:r6, cm6-2:cm6)=1; c6(r6-2:r6,1:cm6)=1;
c7 = zeros(size(b7)); [r7,cm7]=size(c7);
c7(1:r7, cm7-2:cm7)=1; c7(r7-2:r7,1:cm7)=1;
c8 = zeros(size(b8)); [r8,cm8]=size(c8);
c8(1:r8, cm8-2:cm8)=1; c8(r8-2:r8,1:cm8)=1;
c9 = zeros(size(b9)); [r9,cm9]=size(c9);
c9(1:r9, cm9-2:cm9)=1; c9(r9-2:r9,1:cm9)=1;
d= [b1+c1, b2+c2,b3+c3; b4+c4, b5+c5, b6+c6; b7+c7, b8+c8, b9+c9];
e1=sum(b1(:)); e2=sum(b2(:)); e3=sum(b3(:));
e4=sum(b4(:)); e5=sum(b5(:)); e6=sum(b6(:));
e7=sum(b7(:)); e8=sum(b8(:)); e9=sum(b9(:));
e= [e1, e2, e3, e4, e5, e6, e7, e8, e9];
ch1= find(e==max(e));
if(sum(ch1)==45)
ch=0;
end
if(ch1==7)
ch1=7;
end
if(ch1==9)
ch1=9;
end
imshowpair(data,d,'montage');
end

%% (171p)

clear all, clc; close all;
c=im2bw(imread('bolts(이진).pgm'),0.5); % 영상을 읽은 후 2진 영상으로 만듦.
L=prod(size(c));
im=reshape(c',1,L);
x=1;
out=[];
while L~=0,
temp=min(find(im ==x)); % 초기의 0의 개수를 구함.
if isempty(temp),
out=[out L];
break;
end;
out=[out temp-1]; % 출력벡터에서 구한 값보다 1 적은 수를 추가함.
x=1-x;
im=im(temp:L);
L=L-temp+1;
end
whos c out

%% (197p)

function out=jpg_in(x,n)
q=[16 11 10 16 24 40 51 61;...
12 12 14 19 26 58 60 55;...
14 13 16 24 40 57 69 56;...
14 17 22 29 51 87 80 62;...
18 22 37 56 68 109 103 77;...
24 35 55 64 81 104 113 92;...
49 64 78 87 103 121 120 101;...
72 92 95 98 112 100 103 999];
bd= dct2(double(x)-128);
out=round(bd./(q*n));

%% (198p)

function out=jpg_out(x,n)
q=[16 11 10 16 24 40 51 61;...
12 12 14 19 26 58 60 55;...
14 13 16 24 40 57 69 56;...
14 17 22 29 51 87 80 62;...
18 22 37 56 68 109 103 77;...
24 35 55 64 81 104 113 92;...
49 64 78 87 103 121 120 101;...
72 92 95 98 112 100 103 999];
out = round(idct2(x.*q*n)+128);

%% (198p)

clear all, clc; close all;
c=imread('cameraman.tif');
cj1=blkproc(c,[8,8],'jpg_in',1); % 압축
c1=uint8(blkproc(cj1,[8,8],'jpg_out',1));% 복원
imshowpair(c,c1,'montage')