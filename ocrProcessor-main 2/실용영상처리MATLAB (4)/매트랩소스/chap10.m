%% (272p)

function pb_load_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile({'*.bmp';'*.jpg';'*.gif';'*.*'}, 'Pick an Image File');
img=imread([pathname,filename]);
set(handles.edit1,'String',[pathname,filename]);
axes(handles.img_display);
imagesc(img);
set(handles.img_display,'Visible','off');
guidata(hObject, handles);

%% (274p)

function add_OpeningFcn(hObject, eventdata, handles, varargin)
handles.I = imread('cameraman.tif');
J=handles.I;
axes(handles.axes1);
imshow(J)

%% (274p)

function edit1_Callback(hObject, eventdata, handles)
A=str2num(get(handles.edit1, 'String')); % 문자를 숫자로 변경
J=handles.I;
ADDJ=imadd(J,A); % 덧셈 연산
axes(handles.axes3); % 출력할 그림창
imshow(ADDJ,[]); % 영상 디스플레이

%% (275p)

function edit2_Callback(hObject, eventdata, handles)
B=str2num(get(handles.edit2, 'String')); % 문자를 숫자로 변경
J=handles.I;
subJ=imsubtract(J,B); % 뺄셈 연산
axes(handles.axes3);
imshow(subJ,[]);

%% (275p)

function edit3_Callback(hObject, eventdata, handles)
C=str2num(get(handles.edit3, 'String'));
J=handles.I;
multJ=immultiply(J,C); % 곱셈 연산
axes(handles.axes3);
imshow(multJ,[]);

%% (276p)

function edit4_Callback(hObject, eventdata, handles)
D=str2num(get(handles.edit4, 'String'));
J=handles.I;
divJ=imdivide(J,D); % 나눗셈 연산
axes(handles.axes3);
imshow(divJ,[]);

%% (278p)

function add_OpeningFcn(hObject, eventdata, handles, varargin)
handles.I = imread('cameraman.tif');
J=handles.I;
axes(handles.axes1);
imshow(J)

%% (278p)

function slider1_Callback(hObject, eventdata, handles)
J=handles.I;
angle = round(get(hObject,'Value') );
axes(handles.axes1);
imshow(imrotate(J,angle),findobj(hObject,'Tag','axes1'));
get(handles.edit1, 'String');
set(handles.edit1,'String',angle);

%% (282~285p)

function warping_OpeningFcn(hObject, eventdata, handles, varargin)
handles.I = imread('여인.ppm');
J=handles.I;
axes(handles.axes1);
imshow(J)
global k Ax Ay Bx By
k=0;
handles.output = hObject;
guidata(hObject, handles);
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
global k Ax Ay Bx By
cursorPoint = get(handles.axes1, 'CurrentPoint');
curX = round(cursorPoint(1,1));
curY = round(cursorPoint(1,2));
if(k==1)
k=2;
Bx= curX;
By= curY;
axes(handles.axes1);
hold on;
if (Bx>Ax)
xx=Ax:Bx;
yy=((By-Ay)*(xx-Ax))/(Bx-Ax)+Ay;
else
xx=Bx:Ax;
yy=((Ay-By)*(xx-Bx))/(Ax-Bx)+By;
end
plot(xx,yy);
end
if (k==0)
k=1;
Ax= curX;
Ay=curY;
end
guidata(hObject, handles);
function pushbutton1_Callback(hObject, eventdata, handles)
global k Ax Ay Bx By
if (Ax<Bx) Px=round(Ax-(Bx-Ax)/2);
else Px=round(Ax+(Bx-Ax)/2);
end
if (Ax<Bx) Py=round(Ay-(By-Ay)/2);
else Py=round(Ay+(By-Ay)/2);
end
K= handles.I;
warp_I=uint8(zeros(size(K)));
size(K);
size(K,3);
SI=[Px,Py,Ax,Ay;1,1,size(K,2),1;1,1,1,size(K,1);1,size(K,1),size(K,2),...
size(K,1);size(K,1),1,size(K,2),size(K,1)];
DI=[Px,Py,Bx,By;1,1,size(K,2),1;1,1,1,size(K,1);1,size(K,1),size(K,2),...
size(K,1);size(K, 1),1,size(K,2),size(K,1)];
DI_x1=DI(:,1,:,:);
DI_y1=DI(:,2,:,:);
DI_x2=DI(:,3,:,:);
DI_y2=DI(:,4,:,:);
SI_x1=SI(:,1,:,:);
SI_y1=SI(:,2,:,:);
SI_x2=SI(:,3,:,:);
SI_y2=SI(:,4,:,:);
for y=1:size(K,1)
for x=1:size(K,2)
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
if (u<0) d=sqrt((x-x1)^2+(y-y1)^2);
elseif (u>1) d=sqrt((x-x2)^2+(y-y2)^2);
else d=abs(h); end
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
if (source_x < 1 ) source_x=1; end
if (source_x > size(I,2)) source_x = size(I,2); end
if (source_y < 1 ) source_y=1; end
if (source_y > size(I,1)) source_y=size(I,1); end
% 그레이 스케일 영상과 컬러 영상 확인
if size(K,3)==3
warp_I(y,x,1)=K(source_y,source_x,1);
warp_I(y,x,2)=K(source_y,source_x,2);
warp_I(y,x,3)=K(source_y,source_x,3);
else
warp_I(y,x)=uint8(K(source_y,source_x));
end
end
end
axes(handles.axes2);
imshow(warp_I,[])