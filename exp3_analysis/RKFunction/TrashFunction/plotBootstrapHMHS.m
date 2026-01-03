function plotBootstrapHMHS(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, matNames, shapeNames)
% plotBootstrapHMHS - HM/HS モードの Bootstrap プロット
%
% 入力:
%   fig: Figure オブジェクト
%   dataA, dataB: データ配列
%   plotDataA, plotDataB: プロットデータ（Name, Property フィールドを含む構造体）
%   plotOptions: プロットオプション（Mode, Bootstrap, Split, Amp, Property フィールドを含む構造体）
%   matNames: 材質名の配列
%   shapeNames: 形状名の配列

% データの準備
% データの準備
if plotOptions.Mode == "HS"
    dataA_r = permute(dataA, [1, 3, 2, 4, 5]);
    dataB_r = permute(dataB, [1, 3, 2, 4, 5]);
    labels = shapeNames;
    defaultTitle = sprintf("%s vs %s - %s- shape", plotDataA.Name, plotDataB.Name, plotOptions.Property);
else % HM モード
    dataA_r = dataA;
    dataB_r = dataB;
    labels = matNames;
    defaultTitle = sprintf("%s vs %s - %s- material", plotDataA.Name, plotDataB.Name, plotOptions.Property);
end

if isfield(plotOptions, 'ShowTitle') && ~plotOptions.ShowTitle
    sgTitle = "";
else
    sgTitle = defaultTitle;
end

% グラフ初期化
t_significance = tiledlayout(fig, 1, 1, 'Padding', 'normal');
ax_significance = nexttile(t_significance);

% 各条件でループ
loopLimit = size(dataA_r, 2);
for i = 1:loopLimit
    dataA_r2 = squeeze(dataA_r(:, i, :, :, :));
    dataB_r2 = squeeze(dataB_r(:, i, :, :, :));
    fprintf("%s", string(labels(i)));
    
    % Bootstrap 解析
    [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
        Corr_Significance_v4(dataA_r2, dataB_r2, plotOptions.Bootstrap, plotOptions.Split);
    
    % プロット
    Graph_Significance_v2(ax_significance, observed_corr, ceiling_distAA, ceiling_distAB, ...
        p_value, bca_ci_AB, i, 'Amp', plotOptions.Amp, 'Title', sgTitle);
end

% 軸ラベル設定
set(ax_significance, 'XTick', 1:length(labels), 'XTickLabel', labels);
addSignificanceNote(ax_significance, plotOptions.Amp);

end
