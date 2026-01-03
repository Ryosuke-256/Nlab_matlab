function plotBootstrapHMS(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, mat_idx, matNames, shapeNames)
% plotBootstrapHMS - HMS モードの Bootstrap プロット
%
% 入力:
%   fig: Figure オブジェクト
%   dataA, dataB: データ配列
%   plotDataA, plotDataB: プロットデータ（Name, Property フィールドを含む構造体）
%   plotOptions: プロットオプション（Bootstrap, Split, Amp, Property フィールドを含む構造体）
%   mat_idx: 材質インデックス
%   matNames: 材質名の配列
%   shapeNames: 形状名の配列

% モードに応じた形状数を取得
shapeCount = size(dataA, 3);

% タイトル
% タイトル
if isfield(plotOptions, 'ShowTitle') && ~plotOptions.ShowTitle
    sgTitle = "";
else
    sgTitle = sprintf("%s vs %s - %s - %s", plotDataA.Name, plotDataB.Name, ...
        plotOptions.Property, string(matNames(mat_idx)));
end

% グラフ初期化
t_significance = tiledlayout(fig, 1, 1, 'Padding', 'normal');
ax_significance = nexttile(t_significance);

% 各形状でループ
for shape = 1:shapeCount
    dataA_r = squeeze(dataA(:, mat_idx, shape, :, :));
    dataB_r = squeeze(dataB(:, mat_idx, shape, :, :));
    fprintf("mat:%s, shape:%s", string(matNames(mat_idx)), string(shapeNames(shape)));
    
    % Bootstrap 解析
    [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
        Corr_Significance_v4(dataA_r, dataB_r, plotOptions.Bootstrap, plotOptions.Split);
    
    % プロット
    Graph_Significance_v2(ax_significance, observed_corr, ceiling_distAA, ceiling_distAB, ...
        p_value, bca_ci_AB, shape, 'Amp', plotOptions.Amp, 'Title', sgTitle);
end

% 軸ラベル設定
set(ax_significance, 'XTick', 1:length(shapeNames), 'XTickLabel', shapeNames);
addSignificanceNote(ax_significance, plotOptions.Amp);

end
