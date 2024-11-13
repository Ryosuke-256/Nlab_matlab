clear all;

%% 1. 実験条件・照明環境ごとの選好尺度値（被験者平均）
load('z_conditionList.mat');

%% 実験1の選好尺度値のリストを作る
rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1/data/psvList';
subject = ["aso","dogu", "horiuchi", "son", "takanashi"];
directory = '5';

illumNum = 30;
[conditionNum,~] = size(experiment_condition);
[~, subjectNum] = size(subject);

psvListAll = zeros(conditionNum, illumNum, subjectNum);

for j = 1 : subjectNum
    current_subject = subject(j);
    for i = 1 : conditionNum
        filename = strcat(current_subject,directory,'_', experiment_condition(i,2),'_',experiment_condition(i,1),'_', experiment_condition(i,3),'.mat');
        filepath = strcat(rootpath, '/', current_subject,'/',directory,'/', filename);

        load(filepath);

        psvListAll(i,:, j) = illumiPsvAll(5,:);
    end
end
maxv = max(psvListAll(:)) + 0.2;
minv = min(psvListAll(:)) - 0.2;

[xGrid, yGrid] = meshgrid(1:illumNum, 1:subjectNum);

% 被験者ごとに色を設定
colors = lines(subjectNum);

psvList_eachSubject = (squeeze(mean(psvListAll,1)))';
psvList_eachIllum = mean(psvListAll,3);



% save('z_psvList.mat', 'psvList_eachIllum');
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
            %lgd = legend('被験者1', '被験者2', '被験者3', '被験者4', '被験者5');
            %lgd.FontSize = 1;
            grid on;
            
            hold off;
            
            fileName = sprintf('res_%d%d%d.jpg', material_type, mesh_type, roughness_type);
            saveas(h, fileName);

            % 条件インデックスを計算
            condition_index = condition_index + 1;
        end
    end
end
%}

%% 各照明条件の被験者応答


% 図の作成
h1 = figure('Position', [1 1 1920 1200], 'Name', '各照明条件の被験者応答');

% 各被験者のデータをプロット
hold on; % 複数のプロットを重ねる
for i = 1:subjectNum
    x = xGrid(i, :); % 条件
    y = psvList_eachSubject(i, :); % i番目の被験者の応答値
    scatter(x, y, 'MarkerEdgeColor', colors(i, :), 'SizeData', 200, 'LineWidth', 3); % 散布図のプロット
	plot(x, y, ':', 'Color', colors(i, :),'HandleVisibility','off'); % 点線でつなぐ
end

% タイトルと軸ラベルの設定
%title('Scatter Plot of Responses for 5 Subjects Across 30 Conditions');
ax = gca; % 現在の軸を取得
ax.FontSize = 30; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 60);
xlim([0, illumNum + 1]);
ylabel('光沢知覚量', 'FontSize', 60);
legend('被験者1', '被験者2', '被験者3', '被験者4', '被験者5','Location', 'best');
lgd.FontSize = 20;

hold off;
% 凡例の表示


fileName = sprintf('response_subject.png');
saveas(h1, fileName);


%% 各照明条件の被験者応答の平均

psv_experiment1 = mean(psvList_eachIllum,1);


% 棒グラフの描画
h2 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量');
bar(psv_experiment1');

hold on;
xlabel('照明番号', 'FontSize', 60);
ylabel('光沢知覚量', 'FontSize', 60);
ylim([min(psv_experiment1) - 1, max(psv_experiment1) + 1]);
%title('実験１の照明ごとの平均光沢知覚量', 'FontSize', 20);
grid on;
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
hold off;


% 折れ線グラフの描画
h3 = figure('Position', [1 1 1920 1200], 'Name', '照明条件ごとの実験１の平均光沢知覚量（折れ線グラフ）');
plot(1:illumNum, psv_experiment1, '-o', 'LineWidth', 2);  % 折れ線グラフの描画

hold on;

% 縦軸が0の横軸を太くする
yZeroLine = 0; % 縦軸が0の値
line([-0.5, illumNum + 1.5], [yZeroLine yZeroLine], 'Color', 'black', 'LineWidth', 0.5); % 太い横線を追加


% 軸ラベルと軸の範囲の設定
xlim([0, illumNum + 1]);
ylim([min(psv_experiment1) - 1, max(psv_experiment1) + 1]);
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 60);
ylabel('光沢知覚量', 'FontSize', 60);
grid on;
hold off;

fileName = sprintf('response_allMean.png');
saveas(h3, fileName);
%}


%% combine
%{
psv_experiment1 = mean(psvList_eachIllum,1);

% 新しい図を作成
h_combined = figure('Position', [1 1 1920 1200], 'Name', '被験者応答と平均の統合グラフ');

% 各被験者の応答結果をプロット (h1の内容を参照)
hold on;
for i = 1:subjectNum
    x = xGrid(i, :); 
    y = psvList_eachSubject(i, :);
    scatter(x, y, 'MarkerEdgeColor', colors(i, :), 'SizeData', 200, ...
            'MarkerEdgeAlpha', 1, 'MarkerFaceAlpha', 1);  % 透明度を追加
    plot(x, y, ':', 'Color', [colors(i, :) 0.5], 'HandleVisibility','off');  % 線の透明度を追加
end

% 被験者平均をプロット (h3の内容を参照)
plot(1:illumNum, psv_experiment1, '-o', 'LineWidth', 2);

% 軸ラベル、タイトル、凡例の設定
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
xlabel('照明番号', 'FontSize', 30);
ylabel('光沢知覚量', 'FontSize', 30);
%title('各被験者の応答と平均の統合グラフ');
legend('被験者1', '被験者2', '被験者3', '被験者4', '被験者5', '被験者平均', 'Location', 'best');
grid on;
hold off;
%}

%% 照明ごとの光沢知覚量の分散
%{
psv_var = zeros(1, illumNum);

for i = 1 : illumNum
    psv_var(1,i) = var(psvList_eachIllum(:,i));
end

% 棒グラフの描画
h3 = figure('Position', [1 1 1301 944], 'Name', '照明条件ごとの平均光沢知覚量の分散');
bar(psv_var');

hold on;
xlabel('照明番号', 'FontSize', 20);
ylabel('分散', 'FontSize', 20);
ylim([min(psv_var) - 1, max(psv_var) + 1]);
%title('実験１の照明ごとの平均光沢知覚量', 'FontSize', 20);
grid on;
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定
hold off;
%}
%% 実験間で照明ごとの光沢知覚量を比較
%{
load('/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/z_psvList.mat');
psv_experiment2 = mean(psvList_eachIllum,1);

psv_experiment12 = [psv_experiment1; psv_experiment2];
bar(psv_experiment12');
legend('experiment1', 'experiment2');
%}