clear all;

%% 2.選好尺度値から物体条件間の相関行列を作成

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';
filename = strcat(rootpath, '/z_conditionList.mat');
load(filename);
filename = strcat(rootpath, '/z_psvList.mat');
load(filename);

[conditionNum, ~] = size(experiment_condition);
illumNum = 30;

material = ["cu" "pla" "glass"];
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
materialNum = length(material);
meshNum = length(mesh);
[~,roughnessNum] = size(roughness);

shape_corr = zeros(meshNum, illumNum);
material_corr = zeros(materialNum * roughnessNum, illumNum);

material_idx = 1;
shape_idx = 2;
roughness_idx = 3;

%% 形状でまとめる
%% 形状内の平均値の相関
for i = 1 :meshNum
    for j = 1 : conditionNum
        if(experiment_condition(j,shape_idx) == mesh(i))
            shape_corr(i,:) = shape_corr(i,:) + psvList(j,:);
        end
    end
    
    shape_corr(i,:) = shape_corr(i,:) / sum(experiment_condition(:,shape_idx) == mesh(i)); 
end

R_shape = corrcoef(shape_corr');

%% 形状内の条件すべての相関
shape_corr2 = zeros(illumNum * 6, meshNum);

for i = 1 :meshNum
    tmp = [];
    for j = 1 : conditionNum
        if(experiment_condition(j,shape_idx) == mesh(i))
            tmp = [tmp; psvList(j,:)'];
        end
    end
    shape_corr2(:,i) = tmp;
end

R_shape2 = corrcoef(shape_corr2);

%% 素材・ラフネスでまとめる

count = 1;
count2 = 1;
for i = 1 : materialNum
    for j = 1 : roughnessNum
        for k = 1 : conditionNum
            if(experiment_condition(k,material_idx) == material(i) && experiment_condition(k,roughness_idx) == roughness(i,j))
                material_corr(count,:) = material_corr(count,:) + psvList(k,:);
            end
        end
        material_corr(count,:) = material_corr(count,:) / sum((experiment_condition(:,material_idx) == material(i)) & (experiment_condition(:,roughness_idx) == roughness(i,j)));
        count = count + 1;
    end
end

R_material = corrcoef(material_corr');


mesh_name = ["sphere","bunny","dragon","boardA","boardB","boardC","boardA-30","boardB-30","boardC-30"];%,"単純[2]","中間[2]","複雑[2]"];
h1 = figure('Position', [1 1 1301 944], 'Name', '形状内平均値の相関');
figure(h1)
hm1 = heatmap(mesh_name, mesh_name, R_shape);
%title('形状内平均値の相関');
hm1.FontSize = 20;

material_roughness = ["Cu-0.025", "Cu-0.129", "Pla-0.075", "Pla-0.225", "Glass-0.05", "Glass-0.5"];
h2 = figure('Position', [1 1 1301 944], 'Name', '素材・ラフネス内平均値の相関');
figure(h2)
hm2 = heatmap(material_roughness, material_roughness, R_material);
%title('素材・ラフネス内平均値の相関');
hm2.FontSize = 20;
