function [] = Graph_MatShape_Significance(dataA,dataB,corrA,corrAB,threshold,NameA,NameB,numBootstrap,MatNames,ShapeNames,savepath,amp)
[numIllumination,MatNum,ShapeNum,~] = size(dataA); % 照明環境の数

for mat = 1:MatNum
    figure;
    hold on;
    for shape = 1:ShapeNum   
        % coef and slope
        x = dataA(:,mat,shape);
        y = dataB(:,mat,shape);
        r_value = corr(x,y);
        p = polyfit(x,y,1);

        maxValue = max(corrAB(:,mat,shape));
        minValue = min(corrAB(:,mat,shape));
        centerValue = mean(corrAB(:,mat,shape));
        upperError = maxValue - centerValue;
        lowerError = centerValue - minValue;

        % coef hisgram
        x_axis = shape;
        bar_width = 0.4;
        bar_coef = bar(x_axis,r_value,bar_width, 'FaceColor', 'b', 'DisplayName', 'Coef');

        errorbar(x_axis, centerValue, lowerError, upperError, 'o', 'LineWidth', 1.0);

        graphtext1 = sprintf('%.2f',r_value);
        text(x_axis-0.1,(abs(r_value)+0.06)*r_value/abs(r_value),graphtext1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',8*amp);
        if threshold(mat,shape) > 0
            graphtext3 = sprintf('*');
            text(x_axis,(abs(r_value)+0.12)*r_value/abs(r_value),graphtext3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',12*amp);
        end

        ylim([-0.1,1.1]);
        y_Limits = ylim;
        x_Limits = xlim;
        SortCorrA = sort(corrA(:,mat,shape));
        maxorigin = SortCorrA(round(numBootstrap*0.95)); 
        minorigin = SortCorrA(round(numBootstrap*0.05)); 
        CI95 = fill([x_axis-0.5,x_axis+0.5,x_axis+0.5,x_axis-0.5], ...
            [minorigin,minorigin,maxorigin,maxorigin], ...
            'k', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

        aveorigin = mean(corrA(:,mat,shape));
        bar_plot = plot([x_axis-0.5, x_axis+0.5], [aveorigin, aveorigin], 'r--', 'LineWidth', 1.2,'DisplayName', 'Within-subject average');
    end
    set(gca, 'XTick', 1:length(ShapeNames));
    xticklabels(ShapeNames);
    xlabel('Shape types','FontSize',18*amp);
    ylabel('Correlation Coefficient','FontSize',18*amp);
    title(sprintf('%s VS %s Correlation Coefficient\n%s',NameA,NameB,string(MatNames(mat))),'FontSize',18*amp);
    text(x_Limits(1)*0.9,y_Limits(2)*0.95, '* : p < 0.05', 'FontSize', 15*amp);
    %legend([bar_coef, VR_bar,VR_95CI], {'Row data', 'VR bar','VR 95 CI'}, 'Location', 'best','Orientation','vertical');
    hold off;
    plotname = sprintf('%s/%svs%s_Coefbar_%s.jpg',savepath, NameA,NameB,string(MatNames(mat)));
    saveas(gcf, plotname);
end
end

