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
    fig = figure('Visible', 'off');
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
            legend('Location', 'best', 'FontSize', 3*options.Amp);
            titleKind = 'All';
        case "HM"
            [matNames, ~] = selectNamesFromDataSize(residuals, [], options.Mode);
            legend(matNames, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 3*options.Amp);
            titleKind = 'Material';
        case "HS"
            [~, shapeNames] = selectNamesFromDataSize(residuals, [], options.Mode);
            legend(shapeNames, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 3*options.Amp);
            titleKind = 'Shape';
        case "HMS"
            titleKind = 'HMS';
    end

    titleStr = sprintf('%s vs %s about %s\\nResiduals_%s', dataSpec1.SetName, dataSpec2.SetName, options.Property, titleKind);
    title(titleStr, 'Interpreter', 'none', 'FontSize', 12*options.Amp);
    xlabel('Illumination', 'Interpreter', 'none', 'FontSize', 12*options.Amp);
    ylabel('Residuals', 'Interpreter', 'none', 'FontSize', 12*options.Amp);
    grid on; box on; axis tight;
    
    x = 1:length(HDRNum_30);
    set(gca, 'XTick', x);
    xticklabels(HDRNum_30);
    xtickangle(90);
    set(gca, 'FontSize', 6 * options.Amp);
    
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
