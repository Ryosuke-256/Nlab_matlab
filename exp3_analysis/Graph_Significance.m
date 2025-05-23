function [] = Graph_Significance(dataA,dataB,corrA,corrAB,threshold,amp)
x = dataA;
y = dataB;
r = corr(x,y);
r_value = r;

% coef hisgram
%hold on;
x_axis = 1;
bar_width = 0.4;
bar_coef = bar(x_axis,r_value,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

maxValue = max(corrAB);
minValue = min(corrAB);
centerValue = mean(corrAB);
upperError = maxValue - centerValue;
lowerError = centerValue - minValue;
errorbar(x_axis, centerValue, lowerError, upperError, 'o', 'LineWidth', 1.0);

graphtext1 = sprintf('%.2f',r_value);
text(1*0.9,(abs(r_value)+0.06)*r_value/abs(r_value),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8*amp);
if threshold > 0
    graphtext3 = sprintf('*');
    text(1,(abs(r_value)+0.12)*r_value/abs(r_value),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12*amp);
end

ylim([0.0,1.1]);
y_Limits = ylim;
x_Limits = xlim;
maxorigin = max(corrA);
minorigin = min(corrA);
VR_95CI = fill([x_Limits(1),x_Limits(2),x_Limits(2),x_Limits(1)], ...
    [minorigin,minorigin,maxorigin,maxorigin], ...
    'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

aveorigin = mean(corrA);
VR_bar = yline(aveorigin, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Within-subject average');

text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 15*amp);
ylabel('Correlation Coefficient','FontSize',18*amp);
%{
set(gca, 'XTick', []);
ylabel('Correlation Coefficient','FontSize',18*amp);
title(graphtitle,'FontSize',18*amp);
text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 15*amp);
grid on;
hold off;
%}
end