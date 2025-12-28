function [matCount, shapeCount] = getMatShapeCount(data, mode)
    % getMatShapeCount - データとモードから材質数と形状数を取得
    %
    % 入力:
    %   data: データ配列
    %   mode: "H", "HM", "HS", "HMS"
    
    dataSize = size(data);
    switch mode
        case "H"
            matCount = 1; shapeCount = 1;
        case "HM"
            matCount = getSizeAt(dataSize, 2); shapeCount = 1;
        case "HS"
            matCount = 1; shapeCount = getSizeAt(dataSize, 2);
        case "HMS"
            matCount = getSizeAt(dataSize, 2); shapeCount = getSizeAt(dataSize, 3);
        otherwise
            matCount = 1; shapeCount = 1;
    end
end
