function performHistgramCompare(dataStructA, dataStructB, options)
    % performHistgramCompare - ヒストグラム比較の作成、レイアウト設定、保存を一括で行う関数
    %
    % 入力:
    %   dataStructA, dataStructB: プロットデータ構造体 (target, error, Name)
    %   options: オプション構造体
    %       .Mode: "H", "HM", "HS", "HMS"
    %       .ResultDir: 保存先ディレクトリ
    %       .Property: プロパティ名
    %       .MatNames: 材質名リスト
    %       .ShapeNames: 形状名リスト
    %       .hdr: HDR番号リスト
    %       .Amp: 拡大率
    %       .ShowTitle: タイトル表示フラグ (任意, default: true)
    
    arguments
        dataStructA
        dataStructB
        options struct
    end
    
    % ShowTitleオプションのデフォルト設定
    if ~isfield(options, 'ShowTitle')
        options.ShowTitle = true;
    end
    
    % HMSモードは複数のFigureを作成するためループ処理
    if options.Mode == "HMS"
        numMats = size(dataStructA.target, 2);
        for m = 1:numMats
            drawAndSave(dataStructA, dataStructB, options, m);
        end
    else
        drawAndSave(dataStructA, dataStructB, options, []);
    end
end

function drawAndSave(dataStructA, dataStructB, options, matIdx)
    try
        % 1. データサイズから材質数・形状数を取得 (targetデータを使用)
        [matCount, shapeCount] = getMatShapeCount(dataStructA.target, options.Mode);
        
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
                callPlotHistgramVer1(dataStructA, dataStructB, options, "");
                
            case {"HM", "HS"}
                % タイルプロット
                if options.ShowTitle
                    sgtitle(tLayout, options.Title, 'Interpreter', 'none');
                end
                
                for i = 1:layoutConfig.loopCount
                    nexttile;
                    titleStr = string(layoutConfig.labels(i));
                    
                    % サブデータの抽出と構造体再構築
                    subDataA = sliceStruct(dataStructA, options.Mode, i, []);
                    subDataB = sliceStruct(dataStructB, options.Mode, i, []);
                    
                    callPlotHistgramVer1(subDataA, subDataB, options, titleStr);
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
                    
                    subDataA = sliceStruct(dataStructA, options.Mode, matIdx, s);
                    subDataB = sliceStruct(dataStructB, options.Mode, matIdx, s);
                    
                    callPlotHistgramVer1(subDataA, subDataB, options, titleStrSub);
                end
        end
        
        % 5. 保存 (Histgramとして保存)
        % DataAnalyzerからの呼び出しに合わせてNameA, NameBがoptionsに含まれていることを期待
        % dataStructA.Name を使うために options に追加する必要があるか確認
        % saveFigure内で options.NameA が使われるため、呼び出し元で設定するか、ここで設定する
        if ~isfield(options, 'NameA') || isempty(options.NameA)
            options.NameA = dataStructA.Name;
        end
        if ~isfield(options, 'NameB') || isempty(options.NameB)
            options.NameB = dataStructB.Name;
        end

        saveFigure(fig, options, matIdx, "Histgram");
        
    catch ME
        if exist('fig', 'var') && isvalid(fig)
            close(fig);
        end
        rethrow(ME);
    end
end

function subStruct = sliceStruct(mainStruct, mode, idx1, idx2)
    subStruct = mainStruct; % Nameなどはコピー
    
    if mode == "HM" || mode == "HS"
        subStruct.target = mainStruct.target(:, idx1);
        subStruct.error = mainStruct.error(:, idx1);
    elseif mode == "HMS"
        subStruct.target = mainStruct.target(:, idx1, idx2);
        subStruct.error = mainStruct.error(:, idx1, idx2);
    else
        % H mode or plain copy
    end
end

function callPlotHistgramVer1(plotDataA, plotDataB, options, titleStr)
    PlotHistgram_ver1(plotDataA, plotDataB, ...
        "XLabel", sprintf('Illumination map'), ...
        "YLabel", sprintf('%s', options.Property), ...
        "Title", titleStr, ...
        "HDRNo", options.hdr, ...
        "Amp", options.Amp);
end
