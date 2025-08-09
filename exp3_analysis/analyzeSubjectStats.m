function analyzeSubjectStats(data_5d, cond1_level, cond2_level)
%analyzeSubjectStats 5次元データから指定条件のデータを抽出し、被験者ごとの統計量を表示します。
%
% [INPUTS]
%   data_5d      - (5D行列) 元データ (d1, d2, d3, 被験者, 試行)
%   cond1_level  - (整数)   抽出したい条件1（2次元目）のインデックス
%   cond2_level  - (整数)   抽出したい条件2（3次元目）のインデックス

%% 1. 引数の検証
arguments
    data_5d (:,:,:,:,:) {mustBeNumeric}
    cond1_level (1,1) double {mustBeInteger, mustBePositive}
    cond2_level (1,1) double {mustBeInteger, mustBePositive}
end

% 指定されたインデックスがデータのサイズ内か検証
if cond1_level > size(data_5d, 2) || cond2_level > size(data_5d, 3)
    error('指定された条件のインデックスが、データの次元サイズを超えています。');
end

%% 2. 指定した条件のデータを抽出
% 2次元目と3次元目を指定したレベルでスライス（切り出し）
selected_data = data_5d(:, cond1_level, cond2_level, :, :);

% 不要な次元（サイズが1になった2,3次元目）を削除して、3D配列に整形
% -> (d1, 被験者, 試行) の形になる
selected_data_3d = squeeze(selected_data);

%% 3. 試行回数次元で平均化
% 3次元目になった試行回数次元に沿って平均をとる
% -> (d1, 被験者) の2D行列になる
avg_over_trials = mean(selected_data_3d, 3);

%% 4. 被験者ごとに統計量を計算・表示
num_subjects = size(avg_over_trials, 2);

fprintf('--- 条件(cond1=%d, cond2=%d)における被験者ごとの統計量 ---\n', cond1_level, cond2_level);

for i = 1:num_subjects
    % i番目の被験者のデータ（列ベクトル）を抽出
    subject_data_vector = avg_over_trials(:, i);
    
    % 1次元目に沿って平均値と標準偏差を計算
    subject_mean = mean(subject_data_vector);
    subject_std  = std(subject_data_vector);
    
    % 結果を表示
    fprintf('被験者 %2d: 平均 = %8.4f, 標準偏差 = %8.4f\n', i, subject_mean, subject_std);
end

end