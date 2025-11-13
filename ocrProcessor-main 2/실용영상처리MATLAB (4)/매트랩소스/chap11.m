%% p 312

clear all; clc;

I = imread('rice.png'); % 영상 읽기
BW = im2bw(I, graythresh(I)); % 이진 영상으로 변환
[B,L] = bwboundaries(BW,'noholes'); % 경계 값 축출
imshow(label2rgb(L, @jet, [.5 .5 .5])) % 영상을 화면에 디스플레이
hold on  %레이블을 jet 컬러로 변환
for k = 1:length(B) % 각 영상의 외곽을 흰색으로 설정
boundary = B{k};
plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end

%% p 313

clear all; clc;

BW = imread('blobs.png'); % 영상 읽기
[B,L,N,A] = bwboundaries(BW); % 경계 값 축출
figure, imshow(BW); hold on; % 영상을 화면에 디스플레이
colors=['b' 'g' 'r' 'c' 'm' 'y']; % 색깔 행 벡터
for k=1:length(B) % 각 경계에 대한 인덱스 출력
boundary = B{k};
cidx = mod(k,length(colors))+1;
plot(boundary(:,2), boundary(:,1),...
colors(cidx),'LineWidth',2);
%randomize text position for better visibility
rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
col = boundary(rndRow,2); row = boundary(rndRow,1);
h = text(col+1, row-1, num2str(L(row,col)));
set(h,'Color',colors(cidx),'FontSize',14,'FontWeight','bold');
end

%% p 315

clear all; clc;

BW = imread('text.png'); % 영상 읽기
s = regionprops(BW,'centroid'); % 중심 값 축출
centroids = cat(1, s.Centroid); % centroids 생성
imshow(BW) % 화면에 디스플레이
hold on
plot(centroids(:,1),centroids(:,2), 'b*') % 중심에 파란색의 * 출력
hold off


%% p 316

clear all; clc;

BW = imread('circles.png'); % 영상 읽기
imshow(BW) % 화면에 디스플레이
bwarea(BW) % 이진영상의 면적

%% p 316-2

clear all; clc;

BW = imread('circles.png'); % 영상 읽기
BW2 = bwperim(BW,8); % 경계 영상 획득
imshowpair(BW,BW2,'montage') % 화면에 디스플레이

%% p 317

clear all; clc;

clear all; clc;
f = imread('11장-사각형마커(이진영상).pgm'); % 영상 읽기
g=bwperim(~f,4); % 2진 영상 획득
[b,L]=bwboundaries(~f,4,'holes'); % 경계값의 좌표 획득
max(L(:)); % 윤곽선의 레이블
c=cat(1,b{:}); % 2차원 좌표 생성
[m,n]=size(f);
image=bound2im(c,m,n); % 좌표값을 m×n 크기로 영상 생성
imshowpair(f,~image,'montage') % 화면에 디스플레이

%%  선분 근사화 이전 %%  p 318 ~p 322 

clear all; clc; close all;
f = imread('11장-원.pgm');
[b,L]=bwboundaries(f,4,'holes');
k =max(L(:));
 [m,n]=size(f);
 
 
for j=2 : k
    for i =j : j        
      x = b{i,1} ;
    end
    
    val_x = x(:,1);
    val_y = x(:,2);
    
    
    
    Y(j) = contour_length(val_x, val_y);
    
       c=cat(1,b{j} ); 
       image=bound2im(c,m,n);
       gb= imfill( image,4, 'holes');
       state = regionprops( gb,'Area','Centroid', 'ConvexHull'); 
       contour_centroid {j} = cat(1, state.Centroid); 
   
       contour_ConvexHull {j} = cat(1, state.ConvexHull); 
       contour_area(j) = cat(1, state.Area) ; 
    
             if length(contour_ConvexHull {j})>0
                    is_ConvexHull(j) =1;
             else
                    is_ConvexHull(j) =0;
        
             end
              
             circularity(j)= (4.0 * pi *  contour_area(j) )./ (Y(j).^2);
             
end
   
    nvertices = length(x);
    lengths = max(Y);
    area = max(contour_area);
    circularitys = max(circularity) ;
    centers = contour_centroid{2};
    is_Convex = max( is_ConvexHull);
    
    T = table( nvertices, lengths , area, circularitys, centers, is_Convex )

    
%%  선분 근사화 이후 %%  p 322 ~p 325
 
 clear all; clc; close all;
f1 = imread('11장-원.pgm');
%f1 = imread('11장-사각형.pgm');

T1 = graythresh(f1);
f2= ~im2bw(f1,T1);
f3 = imclearborder(f2);
 f4=bwareaopen(f3,30);
f =~imfill(f4,4, 'holes'); 



[b,L]=bwboundaries(f,4,'holes');

k =max(L(:));
 [m,n]=size(f);

 
 
 
 
for j=2 : k
    for i =j : j
      x = b{i,1} ;
    end
    
    ptList_reduced = RDP_recs(x,0.1);
    size(ptList_reduced);
    val_x{i} = ptList_reduced(1:size( ptList_reduced)-1,1);
    val_y{i} = ptList_reduced(1:size( ptList_reduced)-1,2);
    
    
    
    Y(j) = contour_length(val_x{i}, val_y{i});
    

        c=cat(1,ptList_reduced ); 

        image1=connectpoly(val_x{i}, val_y{i}); 
       image=bound2im(image1,m,n); 
       gb= imfill( image,4, 'holes');
       
       ga{i} = gb;

    state = regionprops( gb,'all' ); 
    contour_centroid {j} = cat(1, state.Centroid);
    contour_ConvexHull {j} = cat(1, state.ConvexHull); 
    contour_area(j) = cat(1, state.Area) ; 
    contour_BoundingBox{j} = cat(1, state.BoundingBox) ; 
    contour_Extrema{j} = cat(1, state.Extrema) ; 
    contour_PixelIdxList{j} = cat(1,state.PixelIdxList); 
    contour_Perimeter{j} = cat(1,state. Perimeter); 
    
             if length(contour_ConvexHull {j})>0
                    is_ConvexHull(j) =1;
             else
                    is_ConvexHull(j) =0;
        
             end
              
              circularity(j)= (4.0 * pi *  contour_area(j) )./ ( contour_Perimeter{j}.^2)
              
             ptList{i} = {val_x{i}, val_y{i}};   
end

    nvertices = length(val_x{2});
    lengths = contour_Perimeter{2};
    area = contour_area(2);
    circularitys = circularity(2) ;
    centers = contour_centroid{2};
    is_Convex = max( is_ConvexHull);
    
    T = table( nvertices, lengths , area, circularitys, centers, is_Convex )

     imshowpair(f,~image,'montage')
     
     %% hough p327
     
      clear all; clc; close all;
     f=zeros(101,101);
    f(1,1)=1; f(101,1)=1;f(1,101)=1; f(101,101)=1;f(50,50)=1;
    H=hough(f);
    imshow(H,[]);
     
    
    %% houghpeaks p328
    
    clear all; clc; close all;
    f=zeros(101,101);
    f(1,1)=1; f(101,1)=1;f(1,101)=1; f(101,101)=1;f(50,50)=1;

    [H,theta,rho]=hough(f);
    peaks=houghpeaks(H,5)
    imshow(H,'XData',theta,'YData',rho,'InitialMagnification','fit');
    axis on, axis normal
    xlabel('\theta'), ylabel('\rho');


%% houghlines p329

clear all; clc; close all;
g=imread('test.tif');
f=edge(g,'canny',[0.04, 0.1],1.5);
[H,theta,rho]=hough(f);
peaks=houghpeaks(H,5);
lines = houghlines(f,theta,rho,peaks);
figure, imshow(f), hold
for k=1:length(lines)
xy=[lines(k).point1; lines(k).point2];
plot(xy(:,1),xy(:,2),'LineWidth',4);
end


%% houghlines p329

   clear all; clc;    close all;

f1 =imread('11장-단순물체.ppm');
 T1 = graythresh(f1);
 f2= ~im2bw(f1,T1);
 f3 = imclearborder(f2);
  f4=bwareaopen(f3,30);
 img =~imfill(f4,4, 'holes');      

outlined_img = img;
img = im2bw(img);% img must be rgb and high resolution
img = edge(img);

CC = bwconncomp(img);
STATS = regionprops(CC, 'all');

imshow(f1,[]);hold on;

for i = 1:CC.NumObjects
    BB = STATS(i).Centroid;

    
    BW = STATS(i).Image;% each connected object

    BW = bwmorph(BW,'diag');
    
    [H,T,R] = hough(BW, 'ThetaResolution',12);
    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:)))); 
    lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);

    
    Area = STATS(i).FilledArea;
    Perimeter = STATS(i).Perimeter;
    Roundness=(4*Area*pi)/(Perimeter.^2);
    
        
    if(Roundness > 0.9)
            text(BB(1),BB(2),'circle','color','red');
    elseif(length(lines) == 3)
        text(BB(1),BB(2),'triangle','color','red');
    elseif(length(lines) == 4)
        text(BB(1),BB(2),'rectangle','color','red');
    elseif(length(lines) == 5)
        text(BB(1),BB(2),'Pentagon','color','red');
    else
        text(BB(1),BB(2),'unknown','color','red');
    end
end



%%
    clear all; clc;    close all;

f1 =imread('11장-단순물체.ppm');
 T1 = graythresh(f1);
 f2= ~im2bw(f1,T1);
 f3 = imclearborder(f2);
  f4=bwareaopen(f3,30);
 img =~imfill(f4,4, 'holes');      

 [M,L] = bwlabel(~img,4);
 
 
 for k=1:L
    p=(M==k);
    B{k} =im2bw(M.*p) ;
     img=B{k};
     detect_shape(img);
 end 
 
 
%% 사용자 정의 함수 정리(역순)

% function [out_bimg] = detect_shape( img )
   
    figure; imshow(img,[]);hold on;
    
    
    outlined_img =img;
    img = edge(img);
    
     CC = bwconncomp(img);
     STATS = regionprops(CC, 'all');

    BB = STATS.Centroid;
    
    BW = STATS.Image;% each connected object

    BW = bwmorph(BW,'diag');
    out_bimg =imfill(BW,4, 'holes');

    
    [H,T,R] = hough(BW, 'ThetaResolution',12);
    P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);


    Orient = STATS.Orientation;
    Area = STATS.FilledArea;
    Perimeter = STATS.Perimeter;
    Roundness=(4*Area*pi)/(Perimeter.^2);
    
        
     if(Roundness > 0.9)
             text(BB(1),BB(2),'circle','color','red');
     elseif(length(lines) == 3)
         text(BB(1),BB(2),'triangle','color','red');
     elseif(length(lines) == 4)
         text(BB(1),BB(2),'rectangle','color','red');
     elseif(length(lines) == 5)
         text(BB(1),BB(2),'Pentagon','color','red');
     else
         text(BB(1),BB(2),'unknown','color','red');
     end     
end 


%%

 %function ptList_reduced = RDP_recs(ptList, epsilon)
        n = size(ptList,1);
        if n <= 2
            ptList_reduced = ptList;
            return;
        end
        
        %Find the point with the maximum distance
        
        dmax =0;
        idx = 0;
        for k = 2:n-1
            d = PerpendicularDistance(ptList(k,:), ptList([1,n],:));
            if d > dmax
                dmax = d;
                idx = k;
            end
        end
        
        %If max distance is greater than epsilon, recursively simplify
        
        if dmax > epsilon
            %Recursive call
        %     recList1 = RDP_recs(ptList(1:idx,:), idx);
         %   recList2 = RDP_recs(ptList(idx:n,:), n-idx+1);
          recList1 = RDP_recs(ptList(1:idx,:), epsilon);
           recList2 = RDP_recs(ptList(idx:n,:), epsilon);
            %Build the result list
            ptList_reduced = [recList1; recList2(2:end,:)];
        else
            ptList_reduced = ptList([1,n],:);
        end
    end

%    function d = PerpendicularDistance(pt, lineNode)
        %lineNode: [NodeA[Ax,Ay];NodeB[Bx,By]]
        Ax = lineNode(1,1);
        Ay = lineNode(1,2);
        Bx = lineNode(2,1);
        By = lineNode(2,2);
        d_node = sqrt((Ax-Bx).^2+(Ay-By).^2);
        if d_node > eps
            d = abs(det([1 1 1;pt(1) Ax Bx;pt(2) Ay By]))/d_node;
        else
            d = sqrt((pt(1)-Ax).^2+(pt(2)-Ay).^2);
        end
        end
    
 %%
        