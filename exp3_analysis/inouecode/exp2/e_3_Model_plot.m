clear all;

%% モデル結果のプロット

%% データ読み込み
rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';

%load(strcat(rootpath, '/AllAnalysisInfo_separate_common_model.mat'));
%load(strcat(rootpath, '/result/model_all_condition_all_result_1229.mat'));
load(strcat(rootpath, '/result/model_all_condition_limited_C1_1229.mat'));

load(strcat(rootpath, '/z_conditionList.mat'));
load(strcat(rootpath, '/z_clusterList.mat'));

mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
meshNum = length(mesh);
materialNum = length(material);
[~,roughNum] = size(roughness);
illumNum = 30;
allIllumNum = 295;
[conditionNum, ~] = size(experiment_condition(:,1));


%% 物体モデルの結果のプロット

obj_R2_list = [];
obj_r_list = [];
obj_names = cell(materialNum * meshNum * roughNum, 1); % 名前を格納するセル配列を初期化
obj_count = 1;
count2 = 1;

for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughNum
            
            obj = AllAnalysisInfo{material_type,shape_type,gloss_type}.obj;
            
            %% 物体モデルの決定係数
            obj.rss = sum((obj.result(:, 2) - obj.result(:, 1)).^2);
            obj.tss = sum((obj.result(:, 1) - mean(obj.result(:, 1))).^2);%実験結果(目的変数)の平均との差
            obj.R2 = 1-obj.rss./obj.tss;

            obj_result_output = sprintf('objectmodel: %s-%s-%s : R2= %1.3f ,r= %1.3f', ...
            material(material_type), mesh(shape_type), roughness(material_type,gloss_type), obj.R2, corr(obj.result(:, 2), obj.result(:, 1)));
            disp(obj_result_output);

            obj_R2_list = [obj_R2_list; obj.R2];
            obj_r_list = [obj_r_list; corr(obj.result(:, 2), obj.result(:, 1))];

            % 名前を生成（例：'cu_sphere_0.025'）
            obj_names{obj_count} = strcat(material(material_type), '-', mesh(shape_type), '-', roughness(material_type, gloss_type));
            obj_count = obj_count + 1;
        end
    end
end

% 色の設定
colorMap = containers.Map({1, 2, 3}, {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]});

% グラフの描画    
h1 = figure('Position', [1 1 1301 944], 'Name', '物体モデル推定値と実験測定値の決定係数とクラスターの関係');
hold on;
% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, max(clusterList));

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:max(clusterList)
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, obj_R2_list(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('物体モデル推定値と実験測定値の決定係数', 'FontSize', 28);
%title('物体モデルの決定係数とクラスターの関係');
ylim([0, max(obj_R2_list) + 0.2]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:max(clusterList), 'UniformOutput', false), 'FontSize', 14, 'Location', 'best');

hold off;

h2 = figure('Position', [1 1 1301 944], 'Name', '物体モデル推定値と実験測定値の相関係数とクラスターの関係');
hold on;
% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, max(clusterList));

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:max(clusterList)
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, obj_r_list(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('物体モデル推定値と実験測定値の相関係数', 'FontSize', 28);
%title('物体モデルの相関係数とクラスターの関係');
ylim([0,1]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:max(clusterList), 'UniformOutput', false), 'FontSize', 14, 'Location', 'best');

hold off;

%% 照明モデル
illum = AllAnalysisInfo_common{1}.illum;
result = [];

%% result
count_result = 1;
for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughNum
            obj = AllAnalysisInfo{material_type,shape_type,gloss_type}.obj;
            result = [obj.result(:,2) squeeze(illum.result(:,2:3,1)) obj.result(:,1)];
            
            count_result = count_result + 1;
        end
    end
end

%% 照明モデル全体の結果をプロット
%{
figure('Position', [48 41 1397 390])

rss = sum((result(:, 2) - result(:, 1)).^2);
tss = sum((result(:, 1) - mean(result(:, 1))).^2);%実験結果(目的変数)の平均との差
R2 = 1-rss./tss;    

subplot(1,2,1);    hold on;          
plot(result(:, 2), result(:, 1), 'o');
lsline
maxv = max(max(result(:, 2)));
minv = min(min(result(:, 1)));
xlabel('illumination model prediction'); ylabel('object model output');
xlim([minv maxv])
ylim([minv maxv])
plot([minv maxv],[minv maxv],'-k');
title('Illumination model')
text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, sprintf('R2 = %1.2f, r=%1.2f', R2, corr(illum.result(:, 2), illum.result(:, 1))))


rss = sum((result(:, 4) - result(:, 3)).^2);
tss = sum((result(:, 4) - mean(result(:, 4))).^2);%実験結果(目的変数)の平均との差
R2 = 1-rss./tss;   

subplot(1,2,2);    hold on;          
plot(result(:, 3), result(:, 4), 'o');
lsline
maxv = max([result(:, 3);result(:, 4)]);
minv = min([result(:, 3);result(:, 4)]);
xlabel('illumination model prediction'); ylabel('experimental results');
xlim([minv maxv])
ylim([minv maxv])
plot([minv maxv],[minv maxv],'-k');
title('Illumination model (prediction of psychological value)')
r2infostring = sprintf('R2 = %1.2f, r=%1.2f ', R2, corr(result(:, 3), result(:, 4)));
text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, r2infostring);
%}

%% 照明モデルの回帰係数をプロット

statname = {'contrast','skew','kurt','sub-cont1','sub-cont2','sub-cont3','sub-cont4','sub-cont5','sub0-cont6',...
    'sub-skew1', 'sub-skew2','sub-skew3','sub-skew4','sub-skew5','sub-skew6',...
    'sub-kurt1', 'sub-kurt2','sub-kurt3','sub-kurt4','sub-kurt5','sub-lirt6',...
    'entropy', 'illum-num', 'illum-size', 'sphe-pow1', 'sphe-pow2', 'sphe-pow3', 'sphe-pow4',...
    'sphe-pow5', 'sphe-pow6', 'sphe-pow7', 'sphe-pow8', 'sphe-pow9', 'sphe-pow10',...
    'brilliance', 'diffuseness', 'back-cont', 'back-skew', 'back-kurt', 'back-entropy'};

illum = AllAnalysisInfo_common{1}.illum;
coef = illum.coef;

h7 = figure('Position', [1 1 1301 944], 'Name', '照明モデルの偏回帰係数');
figure(h7)
bar(coef)

hold on;

xlabel('画像特徴量', 'FontSize', 28);
%title('照明モデルの偏回帰係数');
xticks(1:length(statname))
xticklabels(statname)
xtickangle(45)
maxY = max(coef)+ 0.1 ;
minY = min(coef)- 0.1 ;
ylim([minY maxY]) % 一部、負に大きな変数あり

hold off;


%% 各条件と照明モデル
illum = AllAnalysisInfo_common{1}.illum;
count = 1;

illum_R2_list_model = [];
illum_r_list_model = [];

% with object_model
count_illum = 1;
for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughNum
                obj = AllAnalysisInfo{material_type,shape_type,gloss_type}.obj;
                result = [obj.result(:,2) squeeze(illum.result(:,2:3,1)) obj.result(:,1)];
                
                rss = sum((result(:, 2) - result(:, 1)).^2);
                tss = sum((result(:, 1) - mean(result(:, 1))).^2);%実験結果(目的変数)の平均との差
                R2 = 1-rss./tss;
                
                illum_R2_list_model = [illum_R2_list_model;R2];
                illum_r_list_model = [illum_r_list_model;corr(result(:, 1), result(:, 2))];

                illum_result_output = sprintf('Illumination_model(with_object_model) %s-%s-%s : R2= %1.3f ,r= %1.3f', ...
                    material(material_type), mesh(shape_type), roughness(material_type,gloss_type), R2, corr(result(:, 1), result(:, 2)));
                disp(illum_result_output);
                count_illum = count_illum + 1;
        end
    end         
end

% R2
h3 = figure('Position', [1 1 1301 944], 'Name', '照明モデル推定値と物体モデル推定値の決定係数とクラスターの関係');
hold on;

% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, 3); % ここでの '3' はクラスターの数を表します

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:3
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, illum_R2_list_model(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('照明モデル推定値と物体モデル推定値の決定係数', 'FontSize', 28);
%title('照明モデルの決定係数とクラスターの関係');
ylim([0, max(illum_R2_list_model) + 0.1]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:3, 'UniformOutput', false), 'FontSize', 14);

hold off;

% r
h4 = figure('Position', [1 1 1301 944], 'Name', '照明モデル推定値と物体モデル推定値の相関係数とクラスターの関係');
hold on;

% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, 3); % ここでの '3' はクラスターの数を表す

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:3
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, illum_r_list_model(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('照明モデル推定値と物体モデル推定値の相関係数', 'FontSize', 28);
%title('照明モデルの決定係数とクラスターの関係');
ylim([min(illum_r_list_model) - 0.1, max(illum_r_list_model) + 0.2]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:3, 'UniformOutput', false), 'FontSize', 14);

hold off;


% with obserever_response

illum_R2_list_response = [];
illum_r_list_response = [];
count_illum = 1;

for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughNum
                obj = AllAnalysisInfo{material_type,shape_type,gloss_type}.obj;
                result = [obj.result(:,2) squeeze(illum.result(:,2:3,1)) obj.result(:,1)];
                
                rss = sum((result(:, 3) - result(:, 4)).^2);
                tss = sum((result(:, 4) - mean(result(:, 4))).^2);%実験結果(目的変数)の平均との差
                R2 = 1-rss./tss;
                
                illum_R2_list_response = [illum_R2_list_response;R2];
                illum_r_list_response = [illum_r_list_response;corr(result(:, 3), result(:, 4))];
                
                illum_result_output = sprintf('Illumination_model(with_observer_response) %s-%s-%s : R2= %1.3f ,r= %1.3f', ...
                    material(material_type), mesh(shape_type), roughness(material_type,gloss_type), R2, corr(result(:, 3), result(:, 4)));
                
                disp(illum_result_output);
                count_illum = count_illum + 1;
        end
    end         
end

h5 = figure('Position', [1 1 1301 944], 'Name', '照明モデル推定値と実験測定値の決定係数とクラスターの関係');
hold on;

% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, 3); % ここでの '3' はクラスターの数を表す

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:3
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, illum_R2_list_response(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('照明モデル推定値と実験測定値の決定係数', 'FontSize', 28);
%title('照明モデルの決定係数とクラスターの関係');
ylim([0, max(illum_R2_list_response) + 0.1]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:3, 'UniformOutput', false), 'FontSize', 14);

hold off;


h6= figure('Position', [1 1 1301 944], 'Name', '照明モデル推定値と実験測定値の相関係数とクラスターの関係');
hold on;

% 凡例用のハンドルを格納するための配列
legendHandles = zeros(1, 3); % ここでの '3' はクラスターの数を表す

% クラスターごとにデータを分けてプロット
for clusterIdx = 1:3
    clusterDataIdx = find(clusterList == clusterIdx);
    
    % クラスターに属するデータのバーをプロット
    h = bar(clusterDataIdx, illum_r_list_response(clusterDataIdx), 'FaceColor', colorMap(clusterIdx), 'EdgeColor', 'none');
    
    % 最初のバーのハンドルを保存
    if ~isempty(clusterDataIdx)
        legendHandles(clusterIdx) = h(1);
    end
end

xlabel('物体条件', 'FontSize', 28);
ylabel('照明モデル推定値と実験測定値の相関係数', 'FontSize', 28);
%title('照明モデルの決定係数とクラスターの関係');
ylim([min(illum_r_list_response) - 0.1, max(illum_r_list_response) + 0.1]);

% 凡例を追加
legend(legendHandles(legendHandles ~= 0), arrayfun(@(x) sprintf('Cluster %d', x), 1:3, 'UniformOutput', false), 'FontSize', 14);

hold off;