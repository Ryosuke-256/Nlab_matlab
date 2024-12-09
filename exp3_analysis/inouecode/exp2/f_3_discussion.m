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
load('./z_psvList.mat','psvList');
load('z_clusterList.mat', 'clusterList');
% filename = ['./result/model_all_condition_all_result_', currentDate, '.mat'];
filename = './result/model_all_condition_limited_C1_1229.mat';
load(filename);

load('./data4analysis/illum_setumei.mat');
setumei = table2array(setumeihensu);
setumei(:,25) = [];
for i = 1 : 40
    z_setumei(:,i) = zscore(setumei(:,i));
end

ob_names = {'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', 'サブバンドコントラスト', ...
         '輝度平均', '歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', 'サブバンド歪度', ...
         '輝度コントラスト', 'ハイライトコントラスト', 'ハイライトカバレッジ'};

statname = {'コントラスト','歪度','尖度','サブバンドコントラスト1','サブバンドコントラスト2','サブバンドコントラスト3','サブバンドコントラスト4','サブバンドコントラスト5','サブバンドコントラスト6',...
    'サブバンド歪度1', 'サブバンド歪度2','サブバンド歪度3','サブバンド歪度4','サブバンド歪度5','サブバンド歪度6',...
    'サブバンド尖度1', 'サブバンド尖度2','サブバンド尖度3','サブバンド尖度4','サブバンド尖度5','サブバンド尖度6',...
    'エントロピー', '照明数', '照明サイズ', '球面調和関数1', '球面調和関数2', '球面調和関数3', '球面調和関数4',...
    '球面調和関数5', '球面調和関数6', '球面調和関数7', '球面調和関数8', '球面調和関数9', '球面調和関数10',...
    'brilliance', 'diffuseness', '背景コントラスト', '背景歪度', '背景尖度', '背景エントロピー'};




%% response
%{
psv_c1 = [];
psv_c1_allSubject = [];

for condition = 1 : conditionNum
   if(clusterList(condition,1) == 1)
       psv_c1 = [psv_c1; psvList(condition,:);];
   end
end

psv_c1_mean = mean(psv_c1,1);

psv_standard_errors = std(psv_c1, 0, 1);

h3 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量（折れ線グラフ）');
plot(1:illumNum, psv_c1_mean, ':o', 'LineWidth', 2, 'MarkerSize', 10);  % 折れ線グラフの描画

hold on;
errorbar(1:illumNum, psv_c1_mean, psv_standard_errors, 'k', 'linestyle', 'none', 'LineWidth', 1);  % エラーバーを追加

% 縦軸が0の横軸を太くする
yZeroLine = 0; % 縦軸が0の値
line([-0.5, illumNum + 1.5], [yZeroLine yZeroLine], 'Color', 'black', 'LineWidth', 0.5); % 太い横線を追加


% 軸ラベルと軸の範囲の設定

xlim([0, illumNum + 1]);
ylim([min(psv_c1_mean)-1, max(psv_c1_mean) + 1]); 
grid on;
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 40);
ylabel('光沢知覚量', 'FontSize', 40);
hold off;
%}

%% model coef
%{
illum= AllAnalysisInfo_common{1}.illum;
coef = illum.coef;

[sorted_values, sorted_indices] = sort(abs(coef), 'descend');
coef = coef(sorted_indices);
statname = statname(sorted_indices);

h1 = figure('Position', [1 1 1920 1200], 'Name', '照明モデルの偏回帰係数');

figure(h1)

bar(coef);
%lgd = legend('照明環境5', '照明環境8', '照明環境12','照明環境17', '照明環境18', 'Location', 'northeastoutside');
%lgd.FontSize = 28;
%title('照明モデルの偏回帰係数');
xticks(1:length(statname))
xticklabels(statname)
xtickangle(90)
maxY = max(coef(:))+ 0.1 ;
minY = min(coef(:))- 0.1 ;
ylim([minY maxY]) % 一部、負に大きな変数あり
ax = gca; % 現在の軸を取得
ax.FontSize = 22; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
%}

%% object setumei
%{
ob_explanatory_List = [];
ob_explanatory_List_target = [];

for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
            fileName = sprintf('./data4analysis/object_explanatory/%s_%s_%s.mat', mesh(shape_type), material(material_type), roughness(material_type, gloss_type));
            load(fileName);
            
            ob_explanatory_List{end+1} = ob_explanatory(bangou1223,:); % 1:18_cu
        end
    end
end


idx_shape = [1,3,5,9,11,15,17];
corrList_shape = zeros(length(idx_shape), length(ob_names));
target_idx = 7;

count = 1;
for j = idx_shape
    for i = 1:17
    % i番目の統計量について1番目と15番目の物体のデータを取得
    stat_obj1 = ob_explanatory_List{target_idx}(:, i);
    stat_obj2 = ob_explanatory_List{j}(:, i);

    % 相関係数を計算し、結果を格納
    corr_matrix = corrcoef(stat_obj1, stat_obj2);
    corrList_shape(count, i) = corr_matrix(1,2); % 1,2要素が2つのベクトル間の相関係数
    end
    count = count + 1;
end

idx_cu_low = [1,3,5,9,11,15,17];
idx_cu_high = [2,4,6,10,12,16,18];
idx_glass_low = [37,40,42,45,47,51,53];
idx_glass_high = [38,41,43,46,48,52,54];

corrList_12 = zeros(length(idx_shape), length(ob_names));
corrList_13 = zeros(length(idx_shape), length(ob_names));
corrList_14 = zeros(length(idx_shape), length(ob_names));
corrList_23 = zeros(length(idx_shape), length(ob_names));
corrList_24 = zeros(length(idx_shape), length(ob_names));
corrList_34 = zeros(length(idx_shape), length(ob_names));

count = 1;
for j = 1 : 7
    for i = 1:17
        % i番目の統計量について1番目と15番目の物体のデータを取得
        stat_obj_cu_low = ob_explanatory_List{idx_cu_low(j)}(:, i);
        stat_obj_cu_high = ob_explanatory_List{idx_cu_high(j)}(:, i);
        stat_obj_glass_low = ob_explanatory_List{idx_glass_low(j)}(:, i);
        stat_obj_glass_high = ob_explanatory_List{idx_glass_high(j)}(:, i);
        
        % 相関係数を計算し、結果を格納
        corr_12 = corrcoef(stat_obj_cu_low, stat_obj_cu_high);
        corr_13 = corrcoef(stat_obj_cu_low, stat_obj_glass_low);
        corr_14 = corrcoef(stat_obj_cu_low, stat_obj_glass_high);
        corr_23 = corrcoef(stat_obj_cu_high, stat_obj_glass_low);
        corr_24 = corrcoef(stat_obj_cu_high, stat_obj_glass_high);
        corr_34 = corrcoef(stat_obj_glass_low, stat_obj_glass_high);
        
        corrList_12(count, i) = corr_12(1,2); % 1,2要素が2つのベクトル間の相関係数
        corrList_13(count, i) = corr_13(1,2); % 1,2要素が2つのベクトル間の相関係数
        corrList_14(count, i) = corr_14(1,2); % 1,2要素が2つのベクトル間の相関係数
        corrList_23(count, i) = corr_23(1,2); % 1,2要素が2つのベクトル間の相関係数
        corrList_24(count, i) = corr_24(1,2); % 1,2要素が2つのベクトル間の相関係数
        corrList_34(count, i) = corr_34(1,2); % 1,2要素が2つのベクトル間の相関係数
    end
    count = count + 1;
end

corrList_material = [mean(corrList_12, 1); mean(corrList_13, 1); mean(corrList_14, 1); mean(corrList_23, 1); mean(corrList_24, 1); mean(corrList_34, 1);];

%shape_names = {'sphere', 'bunny', 'dragon', 'boardA', 'boardB', 'boardC', 'boardA30', 'boardB30', 'boardC30' };

shape_names = {'sphere', 'bunny', 'dragon', 'boardB', 'boardC', 'boardB30', 'boardC30' };

h1 = figure('Position', [1 1 1920 1200], 'Name', '照明モデルの偏回帰係数shape');

figure(h1)
hold on
bar(corrList_shape');
legend('sphere', 'bunny', 'dragon', 'boardB', 'boardC', 'boardB30', 'boardC30', 'Location', 'best');
ylabel('相関係数');
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
%ylim([min(corrList, [], 'all') - 0.1, max(corrList, [], 'all') + 0.1]);
ylim([-1,1]);
xticks(1:numel(ob_names));
xticklabels(ob_names);
xtickangle(90); % x軸のラベルを90度傾ける

hold off

saveas(h1, 'object_setumei_shape.png');


h2 = figure('Position', [1 1 1920 1200], 'Name', 'モデルの偏回帰係数material');
figure(h2)
hold on

bar(corrList_material');
legend('Cu0.025-Cu0129', 'Cu0.025-glass0.05', 'Cu0.025-glass0.5', 'Cu0.129-glass0.05', 'Cu0.129-glass0.5', 'glass0.05-glass0.5', 'Location', 'best');
ylabel('相関係数');
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
%ylim([min(corrList, [], 'all') - 0.1, max(corrList, [], 'all') + 0.1]);
ylim([-0.6, 1])
xticks(1:numel(ob_names));
xticklabels(ob_names);
xtickangle(90); % x軸のラベルを90度傾ける

hold off

saveas(h2, 'object_setumei_material.png');
%}

%% illum_setumei
%{
matrix = setumei(bangou1223,:);

num = 3;

% 各列ごとに値が高い行と低い行を見つける
num_rows = size(matrix, 1);
num_columns = size(matrix, 2);
high_rows = zeros(num, num_columns);
low_rows = zeros(num, num_columns);

for col = 1:num_columns
    column_data = matrix(:, col);
    
    % 値が高い行のインデックスを見つける
    [sorted_values, sorted_indices] = sort(column_data, 'descend');
    high_rows(:, col) = sorted_indices(1:num)';
    
    % 値が低い行のインデックスを見つける
    [sorted_values, sorted_indices] = sort(column_data, 'ascend');
    low_rows(:, col) = sorted_indices(1:num)';
end
%}

% high illum

%{
bangou = [5,8,12,17,18];

%coef = setumei(bangou1223(bangou),:);
coef = z_setumei(bangou1223(bangou),:);

bar(coef');
lgd = legend('照明環境5', '照明環境8', '照明環境12','照明環境17', '照明環境18', 'Location', 'northeastoutside');
lgd.FontSize = 28;
%title('照明モデルの偏回帰係数');
xticks(1:length(statname))
xticklabels(statname)
xtickangle(90)
maxY = max(coef(:))+ 1 ;
minY = min(coef(:))- 1 ;
ylim('auto');%[minY maxY]) % 一部、負に大きな変数あり
ax = gca; % 現在の軸を取得
ax.FontSize = 14; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定



illum= AllAnalysisInfo_common{1}.illum;
illum_Y = illum.Y;
illum_Y_295 = [];
for i = 1 : 38
    illum_Y_295 = [illum_Y_295, illum_Y((i-1) * 295 + 1:i * 295)];     
end

illum_Y_295_mean = mean(illum_Y_295,2);

[sorted_data, sorted_idx] = sort(illum_Y_295_mean);

% 上位30個と下位30個の要素を抜き出す
top_30_elements = sorted_data(end-29:end);
bottom_30_elements = sorted_data(1:30);
% 上位30個と下位30個の要素のインデックスも取得する場合
top_30_elements_idx = sorted_idx(end-29:end);
bottom_30_elements_idx = sorted_idx(1:30);
%}

%% happyou sanpuzu
%{
filename1 = '/home/nagailab/デスクトップ/inoue_programs/experiment1/data/image_XYZ/sphere/sphere_cu_0.025_5.mat';
load(filename1);

Y_1 = image_np_XYZ_900(:,:,2);

filename2 = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/data4analysis/imageXYZ/sphere/sphere_cu_0.025_5.mat';
load(filename2);

Y_2 = image_np_XYZ_900(:,:,2);

h1 = figure('Position', [1 1 1200 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量（折れ線グラフ）');

figure(h1)

hold on;

plot(Y_1(:), Y_2(:), 'o', 'LineWidth', 1, 'MarkerSize', 5);

grid on;
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('銅素材・低ラフネス', 'FontSize', 40);
ylabel('ガラス素材・高ラフネス', 'FontSize', 40);
hold off;
%}


%% happyou sanpuzu
%{
load('/home/nagailab/デスクトップ/inoue_programs/experiment1/z_psvList.mat', 'psvList');
psv_experiment1 = psvList(:);

load('/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/z_psvList.mat', 'psvList');
psv_experiment2 = psvList(:);

disp(corr(psv_experiment1,psv_experiment2));

x = -10:0.1:10;
y = x;
h1 = figure('Position', [1 1 1200 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量（折れ線グラフ）');

figure(h1)

hold on;

plot(x,y,'-k');
plot(psv_experiment1, psv_experiment2, 'o', 'LineWidth', 1, 'MarkerSize', 5);  % 折れ線グラフの描画

xlim([min([psv_experiment1;psv_experiment2]), max([psv_experiment1;psv_experiment2])]);
ylim([min([psv_experiment1;psv_experiment2]), max([psv_experiment1;psv_experiment2])]);

% grid on;
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('実験1', 'FontSize', 40);
ylabel('実験2', 'FontSize', 40);
hold off;
%}