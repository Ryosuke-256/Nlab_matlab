function plotScatterWithErrorBars(ax, box_data, scatter_data, options)
%plotScatterWithPercentileBars データをソートし、95パーセンタイル範囲をエラーバーとして描画します。
%
% [説明]
%   1. scatter_dataの値で実験条件を昇順に並び替えます。
%   2. box_dataの各条件の中央値をY軸の値とします。
%   3. box_dataから2.5%点と97.5%点を計算し、エラーバーとして表示します。
%
% [INPUTS]
%   ax           - 描画対象のAxesハンドル
%   box_data     - (行列) エラーバー計算用のデータ。各行が1つの実験条件。
%   scatter_data - (ベクトル) 並び替えの基準となる値。
%
% [OPTIONS]
%   "Title", "XLabel", "YLabel", "Labels", "Amp", "TickStep"

%% 1. 引数の定義と検証
arguments
    ax (1,1) matlab.graphics.axis.Axes
    box_data (:,:) {mustBeNumeric, mustBeReal}
    scatter_data (:,1) {mustBeNumeric, mustBeReal}
    options.Title (1,1) string = "Scatter Plot with 95 Percentile Range"
    options.XLabel (1,1) string = "Sorted Condition Index"
    options.YLabel (1,1) string = "Value"
    options.Amp      (1,1) double = 1.0
    options.Labels   (1,:) string = []
    options.TickStep (1,1) double {mustBeInteger, mustBePositive} = 1
end

% (データの検証と並び替えロジックは変更なし)
num_conditions = size(box_data, 1);
if num_conditions ~= numel(scatter_data)
    error('box_dataの行数と、scatter_dataの要素数が一致しません。');
end
if ~isempty(options.Labels) && num_conditions ~= numel(options.Labels)
    error('データの条件数とラベルの数が一致しません。');
end
[~, sort_indices] = sort(scatter_data, 'ascend');
sorted_box_data = box_data(sort_indices, :);

%% 2. ★ 95パーセンタイル範囲の計算
% quantile関数を使い、各行（実験条件ごと）の2.5%, 50%(中央値), 97.5%点を一度に計算
% 第3引数の「2」は、行方向（2次元目）に沿って計算することを意味します
percentiles = quantile(sorted_box_data, [0.025, 0.5, 0.975], 2);

lower_bounds = percentiles(:, 1); % 2.5%点
medians      = percentiles(:, 2); % 50%点（中央値）
upper_bounds = percentiles(:, 3); % 97.5%点

% ★ errorbar関数用の非対称エラーバーの長さを計算
positive_errors = upper_bounds - medians; % 上方向の長さ
negative_errors = medians - lower_bounds; % 下方向の長さ

%% 3. ★ エラーバー付き散布図の描画 (非対称エラーバーを使用)
cla(ax, 'reset');
hold(ax, 'on');

% errorbar(x, y, neg, pos) の形式で、中心点、下方向、上方向の長さを指定
errorbar(ax, 1:num_conditions, medians, negative_errors, positive_errors, ...
    'o', ...
    'MarkerSize', 4*options.Amp, ...
    'MarkerEdgeColor', 'b', ...
    'MarkerFaceColor', [0.3 0.7 1.0], ...
    'Color', 'b', ...
    'LineWidth', 1.0*options.Amp, ...
    'LineStyle', 'none', ...
    'CapSize', 5*options.Amp);

%% 4. グラフの体裁調整
% (以降のコードは変更なし)
grid(ax, 'on');
%title(ax, options.Title, 'FontSize', 16 * options.Amp, 'Interpreter', 'none');
xlabel(ax, options.XLabel, 'FontSize', 12 * options.Amp);
ylabel(ax, options.YLabel, 'FontSize', 12 * options.Amp);
xlim(ax, [0, num_conditions + 1]);
set(ax, 'FontSize', 8 * options.Amp);

if ~isempty(options.Labels)
    sorted_labels = options.Labels(sort_indices);
    tick_positions = 1:options.TickStep:num_conditions;
    tick_display_labels = sorted_labels(tick_positions);
    xticks(ax, tick_positions);
    xticklabels(ax, tick_display_labels);
    xtickangle(ax, 45);
end

hold(ax, 'off');
end