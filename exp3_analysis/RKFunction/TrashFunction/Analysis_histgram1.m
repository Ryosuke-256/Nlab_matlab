function [] = Analysis_histgram1(array1,err_array1,array2,err_array2,x_label,x_ticklabels,y_label,graph_title,amp)
    bar1 = array1;
    err1 = err_array1;
    bar2 = array2;
    err2 = err_array2;
    bar_width = 0.35;
    x = 1:length(x_ticklabels);

    hold on;
    bar_1 = bar(x + bar_width/2, bar1, bar_width, 'FaceColor', 'b', 'DisplayName', '3D'); 
    errorbar(x + bar_width/2, bar1, err1, 'k', 'linestyle', 'none');
    bar_2 = bar(x - bar_width/2, bar2, bar_width, 'FaceColor', 'r', 'DisplayName', '3D'); 
    errorbar(x - bar_width/2, bar2, err2, 'k', 'linestyle', 'none');
    hold off;

    ylim([-1.2 1.2]);
    set(gca, 'XTick', x);
    xticklabels(x_ticklabels);
    xtickangle(90);
    set(gca,'FontSize',6*amp);

    xlabel(x_label,'FontSize',12*amp); 
    ylabel(y_label,'FontSize',12*amp);
    title(graph_title,'FontSize',12*amp);
    legend([bar_1, bar_2], {'VR', '2D'}, 'Location', 'southeast','Orientation','vertical');
    legend('boxoff');
    grid on;
end