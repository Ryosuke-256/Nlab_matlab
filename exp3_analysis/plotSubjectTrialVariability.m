function plotSubjectTrialVariability(data_5d, options)
%plotSubjectTrialVariability 5次元データの被験者ごとの全応答値の分布を可視化します。

%% 1. 引数の検証と次元の動的認識
arguments
    data_5d (:,:,:,:,:) {mustBeNumeric}
    options.SubjectNames (1,:) string = []
    options.Title (1,1) string = "被験者ごとの全応答値の分布"
    options.SavePath (1,1) string = ""
end

% 4次元目を被験者と解釈
num_subjects = size(data_5d, 4);
if ~isempty(options.SubjectNames) && numel(options.SubjectNames) ~= num_subjects
    error('SubjectNamesの数と、データの4次元目のサイズ(被験者数)が一致しません。');
end

%% 2. グラフの作成準備
fig = figure('Visible', 'off', 'Position', [50, 50, 300*ceil(sqrt(num_subjects)), 250*ceil(num_subjects/ceil(sqrt(num_subjects)))]);
cleanupObj = onCleanup(@() close(fig));

% 被験者数に応じて、タイルレイアウトの行数・列数を自動計算
num_cols = ceil(sqrt(num_subjects));
num_rows = ceil(num_subjects / num_cols);
t = tiledlayout(fig, num_rows, num_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

%% 3. ループで各被験者のグラフを描画
for i = 1:num_subjects
    % i番目の被験者のデータを抽出
    subject_data = data_5d(:, :, :, i, :);
    
    % ★修正点: 実験条件で平均せず、全応答値を1つのベクトルに変換
    all_responses = subject_data(:);
    
    % 次のタイルを選択
    ax = nexttile;
    
    % ヒストグラムを描画
    histogram(ax, all_responses);
    
    % 各タイトルの設定
    if ~isempty(options.SubjectNames)
        title(ax, options.SubjectNames(i));
    else
        title(ax, sprintf('Subject %d', i));
    end
    grid(ax, 'on');
end

%% 4. Figure全体の体裁を調整
title(t, options.Title, 'FontSize', 16, 'FontWeight', 'bold');
% ★修正点: X軸ラベルを修正
xlabel(t, '測定値 (全試行)');
ylabel(t, '度数 (Frequency)');

%% 5. 保存または表示
if ~isempty(options.SavePath)
    try
        saveas(fig, options.SavePath);
        fprintf('グラフを保存しました: %s\n', options.SavePath);
    catch ME
        warning('グラフの保存中にエラーが発生しました: %s', ME.message);
    end
else
    set(fig, 'Visible', 'on');
    delete(cleanupObj);
end


end