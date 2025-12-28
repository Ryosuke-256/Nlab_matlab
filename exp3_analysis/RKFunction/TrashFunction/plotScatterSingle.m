function plotScatterSingle(plotData, plotOptions, titleStr, matIdx, shapeIdx)
% plotScatterSingle - 単一の散布図をプロット
%
% 入力:
%   plotData: プロットデータ（targetA, targetB, hdr フィールドを含む構造体）
%   plotOptions: プロットオプション（NameA, NameB, Property, Residual, Amp フィールドを含む構造体）
%   titleStr: タイトル文字列
%   matIdx: 材質インデックス (オプション)
%   shapeIdx: 形状インデックス (オプション)

% データを取得
if nargin < 4
    % H モード
    dataA = plotData.targetA(:);
    dataB = plotData.targetB(:);
elseif nargin < 5
    % HM または HS モード
    dataA = plotData.targetA(:, matIdx);
    dataB = plotData.targetB(:, matIdx);
else
    % HMS モード
    dataA = plotData.targetA(:, matIdx, shapeIdx);
    dataB = plotData.targetB(:, matIdx, shapeIdx);
end

% 散布図をプロット
PlotScatter_ver2(dataA, dataB, ...
    "XLabel", sprintf('%s-%s', plotOptions.NameA, plotOptions.Property), ...
    "YLabel", sprintf('%s-%s', plotOptions.NameB, plotOptions.Property), ...
    "Mode", plotOptions.Residual, "Title", titleStr, ...
    "HDRNo", plotData.hdr, "Amp", plotOptions.Amp, "FitType", "linear");

end
