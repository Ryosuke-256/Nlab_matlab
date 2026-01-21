function [ranova_table, rm_model] = performMixedAnova(dataA, dataB, options)
% [説明]
%   1. データの次元数を動的に認識します。
%   2. 最後から2番目(被験者)と最後(試行)の次元を、1つの「繰り返し」次元に統合します。
%   3. 残った次元(要因)と、「データソース(A/B)」を要因としてN-way ANOVAを実行します。
%      被験者・試行間のばらつきが誤差項として扱われます。
% [INPUTS]
%   dataA - (N-D行列, N>=3) 1つ目のデータセット
%   dataB - (N-D行列, N>=3) 2つ目のデータセット
%
% [OPTIONS] (Name-Value Pairs)
%   "FactorNames" - (string/cell array) 要因名。最後の要因名はデータソース用に
%                   確保してください。例: ["照明", "素材", "データ元"]
% [OUTPUTS]
%   p_values    - (ベクトル) 各要因と交互作用のp値。
%   anova_table - (セル配列) 分散分析表。
%
%　表読み方
% Source: 分析対象の要因です。「illumination」のような個別の要因（主効果）と、「illumination*Material」のような要因の組み合わせ（交互作用）があります。
% Sum Sq. (平方和): データのばらつきの大きさを示します。
% d.f. (自由度): 統計的な計算に使われる数値です。
% Mean Sq. (平均平方): Sum Sq. / d.f. で計算される、平均的なばらつきです。
% F (F値): 要因の効果の大きさを表す指標です。値が大きいほど、影響が大きいことを示します。
% Prob>F (p値): 結果を判断する上で最も重要な列です。この値が偶然得られる確率を示します。

%% 1. 引数の検証と次元の動的認識
arguments
    dataA {mustBeNumeric}
    dataB {mustBeNumeric}
    options.FactorNames (1,:) string = []
    options.SubjectIDs (1,:) string = []
    options.BetweenFactorName (1,1) string = "Condition"
end

num_dims = ndims(dataA);
if num_dims < 3, error('入力データは3次元以上である必要があります。'); end
sizeA = size(dataA);
sizeB = size(dataB);
subject_dim = num_dims - 1;
dims_to_check = [1:(subject_dim-1), num_dims];
if ~isequal(sizeA(dims_to_check), sizeB(dims_to_check))
    error('被験者次元以外の次元サイズが一致しません。');
end
factor_dims = 1:(num_dims - 2);
factor_sizes = sizeA(factor_dims);
num_within_factors = numel(factor_sizes);
if isempty(options.FactorNames) || numel(options.FactorNames) ~= num_within_factors
    error('FactorNamesの数は、被験者内要因の数(%d)と一致させてください。', num_within_factors);
end

%% 2. データの準備 (変更なし)
dataA_avg = mean(dataA, num_dims);
dataB_avg = mean(dataB, num_dims);
dataA_2d = reshape(permute(dataA_avg, [subject_dim, factor_dims]), sizeA(subject_dim), []);
dataB_2d = reshape(permute(dataB_avg, [subject_dim, factor_dims]), sizeB(subject_dim), []);
all_data_matrix = [dataA_2d; dataB_2d];

%% 3. fitrm用のテーブルを作成
num_subjects_A = size(dataA_2d, 1);
num_subjects_B = size(dataB_2d, 1);
subject_ids = (1:(num_subjects_A + num_subjects_B))';
between_factor_group = [repmat("A", num_subjects_A, 1); repmat("B", num_subjects_B, 1)];

num_measurements = prod(factor_sizes);
measurement_var_names = "Y" + (1:num_measurements);
tbl = array2table(all_data_matrix, 'VariableNames', measurement_var_names);
tbl.SubjectID = subject_ids;
tbl.(options.BetweenFactorName) = between_factor_group;

%% 4. 繰り返し測定モデルの定義
within_factors_table = table;
grid_vectors = arrayfun(@(n) (1:n)', factor_sizes, 'UniformOutput', false);
[grid_outputs{1:num_within_factors}] = ndgrid(grid_vectors{:});
within_factor_names = options.FactorNames(1:num_within_factors);
for i = 1:num_within_factors
    within_factors_table.(within_factor_names(i)) = grid_outputs{i}(:);
end

model_formula = sprintf('%s-%s ~ %s', measurement_var_names(1), measurement_var_names(end), options.BetweenFactorName);

rm_model = fitrm(tbl, model_formula, 'WithinDesign', within_factors_table);

%% 5. 分散分析の実行と表示
within_model_formula = strjoin(within_factor_names, '*');
ranova_table = ranova(rm_model, 'WithinModel', within_model_formula);
fprintf('\n--- Repeated Measures ANOVA Table ---\n');

disp(ranova_table);

% --- 効果量(Partial Eta Squared)の計算 ---
try
    % ranova_tableは、各要因の行と、それに対応する誤差(Error)の行ペアで構成されることが多いですが、
    % MATLABのバージョンやモデル記述によっては Error(...) という行に分かれます。
    % ここでは、「Error」を含む行名を誤差項として識別し、直前の行(または対応する項)の効果量を計算します。
    
    % SumSq列を取得
    SumSq = ranova_table.SumSq;
    RowNames = ranova_table.Properties.RowNames;
    
    partial_eta_sq = nan(height(ranova_table), 1);
    
    % "Error"で始まる行を探す
    error_indices = find(startsWith(RowNames, 'Error', 'IgnoreCase', true));
    
    % Block-based approach:
    % Table is assumed to be ordered as: [Effect1, Effect2, ..., Error1, Effect3, ..., Error2, ...]
    % All rows between the previous Error row (or start) and the current Error row depend on the current Error row.
    
    last_error_idx = 0;
    
    for i = 1:numel(error_indices)
        err_idx = error_indices(i);
        
        % Define the block of effects associated with this error term
        block_start = last_error_idx + 1;
        block_end = err_idx - 1;
        
        if block_end >= block_start
            SS_error = SumSq(err_idx);
            
            for j = block_start:block_end
                SS_effect = SumSq(j);
                partial_eta_sq(j) = SS_effect / (SS_effect + SS_error);
            end
        end
        
        last_error_idx = err_idx;
    end
    
    ranova_table.PartialEtaSq = partial_eta_sq;
    fprintf(' -> Partial Eta Squared added to table.\n');
catch ME
    warning('効果量の計算に失敗しました: %s', ME.message);
end

end