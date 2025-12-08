function [ceiling_distAA,ceiling_distAB,p_value,observed_corr,all_sampled_dataA,all_sampled_dataB] = Corr_Significance_v2(dataA,dataB,num_bootstrap, num_splits)
rng('shuffle')
%{
○入力
・dataA:[照明条件,被験者,試行回数]のデータ
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

% === ステップ1: initialize ===
% 結果保存用データの宣言
correlationDiffs = zeros(num_bootstrap, 1);
ceiling_distAA = zeros(num_bootstrap,1);
ceiling_distAB = zeros(num_bootstrap,1);
all_sampled_dataA = zeros(size(dataA,1),num_bootstrap,num_splits,2);
all_sampled_dataB = zeros(size(dataB,1),num_bootstrap,num_splits,2);

[num_cond_A, num_subjects_A, num_trials_A] = size(dataA);
[num_cond_B, num_subjects_B, num_trials_B] = size(dataB);

% 元データの相関係数の計算
Zs_meaned_dataA = zscore(MeanArray(dataA,1));
Zsed_data_A = zscore_array(dataA);
Meaned_Zs_dataA = mean(Zsed_data_A,[2,3]);

Zs_meaned_dataB = zscore(MeanArray(dataB,1));
Zsed_data_B = zscore_array(dataB);
Meaned_Zs_dataB = mean(Zsed_data_B,[2,3]);

observed_corr = corr(Meaned_Zs_dataA,Meaned_Zs_dataB);

% === ステップ2: リサンプリング ===
for i = 1:num_bootstrap
    % ---  被験者リサンプリング ---
    % dataA
    boot_subj_indices_A = randi(num_subjects_A, 1, num_subjects_A);
    resampled_data_A = dataA(:, boot_subj_indices_A, :);
    split_half_corrs_AA = zeros(num_splits, 1);
        
    % dataB 
    boot_subj_indices_B = randi(num_subjects_B, 1, num_subjects_B);
    resampled_data_B = dataB(:, boot_subj_indices_B, :);
    split_half_corrs_AB = zeros(num_splits, 1);
    
    % ---応答リサンプリング ---
    for j = 1:num_splits
        [pattern1_A,pattern2_A] = resampleAndSplit_2(resampled_data_A);
        [pattern1_B,pattern2_B] = resampleAndSplit_2(resampled_data_B);
        
        split_half_corrs_AA(j) = corr(pattern1_A, pattern2_A);
        split_half_corrs_AB(j) = corr(pattern1_A, pattern1_B);
        
        %個別データ保存
        all_sampled_dataA(:,i,j,1)= pattern1_A;
        all_sampled_dataA(:,i,j,2)= pattern2_A;
        all_sampled_dataB(:,i,j,1)= pattern1_B;
        all_sampled_dataB(:,i,j,2)= pattern2_B;
        
    end   
    ceiling_distAA(i) = mean(split_half_corrs_AA);
    ceiling_distAB(i) = mean(split_half_corrs_AB);
    
    % --- 相関係数の差 ---
    %correlationDiffs(i) = ceiling_distAA(i) - ceiling_distAB(i);
    correlationDiffs(i) = ceiling_distAA(i) - observed_corr;
end


% === ステップ3: p値と95%CIの算出 ===
p_value = sum(correlationDiffs <= 0) / length(ceiling_distAA);
ci_95_AA = quantile(ceiling_distAA, [0.05, 1.0]);
ci_95_AB = quantile(ceiling_distAB, [0.05, 1.0]);

% === ステップ4: 結果の表示と可視化 ===
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

%% ヘルパー関数
function [vector1, vector2] = resampleAndSplit_1(data_3d)
    % リサンプリングのハンドリング関数

    % 1. 引数の検証
    arguments
        data_3d (:,:,:) {mustBeNumeric, mustBeReal}
    end

    % 2. 最初にデータを2次元目で半分に分割
    [d1, d2, d3] = size(data_3d);
    
    num_d2_half = floor(d2 * 0.5);

    half1_orig = data_3d(:, 1 : d2-num_d2_half, :);
    half2_orig = data_3d(:, num_d2_half + 1 : end, :);

    % 3. 分割した各データを個別にリサンプリング
    resampled_half1 = resample3rdDim(half1_orig);
    vector1 = mean(resampled_half1, [2,3]);
    
    resampled_half2 = resample3rdDim(half2_orig);
    vector2 = mean(resampled_half2, [2,3]);
end

function [vector1, vector2] = resampleAndSplit_2(data_3d)
    %リサンプリングのハンドリング関数

    % 1. 引数の検証
    arguments
        data_3d (:,:,:) {mustBeNumeric, mustBeReal}
    end
    
    % 2. 1回目のリサンプリングとパターンベクトルの生成
    resampled_data1 = resample3rdDim(data_3d);
    Zs_resampled_data1 = zscore_array(resampled_data1);
    vector1 = mean(Zs_resampled_data1, [2, 3]);
    
    % 3.2回目のリサンプリングとパターンベクトルの生成
    resampled_data2 = resample3rdDim(data_3d);
    Zs_resampled_data2 = zscore_array(resampled_data2);
    vector2 = mean(Zs_resampled_data2, [2, 3]);
end


function resampled_data = resample3rdDim(input_3d_data)
    % 3次元配列の3次元目を、各(d1,d2)ファイバーで個別にリサンプリングする関数
    
    [d1, d2, d3] = size(input_3d_data);

    % 各(d1,d2)ファイバーに対する、重複ありのランダムなインデックス(1-d3)を一度に生成
    random_indices_3d = randi(d3, d1, d2, d3);

    % 1, 2次元目のインデックスを作成し、3次元に拡張
    [J, I] = meshgrid(1:d2, 1:d1);
    I = repmat(I, [1, 1, d3]);
    J = repmat(J, [1, 1, d3]);

    % (行, 列, 深さ)の3Dインデックスを線形インデックスに変換
    linear_indices = sub2ind(size(input_3d_data), I, J, random_indices_3d);

    % 線形インデックスを使って一気にデータを抽出
    resampled_data = input_3d_data(linear_indices);
end

function zscore_data = zscore_array(data)
    % 3次元配列をzscore化(GRI化)する関数
    
    zscore_data = zeros(size(data));
    for participant = 1:size(data,2)
        for trial = 1:size(data,3)
            zscore_data(:,participant,trial) = zscore(data(:,participant,trial));
        end
    end
end

function [reducedData] = MeanArray(array,limit)
    % 配列を平均する関数
    
    dims = ndims(array);
    reducedData = array;

    % limitまで平均
    for d = dims:-1:limit+1
        reducedData = mean(reducedData, d);
    end
end