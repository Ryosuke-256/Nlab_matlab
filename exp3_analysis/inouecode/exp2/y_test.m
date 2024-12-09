clear all;

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size015" "board_ang0_size03" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
meshNum = length(mesh);
materialNum = length(material);
roughnessNum = length(roughness(1, :));
experimentNum = meshNum * materialNum;

experiment_illum = [5, 19, 34, 39, 42, 43, 78, 80, 102, 105, 125, 152, 164, 183, 198, 201, 202, 203, 209, 222, 226, 227, 230, 232, 243, 259, 272, 278, 281, 282];
illum = 1:295;
illumNum = length(illum);

maskList = zeros(256,256,9);
for j1 = 1 : meshNum
    currentMeshNum = j1;
    filename_mask = strcat(rootpath,"/data4analysis/mask/",mesh(j1), "_mask.mat");
    load(filename_mask);
    maskList(:,:,j1) = image_np_mask(:,:,2);
    
end


count = 1;
for j1 = 1 : meshNum
    for j2 = 1 : materialNum
        for i2 = 1 : roughnessNum
            count2 = 1;
            for i1 = experiment_illum%1 : illumNum
                
                filename_XYZ = strcat(rootpath, "/data4analysis/imageXYZ/", mesh(j1), "/", mesh(j1), "_", material(j2), "_", roughness(j2, i2), "_", num2str(illum(i1)), ".mat");
                load(filename_XYZ);
                
                image_Y{count,count2} = xyz_data(:,:,2);
                
                count2 = count2 + 1;
            end
            count= count+ 1;
        end
    end
end

Y = [];
for i = 1:54
    for j = 1:30
        % セル内の輝度データの平均を計算
        Y = [Y;image_Y{i,j}(:)];
    end
end

bar(Y);