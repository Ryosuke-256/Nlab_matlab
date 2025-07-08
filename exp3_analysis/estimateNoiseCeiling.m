function ceiling_dist = estimateNoiseCeiling(data3D, num_bootstrap, num_splits)
% 入力:
%   data3D         - (目的条件, 被験者, 試行) の3次元データ
%   num_bootstrap  - 被験者リサンプリングの回数 (例: 10000)
%   num_splits     - 応答リサンプリング(Split-half)の繰り返し回数 (例: 100)
%
% 出力:
%   ceiling_dist   - 推定されたノイズ天井(内部相関)の分布 (10000 x 1)

    [num_cond, num_subjects, num_trials] = size(data3D);
    ceiling_dist = zeros(num_bootstrap, 1);
    
    fprintf('ノイズ天井の推定を開始 (被験者リサンプリング: %d回)...\n', num_bootstrap);
    
    % --- Outer Loop: 被験者リサンプリング ---
    for i = 1:num_bootstrap
        % 被験者のインデックスを復元抽出し、仮想的な被験者セットを作成
        boot_subj_indices = randi(num_subjects, 1, num_subjects);
        resampled_data = data3D(:, boot_subj_indices, :);
        
        split_half_corrs = zeros(num_splits, 1);
        
        % --- Inner Loop: 応答リサンプリング (Split-Half法) ---
        for j = 1:num_splits
            [pattern1,pattern2] = splitData(resampled_data);
            
            % 2つのパターン間の相関を計算
            split_half_corrs(j) = corr(pattern1, pattern2);
        end
        
        % 内部相関の安定した推定値として、平均値を用いる
        ceiling_dist(i) = mean(split_half_corrs);
    end
    fprintf('ノイズ天井の推定が完了しました。\n');
end

function [pattern1,pattern2] = splitData(data3D)
    [~, ~, num_trials] = size(data3D);
    permuted_trials = randperm(num_trials);
    half1_trials = permuted_trials(1:floor(num_trials/2));
    half2_trials = permuted_trials(floor(num_trials/2)+1:end);
    
    % 各半分の試行を平均化し、2つのパターンベクトルを生成
    pattern1 = mean(mean(data3D(:, :, half1_trials), 3), 2);
    pattern2 = mean(mean(data3D(:, :, half2_trials), 3), 2);
end