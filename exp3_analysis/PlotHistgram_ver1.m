function [] = PlotHistgram_ver1(plotDataA,plotDataB,options)
    % --- 1. 引数の定義と検証 ---
    arguments
        plotDataA (1,1) struct {mustHaveFields(plotDataA, ["target", "error", "Name"])}
        plotDataB (1,1) struct {mustHaveFields(plotDataB, ["target", "error", "Name"])}
        
        % オプション引数 (名前/値ペア)
        options.HDRNo (:,:) double {mustBeVector} = []
        options.XLabel (1,1) string = "X"
        options.YLabel (1,1) string = "Y"
        options.Title (1,1) string = "title"
        options.Amp (1,1) double = 1
    end

    bar1 = plotDataA.target;
    err1 = plotDataA.error;
    name1 = plotDataA.Name;
    bar2 = plotDataB.target;
    err2 = plotDataB.error;
    name2 = plotDataB.Name;
    
    bar_width = 0.35;
    x = 1:length(options.HDRNo);

    hold on;
    bar_1 = bar(x + bar_width/2, bar1, bar_width, 'FaceColor', '#F8A088',  'DisplayName', sprintf("%s",name1)); 
    errorbar(x + bar_width/2, bar1, err1, 'k', 'linestyle', 'none');
    bar_2 = bar(x - bar_width/2, bar2, bar_width, 'FaceColor', '#7F96C2', 'DisplayName', sprintf("%s",name2)); 
    errorbar(x - bar_width/2, bar2, err2, 'k', 'linestyle', 'none');

    % range
    ymax = max(max(bar1),max(bar2))*1.2;
    ymin = min(min(bar1),min(bar2))*1.2;
    ylim([ymin ymax]);
    
    set(gca, 'XTick', x);
    xticklabels(options.HDRNo);
    xtickangle(90);
    set(gca,'FontSize',8*options.Amp);

    xlabel(options.XLabel,'FontSize',14*options.Amp); 
    ylabel(options.YLabel,'FontSize',14*options.Amp);
    title(options.Title,'FontSize',12*options.Amp);
    legend([bar_1, bar_2], 'Location', 'southeast','Orientation','vertical', 'Box', 'on');
    %legend('boxoff');
    
    grid on;
    box on;
    hold off;
end