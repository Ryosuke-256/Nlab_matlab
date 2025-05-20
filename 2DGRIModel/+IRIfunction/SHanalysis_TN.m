function [PowerList,diffuse,brilliance]=SHanalysis_TN(hdrplace)
%Light probe画像のリスト化-------------------------------------------------
%LightProbesフォルダ内の画像を読み込みます。正距円筒図法で長方形になった
%  球面画像が解析対象です。デフォルトでは.hdr形式の画像を読み込みます。
%.hdr以外の画像を解析したい場合は、Light probe画像の拡張子に合わせて例のよう
%  に拡張子を書き換えてください。
%HdrSwitchの値は.hdr画像を解析する場合は1、それ以外の場合は0にしてください。
%--------------------------------------------------------------------------

%画像(.hdr)
img = dir([hdrplace '*.hdr']);
disp(length(img))
%画像(.hdr以外の例)
%img = dir('./LightProbes/*.PNG'); %.png形式の画像を読み込みたいときの例
%img = dir('./LightProbes/*.bmp'); %.bmp形式の画像を読み込みたいときの例

HdrSwitch = 1;

%計算する次数(L)の最大値----------------------------------------------------
%MaxLの値を0～(inf)にすることで計算する次数の最大値を指定します。
%  各次数は2*L+1の位数(M)を持つので、MaxLを増やすと計算時間が大幅に増加していきます。
%--------------------------------------------------------------------------

MaxL = 10;

%解析結果を格納する行列の初期化
PowerList = zeros(length(img),MaxL + 1);

%Light probe画像の球面調和関数(Ylm)とその係数(flm)への分解
figure
for iNum = 1:length(img)
%for iNum = 1:3
    
    %Light probe画像を読み込んでグレースケール画像に変換する----------------
    if HdrSwitch == 1
        %.hdr画像の読み込み
        Image = hdrread([img(iNum).folder '/' img(iNum).name]);
%         Image = HDRRead([img(iNum).folder '/' img(iNum).name]);
        %.hdrの輝度情報をディスプレイのdigitに戻す
%         ImageDigit = nthroot(Image, 2.2);
%         %SDR上の最高輝度(=1)以上の輝度を1に圧縮
%         ImageCasted = cast(ImageDigit, 'double');
%         ImageSDR = ImageCasted;
%         ImageSDR(ImageSDR > 1) = 1;
    else
        %.hdr以外の画像の読み込み
        ImageSDR = imread(img(iNum).name);
    end

    %画像をグレースケールに変換
    %ガンマカーブでDigitを輝度に変換
    % ImageGamma = ImageSDR.^2.2;
    
    [xlen,ylen,dummy] = size(Image);
    halfImage = Image(:, round(ylen/2):end, 1:3);
    Image = cat(2, halfImage, flip(halfImage, 2));
%     Imagetmp = imresize(Image, 0.25);
    ImageGamma = Image;
    %RGBの輝度からピクセルごとの輝度を算出（rgb2grayの重み付けがsRGBと違うから人力でやってる）
    ImageLum(:,:) = 0.2126 * ImageGamma(:,:,1) + 0.7152 *  ImageGamma(:,:,2) + 0.0722 * ImageGamma(:,:,3);
%     meanlum = mean(mean(ImageLum));
%     ImageLum = ImageLum./meanlum;

    
    %画像の縦横の各ピクセルに極角と方位角を割り振る--------------------------
    %画像サイズの取得
    ImgSize = size(ImageLum);
    %極角(Polar angle)
    ap = linspace(0,pi,ImgSize(1));
    %方位角(azimuth angle)
    az = linspace(0,2*pi,ImgSize(2));

    
    %次数(L)ごとの各位数(M)の係数(flm)の算出（本文(3)式）-------------------
    %極角と方位角のグリッドの作製
    [phi,theta] = meshgrid(az,ap);
    x = 1:length(az);
    y = 1:length(ap);

    %作業変数の初期化
    LPower = zeros(1,MaxL + 1);

    for L = 0:MaxL
        fprintf('L=%d\n', L);
        
        M = [-L:L];
        power = zeros(1,length(M));

        for mNum = M
            %係数
            a = (2*L+1)*factorial(L-abs(mNum));
            b = 4*pi*factorial(L+abs(mNum));
            K = sqrt(a/b);

            %ルジャンドル陪関数の算出
            Plm = legendre(L,cos(theta));
            if L == 0 && mNum == 0
                Pex = Plm;
            else
                Pex = reshape(Plm(abs(mNum)+1,:,:), size(phi));
            end
            
            %球面調和関数の算出
            if mNum > 0
                Y = sqrt(2) * K .* cos(mNum * phi) .*  Pex;
            elseif mNum < 0
                Y = sqrt(2) * K .* sin(abs(mNum) * phi) .* Pex;
            else
                Y = K .* Pex;
            end

            SinAlt = sin(ap);
            Rsin = rot90(SinAlt,3);
            SinArray = repmat(Rsin,1,length(az));
            F = double(ImageLum) .* Y .* SinArray;

            %power(1,pNum) = trapz(y, trapz(x, F, 2));
            power(1,find(M == mNum)) = trapz(y, trapz(x, F, 2));
            
            clearvars a b K Plm Pex Y SinAlt Rsin SinArray F
        end

        LPower(1,L+1) = sqrt(sum(power.^2));
        LPower_norm = LPower./LPower(1); % TN: normalize
        PowerList(iNum,:) = LPower_norm(1,:);
        
        clearvars M power mNum
    end 
    
%     plot(1:MaxL+1,LPower_norm(1,:))
%     hold on

    clearvars Image ImageLum...
                ImgSize ImageCast HighCutImg ap az x y theta phi L LPower
            
            disp(iNum)
end

% xlabel('Order')
% xticks(1:MaxL+1)
% xticklabels(string(0:MaxL))
% ylabel('Power')
% legend(img(1:end).name)

clearvars HdrSwitch iNum



%%
diffuse = zeros(1,length(img));
brilliance = zeros(1,length(img));
for filen = 1:length(img)
    diffuse(filen) = 1 - PowerList(filen, 2)/PowerList(filen, 1)/sqrt(3);
    brilliance(filen) = sum(PowerList(filen, 4:10))/sum(PowerList(filen, 1:10));
end

end
