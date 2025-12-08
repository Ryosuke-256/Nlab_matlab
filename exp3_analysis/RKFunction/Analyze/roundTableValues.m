function rounded_table = roundTableValues(input_table, options)
%roundTableValues table内の全ての数値列を指定した小数点以下の桁数に丸めます。
%
% [INPUTS]
%   input_table - (table) 元となるテーブル。
%
% [OPTIONS] (Name-Value Pairs)
%   "NumDecimals" - (整数) 丸める小数点以下の桁数。デフォルトは 2 です。
%
% [OUTPUTS]
%   rounded_table - (table) 数値が丸められた新しいテーブル。

%% 1. 引数の検証
arguments
    input_table table
    options.NumDecimals (1,1) double {mustBeInteger, mustBeNonnegative} = 2
end

%% 2. 処理
% 出力用のテーブルとして、入力テーブルをコピー
rounded_table = input_table;

% テーブルの全ての変数名（列名）を取得
var_names = rounded_table.Properties.VariableNames;

% 小数点以下の桁数に応じた倍率を計算
factor = 10^options.NumDecimals;

% 各列に対してループ処理
for i = 1:numel(var_names)
    current_var_name = var_names{i};
    column_data = rounded_table.(current_var_name);
    
    % ★列が数値データの場合のみ、丸め処理を実行
    if isnumeric(column_data)
        rounded_table.(current_var_name) = round(column_data * factor) / factor;
    end
end

end