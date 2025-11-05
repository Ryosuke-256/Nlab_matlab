function [corrMatrix, heatmapHandle] = createHeatmap(plotData, options)
%CREATEHEATMAP データ構造体から相関係数ヒートマップを作成する
%
% この関数は、指定されたAxesオブジェクト(ax)上に、入力データ(plotData)の
% targetフィールドの各列間の相関係数を計算し、ヒートマップとして描画します。
%
% Syntax:
%   [corrMatrix, h] = createHeatmap(ax, plotData)
%   [corrMatrix, h] = createHeatmap(ax, plotData, 'Title', 'My Title')
%
% Inputs:
%   plotData    - (1,1) struct。以下のフィールドを持つ必要があります:
%                 .target - (m x n) 数値行列。相関計算の対象データ。
%                 .error  - (m x n) 数値行列。(この関数では未使用)
%                 .Name   - (1 x n) string配列。各列の変数名。ヒートマップのラベルとして使用。

% --- 入力引数の定義と検証 ---
arguments
    plotData (1,1) struct {mustHaveFields(plotData, ["target", "error", "Name"])}

    % オプション引数 (名前/値ペア)
    options.Labels (:,:) string = []
    options.Title (1,1) string = "Correlation Heatmap"
    options.Amp (1,1) double = 1
end

% --- メイン処理 ---
% plotData構造体から相関計算用のデータとラベル名を取得
data = plotData.target;
labels = options.Labels;

% データの次元数とラベルの数が一致するかチェック
[~, n_data] = size(data);
if numel(labels) ~= n_data
    error('plotData.targetの列数とplotData.Nameの要素数が一致しません。');
end

% 1. 相関係数行列の計算
corrMatrix = corrcoef(data);

% 2. Heatmapの描画
% heatmap関数は指定されたAxesの内容を上書きするため、hold onは不要です。
heatmapHandle = heatmap(labels, labels, corrMatrix);

% 3. プロパティの設定
heatmapHandle.Title = options.Title;
heatmapHandle.Colormap = parula;
%heatmapHandle.XLabel = 'Variables';
%heatmapHandle.YLabel = 'Variables';
heatmapHandle.ColorLimits = [-1, 1];

end