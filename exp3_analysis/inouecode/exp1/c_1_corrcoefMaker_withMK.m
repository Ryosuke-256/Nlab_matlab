clear all;

%% 2.選好尺度値から物体条件間の相関行列を作成

load('z_conditionList_withMK.mat');

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1';
filename = strcat(rootpath, '/z_psvList_withMK.mat');

load(filename);

mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015" "makihiraA" "makihiraB" "makihiraC"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];

[~, meshNum] = size(mesh);
[~, materialNum] = size(material);
[~, roughnessNum] = size(roughness);
illumNum = 30;
[conditionNum, ~] = size(experiment_condition);

shape_corr = zeros(meshNum, illumNum);
material_corr = zeros(materialNum * roughnessNum, illumNum);

% 形状でまとめる

for i = 1 :meshNum
    for j = 1 : conditionNum
        if(experiment_condition(j,2) == mesh(i))
            shape_corr(i,:) = shape_corr(i,:) + zscore(psvList(j,:));
            disp(experiment_condition(j,:));
        end
    end
    mesh_count = sum(experiment_condition(:,2) == mesh(i));
    shape_corr(i,:) = shape_corr(i,:) / mesh_count; 
end

% shape_corr = [shape_corr(10:12,:);shape_corr(1:3,:);shape_corr(5,:);shape_corr(8,:);shape_corr(6,:);shape_corr(9,:);shape_corr(4,:);shape_corr(7,:);];

R_shape = corrcoef(shape_corr');

% 素材でまとめる

count = 1;
count2 = 1;
for i = 1 : materialNum
    for j = 1 : roughnessNum
        for k = 1 : conditionNum
            if(experiment_condition(k,1) == material(i) && experiment_condition(k,3) == roughness(i,j))
                material_corr(count,:) = material_corr(count,:) + zscore(psvList(k,:));
            end
        end
        material_corr(count,:) = material_corr(count,:) / sum((experiment_condition(:,1) == material(i)) & (experiment_condition(:,3) == roughness(i,j)));
        count = count + 1;
    end
end

R_material = corrcoef(material_corr');

mesh_name = ["sphere","bunny","dragon","boardA","boardB","boardC","boardA-30","boardB-30","boardC-30","単純[6]","中間[6]","複雑[6]"];
h1 = figure('Position', [1 1 1200 1200], 'Name', '形状内平均値の相関');
figure(h1)
hm1 = heatmap(mesh_name, mesh_name, R_shape);
%title('形状内平均値の相関');
hm1.FontSize = 20;

fileName = sprintf('corr_matrix_shape_withMK.png');
saveas(hm1, fileName);

material_roughness = ["Cu-0.025", "Cu-0.129", "Pla-0.075", "Pla-0.225", "Glass-0.05", "Glass-0.5"];
h2 = figure('Position', [1 1 1200 1200], 'Name', '素材・ラフネス内平均値の相関');
figure(h2)
hm2 = heatmap(material_roughness, material_roughness, R_material);
%title('素材・ラフネス内平均値の相関');
hm2.FontSize = 20;

fileName = sprintf('corr_matrix_material_withMK.png');
saveas(hm2, fileName);