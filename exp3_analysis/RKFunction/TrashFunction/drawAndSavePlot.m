function drawAndSavePlot(plotData, plotOptions, mat_idx, ResultDir, configurePlotLayout, createFigureWithLayout, saveFigureWithNaming, getMatShapeCount, plotScatterSingle)
% drawAndSavePlot - 散布図の描画と保存
%
% 入力:
%   plotData: プロットデータ
%   plotOptions: プロットオプション
%   mat_idx: 材質インデックス (HMS モードのみ)
%   ResultDir: 結果ディレクトリ
%   configurePlotLayout: レイアウト設定関数ハンドル
%   createFigureWithLayout: Figure作成関数ハンドル
%   saveFigureWithNaming: 保存関数ハンドル
%   getMatShapeCount: 材質・形状数取得関数ハンドル
%   plotScatterSingle: 単一散布図プロット関数ハンドル

if nargin < 3
    mat_idx = []; % HMSモードでない場合は空
end

try
    % モードに応じた材質数と形状数を取得
    [matCount, shapeCount] = getMatShapeCount(plotData.targetA, plotOptions.Mode);
    
    % レイアウト設定を取得
    layoutConfig = configurePlotLayout(plotOptions.Mode, matCount, shapeCount);
    
    % Figure とレイアウトを作成
    [fig, tLayout] = createFigureWithLayout(plotOptions.Mode, matCount, shapeCount);

    % モードに応じてプロット
    switch plotOptions.Mode
        case "H"
            plotScatterSingle(plotData, plotOptions, plotOptions.Title);
            
        case {"HM", "HS"}
            sgtitle(tLayout, plotOptions.Title, 'Interpreter', 'none');
            for i = 1:layoutConfig.loopCount
                nexttile;
                titleStr = sprintf('%s', string(layoutConfig.labels(i)));
                plotScatterSingle(plotData, plotOptions, titleStr, i);
            end
            
        case "HMS"
            titleStr = sprintf('%s-%s', plotOptions.Title, string(plotOptions.MatNames(mat_idx)));
            sgtitle(tLayout, titleStr, 'Interpreter', 'none');
            
            for shape = 1:layoutConfig.loopCount
                nexttile;
                titleStr = sprintf('%s', string(plotOptions.ShapeNames(shape)));
                plotScatterSingle(plotData, plotOptions, titleStr, mat_idx, shape);
            end
    end

    % 保存
    saveFigureWithNaming(fig, plotOptions.NameA, plotOptions.NameB, ...
        plotOptions.Property, plotOptions.Mode, mat_idx, 'scatter', ResultDir);

catch ME
    if exist('fig', 'var') && isvalid(fig)
        close(fig);
    end
    rethrow(ME);
end

end
