function [observed_corr, p_value, null_dist] = testCorrelationPermutation(patternA, patternB, num_permutations)
% testCorrelationPermutation: 2つのパターン間の相関が偶然以上か検定する
%
% 入力:
%   patternA, patternB - 同じ長さの列ベクトル
%   num_permutations   - 並べ替えの試行回数 (例: 10000)
%
% 出力:
%   observed_corr      - 観測されたデータでの相関係数
%   p_value            - p値 (片側検定: 相関 > 偶然)
%   null_dist          - 生成された帰無分布

% 1. 観測された相関係数を計算
observed_corr = corr(patternA, patternB);
fprintf('観測された相関: %.4f\n', observed_corr);

% --- 2. 帰無分布を生成 ---
null_dist = zeros(num_permutations, 1);
num_elements = length(patternA);

fprintf('Permutation Testを開始します (試行回数: %d)...\n', num_permutations);
for i = 1:num_permutations
    % 片方のパターンの要素の順序をランダムにシャッフルする
    shuffled_indices = randperm(num_elements);
    shuffled_patternB = patternB(shuffled_indices);
    
    disp(shuffled_indices);
    disp("-------------------------------------------");

    % シャッフルされたデータとの相関を計算
    null_dist(i) = corr(patternA, shuffled_patternB);
end

% --- 3. p値の計算 ---
% (相関が偶然以上に「大きい」ことを検定する場合)
p_value_large = sum(null_dist >= observed_corr) / num_permutations;

% (相関が偶然以上に「小さい」ことを検定する場合)
p_value_small = sum(null_dist <= observed_corr) / num_permutations;

% --- 4. 結果表示 ---
p_value = p_value_large; 

fprintf('\n--- 検定結果 ---\n');
fprintf('p値 (相関 > 偶然): %.4f\n', p_value_large);
fprintf('p値 (相関 < 偶然): %.4f\n', p_value_small);

if p_value < 0.05
    disp('結論: 観測された相関は偶然よりも有意に大きいです (p < 0.05)');
else
    disp('結論: 観測された相関は偶然の範囲内です');
end
end