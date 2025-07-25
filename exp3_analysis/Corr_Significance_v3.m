function [ceiling_distAA, ceiling_distAB, p_value, observed_corr, all_sampled_dataA, all_sampled_dataB] = Corr_Significance_v3(dataA, dataB, num_bootstrap, num_splits)
    %{
    ○入力
    ・dataA:[照明条件,~~~,被験者,試行回数]のデータ
    ・dataB:dataAと同じ形状
    ・num_bootstrap:bootstrapの回数 (被験者リサンプリングの回数)
    ・num_splits:応答リサンプリングの回数
    ○出力
    ・ceiling_distAA:dataAの内部相関の記録
    ・ceiling_distAB:dataAとdataBの相関係数の記録
    ・p_value:ノイズ天井法のp値
    ・observed:dataAとdataBの生データの相関係数
    ・all_sampled_dataA:dataAのリサンプリングで得られた値の記録
    ・all_sampled_dataB:dataBのリサンプリングで得られた値の記録
    %}
    
    %% 1. 引数と設定
    arguments
        dataA {mustBeNumeric}
        dataB {mustBeNumeric}
        num_bootstrap (1,1) double = 10000
        num_splits (1,1) double = 1
    end
    % rng('shuffle'); 

    %% 2. ★ 次元の自動認識
    num_dims_A = ndims(dataA);
    subject_dim_A = num_dims_A - 1;
    trial_dim_A = num_dims_A;

    data_size_A = size(dataA);
    num_subjects_A = data_size_A(subject_dim_A);
    
    % dataBも同様に次元を認識
    num_dims_B = ndims(dataB);
    subject_dim_B = num_dims_B - 1;
    
    data_size_B = size(dataB);
    num_subjects_B = data_size_B(subject_dim_B);
    
    %% 3. 元データの相関係数（観測値）を計算
    % データをZスコア化し、全次元（照明条件以外）で平均をとってパターンベクトルを生成
    pattern_vec_A = mean(zscore(dataA, 0, 1), 2:num_dims_A);
    pattern_vec_B = mean(zscore(dataB, 0, 1), 2:num_dims_B);
    observed_corr = corr(pattern_vec_A, pattern_vec_B);

    %% 4. 結果保存用の変数を初期化
    ceiling_distAA = zeros(num_bootstrap, 1);
    ceiling_distAB = zeros(num_bootstrap, 1);
    all_sampled_dataA = zeros(data_size_A(1), num_bootstrap, num_splits, 2);
    all_sampled_dataB = zeros(data_size_B(1), num_bootstrap, num_splits, 2);

    %% 5. Bootstrap loop
    for i = 1:num_bootstrap
        % --- 被験者リサンプリング ---
        resampled_by_subj_A = resampleDimension(dataA, subject_dim_A);
        resampled_by_subj_B = resampleDimension(dataB, subject_dim_B);
        
        num_slice = 5;
        resampled_by_subj_A2 = extractSlices(resampled_by_subj_A,subject_dim_A,num_slice);
        resampled_by_subj_B2 = extractSlices(resampled_by_subj_B,subject_dim_B,num_slice);
        
        split_half_corrs_AA = zeros(num_splits, 1);
        split_half_corrs_AB = zeros(num_splits, 1);

        % --- 応答（試行）リサンプリング ---
        for j = 1:num_splits
            % 試行リサンプリングとパターンベクトル生成をヘルパー関数で実行
            [pattern1_A, pattern2_A] = createPatternVectors(resampled_by_subj_A2, trial_dim_A);
            [pattern1_B, pattern2_B] = createPatternVectors(resampled_by_subj_B2, trial_dim_A);
            
            split_half_corrs_AA(j) = corr(pattern1_A, pattern2_A);
            split_half_corrs_AB(j) = corr(pattern1_A, pattern1_B);

            % 個別データ保存
            all_sampled_dataA(:, i, j, 1) = pattern1_A;
            all_sampled_dataA(:, i, j, 2) = pattern2_A;
            all_sampled_dataB(:, i, j, 1) = pattern1_B;
            all_sampled_dataB(:, i, j, 2) = pattern2_B;
        end  
        
        ceiling_distAA(i) = mean(split_half_corrs_AA);
        ceiling_distAB(i) = mean(split_half_corrs_AB);
    end

    %% 6. p値の計算と結果表示
    correlationDiffs = ceiling_distAA - observed_corr;
    p_value = sum(correlationDiffs <= 0) / num_bootstrap;
    ci_95_AA = quantile(ceiling_distAA, [0.05, 1.0]);
    ci_95_AB = quantile(ceiling_distAB, [0.05, 1.0]);
    
    fprintf('\n観測された相関 corr(A, B): %.4f\n', observed_corr);
    fprintf('データAAのCI95: %.3f, %.3f\n', ci_95_AA(1),ci_95_AA(2));
    fprintf('データABのCI95: %.3f, %.3f\n', ci_95_AB(1),ci_95_AB(2));
    fprintf('p値: %.3f\n', p_value);
    if p_value > 0.05
        fprintf('結論: corr(A,B)はノイズ天井の範囲内です\n');
    else
        fprintf('結論: corr(A,B)はノイズ天井よりも有意に低いです\n');
    end
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