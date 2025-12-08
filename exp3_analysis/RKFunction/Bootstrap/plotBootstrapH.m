function plotBootstrapH(fig, dataA, dataB, plotDataA, plotDataB, plotOptions)
% plotBootstrapH - H モードの Bootstrap プロット
%
% 入力:
%   fig: Figure オブジェクト
%   dataA, dataB: データ配列
%   plotDataA, plotDataB: プロットデータ（Name, Property フィールドを含む構造体）
%   plotOptions: プロットオプション（Bootstrap, Split, Amp, Property フィールドを含む構造体）

% Bootstrap 解析
[ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
    Corr_Significance_v4(dataA, dataB, plotOptions.Bootstrap, plotOptions.Split);

% タイトル
sgTitle = sprintf("%s vs %s - %s- all condition", plotDataA.Name, plotDataB.Name, plotOptions.Property);

% プロット
t_significance = tiledlayout(fig, 1, 1, 'Padding', 'normal');
ax_significance = nexttile(t_significance);

Graph_Significance_v2(ax_significance, observed_corr, ceiling_distAA, ceiling_distAB, ...
    p_value, bca_ci_AB, 'Amp', plotOptions.Amp, 'Title', sgTitle);

addSignificanceNote(ax_significance, plotOptions.Amp);

end
