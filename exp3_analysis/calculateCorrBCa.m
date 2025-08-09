function bca_ci = calculateCorrBCa(dataA, dataB, num_bootstrap, num_splits)
    arguments
        dataA {mustBeNumeric}
        dataB {mustBeNumeric}
        num_bootstrap (1,1) double = 10000
        num_splits (1,1) double = 1
    end

    % --- 統計量計算のための内部関数を定義 ---
    % この関数が、bootciの反復ごとに呼び出される
    function stat = calculate_bootstrap_stat(d_A, d_B)
        
        trial_dim = ndims(d_A); % 試行次元は常に最後
        
        % 応答リサンプリングをnum_splits回実行
        split_corrs = zeros(num_splits, 1);
        for i = 1:num_splits
            [p1A, ~] = createPatternVectors(d_A, trial_dim);
            [p1B, ~] = createPatternVectors(d_B, trial_dim);
            split_corrs(i) = corr(p1A, p1B);
        end
        % 平均値をこのブートストラップ反復の統計量とする
        stat = mean(split_corrs);
    end

    % --- bootciの実行 ---
    % 被験者次元を特定
    subject_dim = ndims(dataA) - 1;
    num_subjects = size(dataA, subject_dim);
    subject_indices = 1:num_subjects;

    % bootciがインデックスをリサンプリングし、それをstatfunに渡す
    statfun_wrapper = @(idx) calculate_bootstrap_stat( ...
        resampleDimension(dataA, subject_dim, idx), ...
        resampleDimension(dataB, subject_dim, idx) ...
    );

    % bootciでBCa信頼区間を計算
    bca_ci = bootci(num_bootstrap, statfun_wrapper, subject_indices, 'Type', 'bca');

end

%% ========== ヘルパー関数群 ==========

function [vector1, vector2] = createPatternVectors(data, trial_dim)
    % データを受け取り、応答リサンプリングを2回行い、2つのパターンベクトルを生成する
    
    % 1回目の試行リサンプリング
    resampled_data1 = resampleDimension(data, trial_dim);
    % Zスコア化 -> 平均化
    vector1 = mean(zscore(resampled_data1, 0, 1), 2:ndims(resampled_data1));
    
    % 2回目の試行リサンプリング
    resampled_data2 = resampleDimension(data, trial_dim);
    % Zスコア化 -> 平均化
    vector2 = mean(zscore(resampled_data2, 0, 1), 2:ndims(resampled_data2));
end


function resampled_data = resampleDimension(data, dim_to_resample)
    % 配列の指定した次元(dim_to_resample)をリサンプリング（復元抽出）する
    
    data_size = size(data);
    num_dims = ndims(data);
    dim_size = data_size(dim_to_resample);
    
    % 指定次元に対するランダムなインデックスをN次元で一度に生成
    random_indices_nd = randi(dim_size, data_size);
    
    % 各次元のインデックスグリッドを作成
    grid_vectors = arrayfun(@(n) 1:n, data_size, 'UniformOutput', false);
    indices_cell = cell(1, num_dims);
    [indices_cell{:}] = ndgrid(grid_vectors{:});
    
    % シャッフル対象の次元のインデックスを、ランダムなインデックスに置き換え
    indices_cell{dim_to_resample} = random_indices_nd;
    
    % N次元インデックスを線形インデックスに変換し、一気にデータを抽出
    linear_indices = sub2ind(data_size, indices_cell{:});
    resampled_data = data(linear_indices);
end

function extracted_data = extractSlices(data, dim, num_to_extract)
    % 配列の特定の次元から指定した数だけ要素を抽出する関数

    if num_to_extract > size(data, dim)
        error('抽出したい数 (%d) が、指定された次元 (%d) の大きさ (%d) を超えています。', ...
              num_to_extract, dim, size(data, dim));
    end
    total_slices = size(data, dim);

    % 動的なインデックスの作成
    num_dims = ndims(data);
    idx = repmat({':'}, 1, num_dims);

    % 1から次元の大きさまでの整数から、重複なしでランダムにインデックスを抽出
    selected_indices = randperm(total_slices, num_to_extract);

    % 抽出対象の次元のインデックスを、ランダムなインデックスで上書き
    idx{dim} = selected_indices;

    % インデックスを使ってデータを抽出
    extracted_data = data(idx{:});
end