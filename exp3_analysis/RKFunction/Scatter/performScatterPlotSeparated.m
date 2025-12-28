function performScatterPlotSeparated(dataA, dataB, options)
    % performScatterPlotSeparated - 散布図を条件ごとに個別のファイルとして保存する関数
    %
    % 入力:
    %   dataA, dataB: プロットするデータ
    %   options: オプション構造体
    %       .Mode: "H", "HM", "HS", "HMS"
    %       .ResultDir: 保存先ディレクトリ
    %       .NameA, .NameB: データセット名
    %       .Property: プロパティ名 (例: "GRI")
    %       .MatNames: 材質名リスト
    %       .ShapeNames: 形状名リスト
    %       .hdr: HDR番号リスト
    %       .Amp: 拡大率
    %       .Residual: "regression" or "outlier"
    %       .ShowTitle: タイトルを表示するかどうか (default: true)
    %       .TitleLocation: "top" or "bottom" (default: "top")
    
    arguments
        dataA
        dataB
        options struct
    end
    
    % ShowTitleオプションのデフォルト設定
    if ~isfield(options, 'ShowTitle')
        options.ShowTitle = true;
    end
    
    % TitleLocationオプションのデフォルト設定
    if ~isfield(options, 'TitleLocation')
        options.TitleLocation = "top";
    end

    try
        % 1. データサイズから材質数・形状数を取得
        [matCount, shapeCount] = getMatShapeCount(dataA, options.Mode);
        
        % 2. モード別のループ処理と保存
        switch options.Mode
            case "H"
                % [1枚]
                processSinglePlot(dataA(:), dataB(:), options, "", []);
                
            case "HM"
                % [M枚]
                for m = 1:matCount
                    subDataA = dataA(:, m);
                    subDataB = dataB(:, m);
                    titleStr = string(options.MatNames(m));
                    suffix = sprintf('_%s', titleStr);
                    processSinglePlot(subDataA, subDataB, options, titleStr, suffix);
                end
                
            case "HS"
                 % [S枚]
                for s = 1:shapeCount
                    subDataA = dataA(:, s);
                    subDataB = dataB(:, s);
                    titleStr = string(options.ShapeNames(s));
                    suffix = sprintf('_%s', titleStr);
                    processSinglePlot(subDataA, subDataB, options, titleStr, suffix);
                end
                
            case "HMS"
                 % [M * S枚]
                for m = 1:matCount
                    for s = 1:shapeCount
                        subDataA = dataA(:, m, s);
                        subDataB = dataB(:, m, s);
                        
                        matStr = string(options.MatNames(m));
                        shapeStr = string(options.ShapeNames(s));
                        titleStr = sprintf('%s-%s', matStr, shapeStr);
                        suffix = sprintf('_%s_%s', matStr, shapeStr);
                        
                        processSinglePlot(subDataA, subDataB, options, titleStr, suffix);
                    end
                end
        end
        
    catch ME
        rethrow(ME);
    end
end

function processSinglePlot(vecA, vecB, options, titlePart, suffix)
    % 単一のプロットを作成・保存する内部関数
    
    % Figure作成
    fig = figure('Visible', 'off'); % サイズはデフォルトまたは適宜調整
    
    % タイトル生成
    % 全体のタイトル + 個別の条件名
    if titlePart ~= ""
        fullTitle = sprintf('%s (%s)', options.Title, titlePart);
    else
        fullTitle = options.Title;
    end
    
    % タイトル表示制御
    if ~options.ShowTitle
        displayTitle = "";
    else
        displayTitle = fullTitle;
    end

    % プロット呼び出し
    PlotScatter_ver2(vecA, vecB, ...
        "XLabel", sprintf('%s-%s', options.NameA, options.Property), ...
        "YLabel", sprintf('%s-%s', options.NameB, options.Property), ...
        "Mode", options.Residual, ...
        "Title", displayTitle, ...
        "HDRNo", options.hdr, ...
        "Amp", options.Amp, ...
        "FitType", "linear", ...
        "TitleLocation", options.TitleLocation);
    
    % 保存
    if options.ResultDir ~= ""
        % ファイル名生成: Scatter_[NameA]_[NameB]_[Property][suffix].jpg
        baseName = sprintf('Scatter_%s_%s_%s', options.NameA, options.NameB, options.Property);
        fileName = string(baseName) + string(suffix) + ".jpg";
        
        saveas(fig, fullfile(options.ResultDir, fileName));
        fprintf('  -> Plot saved: %s\n', fileName);
    end
    
    close(fig);
end
