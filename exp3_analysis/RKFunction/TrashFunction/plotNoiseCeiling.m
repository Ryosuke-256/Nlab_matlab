function plotNoiseCeiling(observed_corr, noise_ceiling_dist, p_value)
% 入力:
%   observed_corr      - 観測された相関係数（例: corr(A,B)）
%   noise_ceiling_dist - ノイズ天井の経験分布（例: corr(A,A')の分布）
%   p_value            - 事前に計算した検定のp値

% --- 1. ノイズ天井分布から統計量を計算 ---
mean_ceiling = mean(noise_ceiling_dist);
% 2.5パーセンタイルと97.5パーセンタイルを計算して95%信頼区間とする
ci_95 = quantile(noise_ceiling_dist, [0.025, 0.975]);

% --- 2. グラフの描画 ---
%figure;
hold on;

% 2a. ノイズ天井の95%信頼区間を灰色のエリアで描画
fill([0.5, 1.5, 1.5, 0.5], [ci_95(1), ci_95(1), ci_95(2), ci_95(2)], ...
     [0.85 0.85 0.85], ... 
     'EdgeColor', 'none', ...
     'DisplayName', '95% CI');

% 2b. ノイズ天井の平均値を黒い破線で描画
yline(mean_ceiling, 'k--', 'LineWidth', 1.5, ...
      'DisplayName', 'Average');

% 2c. 観測された相関係数を青色の棒グラフで描画
bar(1, observed_corr, 0.4, ...
    'FaceColor', [0.3 0.6 1.0], ... 
    'DisplayName', 'r');

% --- 3. グラフへのテキスト追加 ---
% 棒グラフの上に数値を表示
text(1, observed_corr - 0.1, sprintf('%.3f', observed_corr), ...
     'HorizontalAlignment', 'center', 'FontSize', 12);

% p値に基づいて有意差を示すアスタリスク(*)を表示
if p_value < 0.05
    text(1, observed_corr + 0.08, '*', 'HorizontalAlignment', 'center', ...
         'FontSize', 20, 'FontWeight', 'bold', 'Color', 'r');
end

% --- 4. グラフの体裁を整える ---
%box on; 
set(gca, 'XTick', []); 
xlim([0.5, 1.5]);
ylim([min(0, ci_95(1)-0.1) , max(1, observed_corr+0.15)]); 

%title('相関とノイズ天井の比較', 'FontSize', 16);
ylabel('Correlation coeffecient', 'FontSize', 14);
legend('Location', 'southeast');

hold off; 
end