function createSingleResidualPlot(residuals, dataSpec1, dataSpec2, options, HDRNum_30, ResultDir, selectNamesFromDataSize)
% createSingleResidualPlot - 単一の残差プロットを作成
%
% 入力:
%   residuals: 残差データ
%   dataSpec1, dataSpec2: データ仕様
%   options: オプション（Mode, Amp, Property, Save フィールドを含む）
%   HDRNum_30: HDR番号配列
%   ResultDir: 結果ディレクトリ
%   selectNamesFromDataSize: 名前選択関数ハンドル

try
    % オプションデフォルト設定
    if ~isfield(options, 'FigureSize'), options.FigureSize = "slender"; end
    if ~isfield(options, 'ShowTitle'), options.ShowTitle = true; end
    if ~isfield(options, 'TitleLocation'), options.TitleLocation = "top"; end

    % 図のサイズ設定
    if options.FigureSize == "slender"
        figPos = [100, 100, 1200, 300]; % 横長
    else
        figPos = [100, 100, 1000, 600];  % 通常
    end

    fig = figure('Visible', 'off', 'Position', figPos);
    hold on;
    
    % 2次元目でループして、同一グラフにプロット
    for i = 1:size(residuals, 2)
        data_slice = residuals(:, i);
        plot(1:numel(data_slice), data_slice, '-o', 'LineWidth', 0.75);
    end
    
    hold off;
    grid on; box on; axis tight;
    
    % モードに応じて凡例とタイトルを設定
    switch options.Mode
        case "H"
            %legend('Location', 'bestoutside', 'FontSize', 5*options.Amp);
            titleKind = 'All';
        case "HM"
            [matNames, ~] = selectNamesFromDataSize(residuals, [], options.Mode);
            legend(matNames, 'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 5*options.Amp);
            titleKind = 'Material';
        case "HS"
            [~, shapeNames] = selectNamesFromDataSize(residuals, [], options.Mode);
            legend(shapeNames, 'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 5*options.Amp);
            titleKind = 'Shape';
        case "HMS"
            titleKind = 'HMS';
    end
    
    x = 1:length(HDRNum_30);
    set(gca, 'XTick', x);
    xticklabels(HDRNum_30);
    xtickangle(90);
    set(gca, 'FontSize', 6 * options.Amp);
    
    % タイトル生成
    titleStr = sprintf('%s vs %s about %s_Residuals_%s', dataSpec1.SetName, dataSpec2.SetName, options.Property, titleKind);
    
    if ~options.ShowTitle
        titleStr = "";
    end

    if options.TitleLocation == "top"
        xlabel('Illumination', 'Interpreter', 'none', 'FontSize', 10*options.Amp);
        if titleStr ~= ""
            title(titleStr, 'Interpreter', 'none', 'FontSize', 8*options.Amp);
        end
    else
        % bottom
        if titleStr ~= ""
            xlabel({'Illumination', titleStr}, 'Interpreter', 'none', 'FontSize', 10*options.Amp);
        else
            xlabel('Illumination', 'Interpreter', 'none', 'FontSize', 10*options.Amp);
        end
    end
    
    ylabel('Residuals', 'Interpreter', 'none', 'FontSize', 10*options.Amp);
    grid on; box on; axis tight;
    
    ymax = max(abs(residuals), [], 'all') * 1.1;
    ylim([-ymax ymax]);

    if options.Save
        plotFileName = sprintf('%svs%s_%s_%s_residual.jpg', ...
                               dataSpec1.SetName, dataSpec2.SetName, options.Property, titleKind);
        plotFullPath = fullfile(ResultDir, plotFileName);
        saveas(fig, plotFullPath);
        fprintf('  -> 残差プロットを保存しました: %s\n', plotFullPath);
        close(fig);
    else
        set(fig, 'Visible', 'on');
    end
catch ME
    if exist('fig', 'var') && isvalid(fig)
        close(fig);
    end
    rethrow(ME);
end

end
