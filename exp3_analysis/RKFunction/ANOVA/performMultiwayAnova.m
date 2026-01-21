function [p_values, anova_table] = performMultiwayAnova(dataA, dataB, options)
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
    options.InnerFactor (1,:) string = []
    options.OuterFactor (1,:) string = []
end

FactorNames = [options.InnerFactor,options.OuterFactor];

% 検証ロジック
num_dims = ndims(dataA);
if num_dims < 3, error('入力データは3次元以上である必要があります。'); end
sizeA = size(dataA);
sizeB = size(dataB);
subject_dim = num_dims - 1;
% 被験者次元を除く、他のすべての次元サイズが一致することを検証
dims_to_check = [1:(subject_dim-1), num_dims];
if ~isequal(sizeA(dims_to_check), sizeB(dims_to_check))
    error('被験者次元以外の次元サイズが一致しません。');
end

% 要因の次元を動的に決定
factor_dims = 1:(num_dims - 2);
num_factors = numel(factor_dims) + 1; % データソース要因(+1)

if ~isempty(FactorNames) && numel(FactorNames) ~= num_factors
    error('FactorNamesの数(%d)が、実際の要因数(%d)と一致しません。', numel(FactorNames), num_factors);
end


%% 2. ★ データのサンプル次元への変換
factor_sizes = sizeA(factor_dims);

% データAの変形
num_reps_A = size(dataA, num_dims - 1) * size(dataA, num_dims);
dataA_reshaped = reshape(dataA, [prod(factor_sizes), num_reps_A]);

% データBの変形
num_reps_B = size(dataB, num_dims - 1) * size(dataB, num_dims);
dataB_reshaped = reshape(dataB, [prod(factor_sizes), num_reps_B]);


%% 3. anovan関数用のデータ形式に準備
all_values = [dataA_reshaped(:); dataB_reshaped(:)];

% グループ変数をデータAとBで個別に作成してから結合
grid_vectors = arrayfun(@(n) 1:n, factor_sizes, 'UniformOutput', false);
grid_outputs = cell(1, numel(factor_sizes));
[grid_outputs{:}] = ndgrid(grid_vectors{:});

groups = cell(1, num_factors);
for i = 1:numel(factor_sizes)
    factor_group_base = grid_outputs{i}(:);
    group_A_i = repmat(factor_group_base, num_reps_A, 1);
    group_B_i = repmat(factor_group_base, num_reps_B, 1);
    % 結合
    groups{i} = [group_A_i; group_B_i];
end

% データソース要因(A/B)を追加
groups{end} = [repmat("A", numel(dataA_reshaped), 1); repmat("B", numel(dataB_reshaped), 1)];

%% 4. 多因子分散分析(N-way ANOVA)の実行
[p_values, anova_table] = anovan(all_values, groups, ...
    'model', 'full', ...
    'varnames', FactorNames, ...
    'display', 'on');

% --- 効果量(Eta Squared, Partial Eta Squared)の計算 ---
try
    % ヘッダー行から列インデックスを取得
    header = anova_table(1, :);
    ss_col = find(strcmp(header, 'Sum Sq.'));
    source_col = find(strcmp(header, 'Source'));
    
    if ~isempty(ss_col) && ~isempty(source_col)
        % 行数
        num_rows = size(anova_table, 1);
        
        % Error行とTotal行を探す
        sources = anova_table(:, source_col);
        error_row = find(strcmp(sources, 'Error'));
        total_row = find(strcmp(sources, 'Total'));
        
        if ~isempty(error_row) && ~isempty(total_row)
            SS_error = anova_table{error_row, ss_col};
            SS_total = anova_table{total_row, ss_col};
            
            % 新しい列を追加
            anova_table{1, end+1} = 'EtaSq';
            anova_table{1, end+1} = 'PartialEtaSq';
            
            % 各行について計算 (ヘッダー除く, Error/Total除く)
            for i = 2:num_rows
                % ErrorやTotal行はスキップ
                if i == error_row || i == total_row
                    continue;
                end
                
                SS_effect = anova_table{i, ss_col};
                
                % Eta Squared = SS_effect / SS_total
                eta_sq = SS_effect / SS_total;
                
                % Partial Eta Squared = SS_effect / (SS_effect + SS_error)
                partial_eta_sq = SS_effect / (SS_effect + SS_error);
                
                anova_table{i, end-1} = eta_sq;
                anova_table{i, end} = partial_eta_sq;
            end
            
            fprintf(' -> Eta Squared & Partial Eta Squared added to table.\n');
        end
    end
catch ME
    warning('効果量の計算に失敗しました: %s', ME.message);
end

end