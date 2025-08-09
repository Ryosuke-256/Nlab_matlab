function [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ci_AA, ci_AB] = Corr_Significance_v4(dataA, dataB, num_bootstrap, num_splits)
    %{
    ○出力 (BCaをパーセンタイルCIに変更)
    ・ci_AA: ceiling_distAAのパーセンタイル法による95%信頼区間
    ・ci_AB: ceiling_distABのパーセンタイル法による95%信頼区間
    %}

    %% 1. 引数と設定
    arguments
        dataA {mustBeNumeric}
        dataB {mustBeNumeric}
        num_bootstrap (1,1) double = 1000
        num_splits (1,1) double = 100
    end

    %% 2. 次元の自動認識
    num_dims = ndims(dataA);
    subject_dim = num_dims - 1;
    trial_dim = num_dims;
    
    num_subjects_A = size(dataA, subject_dim);
    num_subjects_B = size(dataB, subject_dim);
    
    %% 3. 元データの相関係数（観測値）を計算
    pattern_vec_A = mean(zscore(dataA, 0, 1), 2:num_dims);
    pattern_vec_B = mean(zscore(dataB, 0, 1), 2:num_dims);
    observed_corr = corr(pattern_vec_A, pattern_vec_B);

    %% 4. 結果保存用の変数を初期化
    ceiling_distAA = zeros(num_bootstrap, 1);
    ceiling_distAB = zeros(num_bootstrap, 1);

    %% 5. ★ 手動のブートストラップループに戻す
    fprintf('ブートストラップ計算を実行中 (反復回数: %d)...\n', num_bootstrap);
    for i = 1:num_bootstrap
        % --- ★ 被験者リサンプリングをAとBで個別に実行 ---
        indices_A = randi(num_subjects_A, 1, num_subjects_A);
        indices_B = randi(num_subjects_B, 1, num_subjects_B);
        
        resampled_by_subj_A = resampleDimension(dataA, subject_dim, indices_A);
        resampled_by_subj_B = resampleDimension(dataB, subject_dim, indices_B);
        
        split_half_corrs_AA = zeros(num_splits, 1);
        split_half_corrs_AB = zeros(num_splits, 1);

        % --- 応答（試行）リサンプリング ---
        for j = 1:num_splits
            [p1A, p2A] = createPatternVectors(resampled_by_subj_A, trial_dim);
            [p1B, ~]   = createPatternVectors(resampled_by_subj_B, trial_dim);
            
            split_half_corrs_AA(j) = corr(p1A, p2A);
            split_half_corrs_AB(j) = corr(p1A, p1B);
        end
        
        ceiling_distAA(i) = mean(split_half_corrs_AA);
        ceiling_distAB(i) = mean(split_half_corrs_AB);
    end

    %% 6. p値と信頼区間の計算
    correlationDiffs = ceiling_distAA - observed_corr;
    p_value = sum(correlationDiffs <= 0) / num_bootstrap;
    
    % パーセンタイル法で95%信頼区間を計算
    ci_AA = quantile(ceiling_distAA, [0.025, 0.975]);
    ci_AB = quantile(ceiling_distAB, [0.025, 0.975]);
    
    fprintf('\n観測された相関 corr(A, B): %.4f\n', observed_corr);
    fprintf('Noise Ceiling (AA) の95%%信頼区間: [%.4f, %.4f]\n', ci_AA(1), ci_AA(2));
    fprintf('相関 (AB) の95%%信頼区間:         [%.4f, %.4f]\n', ci_AB(1), ci_AB(2));
    fprintf('p値 (観測相関がNoise Ceiling以下である確率): %.4f\n', p_value);
    
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


function resampled_data = resampleDimension(data, dim_to_resample, indices)
    % 配列の指定した次元をリサンプリングします。
    % 3番目の引数 'indices' があればそれらを使い、なければランダムに生成します。
    
    %% 1. 引数の検証と準備
    arguments
        data {mustBeNumeric}
        dim_to_resample (1,1) double {mustBeInteger, mustBePositive}
        indices (1,:) double = [] % ★ 3番目の引数を任意で受け取る
    end
    
    data_size = size(data);
    num_dims = ndims(data);
    dim_size = data_size(dim_to_resample);
    
    %% 2. ★ リサンプリング用インデックスの決定
    if isempty(indices)
        % indicesが指定されていない場合 -> 復元抽出（重複あり）のインデックスをランダムに生成
        random_indices_nd = randi(dim_size, data_size);
    else
        % indicesが指定されている場合 -> それを使ってインデックスマップを作成
        % bootstrp/bootciが渡すのはリサンプリングする次元のインデックスベクトル
        % これを元のデータの次元数に合わせて拡張する必要がある
        
        % 拡張するための準備
        idx_size = ones(1, num_dims);
        idx_size(dim_to_resample) = numel(indices);
        reshaped_indices = reshape(indices, idx_size);
        
        rep_size = data_size;
        rep_size(dim_to_resample) = 1;
        
        % インデックスをブロードキャスト/拡張して、元のデータと同じサイズのマップを作成
        random_indices_nd = repmat(reshaped_indices, rep_size);
    end
    
    %% 3. データの抽出（以降は変更なし）
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