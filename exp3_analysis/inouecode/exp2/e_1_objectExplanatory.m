clear;

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';

% プログラム実行時の時間(ファイル保存用)
dt = datestr(now,'0yyyy_0mm_0dd_0HH_0MM');

% 周波数分解フィルターを作る
filterNum = 6;
filterSize = 201;
hdrfilter = zeros(filterSize,filterSize,6);

for i = 1:filterNum
    hdrfilter(:,:,i) = IRIfunction.subfilter(i);
end

filterVertex = [64,64,193,193; 105,97,199,191; 132,51,178,97; 53,39,232,218; 53,42,227,216; 57,44,226,213; 70,47,232,209; 68,50,226,208; 68,51,226,209;];

% 条件
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size015" "board_ang0_size03" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
allMeshNum = length(mesh);
allMaterialNum = length(material);
allRoughnessNum = length(roughness(1, :));
experimentNum = allMeshNum * allMaterialNum;

experiment_illum = [5, 19, 34, 39, 42, 43, 78, 80, 102, 105, 125, 152, 164, 183, 198, 201, 202, 203, 209, 222, 226, 227, 230, 232, 243, 259, 272, 278, 281, 282];
illum = 1:295;
allIllumNum = length(illum);

for meshNum = 1 : allMeshNum
    currentMeshNum = meshNum;
    filename_mask = fullfile(rootpath, "data4analysis", "mask", mesh(meshNum) + "_mask.mat");
    filename_mask_nan = fullfile(rootpath, "data4analysis", "mask", mesh(meshNum) + "_mask_nan.mat");
    load(filename_mask);
    load(filename_mask_nan);

    a = image_np_mask(:,:,2);
    b = image_np_mask_nan(:,:,2);
    
    for materialNum = 1 : allMaterialNum
        currentMaterialNum = materialNum;
        
        imagemean = zeros(experimentNum, allRoughnessNum,1);
        imageskewness=zeros(experimentNum,allRoughnessNum,1);%歪み度
        imagekurtosis=zeros(experimentNum,allRoughnessNum,1);%sendo
        imageskewness_sb=zeros(experimentNum,allRoughnessNum,filterNum);%歪み度(周波数分解)
        imagestd=zeros(experimentNum,allRoughnessNum,1);%平均輝度
        imagestd_sb=zeros(experimentNum,allRoughnessNum,filterNum);%サブバンドの標準偏差
        imagesubcontrast=zeros(experimentNum,filterNum,allRoughnessNum);%サブバンドコントラスト
        imagehighlightcontrast=zeros(experimentNum,allRoughnessNum,1);%ハイライトコントラスト
        imagehighlightcoverage=zeros(experimentNum,allRoughnessNum,1);%ハイライトカバレッジ
        
        for illumNum = 1 : allIllumNum
            for roughnessNum = 1 : allRoughnessNum
                filename_XYZ = strcat(rootpath, "/data4analysis/imageXYZ/", mesh(meshNum), "/", mesh(meshNum), "_", material(materialNum), "_", roughness(materialNum, roughnessNum), "_", num2str(illum(illumNum)), ".mat");                
                load(filename_XYZ);
                
                lum_XYZ = xyz_data(:,:,2) .* image_np_mask(:,:,2);
                lum_list = lum_XYZ(logical(image_np_mask(:,:,2)));
                c = lum_list;
                
                % 物体条件ごとに切り抜く部分を変える
                object_original = xyz_data(filterVertex(meshNum,1):filterVertex(meshNum,3), filterVertex(meshNum,2):filterVertex(meshNum,4), 2);
                
                imagemean(illumNum,roughnessNum,1) = mean(lum_list);%平均輝度
                imagestd(illumNum,roughnessNum,1) = std(lum_list) / mean(lum_list);%標準偏差
                imageskewness(illumNum,roughnessNum,1) = skewness(lum_list);%歪度
                [imagehighlightcontrast(illumNum,roughnessNum,1),imagehighlightcoverage(illumNum,roughnessNum,1)] = subfunc.object_highlight(xyz_data(:,:,2) ,image_np_mask_nan(:,:,2));%物体ハイライト
                
                for j = 1:filterNum
                    %サブバンドを計算
                    sb_lumimag = imfilter(object_original,hdrfilter(:,:,j),'symmetric');%周波数分解を行う
                    imagestd_sb(illumNum,roughnessNum,j) = std2(sb_lumimag);%サブバンド画像の標準偏差
                    imagesubcontrast(illumNum,roughnessNum,j) = imagestd_sb(illumNum,roughnessNum,j)/imagemean(illumNum,roughnessNum,1);%サブバンドコントラストを求める(サブバンド画像の標準偏差)/(元画像の平均輝度)
                    imageskewness_sb(illumNum,roughnessNum,j) = skewness(sb_lumimag,1,'all');%サブバンド画像の歪度
                end
                
            end
            disp(illumNum)
        end
        
        
        for roughnessNum = 1:allRoughnessNum
            
            roughness_value = roughnessNum;
            
            ob_explanatory(:,1:6) = imagesubcontrast(:,roughness_value,:);
            ob_explanatory(:,7) = imagemean(:,roughness_value,1);
            ob_explanatory(:,8) = imageskewness(:,roughness_value,1);
            ob_explanatory(:,9:14) = imageskewness_sb(:,roughness_value,:);
            ob_explanatory(:,15) = imagestd(:,roughness_value,1);
            ob_explanatory(:,16) = imagehighlightcontrast(:,roughness_value,1);
            ob_explanatory(:,17) = imagehighlightcoverage(:,roughness_value,1);
            
            
            filename = strcat(rootpath,"/data4analysis/object_explanatory/",mesh(meshNum), '_', material(materialNum), '_' +roughness(materialNum, roughnessNum) ,'.mat');
            save(filename, 'ob_explanatory', '-mat');
        end
        
    end
end