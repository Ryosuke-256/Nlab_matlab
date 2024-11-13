clear all;

%% 1. 実験条件・照明環境ごとの選好尺度値（被験者平均）

load('z_conditionList.mat');
material_idx = 1;
shape_idx = 2;
roughness_idx = 3;

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/result/psv';
subject = ["aso", "dogu", "hanada", "horiuchi", "kinoshita", "morishita", "nakajima", "okamoto", "son", "takanashi"];
directory = '5';

illumNum = 30;
[conditionNum, ~] = size(experiment_condition);
[~, subjectNum] = size(subject);

[xGrid, yGrid] = meshgrid(1:illumNum, 1:subjectNum);

psvListAll = zeros(conditionNum, illumNum, subjectNum);

for j = 1 : subjectNum
    current_subject = subject(j);
    for i = 1 : conditionNum
        filename = strcat(current_subject,directory,'_', experiment_condition(i,shape_idx),'_',experiment_condition(i,material_idx),'_', experiment_condition(i,roughness_idx),'.mat');
        filepath = strcat(rootpath, '/', current_subject,'/',directory,'/', filename);

        load(filepath);

        psvListAll(i,:, j) = illumiPsvAll(5,:);
    end
end
maxv = max(psvListAll(:)) + 0.2;
minv = min(psvListAll(:)) - 0.2;

psvList_eachSubject = (squeeze(mean(psvListAll,1)))';
psvList_eachIllum = mean(psvListAll,3);
psvList = psvList_eachIllum;
save('z_psvList.mat', 'psvList');

%% モデル用に選好尺度値を保存
%{
rootpath2 = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/result/response';
for i = 1 : conditionNum
    filename = strcat(experiment_condition(i,shape_idx),'_',experiment_condition(i,material_idx),'_', experiment_condition(i,roughness_idx),'_response.mat');
	filepath = strcat(rootpath2, '/', filename);
    
    Object_response = psvList_eachIllum(i,:);

    save(filepath, 'Object_response');
end
%}

%% 条件ごとの被験者応答
%{
% 条件リスト
material = ["cu", "pla", "glass"];
mesh = ["sphere", "bunny", "dragon", "board_ang0_size0", "board_ang0_size03", "board_ang0_size015", "board_ang30_size0", "board_ang30_size03", "board_ang30_size015"];
roughness = ["0.025", "0.129"; "0.075", "0.225"; "0.05", "0.5"];
materialNum = numel(material);
meshNum = numel(mesh);
roughnessNum = numel(roughness(1,:));

% 被験者ごとに色を設定
colors = lines(subjectNum);

condition_index = 1;
% 条件ごとにグラフを作成
for material_type = 1:materialNum
    for mesh_type = 1:meshNum
        for roughness_type = 1:roughnessNum
            % 現在の条件に対するデータを取得
            currentData = squeeze(psvListAll(condition_index, :, :));

            % グラフの作成
            s = sprintf('Material: %s, Mesh: %s, Roughness: %s', material(material_type), mesh(mesh_type), roughness(material_type, roughness_type));
            h = figure('Position', [1 1 1920 1200], 'Name', s);
            
            hold on;
            plot(1:illumNum,  psvList_eachIllum(condition_index,:), ':', 'HandleVisibility','off', 'LineWidth', 2);
            scatter(1:illumNum, psvList_eachIllum(condition_index,:), 'SizeData', 300, 'LineWidth', 5);
            
            for subject = 1:subjectNum
                scatter(1:illumNum, currentData(:, subject), 'MarkerEdgeColor', colors(subject, :), 'SizeData', 300, 'LineWidth', 2, 'MarkerEdgeAlpha', 0.3);
%                plot(1:illumNum, currentData(:, subject), ':', 'Color', colors(subject, :), 'HandleVisibility','off', 'LineWidth', 0.01);     
            end
            
            ax = gca; % 現在の軸を取得
            ax.FontSize = 30; % フォントサイズを設定
            ax.LineWidth = 2; % 軸の線の太さを設定
            
            xlabel('照明番号', 'FontSize', 60);
            xlim([0, illumNum + 1]);
            ylabel('光沢知覚量', 'FontSize', 60);
            ylim([-6, 6]);
%            lgd = legend('被験者1', '被験者2', '被験者3', '被験者4', '被験者5');
%            lgd.FontSize = 1;
            grid on;
            
            hold off;
            
            fileName = sprintf('%d%d%d.jpg', material_type, mesh_type, roughness_type);
            saveas(h, fileName);

            % 条件インデックスを計算
            condition_index = condition_index + 1;
        end
    end
end
%}

%% 各照明条件の被験者応答
%{
[xGrid, yGrid] = meshgrid(1:illumNum, 1:subjectNum);

% 図の作成
h1 = figure('Position', [1 1 1920 1200], 'Name', '各照明条件の被験者応答');

% 被験者ごとに色を設定
colors = lines(subjectNum);
% 各被験者のデータをプロット
hold on; % 複数のプロットを重ねる
for i = 1:subjectNum
    x = xGrid(i, :); % 条件
    y = psvList_eachSubject(i, :); % i番目の被験者の応答値
    scatter(x, y, 'MarkerEdgeColor', colors(i, :), 'SizeData', 150, 'LineWidth', 3); % 散布図のプロット
	plot(x, y, ':', 'Color', colors(i, :),'HandleVisibility','off'); % 点線でつなぐ
end
% タイトルと軸ラベルの設定

ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
%title('Scatter Plot of Responses for 5 Subjects Across 30 Conditions');
xlabel('照明番号', 'FontSize', 60);
xlim([0, illumNum + 1]);
ylabel('光沢知覚量', 'FontSize', 60);
grid on;


% 凡例の表示
%legend('被験者1', '被験者2', '被験者3', '被験者4', '被験者5', '被験者6', '被験者7', '被験者8', '被験者9', '被験者10','Location', 'best');
%hold off;

saveas(h1, 'response_eadhSubject.png');

%% 各照明条件の被験者応答の平均

psv_experiment2 = mean(psvList_eachIllum,1);


% 棒グラフの描画
h2 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験2の平均光沢知覚量');
bar(psv_experiment2');

hold on;
%title('実験１の照明ごとの平均光沢知覚量', 'FontSize', 20);
ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 60);
xlim([0, illumNum + 1]);
ylabel('光沢知覚量', 'FontSize', 60);
grid on;
hold off;


h3 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量（折れ線グラフ）');

hold on;

plot(1:illumNum, psv_experiment2, '-o', 'LineWidth', 3);  % 折れ線グラフの描画

% 縦軸が0の横軸を太くする
yZeroLine = 0; % 縦軸が0の値
line([-0.5, illumNum + 1.5], [yZeroLine yZeroLine], 'Color', 'black', 'LineWidth', 0.5); % 太い横線を追加


% 軸ラベルと軸の範囲の設定
xlim([0, illumNum + 1]);
ylim([min(psv_experiment2)-1, max(psv_experiment2) + 1]); 
ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 60);
ylabel('光沢知覚量', 'FontSize', 60);
grid on;
hold off;

saveas(h3, 'response_allMean.png');
%}

%% 実験１と実験２の比較
%{
colorMap = containers.Map({1, 2, 3}, {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]});

psvListAll_2 = psvListAll;

% 照明条件ごとの実験１と実験２の平均光沢知覚量
load('/home/nagailab/デスクトップ/inoue_programs/experiment1/z_psvList.mat', 'psvList');
psv_experiment1 = psvList;
psv_experiment1_mean = mean(psvList, 1);

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1/data/psvList';
subject = ["aso","dogu", "horiuchi", "son", "takanashi"];
directory = '5';

illumNum = 30;
[conditionNum,~] = size(experiment_condition);
[~, subjectNum] = size(subject);

psvListAll_1 = zeros(conditionNum, illumNum, subjectNum);

for j = 1 : subjectNum
    current_subject = subject(j);
    for i = 1 : conditionNum
        filename = strcat(current_subject,directory,'_', experiment_condition(i,2),'_',experiment_condition(i,1),'_', experiment_condition(i,3),'.mat');
        filepath = strcat(rootpath, '/', current_subject,'/',directory,'/', filename);

        load(filepath);

        psvListAll_1(i,:, j) = illumiPsvAll(5,:);
    end
end



% 実験２

psv_experiment2 = psvList_eachIllum;
psv_experiment2_mean = mean(psvList_eachIllum,1);
psvList_experiment12 = [psv_experiment1_mean; psv_experiment2_mean];


h1 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験１と実験２の平均光沢知覚量');
figure(h1)

hold on

for i = 1:2
    x = xGrid(i, :); % 条件
    y = psvList_experiment12(i, :); % i番目の被験者の応答値    
    plot(x, y, ':o', 'LineWidth', 3,'MarkerSize', 20);%,'Color', colorMap(i, :),'HandleVisibility','off');  % 折れ線グラフの描画
%    plot(x, y, ':', 'Color', colorMap(i, :),'HandleVisibility','off'); % 点線でつなぐ
end


lgd = legend('実験１', '実験２', 'Location', 'best');
lgd.FontSize = 40;
ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定

xlabel('照明番号', 'FontSize', 60); ylabel('光沢知覚量', 'FontSize', 60);
ylim([min(psvList_experiment12(:)) - 1, max(psvList_experiment12(:)) + 1]);
grid on
% title('実験１と実験２の照明ごとの平均光沢知覚量')
hold off


% 物体条件ごとの実験１と実験２の光沢知覚量の相関
corr_List = [];
for i = 1 : conditionNum
    correlation = corrcoef(psv_experiment1(i,:), psv_experiment2(i,:));
    corr_List = [corr_List, correlation(1,2)];
    output = sprintf('(%s %s %s) : r = %1.2f', experiment_condition(i,1),experiment_condition(i,2),experiment_condition(i,3),correlation(1,2));
    disp(output)
end

h2 = figure('Position', [1 1 1920 1200], 'Name', '物体条件ごとの実験１と実験２の光沢知覚量の相関');
figure(h2)
bar(corr_List);

ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定

xlabel('物体条件番号', 'FontSize', 60); ylabel('相関係数', 'FontSize', 60);

% title('物体条件ごとの実験１と実験２の光沢知覚量の相関')
%}