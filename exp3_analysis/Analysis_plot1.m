function [] = Analysis_plot1(array1,array2,coef_list,slop_list,x_label,y_label,graph_title,HDRNo,amp)
    x = array1;
    y = array2;
    r = corrcoef(x,y);
    r_value = r(1,2);
    coef_list(end+1) = r_value;
    p = polyfit(x,y,1);
    p_fit = polyval(p,x);
    slop_list(end+1) = p(1);

    scatter(x,y,'filled');
    hold on;
    plot(x,p_fit,'r-','LineWidth',1.5);
    hold off;

    % HDR No
    for point = 1:length(x)
        text(x(point)-0.01, y(point)+0.01, num2str(HDRNo(point)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right','FontSize',6*amp);
    end

    y_Limits = ylim;
    x_Limits = xlim;
    text(x_Limits(1)*0.9,y_Limits(2)*0.9, sprintf('r = %.2f',r_value), 'FontSize', 8*amp);
    text(x_Limits(1)*0.9,y_Limits(2)*0.75, sprintf('Slope : %.2f',p(1)), 'FontSize', 8*amp);

    xlabel(x_label,'FontSize',12*amp);
    ylabel(y_label,'FontSize',12*amp);
    title(graph_title,'FontSize',12*amp);
end