function [outlier_indices] = PlotScatter_ver2(x, y, options)
    % 散布図、回帰、統計分析、外れ値検出を統合した高機能描画関数
    
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
        options.YLabel (1,1) string = "Y"
        options.Title (1,1) string = ""
        options.Amp (1,1) double = 1
        options.TitleLocation (1,1) string {mustBeMember(options.TitleLocation, ["top", "bottom"])} = "top"
    end
    
    % --- 2. 統計モデルの構築 (一元化) ---
    mdl = fitlm(x, y);

    % --- 3. 統計量の計算 (モデルから直接取得) ---
    R2 = mdl.Rsquared.Ordinary;
    r_value = sign(mdl.Coefficients.Estimate(2)) * sqrt(R2);

    % --- 4. 描画の準備 ---
    hold on;
    outlier_indices = [];

    % --- 5. メインの散布図を描画 ---
    Color_scatter = [28, 48, 199] / 255;
    scatter(x, y, 15, Color_scatter , 'filled', 'DisplayName', 'Data Points');

    % --- 6. 回帰直線の描画 ---
    if options.FitType == "linear"
        plot(mdl.Variables.x1, mdl.Fitted, 'Color', '#D44843', 'LineStyle', '-','LineWidth', 1.5, 'DisplayName', 'Linear Fit');
    else
        ft_exp = fittype('a*exp(b*(x-c))+d');
        start_point = [max(y), 1, x(y==max(y)), min(y)];
        mdl_exp = fit(x, y, ft_exp, 'StartPoint', start_point);
        x_fit = linspace(min(x), max(x), 100)';
        plot(x_fit, mdl_exp(x_fit), 'm-', 'LineWidth', 1.5, 'DisplayName', 'Exponential Fit');
        y_pred_exp = mdl_exp(x);
        R2 = 1 - (sum((y - y_pred_exp).^2) / sum((y - mean(y)).^2));
    end

    % --- 7. モード別の追加描画 ---
    switch options.Mode
        case "outlier"
            studentized_residuals = mdl.Residuals.Studentized;
            outlier_indices = find(abs(studentized_residuals) > options.OutlierThreshold);
            
            if ~isempty(outlier_indices)
                scatter(x(outlier_indices), y(outlier_indices), 30, 'ro', ...
                        'LineWidth', 1.5, 'DisplayName', 'Outliers');
            end
    end

    % --- 8. グラフの体裁調整 (共通ロジック) ---   
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
    common_limits = [min([x_limits, y_limits]), max([x_limits, y_limits])];
    
    plot(common_limits, common_limits, 'Color', '#81BD5F', 'LineStyle', '--','LineWidth', 1, 'DisplayName', 'y=x line');
    
    % HDR No
    for point = 1:length(x)
        text(x(point)-0.01, y(point)+0.008, num2str(options.HDRNo(point)), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right',...
            'FontSize',8 * options.Amp);
    end

    text_x = x_limits(1)+abs(x_limits(1)-x_limits(2))/15;
    text_y = y_limits(2)-abs(x_limits(1)-x_limits(2))/10;
    text(text_x, text_y, sprintf('r = %.2f\nR^2 = %.2f', r_value, R2), ...
         'VerticalAlignment', 'top', 'FontSize', 9 * options.Amp, ...
         'BackgroundColor', 'w', 'EdgeColor', 'k');
     
    set(gca,'FontSize',8 * options.Amp);

    % --- 9. 最後の仕上げ ---
    if options.TitleLocation == "top"
        xlabel(options.XLabel, 'FontSize', 10*options.Amp, 'Interpreter', 'none');
        title(options.Title, 'FontSize', 12*options.Amp, 'Interpreter', 'none');
    else
        % bottom: タイトルをX軸ラベルの下に追加
        if options.Title ~= ""
            combinedLabel = {options.XLabel, options.Title};
        else
            combinedLabel = options.XLabel;
        end
        xlabel(combinedLabel, 'FontSize', 10*options.Amp, 'Interpreter', 'none');
        % titleは表示しない
    end

    ylabel(options.YLabel, 'FontSize', 10*options.Amp, 'Interpreter', 'none');
    grid on;
    box on;
    axis square;
    hold off;
end