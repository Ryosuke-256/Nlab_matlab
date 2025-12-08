function rounded_cell = roundCellValues(input_cell, options)
%roundCellNumbers cell配列内の全ての数値を、指定した小数点以下の桁数に丸めます。
%
% [INPUTS]
%   input_cell - (cell) 元となるセル配列。数値と他のデータ型が混在可能。
%
% [OPTIONS] (Name-Value Pairs)
%   "NumDecimals" - (整数) 丸める小数点以下の桁数。デフォルトは 3 です。
%
% [OUTPUTS]
%   rounded_cell - (cell) 数値のみが丸められた新しいセル配列。

%% 1. 引数の検証
arguments
    input_cell cell
    options.NumDecimals (1,1) double {mustBeInteger, mustBeNonnegative} = 3
end

%% 2. 処理
% 小数点以下の桁数に応じた倍率を計算
factor = 10^options.NumDecimals;

% cellfunを使って、各セルに匿名関数を適用
% 'UniformOutput', false は、出力がcell配列になることを指定
rounded_cell = cellfun(@(x) round_if_numeric(x, factor), input_cell, 'UniformOutput', false);

end

% --- 内部で使われるヘルパー関数 ---
function content_out = round_if_numeric(content_in, factor)
    % セルの中身が数値なら丸め、そうでなければそのまま返す
    if isnumeric(content_in)
        content_out = round(content_in * factor) / factor;
    else
        content_out = content_in; % 数値でなければ変更しない
    end
end