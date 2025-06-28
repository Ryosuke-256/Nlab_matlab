function [] = PlotScatter_ver1(array1,array2,x_label,y_label,graph_title,HDRNo,amp,PreDim)
    %Default value
    if nargin < 1
        PreDim = 1;
    end
    
    hold on;
    x = array1;
    y = array2;
    xmax = max(abs(x));
    ymax = max(abs(y));
    xmin = min(x);
    ymin = min(y);
    r = corrcoef(x,y);
    r_value = r(1,2);

    % plot
    scatter(x,y,20,'b','filled');

    % 回帰
    if PreDim ==0
        ft = fittype('a*exp(b*(x-c))+d', 'independent', 'x', 'coefficients', {'a', 'b', 'c','d'}); 
        mdl = fit(x, y, ft, 'StartPoint', [1, 1, -xmax, -ymax]);
        x_fit = linspace(min(x), max(x), 100);
        y_fit = mdl.a * exp(mdl.b * (x_fit - mdl.c)) + mdl.d;
        plot(x_fit, y_fit, 'r-', 'LineWidth', 1.5);

        % R2
        y_mean = mean(y);
        y_pred = mdl.a * exp(mdl.b * (x - mdl.c)) + mdl.d;
        rss = sum((y - y_pred).^2);
        tss = sum((y - y_mean).^2);
        R2 = 1 - (rss / tss);
    else
        ft = fittype('a*x + b'); 
        mdl = fit(x, y, ft, 'StartPoint', [1, 0]);
        p_fit = mdl.a * x + mdl.b;
        plot(x, p_fit, 'r-', 'LineWidth', 1.5);
        
        % R2
        y_mean = mean(y);
        y_pred = feval(mdl, x);
        rss = sum((y - y_pred).^2);
        tss = sum((y - y_mean).^2);
        R2 = 1 - (rss / tss);
    end

    xlim([xmin xmax]);
    ylim([ymin ymax]);
    x_limits = xlim;
    y_limits = ylim;
    xlim([min(x_limits(1),y_limits(1)) max(x_limits(2),y_limits(2))]);
    ylim([min(x_limits(1),y_limits(1)) max(x_limits(2),y_limits(2))]);
    x_limits = xlim;
    y_limits = ylim;
    common_limits = [min([x_limits, y_limits]), max([x_limits, y_limits])];
    plot(common_limits, common_limits, 'g--', 'LineWidth', 2);

    % HDR No
    for point = 1:length(x)
        text(x(point)-0.01, y(point)+0.01, num2str(HDRNo(point)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right','FontSize',6*amp);
    end

    text(x_limits(1)*0.9,y_limits(2)*0.9, sprintf('r = %.2f',r_value), 'FontSize', 8*amp);
    %text(x_limits(1)*0.9,y_limits(2)*0.75, sprintf('Slope : %.2f',p(1)), 'FontSize', 8*amp);
    text(x_limits(1)*0.9,y_limits(2)*0.75, sprintf('R2 : %.2f',R2), 'FontSize', 8*amp);

    xlabel(x_label,'FontSize',12*amp);
    ylabel(y_label,'FontSize',12*amp);
    title(graph_title,'FontSize',12*amp);
    hold off;
end