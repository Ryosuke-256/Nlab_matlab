function [] = Simpleplot(x, y, options)
    % --- 1. 引数の定義と検証 ---
    arguments
        x (:,1) double
        y (:,1) double
        % オプション引数 (名前/値ペア)
        options.Mode (1,1) string {mustBeMember(options.Mode, ["regression", "outlier"])} = "regression"
        options.FitType (1,1) string {mustBeMember(options.FitType, ["linear", "exp"])} = "linear"
        options.OutlierThreshold (1,1) double {mustBePositive} = 2.0
        options.HDRNo (:,:) double {mustBeVector} = []
        options.XLabel (1,1) string = "X"
        options.YLabel (1,1) string = "GRI"
        options.Title (1,1) string = "title"
        options.Amp (1,1) double = 1
    end

    % --- 4. 描画の準備 ---
    hold on;

    % --- 5. メインの散布図を描画 ---
    Color_scatter = [28, 48, 199] / 255;
    scatter(x, y, 15, Color_scatter , 'filled', 'DisplayName', 'Data Points');

    % --- 8. グラフの体裁調整 (共通ロジック) ---   
    %{
    xmax = max(abs(x));
    ymax = max(abs(y));
    xmin = min(x);
    ymin = min(y);
    xlim([xmin xmax]);
    ylim([ymin ymax]);
    x_limits = xlim;
    y_limits = ylim;
    xlim([min(x_limits(1),y_limits(1))*1.1 max(x_limits(2),y_limits(2))*1.1]);
    ylim([min(x_limits(1),y_limits(1))*1.1 max(x_limits(2),y_limits(2))*1.1]);
    x_limits = xlim;
    y_limits = ylim;
    %}
    
    % HDR No
    for point = 1:length(x)
        text(x(point)-0.01, y(point)+0.008, num2str(options.HDRNo(point)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right',...
            'FontSize',8 * options.Amp);
    end
    
    set(gca, 'XTick', x);
    xticklabels(options.HDRNo);
    xtickangle(90);
    set(gca,'FontSize',8 * options.Amp);

    % --- 9. 最後の仕上げ ---
    xlabel(options.XLabel, 'FontSize', 12*options.Amp, 'Interpreter', 'none');
    ylabel(options.YLabel, 'FontSize', 12*options.Amp, 'Interpreter', 'none');
    title(options.Title, 'FontSize', 12*options.Amp, 'Interpreter', 'none');
    grid on;
    box on;
    axis square;
    hold off;
end