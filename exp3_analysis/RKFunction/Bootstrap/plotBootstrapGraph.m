function plotBootstrapGraph(ax, observed_corr, noise_ceiling_distAA, noise_ceiling_distAB, p_value, bca_ci_AB, repeater, options)
%Graph_Significance_BCa BCa法による信頼区間をエラーバーとして描画します。

%% 1. 引数の検証
arguments
    ax (1,1) matlab.graphics.axis.Axes
    observed_corr (1,1) double
    noise_ceiling_distAA (:,:) {mustBeNumeric, mustBeReal}
    noise_ceiling_distAB (:,:) {mustBeNumeric, mustBeReal}
    p_value (1,1) double
    bca_ci_AB (1,2) double % ★ BCa信頼区間 [lower, upper] を入力に追加
    repeater (1,1) double = 1
    
    options.Title (1,1) string = ""
    options.XLabel (1,1) string = "Condition"
    options.YLabel (1,1) string = "Correlation Coefficient"
    options.Amp      (1,1) double = 1
end

%% 2. 描画
hold(ax, 'on');
x_axis = repeater;

% ノイズ天井の95%パーセンタイル範囲を灰色のエリアで描画 (変更なし)
ci_100 = quantile(noise_ceiling_distAA, [0.0, 1.0]);
fill(ax, [x_axis-0.5, x_axis+0.5, x_axis+0.5, x_axis-0.5], [ci_100(1), ci_100(1), ci_100(2), ci_100(2)], ...
     'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
ci_95 = quantile(noise_ceiling_distAA, [0.05, 1.0]);
fill(ax, [x_axis-0.5, x_axis+0.5, x_axis+0.5, x_axis-0.5], [ci_95(1), ci_95(1), ci_95(2), ci_95(2)], ...
     'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

% 観測された相関係数を棒グラフで表示 (変更なし)
bar_width = 0.4;
bar(ax, x_axis, observed_corr, bar_width, 'FaceColor', '#81BD5F', 'DisplayName', 'Observed Corr','EdgeColor', 'none');

% ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
% ★ 修正点: エラーバーの計算をBCa信頼区間ベースに変更
% ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
% エラーバーの中心点は、ブートストラップ分布の平均値
centerValue = mean(noise_ceiling_distAB);
% 上方向と下方向のエラーバーの長さを、BCa信頼区間の上限・下限から計算
lowerError = centerValue - bca_ci_AB(1); % 平均 - 下限
upperError = bca_ci_AB(2) - centerValue; % 上限 - 平均

% 非対称エラーバーを描画
errorbar(ax, x_axis, centerValue, lowerError, upperError, 'o', ...
    'Color', '#1C3077', 'LineWidth', 1.0 ,'CapSize', 10, 'DisplayName', 'BCa 95% CI');

% (以降のテキスト描画、体裁調整は微調整のみ)
graphtext1 = sprintf('%.2f', observed_corr);
text(ax, x_axis-0.2, observed_corr, graphtext1, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 10 * options.Amp);
if p_value < 0.05
    text(ax, x_axis, observed_corr + 0.02, '*', 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 12 * options.Amp, 'Color', '#D44843');
end

ylim(ax, [0.0, 1.1]);
y_Limits = ylim(ax);
x_Limits = xlim(ax);

aveorigin = mean(noise_ceiling_distAA);
plot(ax, [x_axis-0.5, x_axis+0.5], [aveorigin, aveorigin], 'k--', 'LineWidth', 1.0, 'DisplayName', 'Within-subject average');

ylabel(ax, options.YLabel, 'FontSize', 12 * options.Amp);
title(ax, options.Title, 'FontSize', 12 * options.Amp, 'Interpreter', 'none');
grid(ax, 'on');
set(ax, 'XTick', []);
hold(ax, 'off');
end