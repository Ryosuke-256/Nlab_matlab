function resampled_array = resampleData(array, resample_dim)
% 構文:
%   resampled_array = resampleData(array, resample_dim)
%
% 入力:
%   array - 入力データ配列 (行列、3次元配列など)
%   resample_dim - リサンプリングを行う次元。分析単位に対応する次元を指定
%                  (例: (条件 x 被験者 x 試行) 配列なら被験者次元の「2」)
%
% 出力:
%   resampled_array - 入力と同じサイズの新しい配列。resample_dimに沿って
%                     復元抽出されて生成される。
%
% 使用例:
%   % 2条件 x 5被験者 x 10試行 のダミーデータを作成
%   original_data = randn(2, 5, 10);
%   % 被験者(2次元目)をリサンプリングする
%   resampled_subjects_data = resampleData(original_data, 2);
%   % サイズが変わらないことを確認
%   disp(size(resampled_subjects_data)); % -> [2 5 10] と表示される

% 1. リサンプリング対象の次元にある単位の数を取得
num_units = size(array, resample_dim);

% 2. 単位のインデックスを復元抽出し、ブートストラップインデックスを生成
boot_indices = randi(num_units, 1, num_units);

% 3. 動的インデックス用のセル配列を作成
total_dims = ndims(array);
idx = repmat({':'}, 1, total_dims);

% 4. リサンプリングしたい次元をブートストラップインデックスに置き換える
idx{resample_dim} = boot_indices;

% 5. 作成したインデックスで元の配列を抽出し、新しい配列を生成
resampled_array = array(idx{:});

dims = ndims(array);
for d = dims:-1:2
    array = mean(array, d);
end

for d = dims:-1:2
    resampled_array = mean(resampled_array, d);
end

end