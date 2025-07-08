function shuffled_array = shuffleArrayDimension(array, shuffle_dim, options)
%shuffleArrayDimension 配列の指定した次元をシャッフルまたはリサンプリングします。
%
% [SYNTAX]
%   shuffled_A = shuffleArrayDimension(A, shuffle_dim)
%   shuffled_A = shuffleArrayDimension(A, shuffle_dim, 'WithReplacement', true)
%
% [INPUTS]
%   A           - 入力配列 (任意の次元数)
%   shuffle_dim - シャッフル対象の次元 (スカラー整数)
%
% [OPTIONS]
%   WithReplacement - (logical) falseの場合、要素の順序を入れ替えます（重複なし）。
%                     trueの場合、重複を許してリサンプリングします。
%                     デフォルトは true です。

%% 1. 引数の定義と検証
arguments
    array {mustBeNumeric}
    shuffle_dim (1,1) double {mustBeInteger, mustBePositive}
    options.WithReplacement (1,1) logical = true
end

%% 2. 配列の情報を取得
array_size = size(array);
num_dims = ndims(array);
if shuffle_dim > num_dims
    error('指定された次元 (shuffle_dim) が配列の次元数を超えています。');
end
dim_size = array_size(shuffle_dim);

%% 3. ★ ランダムなインデックスをN次元で一度に生成 (ベクトル化)
if options.WithReplacement
    % 重複あり: randiで 1～dim_size の整数を配列全体にランダムに配置
    random_indices_nd = randi(dim_size, array_size);
else
    % 重複なし: randで生成した乱数をshuffle_dim方向にソートし、そのインデックスを取得
    [~, random_indices_nd] = sort(rand(array_size), shuffle_dim);
end

%% 4. ★ 配列全体を再配置するためのインデックスを計算
% 各次元のインデックスグリッドを作成するための準備
grid_vectors = arrayfun(@(n) 1:n, array_size, 'UniformOutput', false);

% ndgridで各要素の(i,j,k,...)という位置インデックスを生成
indices_cell = cell(1, num_dims);
[indices_cell{:}] = ndgrid(grid_vectors{:});

% シャッフル対象の次元のインデックスを、先ほど生成したランダムなインデックスに置き換え
indices_cell{shuffle_dim} = random_indices_nd;

% N次元の(i,j,k,...)インデックスを、MATLABが一度に扱える線形インデックスに変換
linear_indices = sub2ind(array_size, indices_cell{:});

%% 5. 線形インデックスを使って一気に配列を並べ替え
shuffled_array = array(linear_indices);

dims = ndims(array);
for d = dims:-1:2
    array = mean(array, d);
end

for d = dims:-1:2
    shuffled_array = mean(shuffled_array, d);
end

end