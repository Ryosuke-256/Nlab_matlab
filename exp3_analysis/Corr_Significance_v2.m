function [ceiling_distAA,ceiling_distAB,p_value,observed_corr,all_sampled_dataA,all_sampled_dataB] = Corr_Significance_v2(dataA,dataB,num_bootstrap, num_splits)
rng('shuffle')

% 結果保存用
correlationDiffs = zeros(num_bootstrap, 1);
ceiling_distAA = zeros(num_bootstrap,1);
ceiling_distAB = zeros(num_bootstrap,1);

[num_cond_A, num_subjects_A, num_trials_A] = size(dataA);
[num_cond_B, num_subjects_B, num_trials_B] = size(dataB);

Zs_meaned_dataA = zscore(MeanArray(dataA,1));
Zs_meaned_dataB = zscore(MeanArray(dataB,1));
observed_corr = corr(Zs_meaned_dataA,Zs_meaned_dataB);

all_sampled_dataA = zeros(size(dataA,1),num_bootstrap,num_splits,2);
all_sampled_dataB = zeros(size(dataB,1),num_bootstrap,num_splits,2);

% === ステップ2: リサンプリング ===
% ---  被験者リサンプリング ---
for i = 1:num_bootstrap
    % === dataA ==
    boot_subj_indices_A = randi(num_subjects_A, 1, num_subjects_A);
    resampled_data_A = dataA(:, boot_subj_indices_A, :);
    split_half_corrs_AA = zeros(num_splits, 1);
    
    % === dataB ==
    boot_subj_indices_B = randi(num_subjects_B, 1, num_subjects_B);
    resampled_data_B = dataB(:, boot_subj_indices_B, :);
    split_half_corrs_AB = zeros(num_splits, 1);
    
    % ---応答リサンプリング (Split-Half法)  ---
    for j = 1:num_splits
        [pattern1_A,pattern2_A] = SplitData(resampled_data_A);
        [pattern1_B,pattern2_B] = SplitData(resampled_data_B);
        
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


% === ステップ3: p値の算出と結論 ===
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

function [pattern1,pattern2] = SplitData(data3D)
    [~, ~, num_trials] = size(data3D);
    permuted_trials = randperm(num_trials);
    half1_trials = permuted_trials(1:floor(num_trials/2));
    half2_trials = permuted_trials(floor(num_trials/2)+1:end);
    
    % 各半分の試行を平均化し、2つのパターンベクトルを生成
    pattern1 = zscore(mean(mean(data3D(:, :, half1_trials), 3), 2));
    pattern2 = zscore(mean(mean(data3D(:, :, half2_trials), 3), 2));
end

function [reducedData] = MeanArray(array,limit)
    dims = ndims(array);
    reducedData = array;

    % limitまで平均化
    for d = dims:-1:limit+1
        reducedData = mean(reducedData, d);
    end
end