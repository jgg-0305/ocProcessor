%% warping  (p149)

clear all; clc;
I = imread('warp.pgm');

SI=[116,7,207,5;34,109,90,21;55,249,30,128;118,320,65,261;123,321,171,321;179,319,240,264;247,251,282,135;...
    281,114,228,8;78,106,123,109;187,115,235,114;72,142,99,128;74,150,122,154;108,127,123,146;182,152,213,132;...
    183,159,229,157;219,131,240,154;80,246,117,212;127,222,146,223;154,227,174,221;228,252,183,213;...
    114,255,186,257;109,258,143,277;152,278,190,262];
DI=[120,8,200,6;12,93,96,16;74,271,16,110;126,336,96,290;142,337,181,335;192,335,232,280;244,259,288,108;...
    285,92,212,13;96,135,136,118;194,119,223,125;105,145,124,134;110,146,138,151;131,133,139,146;188,146,198,134;...
    189,153,218,146;204,133,221,140;91,268,122,202;149,206,159,209;170,209,181,204;235,265,208,199;121,280,205,284;...
    112,286,160,301;166,301,214,287];

            DI_x1=DI(:,1,:,:);
            DI_y1=DI(:,2,:,:);
            DI_x2=DI(:,3,:,:);
            DI_y2=DI(:,4,:,:);
            
            SI_x1=SI(:,1,:,:);
            SI_y1=SI(:,2,:,:);
            SI_x2=SI(:,3,:,:);
            SI_y2=SI(:,4,:,:);
            
      warp_I=uint8(zeros(size(I)));
       
for y=1:size(I,1)
    
    for x=1:size(I,2)
    
        tx=0;
        ty=0;
        totalweight=0;
        
        for line =1:length(DI)

            x1=DI_x1(line);
            y1=DI_y1(line);
            x2=DI_x2(line);
            y2=DI_y2(line);            
                                    
            dest_line_length = sqrt((x2-x1)^2+(y2-y1)^2);
            
            u= (((x-x1)*(x2-x1))+((y-y1)*(y2-y1)))/((x2-x1)^2+(y2-y1)^2);
            h= ((y-y1)*(x2-x1)-(x-x1)*(y2-y1))/dest_line_length ;
            
            if (u<0) 
                d=sqrt((x-x1)^2+(y-y1)^2);
            elseif (u>1) 
                d=sqrt((x-x2)^2+(y-y2)^2);
            else
                d=abs(h);
            end
            
            src_x1=SI_x1(line);
            src_y1=SI_y1(line);
            src_x2=SI_x2(line);
            src_y2=SI_y2(line);  
            
            src_line_length = sqrt((src_x2-src_x1)^2+(src_y2-src_y1)^2);
            
            % 입력 영상에서의 대응 픽셀 위치 계산
            xp= src_x1+u*(src_x2-src_x1)-(h*(src_y2-src_y1))/src_line_length;
            yp= src_y1+u*(src_y2-src_y1)+(h*(src_x2-src_x1))/src_line_length;
            
            % 제어선에 대한 가중치 계산
            a=0.001; b=2; p=0.75;
            weight = (dest_line_length^p/(a+d))^b;
            
            %대응 픽셀과 변위 계산
            tx=tx+(xp-x)*weight;
            ty=ty+(yp-y)*weight;
            totalweight= totalweight+weight;  
        end
      
            source_x = x+round(tx/totalweight+0.5);
            source_y = y+round(ty/totalweight+0.5);
            % 영상의 경제를 벗어나는지 확인
            if (source_x < 1 )
                source_x=1;
            end
            if (source_x > size(I,2))
                source_x = size(I,2);
            end
            if (source_y < 1 )
                source_y=1;
            end
            if (source_y > size(I,1))
                source_y=size(I,1);
            end
         
           warp_I(y,x)=uint8(I(source_y,source_x));
     end
        
end

subplot(1,2,1), imshow(I,[ ]), xlabel('원영상','Fontweight','bold');
subplot(1,2,2),imshow( warp_I,[]),xlabel('워핑 영상','Fontweight','bold');

%% 모핑 프로그램 ( p152)

clear all; clc;
 
% 두 입력 영상을 읽음
I = imread('morph_src.pgm');
J = imread('morph_dest.pgm');
 
subplot(1,2,1);imshow(I,[ ]);
subplot(1,2,2);imshow(J,[ ]);
  
%  10개의 모핑 이미지 저장, 중간의 워핑 결과를 저장할 공간 할당
NUM_FRAMES =10;
for i=1:NUM_FRAMES
    MorphedImg(:,:,i)=uint8(zeros(size(I)));
    WarpedImg(:,:,i)=uint8(zeros(size(I)));
    WarpedImg2(:,:,i)=uint8(zeros(size(I)));
end
 
SI=[116,7,207,5;34,109,90,21;55,249,30,128;118,320,65,261;123,321,171,321;179,319,240,264;247,251,282,135;281,114,228,8;78,106,123,109;187,115,235,114;72,142,99,128;74,150,122,154;108,127,123,146;182,152,213,132;    183,159,229,157;219,131,240,154;80,246,117,212;127,222,146,223;154,227,174,221;228,252,183,213;114,255,186,257;109,258,143,277;152,278,190,262];

DI=[120,8,200,6;12,93,96,16;74,271,16,110;126,336,96,290;142,337,181,335;192,335,232,280;244,259,288,108;285,92,212,13;96,135,136,118;194,119,223,125;105,145,124,134;110,146,138,151;131,133,139,146;188,146,198,134;189,153,218,146;204,133,221,140;91,268,122,202;149,206,159,209;170,209,181,204;235,265,208,199;121,280,205,284;112,286,160,301;166,301,214,287];
 DI_x1=DI(:,1,:,:);
 DI_y1=DI(:,2,:,:);
 DI_x2=DI(:,3,:,:);
 DI_y2=DI(:,4,:,:);

 SI_x1=SI(:,1,:,:);
 SI_y1=SI(:,2,:,:);
 SI_x2=SI(:,3,:,:);
 SI_y2=SI(:,4,:,:);
for frame =1:NUM_FRAMES  % 각 중간 프레임에 대하여
     fweight = frame/NUM_FRAMES; %중간 프레임에 대한 가중치 계산
for line =1:length(DI) %중간 프레임에 대한 제어선 계산 
     warp_lines_px(line)=SI_x1(line) +(DI_x1(line)-SI_x1(line))*fweight;
     warp_lines_py(line)=SI_y1(line) +(DI_y1(line)-SI_y1(line))*fweight;
     warp_lines_qx(line)=SI_x2(line) +(DI_x2(line)-SI_x2(line))*fweight;
     warp_lines_qy(line)=SI_y2(line) +(DI_y2(line)-SI_y2(line))*fweight;  
 end             
 for y=1:size(I,1) %출력 영상의 각 픽셀에 대하여     
 for x=1:size(I,2)
              
 tx=0;
 ty=0;
 totalweight=0;
 tx2=0;
 ty2=0;
        
 for line =1:length(DI) % 각 제어선에 대하여
      x1 = warp_lines_px(line);
      y1 = warp_lines_py(line);
      x2 = warp_lines_qx(line);
      y2 = warp_lines_qy(line);
                           
      dest_line_length = sqrt((x2-x1)^2+(y2-y1)^2);         

 % 수직 교차점의 위치 및 픽셀의 수직 변위 계산
u= (((x-x1)*(x2-x1))+((y-y1)*(y2-y1)))/((x2-x1)^2+(y2-y1)^2);
h= ((y-y1)*(x2-x1)-(x-x1)*(y2-y1))/dest_line_length ;
            
if (u<0) d=sqrt((x-x1)^2+(y-y1)^2);
elseif (u>1) d=sqrt((x-x2)^2+(y-y2)^2);
else d=abs(h); end

src_x1=SI_x1(line);
src_y1=SI_y1(line);
src_x2=SI_x2(line);
src_y2=SI_y2(line); 

src_line_length = sqrt((src_x2-src_x1)^2+(src_y2-src_y1)^2);
dest_x1=DI_x1(line);
dest_y1=DI_y1(line);
dest_x2=DI_x2(line);
dest_y2=DI_y2(line);              
dest_line_length=sqrt((dest_x2-dest_x1)^2+(dest_y2-dest_y1)^2);                 

% 입력 영상1에 대응하는 픽셀 위치 계산
xp= src_x1+u*(src_x2-src_x1)-(h*(src_y2-src_y1))/src_line_length;
yp= src_y1+u*(src_y2-src_y1)+(h*(src_x2-src_x1))/src_line_length;
                            
% 입력 영상2에 대응하는 픽셀 위치 계산
xp2= dest_x1+u*(dest_x2-dest_x1)-(h*(dest_y2-dest_y1))/dest_line_length;
yp2= dest_y1+u*(dest_y2-dest_y1)+(h*(dest_x2-dest_x1))/dest_line_length;  
% 제어선에 대한 가중치 계산
a=0.001; b=2; p=0.75;
weight = (dest_line_length^p/(a+d))^b; 
%입력 영상 1의 대응 픽셀과 변위 계산                             
tx=tx+(xp-x)*weight;
ty=ty+(yp-y)*weight;                         
%입력 영상 2의 대응 픽셀과 변위 계산                             
tx2=tx2+(xp2-x)*weight;
ty2=ty2+(yp2-y)*weight;                               
totalweight= totalweight+weight;  
end
 %입력 영상 1의 대응 픽셀과 변위 계산                         
source_x = x+round(tx/totalweight+0.5);
source_y = y+round(ty/totalweight+0.5);
 %입력 영상 2의 대응 픽셀과 변위 계산                         
source_x2 = x+round(tx2/totalweight+0.5);
source_y2 = y+round(ty2/totalweight+0.5);
% 영상의 경제를 벗어나는지 확인
 if (source_x < 1 ) source_x=1; end
 if (source_x > size(I,2)) source_x = size(I,2);  end
 if (source_y < 1 ) source_y=1; end
 if (source_y > size(I,1)) source_y=size(I,1); end
                        
 if (source_x2 < 1 )  source_x2=1; end
if (source_x2 > size(I,2)) source_x2 = size(I,2); end
if (source_y2 < 1 )  source_y2=1; end
if (source_y2 > size(I,1)) source_y2=size(I,1); end  
%워핑 결과 저장
WarpedImg(y,x)=uint8(I(source_y,source_x));
WarpedImg2(y,x)=uint8(J(source_y2,source_x2));                
end
end               
% 모핑 결과 합병
for y=1:size(I,1)    
for x=1:size(I,2)
   val=round((1-fweight)* WarpedImg(y,x) + fweight*WarpedImg2(y,x));
    if(val < 1 ) val=1; end
    if(val >255) val=255; end
  MorphedImg(y,x,frame) = val;                     
end
end               
end

%시뮬레이션 결과 
subplot(2,5,1),
imshow(MorphedImg(:,:,1),[]),xlabel('모핑영상1','Fontweight','bold');
subplot(2,5,2),
imshow(MorphedImg(:,:,2),[ ]),xlabel('모핑영상2','Fontweight','bold');
subplot(2,5,3),
imshow(MorphedImg(:,:,3),[ ]),xlabel('모핑영상3','Fontweight','bold');
subplot(2,5,4),
imshow(MorphedImg(:,:,4),[ ]),xlabel('모핑영상4','Fontweight','bold');
subplot(2,5,5),
imshow(MorphedImg(:,:,5),[ ]),xlabel('모핑영상5','Fontweight','bold');
subplot(2,5,6),
imshow(MorphedImg(:,:,6),[ ]),xlabel('모핑영상6','Fontweight','bold');
subplot(2,5,7),
imshow(MorphedImg(:,:,7),[ ]),xlabel('모핑영상7','Fontweight','bold');
subplot(2,5,8),
imshow(MorphedImg(:,:,8),[ ]),xlabel('모핑영상8','Fontweight','bold');
subplot(2,5,9),
imshow(MorphedImg(:,:,9),[ ]),xlabel('모핑영상9','Fontweight','bold');
subplot(2,5,10),
imshow(MorphedImg(:,:,10),[ ]),xlabel('모핑영상10','Fontweight','bold');

