% データ読み込み
exp3 = load('Exp3_data.mat');  % OFF
exp4 = load('Exp4_data.mat');  % ON
dataA = exp3.Row_HMSPT;        % [L M S P T]
dataB = exp4.Row_HMSPT;        % [L M S P T]

% 基本パラメータ
sizeA = size(dataA);
sizeB = size(dataB);
num_dims   = ndims(dataA);   % = 5
factor_dims = 1:(num_dims-2); % = [1 2 3]（L,M,S）
subject_dim = 4;              % P（Participant）の次元
factor_sizes = sizeA(factor_dims);
num_measurements = prod(factor_sizes);

% Trial 次元（最後）で平均して 4 次元 [L M S P] に
dataA_avg = mean(dataA, num_dims);
dataB_avg = mean(dataB, num_dims);

% [P, L, M, S] に permute → [nSubj × (L*M*S)] に reshape
dataA_2d = reshape(permute(dataA_avg, [subject_dim, factor_dims]), sizeA(subject_dim), []);
dataB_2d = reshape(permute(dataB_avg, [subject_dim, factor_dims]), sizeB(subject_dim), []);

% OFF/ON を縦結合（行＝被験者）
all_data_matrix = [dataA_2d; dataB_2d];

% 列名（応答変数名）Y1..YK
measurement_var_names = compose('Y%d', 1:num_measurements);  % string 配列
varnames_cell = cellstr(measurement_var_names);               % 互換性のため cellstr

% テーブル化
tbl = array2table(all_data_matrix, 'VariableNames', varnames_cell);

% 被験者間要因（OFF/ON）の列を追加
nA = sizeA(subject_dim);
nB = sizeB(subject_dim);
Group = [repmat("OFF", nA, 1); repmat("ON", nB, 1)];
tbl.Group = categorical(Group);

% 被験者内要因（L/M/S）の水準表（L×M×S 行）
nL = sizeA(1); nM = sizeA(2); nS = sizeA(3);
[Lidx, Midx, Sidx] = ndgrid(1:nL, 1:nM, 1:nS);
within_factors_table = table( ...
    categorical(Lidx(:)), categorical(Midx(:)), categorical(Sidx(:)), ...
    'VariableNames', {'Lighting','Material','Shape'});

% fitrm 用モデル式 "Y1-YK ~ Group"
model_formula = sprintf('%s-%s ~ %s', char(measurement_var_names(1)), char(measurement_var_names(end)), 'Group');

% 反復測定モデルの当て込み
rm_model = fitrm(tbl, model_formula, 'WithinDesign', within_factors_table);

% 例：被験者内要因の効果（L/M/S とその交互作用）を検定
ranovatbl = ranova(rm_model, 'WithinModel', 'Lighting');
% ranovatbl = ranova(rm_model, 'WithinModel', 'Lighting*Material*Shape');
disp(ranovatbl)

