clear all;

% 月と日のみを取得 ('mmdd'形式)
currentDate = num2str(1229);

material = ["cu" "pla" "glass"];
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
materialNum = length(material);
meshNum = length(mesh);
[~,roughnessNum] = size(roughness);
conditionNum = materialNum * meshNum * roughnessNum;

load('./data4analysis/bangou1223.mat');

filename = ['./result/tmpfile_imc_', currentDate, '.mat'];
load(filename);

%% 平らな板の目的変数と各説明変数の相関を確認
%{
expNum = 17;

result_all = cell(expNum, meshNum);
corrList_all = zeros(expNum,meshNum);

for mesh_type = 1 : meshNum
    corrList_coef  = [];
    target_mesh = mesh(mesh_type);
    for exp_type = 1 : expNum
        result = [];

        for material_type = 1 : materialNum
            for shape_type = 1 : meshNum
                if ismember(mesh(shape_type), target_mesh)
                    for roughness_type = 1 : roughnessNum
                        obj = AllAnalysisInfo{material_type, shape_type, roughness_type}.obj;

                        result = [result; obj.result(:,1), obj.all_exp_var(bangou1223, exp_type)];
                    end
                end
            end
        end

        result_all{exp_type,mesh_type} = result;
        corrList_coef = [corrList_coef; corr(result(:,1), result(:,2))];
    end
    
    corrList_all(:,mesh_type) = corrList_coef;
end

corrList_boardA = zeros(expNum,2);
corrList_boardA(:,1) = corrList_all(:,4);
corrList_boardA(:,2) = corrList_all(:,7);


% 可視化

names = {'サブバンドコントラスト1', 'サブバンドコントラスト2', 'サブバンドコントラスト3', 'サブバンドコントラスト4', 'サブバンドコントラスト5', 'サブバンドコントラスト6', ...
         '輝度平均', '歪度', 'サブバンド歪度1', 'サブバンド歪度2', 'サブバンド歪度3', 'サブバンド歪度4', 'サブバンド歪度5', 'サブバンド歪度6', ...
         '輝度標準偏差', 'ハイライトコントラスト', 'ハイライトカバレッジ'};

h1 = figure('Position', [1 1 1301 944], 'Name', '光沢知覚と相関の高い物体画像特徴量');

figure(h1)
bar(corrList_all);
title('光沢知覚と相関の高い物体画像特徴量');
legend('sphere', 'bunny', 'dragon', 'boardA', 'boardB', 'boardC', 'boardA30', 'boardB30', 'boardC30');
xlabel('特徴量');
ylabel('相関係数');
ylim([-0.3,1]);
xticks(1:numel(names));
xticklabels(names);
xtickangle(90); % x軸のラベルを90度傾ける

h2 = figure('Position', [1 1 1301 944], 'Name', 'boardAの光沢知覚と相関の高い物体画像特徴量');

figure(h2)
bar(corrList_boardA);
title('boardAの光沢知覚と相関の高い物体画像特徴量');
legend('boardA', 'boardA30');
xlabel('特徴量');
ylabel('相関係数');
ylim([-0.3,1]);
xticks(1:numel(names));
xticklabels(names);
xtickangle(90); % x軸のラベルを90度傾ける
%}

%% 銅とガラスでモデルの偏回帰係数が変わっているか確認
%{
target_material = ["cu","glass"];
coef_all = cell(length(target_material) * roughnessNum, meshNum);
exp_all = cell(length(target_material) * roughnessNum, meshNum);

material_count = 1;
for material_type = 1 : materialNum
    if ismember(material(material_type), target_material)
        for roughness_type = 1 : roughnessNum
            for shape_type = 1 : meshNum
                obj = AllAnalysisInfo{material_type, shape_type, roughness_type}.obj;
                coef_all{material_count, shape_type} = obj.coef';
                
                % 30種類の照明ごとのデータをすべて1つのベクトル化
                exp2Vector = obj.all_exp_var(bangou1223,:)';
                exp_all{material_count, shape_type} = exp2Vector(:);
            end
            material_count = material_count + 1;
        end
    end
end

combNum = 6;
corrList_coef = zeros(combNum, meshNum);
corrList_exp = zeros(combNum, meshNum);

material_combinations = [1, 2; 1, 3; 1, 4; 2, 3; 2, 4; 3, 4];

for shape_type = 1 : meshNum
    for combIdx = 1 : combNum
        % 各素材の組み合わせごとに相関係数を計算して格納
        corrList_coef(combIdx, shape_type) = corr(coef_all{material_combinations(combIdx, 1), shape_type}, coef_all{material_combinations(combIdx, 2), shape_type});
        corrList_exp(combIdx, shape_type) = corr(exp_all{material_combinations(combIdx, 1), shape_type}, exp_all{material_combinations(combIdx, 2), shape_type});
    end
end

names = {'sphere', 'bunny', 'dragon', 'boardA', 'boardB', 'boardC', 'boardA30', 'boardB30', 'boardC30' };

h3 = figure('Position', [1 1 1301 944], 'Name', '素材条件間の物体モデル偏回帰係数の相関');

figure(h3)
bar(corrList_coef');
title('素材条件間の物体モデル偏回帰係数の相関');
legend('Cu0.025-Cu0129', 'Cu0.025-glass0.05', 'Cu0.025-glass0.5', 'Cu0.129-glass0.05', 'Cu0.129-glass0.5', 'glass0.05-glass0.5');
xlabel('形状');
ylabel('相関係数');
ylim([min(corrList_coef, [], 'all') - 0.1, max(corrList_coef, [], 'all') + 0.1]);
xticks(1:numel(names));
xticklabels(names);
xtickangle(90); % x軸のラベルを90度傾ける

h4 = figure('Position', [1 1 1301 944], 'Name', '素材条件間の説明変数の相関');

figure(h4)
bar(corrList_exp');
title('素材条件間の説明変数の相関');
legend('Cu0.025-Cu0129', 'Cu0.025-glass0.05', 'Cu0.025-glass0.5', 'Cu0.129-glass0.05', 'Cu0.129-glass0.5', 'glass0.05-glass0.5');
xlabel('形状');
ylabel('相関係数');
ylim([min(corrList_exp, [], 'all') - 0.1, max(corrList_exp, [], 'all') + 0.1]);
xticks(1:numel(names));
xticklabels(names);
xtickangle(90); % x軸のラベルを90度傾ける
%}
%% 各物体モデルの偏回帰係数

coef_all = cell(materialNum * roughnessNum, meshNum);

names = {'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', ...
         '輝度平均', '歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', ...
         '輝度標準偏差', 'ハイライトコントラスト', 'ハイライトカバレッジ'};

colors = [0 0.4470 0.7410;0.8500 0.3250 0.0980;0.9290 0.6940 0.1250;0.4940 0.1840 0.5560;0.4660 0.6740 0.1880;0.3010 0.7450 0.9330;0.6350 0.0780 0.1840;1 0 0; 0 1 0];

material_count = 1;
for material_type = 1 : materialNum
    for roughness_type = 1 : roughnessNum
        for shape_type = 1 : meshNum
            obj = AllAnalysisInfo{material_type, shape_type, roughness_type}.obj;
            coef_all{material_count, shape_type} = obj.coef';
        end
        material_count = material_count + 1;
    end
end

% 
material_count = 1;
for material_type = 1 : materialNum
    for roughness_type = 1 : roughnessNum
    s = sprintf('Material: %s, Roughness: %s', material(material_type), roughness(material_type, roughness_type));
    h1 = figure('Position', [1 1 1301 944], 'Name', s);
    
    figure(h1)
    hold on; % 複数の棒グラフを重ねるため
    for shape_type = 1:9 % 形状の条件のループ
        bar((1:17) -0.5 + (shape_type-1)*0.1, coef_all{material_count, shape_type}, 0.1,'FaceColor', colors(shape_type,:)); % 棒グラフ (位置を微調整)
    end
%    title(sprintf('Material %d', i));
    legend('sphere', 'bunny', 'dragon', 'boardA', 'boardB', 'boardC', 'boardA30', 'boardB30', 'boardC30');
    xlabel('偏回帰係数');
    xticks(1:numel(names));
    xticklabels(names);
    xtickangle(90); % x軸のラベルを90度傾ける
    ylim([-1,1]);
    grid on;
    hold off;
    
    material_count = material_count + 1;
    end
end