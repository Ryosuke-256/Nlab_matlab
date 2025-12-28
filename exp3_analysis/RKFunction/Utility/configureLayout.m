function config = configureLayout(mode, matNum, shapeNum, matNames, shapeNames)
    % configureLayout - モードに応じたプロットのレイアウト設定を返す
    %
    % 入力:
    %   mode: "H", "HM", "HS", "HMS"
    %   matNum, shapeNum: 材質数、形状数
    %   matNames, shapeNames: 名前リスト
    
    config = struct();
    switch mode
        case "H"
            config.rows = 1; config.cols = 1;
            config.labels = {};
            config.loopCount = 1;
        case "HM"
            config.rows = 2; config.cols = 2;
            config.labels = matNames;
            config.loopCount = matNum;
        case "HS"
            config.rows = 2; config.cols = 3;
            config.labels = shapeNames;
            config.loopCount = shapeNum;
        case "HMS"
            config.rows = 2; config.cols = 3;
            config.labels = shapeNames;
            config.loopCount = 6; % 通常は形状数
            if shapeNum > 0, config.loopCount = shapeNum; end
    end
end
