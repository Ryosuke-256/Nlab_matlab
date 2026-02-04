function [] = PlotHistgram_Single(plotDataA, options)
    % --- 1. 引数の定義と検証 ---
    arguments
        plotDataA (1,1) struct {mustHaveFields(plotDataA, ["target", "error", "Name"])}
        
        % オプション引数 (名前/値ペア)
        options.HDRNo (:,:) double {mustBeVector} = []
        options.XLabel (1,1) string = "X"
        options.YLabel (1,1) string = "Y"
        options.Title (1,1) string = "title"
        options.Amp (1,1) double = 1
        options.ShowLegend (1,1) logical = true
    end

    bar1 = plotDataA.target;
    err1 = plotDataA.error;
    name1 = plotDataA.Name;
    
    bar_width = 0.6;
    x = 1:length(options.HDRNo);

    hold on;
    % 単一バー
    bar_1 = bar(x, bar1, bar_width, 'FaceColor', '#F8A088', 'DisplayName', sprintf("%s",name1)); 
    errorbar(x, bar1, err1, 'k', 'linestyle', 'none');

    % range
    if isempty(bar1)
         ymax = 1; ymin = 0;
    else
        ymax = max(bar1(:))*1.2;
        ymin = min(bar1(:))*1.2;
    end
    
    if ymax == ymin
        ymax = ymax + 0.1;
    end
    
    ylim([ymin ymax]);
    
    set(gca, 'XTick', x);
    xticklabels(options.HDRNo);
    xtickangle(90);
    set(gca,'FontSize',8*options.Amp);

    xlabel(options.XLabel,'FontSize',14*options.Amp); 
    ylabel(options.YLabel,'FontSize',14*options.Amp);
    title(options.Title,'FontSize',12*options.Amp, 'Interpreter', 'none');
    
    if options.ShowLegend
        legend([bar_1], 'Location', 'southeast','Orientation','vertical', 'Box', 'on');
    end
    
    grid on;
    box on;
    hold off;
end
