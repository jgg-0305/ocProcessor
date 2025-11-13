%% (242p)

s = sin(20.*linspace(0,pi,1000)) + 0.5.*rand(1,1000);
[cA,cD] = dwt(s,'db2');
[length(cA) length(cD)]
ans =
501 501

%% (246p)

clear all; clc; close all;
% 1차원 신호 생성 .
randn('seed',531316785)
s = 2 + kron(ones(1,8),[1 –1]) + ((1:16).^2)/32 + 0.2*randn(1,16);
% haar 필터를 적용한 1차원 단일 레벨 이산 웨이블릿 변환
[ca1,cd1] = dwt(s,'haar');
subplot(311); plot(s); title('Original signal');
subplot(323); plot(ca1); title(Approx. coef. for haar');
subplot(324); plot(cd1); title('Detail coef. for haar');
[Lo_D,Hi_D] = wfilters('haar','d'); % 저역통과 분해 고역통과 분해
[ca1,cd1] = dwt(s,Lo_D,Hi_D);
[ca2,cd2] = dwt(s,'db2');
subplot(325); plot(ca2); title('Approx. coef. for db2');
subplot(326); plot(cd2); title('Detail coef. for db2');

%% (248p)

clear all; clc; close all;
% 1차원 신호 생성 .
randn('seed',531316785)
s = 2 + kron(ones(1,8),[1 –1]) + ((1:16).^2)/32 + 0.2*randn(1,16);
% 이산 웨이블릿 변환 및 그래프 그리기
[ca1,cd1] = dwt(s,'db2');
subplot(221); plot(ca1);
title('Approx. coef. for db2');
subplot(222); plot(cd1);
title('Detail coef. for db2');
% 이산 웨이블릿 역변환, 오차 계산 및 그래프 그리기
ss = idwt(ca1,cd1,'db2');
err = norm(s-ss); % Check reconstruction.
subplot(212); plot([s;ss]');
title('Original and reconstructed signals');
xlabel(['Error norm = ',num2str(err)])
% 재구성 저역통과 필터와 재구성 고역 통과 필터를 이용한 웨이블릿 역변환
[Lo_R,Hi_R] = wfilters('db2','r');
ss = idwt(ca1,cd1,Lo_R,Hi_R);

%% (250p)

clear all; clc; close all;
% 오리지널 영상 로드
load woman;
% 컬러맵이 포함된 오리지널 영상의 크기
nbcol = size(map,1);
% 2차원 웨이블릿 변환
[cA1,cH1,cV1,cD1] = dwt2(X,'db1');
% 웨이블릿 디스플레이
cod_cA1 = wcodemat(cA1,nbcol);
cod_cH1 = wcodemat(cH1,nbcol);
cod_cV1 = wcodemat(cV1,nbcol);
cod_cD1 = wcodemat(cD1,nbcol);
dec2d = [ cod_cA1, cod_cH1; cod_cV1, cod_cD1];
image(dec2d );
colormap(map)
colormap(pink)
title('Decomposition at level 1');

%% (251p)

clear all; clc; close all;
% 오리지널 영상 로드
load woman;
% 컬러맵이 포함된 오리지널 영상의 크기
nbcol = size(map,1);
% 2차원 웨이블릿 변환
[cA1,cH1,cV1,cD1] = dwt2(X,'db1');
% 1-레벨 이미지 코딩
cod_X = wcodemat(X,nbcol);
cod_cA1 = wcodemat(cA1,nbcol);
cod_cH1 = wcodemat(cH1,nbcol);
cod_cV1 = wcodemat(cV1,nbcol);
cod_cD1 = wcodemat(cD1,nbcol);
dec2d = [ cod_cA1, cod_cH1; cod_cV1, cod_cD1];
% 2-레벨 이미지 코딩
[cA2,cHD2,cVD2,cDD2] = dwt2(cA1,'db1');
cod_cA2 = wcodemat(cA2,nbcol);
cod_cHD2 = wcodemat(cHD2,nbcol);
cod_cVD2 = wcodemat(cVD2,nbcol);
cod_cDD2 = wcodemat(cDD2,nbcol);
% 2-레벨 이미지 코딩
[cA2,cHD2,cVD2,cDD2] = dwt2(cA1,'db1');
a0 = idwt2(cA1,cH1,cV1,cD1,'db1',X);
% 멀티 레벨 2차원 웨이블릿 분해 함수를 이용한 분해
[c,s] = wavedec2(X,2,'db1');
%
figure; wavedisplay(c,s); colormap(map); colormap(pink);
title('Decomposition at level 2');

%% (253p)

clear all; clc; close all;
% 오리지널 영상 로딩
load woman;
X= wonan;
% 오리지널 영상의 크기
sX = size(X);
% 2차원 웨이블릿 변환
[cA1,cH1,cV1,cD1] = dwt2(X,'db4');
% 2차원 웨이블릿 역변환
A0 = idwt2(cA1,cH1,cV1,cD1,'db4',sX);
% 성능 평가
max(max(X-A0))
ans =
3.3032e-10