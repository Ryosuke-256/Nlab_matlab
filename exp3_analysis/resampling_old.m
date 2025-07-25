function [zscored_vector1, zscored_vector2] = resampleAndSplit(data_3d)
    %resampleAndSplit 3次元データをリサンプリングし、2つのベクトルに分割・平均・Zスコア化します。
    %
    % [INPUTS]
    %   data_3d - (3D行列) 元となる3次元データ (d1 x d2 x d3)
    %
    % [OUTPUTS]
    %   zscored_vector1 - (列ベクトル) 処理後の1つ目のZスコア化されたベクトル (d1 x 1)
    %   zscored_vector2 - (列ベクトル) 処理後の2つ目のZスコア化されたベクトル (d1 x 1)

    arguments
        data_3d (:,:,:) {mustBeNumeric, mustBeReal}
    end

    % 2. データの2次元化
    data_2d = reshape(data_3d, size(data_3d, 1), []);

    % 3. 各行を個別にリサンプリング
    [num_rows, num_cols] = size(data_2d);

    % 各行で使うランダムな列インデックスを行列として一度に生成
    random_col_indices = randi(num_cols, num_rows, num_cols);
    % 抽出元の行インデックスを行列として作成
    row_indices_grid = repmat((1:num_rows)', 1, num_cols);
    % (行, 列)の座標ペアを線形インデックスに変換
    linear_indices = sub2ind(size(data_2d), row_indices_grid, random_col_indices);
    % 線形インデックスを使って一気にデータを抽出
    resampled_data = data_2d(linear_indices);

    % 4. データの分割と平均化
    num_cols_half = floor(size(resampled_data, 2) / 2);

    half1 = resampled_data(:, 1 : num_cols_half);
    half2 = resampled_data(:, num_cols_half + 1 : end);

    % 各行の平均値を計算して、パターンベクトルを生成します。
    vector1 = mean(half1, 2);
    vector2 = mean(half2, 2);

    % 5. Zスコア化
    zscored_vector1 = zscore(vector1);
    zscored_vector2 = zscore(vector2);
end