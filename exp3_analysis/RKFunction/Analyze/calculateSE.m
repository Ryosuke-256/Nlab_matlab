function SE_array = calculateSE(data, condition_dims, sample_dims)
%calculateSEbyCondition N次元配列の指定した条件次元ごとに標準誤差を計算します。
%
% [INPUTS]
%   data           - (N-D行列) 元となるデータ配列。
%   condition_dims - (ベクトル) 条件として維持したい次元のリスト (例: [2, 3])。
%   sample_dims    - (ベクトル) サンプルとして平均・集計したい次元のリスト (例: [1, 4, 5])。
%
% [OUTPUTS]
%   SE_array       - (配列) 計算された標準誤差を格納した配列。
%                    次元のサイズは、元のデータのcondition_dimsのサイズと一致します。

%% 1. 引数の検証
arguments
    data {mustBeNumeric}
    condition_dims (1,:) {mustBeInteger, mustBePositive}
    sample_dims (1,:) {mustBeInteger, mustBePositive}
end

% 入力された次元が、重複なく全ての次元をカバーしているか検証
num_dims = ndims(data);
all_input_dims = sort(union(condition_dims, sample_dims));
if ~isequal(all_input_dims, 1:num_dims)
    error('condition_dimsとsample_dimsは、重複なく1から%dまでの全ての次元を含んでいる必要があります。', num_dims);
end

%% 2. ★ ステップ1: permuteによる次元の再配置
% [条件次元..., サンプル次元...] という順序になるように、データを並べ替える
permute_order = [condition_dims, sample_dims];
permuted_data = permute(data, permute_order);

%% 3. ★ ステップ2: reshapeによる2次元化
% 条件次元を全て1つの次元（行）に、サンプル次元を全て1つの次元（列）にまとめる
num_conditions = prod(size(data, condition_dims));
num_samples = prod(size(data, sample_dims));
reshaped_data = reshape(permuted_data, num_conditions, num_samples);

%% 4. ★ ステップ3: 各行（条件ごと）の標準誤差を計算
% std(X, flag, dim) を使い、2次元目（列方向）に沿って標準偏差を計算
s = std(reshaped_data, 0, 2);
n = num_samples;
se_vector = s / sqrt(n);

%% 5. ★ ステップ4: reshapeによる最終的な整形
% 計算されたSEのベクトルを、元の条件次元の形に戻す
% まず、元の配列と同じ次元数で、全ての次元サイズが1の配列を作成
output_size = ones(1, num_dims); 
% 次に、条件次元の位置に、実際の次元サイズを挿入
output_size(condition_dims) = size(data, condition_dims);
% 計算されたSEのベクトルを、元の条件次元の形を含むN次元配列に戻す
SE_array = reshape(se_vector, output_size);
% 結果を見やすくするため、サイズが1の次元を削除する場合は以下を有効化
SE_array = squeeze(SE_array);


%{
condition_sizes = size(data, condition_dims);
SE_array = reshape(se_vector, condition_sizes);
%}

end