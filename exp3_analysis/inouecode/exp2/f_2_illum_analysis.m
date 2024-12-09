clear all;

% currentDate = datestr(now, 'mmdd'); % 月と日のみを取得 ('mmdd'形式)
currentDate = num2str(1229);

material = ["cu" "pla" "glass"];
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
materialNum = length(material);
meshNum = length(mesh);
[~,roughnessNum] = size(roughness);
conditionNum = materialNum * meshNum * roughnessNum;
illumNum = 30;

load('./data4analysis/bangou1223.mat');
load('z_clusterList.mat', 'clusterList');
% filename = ['./result/model_all_condition_all_result_', currentDate, '.mat'];
filename = './result/model_all_condition_limited_C1_1229.mat';
load(filename);

statname = {'標準偏差','歪度','尖度','サブバンドコントラスト1','サブバンドコントラスト2','サブバンドコントラスト3','サブバンドコントラスト4','サブバンドコントラスト5','サブバンドコントラスト6',...
    'サブバンド歪度1', 'サブバンド歪度2','サブバンド歪度3','サブバンド歪度4','サブバンド歪度5','サブバンド歪度6',...
    'サブバンド尖度1', 'サブバンド尖度2','サブバンド尖度3','サブバンド尖度4','サブバンド尖度5','サブバンド尖度6',...
    'エントロピー', '照明数', '照明サイズ', '球面調和関数1', '球面調和関数2', '球面調和関数3', '球面調和関数4',...
    '球面調和関数5', '球面調和関数6', '球面調和関数7', '球面調和関数8', '球面調和関数9', '球面調和関数10',...
    'brilliance', 'diffuseness', '背景コントラスト', '背景歪度', '背景尖度', '背景エントロピー'};

%% 全条件の平均値と照明モデルの推定値を比較
%{
result = [];
result1 = [];
result23 = [];

count = 1;
for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
            % 実験測定値
            obj = AllAnalysisInfo{material_type,shape_type,gloss_type}.obj;
            result = [result, obj.result(:,1)]; 
            
            % cluster 1
            if(clusterList(count,1) == 1)
                result1 = [result1, obj.result(:,1)];
            end
            
            % cluster 23
            if(clusterList(count,1) == 2 || clusterList(count,1) == 3)
                result23 = [result23, obj.result(:,1)];
            end
            count = count + 1;
        end
    end
end

illum_result = zeros(illumNum, 2);
illum_result(:,1) = mean(result,2); % 実験測定値
illum_result(:,2) = AllAnalysisInfo_common{1}.illum.result(:,1,1); % 照明モデル結果

maxv = max([illum_result(:);result1(:);result23(:);])+0.1;
minv = min([illum_result(:);result1(:);result23(:);])-0.1;

%% グラフ出力

% all condition

rss = sum((illum_result(:,1) - illum_result(:,2)).^2);
tss = sum((illum_result(:,1) - mean(illum_result(:,1))).^2);
R2 = 1-rss./tss;

h1 = figure('Position', [1 1 1200 1200], 'Name', '演光沢感性の推定値と実験測定値の分布');
figure(h1)
hold on;

plot(illum_result(:,2), illum_result(:,1), 'o','MarkerSize', 12, 'LineWidth', 2);
coefficients = polyfit(illum_result(:,2), illum_result(:,1), 1); % 回帰モデルの係数を計算
x = linspace(min([illum_result(:,2); illum_result(:,1)]) - 0.1, max([illum_result(:,2); illum_result(:,1)]) + 0.1, 100);
y = polyval(coefficients, x);
plot(x, y, '-r', 'LineWidth', 2);

xlim([minv maxv])
ylim([minv maxv])
plot([minv maxv],[minv maxv],'-k');
%title('演光沢感性の推定値と実験測定値の分布（全条件）','FontSize',36)
r2infostring = sprintf('R2 = %1.2f, r=%1.2f ', R2, corr(illum_result(:,2), illum_result(:,1)));
text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, r2infostring, 'FontSize',20);
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明モデルによる推定値', 'FontSize', 50); ylabel('実験で測定した光沢知覚量', 'FontSize', 50);

hold off


% cluster1のグラフ
illum_result1 = mean(result1, 2);

rss2 = sum((illum_result1(:,1) - illum_result(:,2)).^2);
tss2 = sum((illum_result1(:,1) - mean(illum_result1(:,1))).^2);
R2 = 1 - rss2 ./ tss2;

% エラーバーの計算
h2 = figure('Position', [1 1 1200 1200], 'Name', 'クラスター1平均光沢知覚量と照明モデル推定');
figure(h2)
hold on;

plot(illum_result(:,2), illum_result1(:,1), 'o','MarkerSize', 12, 'LineWidth', 2);
coefficients = polyfit(illum_result(:,2), illum_result1(:,1), 1); % 回帰モデルの係数を計算
x = linspace(min([illum_result(:,2); illum_result1(:,1)]) - 0.1, max([illum_result(:,2); illum_result1(:,1)]) + 0.1, 100);
y = polyval(coefficients, x);
plot(x, y, '-r', 'LineWidth', 2);

xlim([minv maxv])
ylim([minv maxv])
plot([minv maxv],[minv maxv],'-k');
%title('演光沢感性の推定値と実験測定値の分布（全条件）','FontSize',36)
r2infostring = sprintf('R2 = %1.2f, r=%1.2f ', R2, corr(illum_result(:,2), illum_result1(:,1)));
text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, r2infostring, 'FontSize',20);
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明モデルによる推定値', 'FontSize', 50); ylabel('実験で測定した光沢知覚量', 'FontSize', 50);

hold off

% cluster23のグラフ
illum_result2 = mean(result23, 2);

rss2 = sum((illum_result2(:,1) - illum_result(:,2)).^2);
tss2 = sum((illum_result2(:,1) - mean(illum_result2(:,1))).^2);
R2 = 1 - rss2 ./ tss2;

% エラーバーの計算
h3 = figure('Position', [1 1 1200 1200], 'Name', 'クラスター23の平均光沢知覚量と照明モデル推定');
figure(h3)
hold on;

plot(illum_result(:,2), illum_result2(:,1), 'o','MarkerSize', 12, 'LineWidth', 2);
coefficients = polyfit(illum_result(:,2), illum_result2(:,1), 1); % 回帰モデルの係数を計算
x = linspace(min([illum_result(:,2); illum_result2(:,1)]) - 0.1, max([illum_result(:,2); illum_result2(:,1)]) + 0.1, 100);
y = polyval(coefficients, x);
plot(x, y, '-r', 'LineWidth', 2);

xlim([minv maxv])
ylim([minv maxv])
plot([minv maxv],[minv maxv],'-k');
%title('演光沢感性の推定値と実験測定値の分布（全条件）','FontSize',36)
r2infostring = sprintf('R2 = %1.2f, r=%1.2f ', R2, corr(illum_result(:,2), illum_result2(:,1)));
text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, r2infostring, 'FontSize',20);
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明モデルによる推定値', 'FontSize', 50); ylabel('実験で測定した光沢知覚量', 'FontSize', 50);

hold off
%}

%% 実験２モデルによる実験１結果推定
filename = './result/model_all_condition_all_result_experiment1.mat';
load(filename);
AllAnalysisInfo_experiment1 = AllAnalysisInfo;
AllAnalysisInfo_common_experiment1 = AllAnalysisInfo_common;

filename = './result/model_all_condition_limited_C1_1229.mat';
load(filename);

illum = AllAnalysisInfo_common{1}.illum;

result = [];
illum_R2_list_model = [];
illum_r_list_model = [];


for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
                obj = AllAnalysisInfo_experiment1{material_type,shape_type,gloss_type}.obj;

                result = [obj.result(:,2), squeeze(illum.result(:,2:3,1)), obj.result(:,1)];
                
                rss = sum((result(:, 2) - result(:, 1)).^2);
                tss = sum((result(:, 1) - mean(result(:, 1))).^2);%実験結果(目的変数)の平均との差
                R2 = 1-rss./tss;
                
                illum_R2_list_model = [illum_R2_list_model;R2];
                illum_r_list_model = [illum_r_list_model;corr(result(:, 1), result(:, 2))];

                illum_result_output = sprintf('Illumination_model(with_object_model) %s-%s-%s : R2= %1.3f ,r= %1.3f', ...
                    material(material_type), mesh(shape_type), roughness(gloss_type), R2, corr(result(:, 1), result(:, 2)));
                disp(illum_result_output);
        end
    end         
end

result = [];
illum_R2_list_response = [];
illum_r_list_response = [];

for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
                obj = AllAnalysisInfo_experiment1{material_type,shape_type,gloss_type}.obj;
                result = [obj.result(:,2) squeeze(illum.result(:,2:3,1)) obj.result(:,1)];
                
                rss = sum((result(:, 3) - result(:, 4)).^2);
                tss = sum((result(:, 4) - mean(result(:, 4))).^2);%実験結果(目的変数)の平均との差
                R2 = 1-rss./tss;
                
                illum_R2_list_response = [illum_R2_list_response;R2];
                illum_r_list_response = [illum_r_list_response;corr(result(:, 3), result(:, 4))];
                
                illum_result_output = sprintf('Illumination_model(with_observer_response) %s-%s-%s : R2= %1.3f ,r= %1.3f', ...
                    material(material_type), mesh(shape_type), roughness(material_type,gloss_type), R2, corr(result(:, 3), result(:, 4)));
                
                disp(illum_result_output);
        end
    end         
end

%% 実験間でのモデルの偏回帰係数比較
%{
filename = './result/model_makihira.mat';
load(filename);
AllAnalysisInfo_common_makihira = AllAnalysisInfo_common;

filename = './result/model_all_condition_all_result_experiment1.mat';
load(filename);
AllAnalysisInfo_common_experiment1 = AllAnalysisInfo_common;

filename = './result/model_all_condition_all_result_1229.mat';
load(filename);

coef = zeros(40, 3);

coef(:,1) = (AllAnalysisInfo_common_makihira{1}.illum.coef)';
coef(:,2) = (AllAnalysisInfo_common_experiment1{1}.illum.coef)';
coef(:,3) = (AllAnalysisInfo_common{1}.illum.coef)';

bar(coef);
lgd = legend('従来モデル[2]', '実験1モデル', '実験2モデル', 'Location', 'best');
lgd.FontSize = 28;
%title('照明モデルの偏回帰係数');
xticks(1:length(statname))
xticklabels(statname)
xtickangle(90)
maxY = max(coef(:))+ 0.1 ;
minY = min(coef(:))- 0.1 ;
ylim([minY maxY]) % 一部、負に大きな変数あり
%}

%% svm
%{
load('./data4analysis/illum_setumei.mat');
load('./SVM_accuracy_normal_BootStrap30.mat','SVM_accuracy', 'all_avg_weights');
load('./data4analysis/bangou1223.mat');

bangou =[];
for i = 1 : illumNum
    if (SVM_accuracy(i,1) > 0.95)
        bangou = [bangou; bangou1223(i)];
    end
end

setumei = table2array(setumeihensu);
setumei(:,25) = [];

%{
% 平均と標準偏差を計算
 means = mean(setumei);
 stddevs = std(setumei);

% 偏差値を計算
 deviation_scores = 10 * ((setumei - means) ./ stddevs) + 50;
 target_scores = deviation_scores(bangou,:);
%}


for i = 1:40
    setumei(:,i) = zscore(setumei(:,i));
end
 target_scores = setumei(bangou,:);


bar(target_scores');
%lgd = legend('照明1','照明2', '照明3','Location', 'best');
lgd.FontSize = 28;
title('照明パラメータ', 'FontSize', 28);
xticks(1:length(statname))
xticklabels(statname)
xtickangle(90)
maxY = max(target_scores(:))*1.1 ;
minY = min(target_scores(:))*1.1 ;
%ylim([minY maxY]) % 一部、負に大きな変数あり
%}