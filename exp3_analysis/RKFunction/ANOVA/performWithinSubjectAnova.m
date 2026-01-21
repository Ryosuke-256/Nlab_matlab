function [ranova_table, rm_model] = performWithinSubjectAnova(dataA, dataB, options)
% [説明]
%   同一被験者に対する2つのデータセット(DataA, DataB)の違いを、
%   新たな「被験者内要因」として扱い、完全反復測定分散分析(Fully Repeated Measures ANOVA)を行います。
%
% [INPUTS]
%   dataA - (N-D行列)
%   dataB - (N-D行列) dataAと同一サイズ
%
% [OPTIONS]
%   "FactorNames" - (string array) 既存の要因名リスト。例: ["照明", "素材"]
%   "ConditionName" - (string) DataA vs DataB の要因名。例: "Condition"
%   "ConditionLevels" - (string array) 水準名。例: ["MotionON", "MotionOFF"]
%
% [OUTPUTS]
%   ranova_table - 分散分析表
%   rm_model - fitrmで作成されたモデルオブジェクト

arguments
    dataA {mustBeNumeric}
    dataB {mustBeNumeric}
    options.FactorNames (1,:) string = []
    options.ConditionName (1,1) string = "Condition"
    options.ConditionLevels (1,2) string = ["A", "B"]
    options.DataNames (1,2) string = ["DataA", "DataB"]
    options.ResultDir (1,1) string = ""
end

%% 1. データの整合性チェック
num_dims = ndims(dataA);
if ~isequal(size(dataA), size(dataB))
    error('DataAとDataBのサイズは完全に一致している必要があります。');
end
if num_dims < 3
    error('データは3次元以上である必要があります ([Factor1, ..., Subject, Trial])');
end

% 次元情報
% 想定: [...Factors..., Subject, Trial]
subject_dim = num_dims - 1;
factor_dims = 1:(subject_dim - 1);
factor_sizes = size(dataA); 
factor_sizes = factor_sizes(factor_dims);
num_existing_factors = numel(factor_sizes);

if isempty(options.FactorNames) || numel(options.FactorNames) ~= num_existing_factors
    error('FactorNamesの数は、データの要因数(%d)と一致させてください。', num_existing_factors);
end

%% 2. データの結合と整形
% 試行平均: [..., Subject, Trial] -> [..., Subject]
dataA_avg = mean(dataA, num_dims, 'omitnan');
dataB_avg = mean(dataB, num_dims, 'omitnan');

% 新しい要因次元を追加して結合: [..., Subject] -> [..., 2, Subject]
% cat関数で、Subject次元の前に新しい次元を挿入するのは少し複雑なので、
% 一旦フラットにしてから結合テーブルを作るアプローチをとります。

% "1行1被験者" (Wide Format) を作る必要があります。
% 変数は (Factor1 * Factor2 * ... * NewFactor) 個になります。

num_subjects = size(dataA_avg, subject_dim);

% AとBを、[Subject, AllFactors] に変形
% dataA_perm: [Subject, Factor1, Factor2, ...]
perm_order = [subject_dim, factor_dims];
dataA_perm = permute(dataA_avg, perm_order);
dataB_perm = permute(dataB_avg, perm_order);

% [Subject, FlattenedFactors]
dataA_flat = reshape(dataA_perm, num_subjects, []);
dataB_flat = reshape(dataB_perm, num_subjects, []);

% テーブル用に結合: [DataA_Columns, DataB_Columns]
% 左半分がDataA (Level1), 右半分がDataB (Level2)
all_data_matrix = [dataA_flat, dataB_flat];

%% 3. fitrm用テーブル作成
num_measurements_per_cond = size(dataA_flat, 2);
total_measurements = num_measurements_per_cond * 2;

var_names = "Y" + (1:total_measurements);
tbl = array2table(all_data_matrix, 'VariableNames', var_names);

% SubjectID の設定は削除 (ユーザーリクエスト)

%% 4. WithinDesgin (要因構成表) の作成
% 既存の要因に、新しい要因 (Condition) を追加します。
% データの並び順は A(all factors) -> B(all factors) なので、最も外側のループが Condition になります。

% 既存の要因のGrid作成
grid_vectors = arrayfun(@(n) (1:n)', factor_sizes, 'UniformOutput', false);
if isempty(grid_vectors) % 次元がSubjectしかない場合
    % (通常ありえないがロバスト性のために)
    sub_table = table();
else
    [grid_outputs{1:numel(grid_vectors)}] = ndgrid(grid_vectors{:});
    sub_table = table();
    for i = 1:numel(options.FactorNames)
        sub_table.(options.FactorNames(i)) = grid_outputs{i}(:);
    end
end

% これを2回繰り返す (DataA用とDataB用)
within_design = [sub_table; sub_table];

% 新しい要因列を追加
% 前半が Level1 (DataA), 後半が Level2 (DataB)
cond_col_vals = [repmat(categorical(options.ConditionLevels(1)), num_measurements_per_cond, 1);
                 repmat(categorical(options.ConditionLevels(2)), num_measurements_per_cond, 1)];

% テーブル結合 (Conditionを一番右に追加、あるいは左に追加？ ranovaの解釈には順序は影響しないが、分かりやすさのため)
within_design.(options.ConditionName) = cond_col_vals;

%% 5. fitrm と ranova 実行
model_formula = sprintf('%s-%s ~ 1', var_names(1), var_names(end)); % 被験者間要因はないので "~ 1"

rm_model = fitrm(tbl, model_formula, 'WithinDesign', within_design);

% 相互作用を含めた全要因モデル
all_factors = within_design.Properties.VariableNames;
within_model_formula = strjoin(all_factors, '*');

ranova_table = ranova(rm_model, 'WithinModel', within_model_formula);

fprintf('\n=== Fully Repeated Measures ANOVA Table ===\n');
disp(ranova_table);

% --- 効果量(Partial Eta Squared)の計算 ---
try
    % SumSq列を取得
    SumSq = ranova_table.SumSq;
    RowNames = ranova_table.Properties.RowNames;
    
    partial_eta_sq = nan(height(ranova_table), 1);
    
    % "Error"で始まる行を探す
    error_indices = find(startsWith(RowNames, 'Error', 'IgnoreCase', true));
    
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
%% 6. 結果保存 (CSV)
if options.ResultDir ~= ""
    % ファイル名にデータ名を含める
    nameA = options.DataNames(1);
    nameB = options.DataNames(2);
    saveFileName = sprintf("PerfectREANOVA_%s_vs_%s_%s.csv", nameA, nameB, options.ConditionName);
    
    saveFullPath = fullfile(options.ResultDir, saveFileName);
    
    % 行名(Source)を含めて保存
    % ranovaの結果テーブルには内部クラスが含まれることがあり、writetableでエラーになる場合があるため
    % 一旦標準的なテーブルに変換/再構築します。
    
    % 行名を取り出す
    RowNames = ranova_table.Properties.RowNames;
    
    % テーブルの内容をセル配列に変換してから再テーブル化（内部型を剥がす）
    % ただし、数値とカテゴリが混ざっている可能性があるが、ranovaの結果は通常数値のみ（p値など）
    % 列名を取得
    VarNames = ranova_table.Properties.VariableNames;
    
    % 新しいテーブルを作成
    outTbl = table();
    outTbl.Source = string(RowNames); % 行名を列として追加
    
    for k = 1:width(ranova_table)
        colName = VarNames{k};
        colData = ranova_table.(colName);
        % 数値列ならdoubleにする
        if isnumeric(colData)
            outTbl.(colName) = double(colData);
        else
            outTbl.(colName) = colData;
        end
    end
    
    % ユーザーリクエスト: 小数点以下3位で丸める
    outTbl = roundTableValues(outTbl, 'NumDecimals', 3);
    
    writetable(outTbl, saveFullPath);
    fprintf('  -> ANOVA結果を保存しました: %s\n', saveFileName);
end

end
