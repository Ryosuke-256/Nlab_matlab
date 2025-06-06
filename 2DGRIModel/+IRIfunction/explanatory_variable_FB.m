
function [explanatory_variable,var_temp2]=explanatory_variable_FB(illumination_rgb,hdrplace)

%変数を一時的に入れる配列
var_temp=zeros(length(illumination_rgb),41);

%平均輝度を揃えるためのデータ
load('./+IRIfunction/value/mean_all.mat','mean_all');

%z-score変換用のデータ
load('./+IRIfunction/value/mean_std_index.mat','mean_X','std_X','index_X');




%フィルターの分割数,サイズ(自分の画像で使っている値です。基本的に変更することはありません。)
filternum=6;filtersize=201;

%周波数分解フィルターを作る
hdrfilter=zeros(filtersize,filtersize,6);
for i=1:filternum
    hdrfilter(:,:,i)=IRIfunction.subfilter(i);
end


disp('球面調和関数以外の説明変数を算出中...')
for b=1:length(illumination_rgb)
    %% rgbをXYZに変換し、全体部分、照明部分、背景部分に変換
    illumination_xyz=srgbxyz(cell2mat(illumination_rgb(b,:)));
    
    Y_all=illumination_xyz.*mean_all./mean2(illumination_xyz);%モデルに使った平均輝度と揃える
    [h,l]=size(Y_all);
    
    Y_righty=Y_all(1:h,h+1:l);%照明環境の照明部分(デフォルトは右半分)を取り出す
    Y_lefty=Y_all(1:h,1:h);%照明環境の背景部分(デフォルトは左半分)を取り出す

    %% 画像サイズトラブル確認用
    %{
    disp("Y_all");
    disp([h,l]);
    disp("right");
    disp(size(Y_righty));
    disp("left");
    disp(size(Y_lefty));
    %}

    %% 照明部分から標準偏差、尖度、歪度、エントロピーを求める
    var_temp(b,1)=std2(Y_righty);%標準偏差
    var_temp(b,2)=skewness(Y_righty,1,'all');%尖度
    var_temp(b,3)= kurtosis(Y_righty,1,'all');%歪度
    var_temp(b,4)=entropy(double(Y_righty));%エントロピー(doubleしか引数に入れることができないため変換)
    
    %% 背景部分から標準偏差、尖度、歪度、エントロピーを求める
    var_temp(b,5)=std2(Y_lefty);%標準偏差
    var_temp(b,6)=skewness(Y_lefty,1,'all');%尖度
    var_temp(b,7)= kurtosis(Y_lefty,1,'all');%歪度
    var_temp(b,8)=entropy(double(Y_lefty));%エントロピー(doubleしか引数に入れることができないため変換)
    
    
    %% subbandコントラスト、歪度、尖度を求める
    for j=1:filternum
        sb_lumimag =imfilter(Y_righty,hdrfilter(:,:,j),'symmetric');%周波数分解を行う
        substd=std2(sb_lumimag);%標準偏差
        var_temp(b,8+j)=substd/mean2(Y_righty);%サブバンドコントラスト;
        var_temp(b,14+j)=skewness(sb_lumimag,1,'all');%サブバンド歪度
        var_temp(b,20+j)= kurtosis(sb_lumimag,1,'all');%サブバンド尖度
    end
    
    %% 照明サイズ、照明数を求める%%
    illumination_rgb_resize=imresize(cell2mat(illumination_rgb(b,:)),1024/h);%大きさをモデル作成に使った照明画像に合わせる
    
    Y_all_resize=srgbxyz(illumination_rgb_resize);
    Y_all_resize=Y_all_resize.*mean_all./mean2(Y_all_resize);
    [h_resize,l_resize]=size(Y_all_resize);
    %1.hdr全体から光源と推測される部分を求める
    hdrmean_su=mean2(Y_all_resize);%hdr全体の平均輝度
    hdrstd_su=std2( Y_all_resize);%hdr全体の標準偏差
    highlight_thr=hdrmean_su+2*hdrstd_su;%光源部分を平均+2SD以上と定義
    A= Y_all_resize >= highlight_thr;%光源部分を求める
    A = bwareaopen(A,70); %恐らく光源ではないノイズ部分を除去
    
    %2.hdrの照明部分の照明数、照明サイズを求める
    A2=A(:,h_resize+1:l_resize);%照明部分を取り出す
    pixel_count=nnz(A2);%光源部分のピクセル数を求める
    var_temp(b,27)=IRIfunction.sizenumber(A2,pixel_count);%照明数(光源部分のピクセル郡の数)を求める
    if var_temp(b,27)==0
        var_temp(b,28)=0;%照明数が0のときは照明サイズも0にする
    else
        var_temp(b,28)=pixel_count./var_temp(b,27);%ピクセル数を照明数で割ることで平均照明サイズを求める
    end
    disp([int2str(b/length(illumination_rgb)*100) '%完了'])
end

%% 球面調和関数を計算(Signal Processing Toolboxが必要)
disp('球面調和関数を算出中...')
[var_temp(:,29:39),var_temp(:,40),var_temp(:,41)]=IRIfunction.SHanalysis_TN(hdrplace);
%Adams(2019)らが使用した指標を計算
disp('完了')

%% 説明変数を標準化し、z-score化

var_temp2=var_temp;%保存用


pan=ones(length(illumination_rgb),41);%正負判断用
pan(var_temp<0)=-1;%負なら-1、それ以外なら1

var_temp=abs(var_temp).^index_X;%標準化
var_temp=var_temp.*pan;%負のものを負に戻す

var_temp=(var_temp-mean_X)./std_X;%z-score化



%% 説明変数を出力
explanatory_variable=table(var_temp);

explanatory_variable=splitvars(explanatory_variable);
explanatory_variable.Properties.VariableNames = {'hdrstd','hdrskewness','hdrkurtosis','hdrentropy','hdrstd_lefty','hdrskewness_lefty','hdrkurtosis_lefty','hdrentropy_lefty','hdrcontrast_sb_1','hdrcontrast_sb_2','hdrcontrast_sb_3','hdrcontrast_sb_4','hdrcontrast_sb_5','hdrcontrast_sb_6','hdrskewness_sb_1','hdrskewness_sb_2','hdrskewness_sb_3','hdrskewness_sb_4','hdrskewness_sb_5','hdrskewness_sb_6','hdrkurtosis_sb_1','hdrkurtosis_sb_2','hdrkurtosis_sb_3','hdrkurtosis_sb_4','hdrkurtosis_sb_5','hdrkurtosis_sb_6','illumination_count','illumination_size','SH_power_0','SH_power_1','SH_power_2','SH_power_3','SH_power_4','SH_power_5','SH_power_6','SH_power_7','SH_power_8','SH_power_9','SH_power_10','Brilliance','Diffuseness'};

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