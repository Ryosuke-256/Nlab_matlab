function [all_sampled_dataA] = Bootstrap_distribution(dataA,num_bootstrap, num_splits)
rng('shuffle')

all_sampled_dataA = zeros(size(dataA,1),num_bootstrap,num_splits,2);

[num_cond_A, num_subjects_A, num_trials_A] = size(dataA);

% === ステップ2: リサンプリング ===
% ---  被験者リサンプリング ---
for i = 1:num_bootstrap
    % === dataA ==
    boot_subj_indices_A = randi(num_subjects_A, 1, num_subjects_A);
    resampled_data_A = dataA(:, boot_subj_indices_A, :);
    split_half_corrs_AA = zeros(num_splits, 1);
    
    % ---応答リサンプリング (Split-Half法)  ---
    for j = 1:num_splits
        [pattern1_A,pattern2_A] = SplitData(resampled_data_A);
        
        split_half_corrs_AA(j) = corr(pattern1_A, pattern2_A);
        
        all_sampled_dataA(:,i,j,1)= pattern1_A;
        all_sampled_dataA(:,i,j,2)= pattern2_A;
    end
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
