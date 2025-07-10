function plotBoxPlot(fig, box_data, scatter_data, options)
%plotBoxPlot 指定されたFigureハンドルに、散布図と箱ひげ図を重ねて表示します。
%
% [説明]
%   1. scatter_dataの値が昇順になるように並び替えます。
%   2. その並び替え順序に従って、box_dataの各実験条件（行）を並び替えます。
%   3. 指定されたFigure (`fig`) 上に散布図と箱ひげ図を重ねて描画します。
%
% [INPUTS]
%   fig          - (Figure Handle) 描画対象のFigureハンドル。
%   box_data     - (行列) 箱ひげ図用のデータ。各行が1つの実験条件に対応。
%   scatter_data - (ベクトル) 散布図用のデータ。並び替えの基準となる値。
%
% [OPTIONS] (Name-Value Pairs)
%   "Title"    - (string) グラフのタイトル。
%   "XLabel"   - (string) X軸のラベル。
%   "YLabel"   - (string) Y軸のラベル。

%% 1. 引数の定義と検証
arguments
    fig (1,1) matlab.ui.Figure % Figureハンドルであることを指定
    box_data (:,:) {mustBeNumeric, mustBeReal}
    scatter_data (:,1) {mustBeNumeric, mustBeReal}
    options.Title (1,1) string = "Scatter Plot with Box Plot Overlay"
    options.XLabel (1,1) string = "Sorted Condition Index"
    options.YLabel (1,1) string = "Value"
end

% 入力データの行数（条件数）が一致するか検証
if size(box_data, 1) ~= numel(scatter_data)
    error('箱ひげ図のデータ行数と、散布図のデータ要素数が一致しません。');
end

%% 2. データの並び替え
[sorted_scatter_values, sort_indices] = sort(scatter_data, 'ascend');
sorted_box_data = box_data(sort_indices, :);

%% 3. 描画
% ★修正点: 操作対象のFigureを明示的にアクティブにする
figure(fig);
set(fig, 'Visible', 'off');
ax = gca; % これで確実にfigのAxesが取得される
cla(ax, 'reset'); % 描画前にAxesをクリアする場合
hold(ax, 'on');

% 箱ひげ図を先に描画
boxplot(ax, sorted_box_data', ...
    'Positions', 1:numel(sorted_scatter_values), ...
    'Widths', 0.5, ...
    'Colors', 'b', ...
    'Symbol', 'b+');

% ソートされた散布図を重ねて描画
scatter(ax, 1:numel(sorted_scatter_values), sorted_scatter_values, ...
    10, 'r', 'filled', 'DisplayName', 'Experiment value');

%% 4. グラフの体裁を調整
grid on;
title(ax, options.Title, 'FontSize', 16);
xlabel(ax, options.XLabel, 'FontSize', 12);
ylabel(ax, options.YLabel, 'FontSize', 12);
legend(ax, 'Location', 'southeast');
xlim(ax, [0, numel(sorted_scatter_values) + 1]);

hold(ax, 'off');
end