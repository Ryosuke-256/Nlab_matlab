function [] = Graph_Significance_HMS(observed_corr_list,ceiling_distAA_list,ceiling_distAB_list,...
    p_value_list,NameA,NameB,MatNames,ShapeNames,savepath,amp)

for mat = 1:length(MatNames)
    fig = figure('Visible', 'off');
    hold on;
    for shape = 1:length(ShapeNames)
        % coef and slope
        r_value = observed_corr_list(mat,shape);

        % coef hisgram
        x_axis = shape;
        
        % ノイズ天井の95%信頼区間を灰色のエリアで描画
        ci_95 = quantile(ceiling_distAA_list(:,mat,shape), [0.05, 1]);
        fill([x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], [ci_95(1), ci_95(1), ci_95(2), ci_95(2)], ...
             'k', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
         
        bar_width = 0.4;
        bar_coef = bar(x_axis,r_value,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

        maxValue = max(ceiling_distAB_list(:,mat,shape));
        minValue = min(ceiling_distAB_list(:,mat,shape));
        centerValue = mean(ceiling_distAB_list(:,mat,shape));
        upperError = maxValue - centerValue;
        lowerError = centerValue - minValue;
        errorbar(x_axis, centerValue, lowerError, upperError, 'o', 'LineWidth', 1.0);

        graphtext1 = sprintf('%.2f',r_value);
        text(x_axis-0.5,(abs(r_value)-0.05)*r_value/abs(r_value),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8*amp);
        if p_value_list(mat,shape) < 0.05
            graphtext3 = sprintf('*');
            text(x_axis,(abs(r_value)+0.05)*r_value/abs(r_value),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12*amp);
        end

        ylim([-0.1,1.1]);
        y_Limits = ylim;
        x_Limits = xlim;

        aveorigin = mean(ceiling_distAA_list(:,mat,shape));
        bar_plot = plot([x_axis-0.5, x_axis+0.5], [aveorigin, aveorigin], 'r--', 'LineWidth', 1.2,'DisplayName', 'Within-subject average');
    end
    set(gca, 'XTick', 1:length(ShapeNames));
    xticklabels(ShapeNames);
    xlabel('Shape types','FontSize',18*amp);
    ylabel('Correlation Coefficient','FontSize',18*amp);
    title(sprintf('%s VS %s Correlation Coefficient\n%s',NameA,NameB,string(MatNames(mat))),'FontSize',18*amp);
    text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 10*amp);
    %legend([bar_coef, VR_bar,VR_95CI], {'Row data', 'VR bar','VR 95 CI'}, 'Location', 'best','Orientation','vertical');
    hold off;
    plotname = sprintf('%s/%svs%s_Coefbar_HMS_%s.jpg',savepath, NameA,NameB,string(MatNames(mat)));
    saveas(fig, plotname);
end
end

