
function PowerList=SHanalysis(illumination_rgb)
load('./+IRIfunction/value/mean_all.mat','mean_all');
%Light probe画像のリスト化-------------------------------------------------
%LightProbesフォルダ内の画像を読み込みます。正距円筒図法で長方形になった
%  球面画像が解析対象です。デフォルトでは.hdr形式の画像を読み込みます。
%.hdr以外の画像を解析したい場合は、Light probe画像の拡張子に合わせて例のよう
%  に拡張子を書き換えてください。
%HdrSwitchの値は.hdr画像を解析する場合は1、それ以外の場合は0にしてください。
%--------------------------------------------------------------------------

%画像(.hdr)
% img = dir([hdrplace '*.hdr']);
%画像(.hdr以外の例)
%img = dir('./LightProbes/*.PNG'); %.png形式の画像を読み込みたいときの例
%img = dir('./LightProbes/*.bmp'); %.bmp形式の画像を読み込みたいときの例

% HdrSwitch = 1;

%計算する次数(L)の最大値----------------------------------------------------
%MaxLの値を0～(inf)にすることで計算する次数の最大値を指定します。
%  各次数は2*L+1の位数(M)を持つので、MaxLを増やすと計算時間が大幅に増加していきます。
%--------------------------------------------------------------------------

MaxL = 10;

%解析結果を格納する行列の初期化
PowerList = zeros(length(illumination_rgb),MaxL + 1);

%Light probe画像の球面調和関数(Ylm)とその係数(flm)への分解
for iNum = 1:length(illumination_rgb)
    
    %画像をグレースケールに変換
    %ガンマカーブでDigitを輝度に変換
    %     ImageGamma = ImageSDR.^2.2;
    %RGBの輝度からピクセルごとの輝度を算出（rgb2grayの重み付けがsRGBと違うから人力でやってる)
    illumination_xyz=srgbxyz(cell2mat(illumination_rgb(iNum,:)));
    ImageLum2=illumination_xyz.*mean_all./mean2(illumination_xyz);%モデルに使った平均輝度と揃える
    [hi,~,~]=size(ImageLum2);
    ImageLum=imresize(ImageLum2,1024/hi);%サイズを調整
    [hi,li,~]=size(ImageLum);
    Image2 = ImageLum(:,li-hi+1:li,:);
    ImageLum(:,1:hi,:)=fliplr(Image2);%hdr画像の照明部分を左右にミラーリング
    
    
    
    
    
    
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
        
        LPower(1,L+1) = rms(power);
        PowerList(iNum,:) = LPower(1,:);
        disp(['L=' int2str(L)])
        clearvars M power mNum
    end
    
    %     clearvars Image Image2 ImageCasted ImageSDR ImageGamma ImageDigit ImageLum...
    %                 ImgSize ImageCast HighCutImg ap az x y theta phi L LPower
    clearvars ImageLum...
        ImgSize ImageCast HighCutImg ap az x y theta phi L LPower
end

end


function XYZ = srgbxyz(hdrhdr)

%大きさを取得し、関数に入るようにサイズ変換
[a,b,~]=size(hdrhdr);
hdr2 = reshape(hdrhdr,3,[]);

%SRGB→XYZに変換
hdrxyz=SRGBPrimaryToXYZ(hdr2);

%サイズを戻す
XYZMontage=reshape(hdrxyz,a,b,3);

%輝度成分のみを取り出す
XYZ = XYZMontage(:,:,2);



end