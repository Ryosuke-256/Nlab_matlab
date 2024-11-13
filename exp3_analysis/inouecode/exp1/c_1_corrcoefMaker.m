clear all;

%% 2.選好尺度値から物体条件間の相関行列を作成

load('z_conditionList.mat');

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1';
filename = strcat(rootpath, '/z_psvList.mat');

load(filename);

mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];

[~, meshNum] = size(mesh);
[~, materialNum] = size(material);
[~, roughnessNum] = size(roughness);illumNum = 30;
[conditionNum, ~] = size(experiment_condition);

material_idx = 1;
shape_idx = 2;
roughness_idx = 3;

shape_corr = zeros(meshNum, illumNum);
material_corr = zeros(materialNum * roughnessNum, illumNum);

% 形状でまとめる

for i = 1 :meshNum
    for j = 1 : conditionNum
        if(experiment_condition(j,2) == mesh(i))
            shape_corr(i,:) = shape_corr(i,:) + psvList(j,:);
            disp(experiment_condition(j,:));
        end
    end
    mesh_count = sum(experiment_condition(:,2) == mesh(i));
    shape_corr(i,:) = shape_corr(i,:) / mesh_count; 
end

R_shape = corrcoef(shape_corr');

% 
%{
shape_corr = zeros(illumNum * 6, meshNum);

for i = 1 :meshNum
    tmp = [];
    for j = 1 : conditionNum
        if(experiment_condition(j,1) == mesh(i))
            tmp = [tmp; psvList(j,:)'];
        end
    end
    shape_corr(:,i) = tmp;
end

R_shape2 = corrcoef(shape_corr2);
%}

% 素材でまとめる
count = 1;
count2 = 1;
for i = 1 : materialNum
    for j = 1 : roughnessNum
        for k = 1 : conditionNum
            if(experiment_condition(k,1) == material(i) && experiment_condition(k,3) == roughness(i,j))
                material_corr(count,:) = material_corr(count,:) + psvList(k,:);
            end
        end
        material_corr(count,:) = material_corr(count,:) / sum((experiment_condition(:,1) == material(i)) & (experiment_condition(:,3) == roughness(i,j)));
        count = count + 1;
    end
end

R_material = corrcoef(material_corr');

R_shape_rounded = round(R_shape,3);
redblue = [linspace(0, 1, 100)', linspace(0, 1, 100)', linspace(1, 0, 100)'];
mesh_name = ["sphere","bunny","dragon","boardA","boardB","boardC","boardA-30","boardB-30","boardC-30"];%,"単純[2]","中間[2]","複雑[2]"];
h1 = figure('Position', [1 1 1200 1200], 'Name', '形状内平均値の相関');
% hm1 = heatmap(mesh_name, mesh_name, R_shape);
hm1 = heatmap(R_shape_rounded);
%title('形状内平均値の相関');
hm1.FontSize = 20;


R_material_rounded = round(R_material,3);
material_roughness = ["Cu-0.025", "Cu-0.129", "Pla-0.075", "Pla-0.225", "Glass-0.05", "Glass-0.5"];
h2 = figure('Position', [1 1 1200 1200], 'Name', '素材・ラフネス内平均値の相関');
figure(h2)
% hm2 = heatmap(material_roughness, material_roughness, R_material);
hm2 = heatmap(R_material_rounded);
%title('素材・ラフネス内平均値の相関');
hm2.FontSize = 20;