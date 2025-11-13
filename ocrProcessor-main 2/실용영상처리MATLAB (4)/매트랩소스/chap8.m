%% (213p)

clear all; clc; close all;
Fs = 1000; % Sampling frequency
T = 1/Fs; % Sample time
L = 1000; % Length of signal
t = (0:L-1)*T; % Time vector
% Sum of a 50 Hz sinusoid and a 120 Hz sinusoid
x = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);
y = x + 2*randn(size(t)); % Sinusoids plus noise
subplot(1,2,1)
plot(Fs*t(1:50),y(1:50))
title('Signal Corrupted with Zero-Mean Random Noise')
xlabel('time (milliseconds)')
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(y,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);
% Plot single-sided amplitude spectrum.
subplot(1,2,2)
plot(f,2*abs(Y(1:NFFT/2+1)))
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')

%% (215p)

%%clear all; clc; close all;
%%N2 = 1024;
%%[gx, gy] = meshgrid( gpuArray.colon( -1, 1/N2, (N2-1)/N2 ) );
%%aperture = ( abs(gx) < 4/N2 ) .* ( abs(gy) < 2/N2 );
%%lightsource = double( aperture );
%%farfieldsignal = fft2( lightsource );
%%farfieldintensity = real( farfieldsignal .* conj( farfieldsignal ) );
%%imagesc( fftshift( farfieldintensity ) );
%%axis( 'equal' ); axis( 'off' );
%%title( 'Rectangular aperture far-field diffraction pattern' );
%%slits = (abs( gx ) <= 10/N2) .* (abs( gx ) >= 8/N2);
%%aperture = slits .* (abs(gy) < 20/N2);
%%lightsource = double( aperture );
%%farfieldsignal = fft2( lightsource );
%%farfieldintensity = real( farfieldsignal .* conj( farfieldsignal ) );
%%figure
%%imagesc( fftshift( farfieldintensity ) );
%%axis( 'equal' ); axis( 'off' );
%%title( 'Double slit far-field diffraction pattern' );

%% (216p)

f=[ones(1,20),zeros(1,200)];
F=fft(f);
Fc=fftshift(F);
figure, plot(f)
figure, plot(Fc)
figure, plot(abs(Fc))

%%(217p)

clear all;
I = zeros(256,256);
I(78:178,78:178)=1;
imshow(I,[]);
FI= fftshift(fft2(I));
figure, imshow(abs(FI),[]);
F2=log(1+abs(FI));
figure, imshow(F2,[]);

%%(217p)

P = phantom('Modified Shepp-Logan',200);
imshow(P);
FP=fft2(P);
FP1= fftshift(FP);
figure, imshow(abs(FP1),[]);
FP2=log(1+abs(FP1));
figure, imshow(FP2,[]);
FP3 =ifft2(FP);
figure, imshow(FP3,[]);

%%(218p)

fid = fopen('horizontal.raw'); % raw 형식의 파일은 파일로 읽음
size=[256,256];
P=fread(fid,size);
status=fclose(fid);
FP=fft2(P);
FP1= fftshift(FP);
FP2=log(1+abs(FP1));
FP3 =ifft2(FP);
subplot(1,2,1), imshow(FP3,[]);
subplot(1,2,2), imshow(FP2,[]);

%%(219p)

fid = fopen('vertical.raw'); % raw 형식의 파일은 파일로 읽음
size=[256,256];
P=fread(fid,size);
status=fclose(fid);
FP=fft2(P);
FP1= fftshift(FP);
FP2=log(1+abs(FP1));
FP3 =ifft2(FP);
subplot(1,2,1), imshow(FP3,[]);
subplot(1,2,2), imshow(FP2,[]);

%%(220p)

fid = fopen('cross.raw'); % raw 형식의 파일은 파일로 읽음
size=[256,256];
P=fread(fid,size);
status=fclose(fid);
FP=fft2(P);
FP1= fftshift(FP);
FP2=log(1+abs(FP1));
FP3 =ifft2(FP);
subplot(1,2,1), imshow(FP3,[]);
subplot(1,2,2), imshow(FP2,[]);

%%(224p)

clear all; clc;
f = imread('Lenna.jpg');
F= fft2(f);
cF=fftshift(F);
lofF=log(1+abs(cF));
[M,N]=size(f);
[x,y]=meshgrid(-floor(N/2):floor((N-1)/2),-floor(M/2):floor((M-1)/2));
d=64; n=2;
bl=1./(1+(sqrt(2)-1)*((x.^2+y.^2)/d^2).^n);
cfbl=cF.*bl;
cfbli=ifft2(cfbl);
title('버터워스 필터 효과');
subplot(2,2,1),imshow(f,[]), xlabel('원영상');
subplot(2,2,2),imshow(cF,[]), xlabel('푸리에 스펙트럼 영상');
subplot(2,2,3),imshow(lofF,[]), xlabel('로그변환이 적용된 스펙트럼 영상');
subplot(2,2,4),imshow(abs(cfbli),[]),xlabel('버터워스 필터 효과');

%%(226p)

clear all; clc;
f = imread('Lenna.jpg');
F= fft2(f);
cF=fftshift(F);
lofF=log(1+abs(cF));
[M,N]=size(f);
[x,y]=meshgrid(-floor(N/2):floor((N-1)/2),-floor(M/2):floor((M-1)/2));
d=8; n=2;
bl=1./(1+(sqrt(2)-1)*((x.^2+y.^2)/d^2).^n);
bh=1-bl;
cfbh=cF.*bh;
cfbhi=ifft2(cfbh);
subplot(2,2,1),imshow(f,[]), xlabel('원영상');
subplot(2,2,2),imshow(cF,[]), xlabel('푸리에 스펙트럼 영상');
subplot(2,2,3),imshow(lofF,[]), xlabel('로그변환이 적용된 스펙트럼 영상');
subplot(2,2,4),imshow(abs(cfbhi),[]),xlabel('버터워스 고역필터 효과');

%%(230p)

x = (1:100) + 50*cos((1:100)*2*pi/40);
X = dct(x);
[XX,ind] = sort(abs(X),'descend');
i = 1;
while norm(X(ind(1:i)))/norm(X)<0.99
i = i + 1;
end
Needed = i;
X(ind(Needed+1:end)) = 0;
xx = idct(X);
plot([x;xx]')
legend('Original',['Reconstructed, N = ' int2str(Needed)], 'Location', 'SouthEast')

%%(232p)

I = imread('Lenna.jpg');
J = dct2(I);
J(abs(J) < 10) = 0;
K = idct2(J);
subplot(1,3,1), imshow(I,[ ]), xlabel('원영상');
subplot(1,3,2),imshow(log(abs(J)),[]),xlabel('2차원 DCT 결과');
subplot(1,3,3), imshow(K,[ ]), xlabel('2차원 DCT 역변환 결과');