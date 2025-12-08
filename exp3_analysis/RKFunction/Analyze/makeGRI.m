function data_GRI = makeGRI(data, zscore_dim, dims_to_average)
%avgThenZscore N次元配列を指定次元で平均化し、その後Zスコア化します。
%
% [INPUTS]
%   data            - (N-D行列) 元となるデータ配列。
%   zscore_dim      - (整数)   Zスコア化を実行する次元。
%   dims_to_average - (ベクトル) 事前に平均化を行う次元のリスト。
%
% [OUTPUTS]
%   zscored_data    - (N-D行列) 処理後のデータ。

%% 1. 引数の検証
arguments
    data {mustBeNumeric}
    zscore_dim (1,1) double {mustBeInteger, mustBePositive}
    dims_to_average (1,:) {mustBeInteger, mustBePositive}
end

% zscore_dimとdims_to_averageに重複がないか検証
if ismember(zscore_dim, dims_to_average)
    error('Zスコア化する次元と、平均化する次元が重複しています。');
end

%% 2. 指定された次元で平均化
averaged_data = mean(data, dims_to_average);

%% 3. 指定された次元でZスコア化
data_GRI = zscore(averaged_data, 0, zscore_dim);

end