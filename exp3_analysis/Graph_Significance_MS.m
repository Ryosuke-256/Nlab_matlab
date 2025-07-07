function [] = Graph_Significance_MS(dataA,dataB,corrA,corrAB,threshold,amp,repeater)

for i = 1:repeater
    r_value  = corr(dataA(:,i),dataB(:,i));

    % coef hisgram
    hold on;
    x_axis = i;
    bar_width = 0.4;
    bar_coef = bar(x_axis,r_value,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

    maxValue = max(corrAB(:,i));
    minValue = min(corrAB(:,i));
    centerValue = mean(corrAB(:,i));
    upperError = maxValue - centerValue;
    lowerError = centerValue - minValue;
    errorbar(x_axis, centerValue, lowerError, upperError, 'o', 'LineWidth', 1.0);

    graphtext1 = sprintf('%.2f',r_value);
    text(x_axis-0.1,(abs(r_value)+0.06)*r_value/abs(r_value),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8*amp);
    if threshold(i) > 0
        graphtext3 = sprintf('*');
        text(x_axis,(abs(r_value)+0.12)*r_value/abs(r_value),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12*amp);
    end

    ylim([0.0,1.1]);
    y_Limits = ylim;
    x_Limits = xlim;
    maxorigin = max(corrA(:,i));
    minorigin = min(corrA(:,i));
    CI95 = fill([x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], ...
        [minorigin,minorigin,maxorigin,maxorigin], ...
        'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    aveorigin = mean(corrA(:,i));
    bar_plot = plot([x_axis-0.5, x_axis+0.5], [aveorigin, aveorigin], 'k--', 'LineWidth', 1.2, 'DisplayName', 'Within-subject average');

    text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 15*amp);
    ylabel('Correlation Coefficient','FontSize',18*amp);
    hold off;
end
end