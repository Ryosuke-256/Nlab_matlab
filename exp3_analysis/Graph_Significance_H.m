function [] = Graph_Significance_H(observed_corr, noise_ceiling_distAA,noise_ceiling_distAB, p_value,amp,title_str,savepath)
%   observed_corr      - 観測された相関係数（例: corr(A,B)）
%   noise_ceiling_dist - ノイズ天井の経験分布（例: corr(A,A')の分布）
%   p_value            - 事前に計算した検定のp値
fig = figure('Visible','off');

% coef hisgram
hold on;
x_axis = 1;

% ノイズ天井の95%信頼区間を灰色のエリアで描画
ci_100 = quantile(noise_ceiling_distAA, [0.0, 1.0]);
fill([x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], [ci_100(1), ci_100(1), ci_100(2), ci_100(2)], ...
     'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
 
ci_95 = quantile(noise_ceiling_distAA, [0.05, 1.0]);
fill([x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], [ci_95(1), ci_95(1), ci_95(2), ci_95(2)], ...
     'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
 
bar_width = 0.4;
bar_coef = bar(x_axis,observed_corr,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

maxValue = max(noise_ceiling_distAB);
minValue = min(noise_ceiling_distAB);
centerValue = mean(noise_ceiling_distAB);
upperError = maxValue - centerValue;
lowerError = centerValue - minValue;
errorbar(x_axis, centerValue,lowerError,upperError, 'o', 'LineWidth', 1.0);

graphtext1 = sprintf('%.2f',observed_corr);
text(1-0.5,(abs(observed_corr)-0.05)*observed_corr/abs(observed_corr),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8*amp);
if p_value < 0.05
    graphtext3 = sprintf('*');
    text(1,(abs(observed_corr)+0.05)*observed_corr/abs(observed_corr),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12*amp);
end

ylim([0.0,1.1]);
y_Limits = ylim;
x_Limits = xlim;

aveorigin = mean(noise_ceiling_distAA);
bar_plot = yline(aveorigin, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Within-subject average');

text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 10*amp);
ylabel('Correlation Coefficient','FontSize',18*amp);

hold off;

grid on;
set(gca, 'XTick', []);
title(title_str, 'FontSize', 18*amp);
saveas(fig, savepath);
fprintf('モードのグラフを保存しました\n');
end