function saveFigure(fig, options, matIdx, plotType)
    % saveFigure - 統一された命名規則でFigureを保存し、閉じる
    %
    % 入力:
    %   fig: Figureハンドル
    %   options: オプション構造体 (NameA, NameB, Property, Mode, ResultDir等を含む)
    %   matIdx: 材質インデックス (HMSモード用、任意)
    %   plotType: プロットの種類 (例: "scatter", "Histgram")
    
    if nargin < 4
        plotType = "scatter";
    end
    
    filename_suffix = options.Mode;
    if options.Mode == "HMS" && ~isempty(matIdx)
        filename_suffix = "HMS_" + string(options.MatNames(matIdx));
    end
    
    if isempty(options.NameB)
        plotFileName = sprintf('%s_%s_%s_%s.jpg', options.NameA, options.Property, plotType, filename_suffix);
    else
        plotFileName = sprintf('%svs%s_%s_%s_%s.jpg', options.NameA, options.NameB, options.Property, filename_suffix, plotType);
    end
    
    if options.ResultDir ~= ""
        fullPath = fullfile(options.ResultDir, plotFileName);
        saveas(fig, fullPath);
        fprintf('  -> Saved scatter plot: %s\n', plotFileName);
    end
    close(fig);
end
