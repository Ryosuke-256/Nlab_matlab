function [] = Graph_Significance(ax,observed_corr, noise_ceiling_distAA,noise_ceiling_distAB, p_value,repeater,options)
arguments
    ax (1,1) matlab.graphics.axis.Axes
    observed_corr (1,1) double
    noise_ceiling_distAA (:,:) {mustBeNumeric, mustBeReal}
    noise_ceiling_distAB (:,:) {mustBeNumeric, mustBeReal}
    p_value (1,1) double
    repeater (1,1) double = 1
    
    options.Title (1,1) string = "Significance Histgram"
    options.XLabel (1,1) string = "Condition"
    options.YLabel (1,1) string = "Correlation Coefficient"
    options.Amp    (1,1) double = 1
    options.Labels (1,:) string = []
end

% coef hisgram
%cla(ax, 'reset');

hold(ax, 'on');
x_axis = repeater;

% ノイズ天井の95%信頼区間を灰色のエリアで描画
ci_100 = quantile(noise_ceiling_distAA, [0.0, 1.0]);
fill(ax,[x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], [ci_100(1), ci_100(1), ci_100(2), ci_100(2)], ...
     'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
 
ci_95 = quantile(noise_ceiling_distAA, [0.05, 1.0]);
fill(ax,[x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], [ci_95(1), ci_95(1), ci_95(2), ci_95(2)], ...
     'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
 
bar_width = 0.4;
bar(ax,x_axis,observed_corr,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

maxValue = max(noise_ceiling_distAB);
minValue = min(noise_ceiling_distAB);
centerValue = mean(noise_ceiling_distAB);
upperError = maxValue - centerValue;
lowerError = centerValue - minValue;
errorbar(ax,x_axis, centerValue,lowerError,upperError, 'o', 'LineWidth', 1.0);

graphtext1 = sprintf('%.2f',observed_corr);
text(ax,x_axis-0.5,(abs(observed_corr)-0.05)*observed_corr/abs(observed_corr),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',10 * options.Amp);
if p_value < 0.05
    graphtext3 = sprintf('*');
    text(ax,x_axis,(abs(observed_corr)+0.05)*observed_corr/abs(observed_corr),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',10 * options.Amp);
end

ylim(ax,[0.0,1.1]);
y_Limits = ylim;
x_Limits = xlim;

aveorigin = mean(noise_ceiling_distAA);
% plot関数で水平線を描画
plot(ax, [x_axis-0.5, x_axis+0.5], [aveorigin, aveorigin], ...
     'k--', 'LineWidth', 1.0, 'DisplayName', 'Within-subject average');
 
% 注釈 
text(ax,x_Limits(1)*0.9,y_Limits(2)*1.05, '* : p < 0.05', 'FontSize', 10 * options.Amp);

%ラベル
ylabel(ax,options.YLabel,'FontSize',12 * options.Amp);
title(ax,options.Title, 'FontSize', 12 * options.Amp);

grid(ax, 'on');
set(ax, 'XTick', []);
hold(ax, 'off');
end