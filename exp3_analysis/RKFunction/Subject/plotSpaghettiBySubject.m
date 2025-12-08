function plotSpaghettiBySubject(data, condition_dim, options)
%plotSpaghettiBySubject 被験者内誤差を視覚化するスパゲッティプロットを作成します。
%
% [INPUTS]
%   data          - (N-D行列) 元データ。最後から2番目が被験者次元、最後が試行次元と仮定。
%   condition_dim - (整数)   X軸としてプロットしたい要因の次元。
%
% [OPTIONS] (Name-Value Pairs)
%   "SubjectNames" - (string/cell) 各被験者の名前。
%   "XLabels"      - (string/cell) X軸の目盛りラベル。
%   "Title"        - (string) Figure全体のタイトル。
%   "YLabel"       - (string) Y軸のラベル。
%   "SavePath"     - (string) 保存先のパス。

%% 1. 引数の検証と次元の動的認識
arguments
    data {mustBeNumeric}
    condition_dim (1,1) double {mustBeInteger, mustBePositive}
    options.SubjectNames (1,:) string = []
    options.XLabels (1,:) string = []
    options.Title (1,1) string = "被験者ごとの応答プロット"
    options.YLabel (1,1) string = "測定値の平均"
    options.SavePath (1,1) string = ""
end

num_dims = ndims(data);
subject_dim = num_dims - 1;
num_subjects = size(data, subject_dim);
num_conditions = size(data, condition_dim);

%% 2. データの準備
% X軸の条件次元と、被験者次元以外の全ての次元を平均化
dims_to_average = setdiff(1:num_dims, [condition_dim, subject_dim]);
mean_data = squeeze(mean(data, dims_to_average));

% プロットのために、(条件 x 被験者) の2次元行列に並べ替え
if condition_dim > subject_dim
    % 例: data(subj, cond) -> data(cond, subj)'
    mean_data = mean_data';
end

%% 3. グラフの作成
fig = figure('Visible', 'off');
cleanupObj = onCleanup(@() close(fig));

hold on;

% 各被験者のデータを細い線でプロット
plot(1:num_conditions, mean_data, '-o', 'LineWidth', 0.5, 'MarkerSize', 4);

% 全被験者の平均を太い黒線でプロット
overall_mean = mean(mean_data, 2);
main_line = plot(1:num_conditions, overall_mean, 'k-o', 'LineWidth', 1, ...
    'MarkerSize', 3, 'MarkerFaceColor', 'k', 'DisplayName', '平均');

hold off;

%% 4. グラフの体裁を調整
grid on;
box on;
ax = gca;
title(ax, options.Title);
ylabel(ax, options.YLabel);

if ~isempty(options.XLabels)
    xlabel(ax, '実験条件');
    xticks(ax, 1:num_conditions);
    xticklabels(ax, options.XLabels);
    xtickangle(ax, 45);
else
    xlabel(ax, sprintf('条件のレベル (次元 %d)', condition_dim));
end

% 凡例は平均線のみ表示
legend(main_line, 'Location', 'best');

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