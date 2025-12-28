function performScatterPlot(dataA, dataB, options)
    % performScatterPlot - 散布図の作成、レイアウト設定、保存を一括で行う関数
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
    
    arguments
        dataA
        dataB
        options struct
    end
    
    % HMSモードは複数のFigureを作成するためループ処理
    if options.Mode == "HMS"
        numMats = size(dataA, 2);
        for m = 1:numMats
            drawAndSave(dataA, dataB, options, m);
        end
    else
        drawAndSave(dataA, dataB, options, []);
    end
end

function drawAndSave(dataA, dataB, options, matIdx)
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
        
        % 2. レイアウト設定
        layoutConfig = configureLayout(options.Mode, matCount, shapeCount, options.MatNames, options.ShapeNames);
        
        % 3. Figure作成
        fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 800]); 
        
        % 全モードでtiledlayoutを使用
        tLayout = tiledlayout(layoutConfig.rows, layoutConfig.cols, 'TileSpacing', 'compact', 'Padding', 'compact');
        
        % 4. プロット実行
        switch options.Mode
            case "H"
                % 単一プロット
                if options.ShowTitle
                    sgtitle(tLayout, options.Title, 'Interpreter', 'none');
                end
                
                nexttile;
                % Hモードではsgtitleでタイトルを表示するため、個別のプロットタイトルは空にするか、必要に応じて設定
                % ここでは重複を避けるため空にする、またはサブタイトルがあればそれを設定
                callPlotScatterVer2(dataA(:), dataB(:), options, "");
                
            case {"HM", "HS"}
                % タイルプロット
                if options.ShowTitle
                    sgtitle(tLayout, options.Title, 'Interpreter', 'none');
                end
                
                for i = 1:layoutConfig.loopCount
                    nexttile;
                    titleStr = string(layoutConfig.labels(i));
                    
                    if options.Mode == "HM"
                        subDataA = dataA(:, i);
                        subDataB = dataB(:, i);
                    else % HS
                        subDataA = dataA(:, i);
                        subDataB = dataB(:, i);
                    end
                    
                    callPlotScatterVer2(subDataA, subDataB, options, titleStr);
                end
                
            case "HMS"
                % HMSモード (特定の材質 matIdx について、形状ごとにプロット)
                titleStrMain = sprintf('%s-%s', options.Title, string(options.MatNames(matIdx)));
                
                if options.ShowTitle
                    sgtitle(tLayout, titleStrMain, 'Interpreter', 'none');
                end
                
                for s = 1:layoutConfig.loopCount
                    nexttile;
                    titleStrSub = string(options.ShapeNames(s));
                    
                    subDataA = dataA(:, matIdx, s);
                    subDataB = dataB(:, matIdx, s);
                    
                    callPlotScatterVer2(subDataA, subDataB, options, titleStrSub);
                end
        end
        
        % 5. 保存
        saveFigure(fig, options, matIdx, "scatter");
        
    catch ME
        if exist('fig', 'var') && isvalid(fig)
            close(fig);
        end
        rethrow(ME);
    end
end

function callPlotScatterVer2(vecA, vecB, options, titleStr)
    PlotScatter_ver2(vecA, vecB, ...
        "XLabel", sprintf('%s-%s', options.NameA, options.Property), ...
        "YLabel", sprintf('%s-%s', options.NameB, options.Property), ...
        "Mode", options.Residual, ...
        "Title", titleStr, ...
        "HDRNo", options.hdr, ...
        "Amp", options.Amp, ...
        "FitType", "linear", ...
        "TitleLocation", options.TitleLocation);
end


