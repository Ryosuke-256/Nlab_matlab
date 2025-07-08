function plotBootstrapResult(observed_corr, null_distribution)
% plotBootstrapResult: ブートストラップ検定の結果を可視化する
%
% 入力:
%   observed_corr     - 観測された相関係数 (単一の値)
%   null_distribution - ブートストラップ/Permutationで生成された帰無分布 (ベクトル)

% --- 1. 95%信頼区間を計算 ---
ci = quantile(null_distribution, [0.025, 0.975]);

% --- 2. グラフの描画 ---
%figure; 
hold on;

% 2a. 95%信頼区間を灰色のエリアで描画
y_limits = get(gca, 'YLim'); 
area([ci(1), ci(2)], [y_limits(2), y_limits(2)], ...
     'FaceColor', [0.8 0.8 0.8], ...
     'EdgeColor', 'none', ...
     'BaseValue', 0, ...
     'DisplayName', '95%信頼区間');

% 2b. 帰無分布をヒストグラムで描画
histogram(null_distribution, 'Normalization', 'pdf', 'DisplayName', '偶然の相関の分布(帰無分布)');

% 2c. 観測された相関係数を赤い縦線で描画
line([observed_corr, observed_corr], get(gca, 'YLim'), ...
     'Color', 'r', ...
     'LineWidth', 2, ...
     'DisplayName', '観測された相関係数');

% --- 3. グラフの体裁を整える ---
title('ブートストラップ検定の結果');
xlabel('相関係数');
ylabel('確率密度');
legend; 
grid on; 
hold off; 

fprintf('\n--- グラフ情報 ---\n');
fprintf('観測された相関係数: %.4f\n', observed_corr);
fprintf('95%%信頼区間: [%.4f, %.4f]\n', ci(1), ci(2));
end