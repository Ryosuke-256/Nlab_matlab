function plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr, matIdx, shapeIdx)
% plotHistgramSingle - 単一のヒストグラムをプロット
%
% 入力:
%   plotDataA, plotDataB: プロットデータ（target, error, Name フィールドを含む構造体）
%   plotOptions: プロットオプション（Property, hdr, Amp フィールドを含む構造体）
%   titleStr: タイトル文字列
%   matIdx: 材質インデックス (オプション)
%   shapeIdx: 形状インデックス (オプション)

% データを準備
if nargin < 5
    % H モード
    HistgramDataA = plotDataA;
    HistgramDataB = plotDataB;
elseif nargin < 6
    % HM または HS モード
    HistgramDataA.target = plotDataA.target(:, matIdx);
    HistgramDataA.error = plotDataA.error(:, matIdx);
    HistgramDataA.Name = plotDataA.Name;
    
    HistgramDataB.target = plotDataB.target(:, matIdx);
    HistgramDataB.error = plotDataB.error(:, matIdx);
    HistgramDataB.Name = plotDataB.Name;
else
    % HMS モード
    HistgramDataA.target = plotDataA.target(:, matIdx, shapeIdx);
    HistgramDataA.error = plotDataA.error(:, matIdx, shapeIdx);
    HistgramDataA.Name = plotDataA.Name;
    
    HistgramDataB.target = plotDataB.target(:, matIdx, shapeIdx);
    HistgramDataB.error = plotDataB.error(:, matIdx, shapeIdx);
    HistgramDataB.Name = plotDataB.Name;
end

% ヒストグラムをプロット
PlotHistgram_ver1(HistgramDataA, HistgramDataB, ...
    "XLabel", sprintf('Illumination map'), ...
    "YLabel", sprintf('%s', plotOptions.Property), ...
    "Title", titleStr, "HDRNo", plotOptions.hdr, "Amp", plotOptions.Amp);

end
