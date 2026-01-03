function corrected_data = BroadcastZscore(reference_data, target_data, zscore_dim, common_dims)
%applyBroadcastZscore 参照データの統計量で、高次元の標的データを補正（Zスコア化）します。
% [INPUTS]
%   reference_data - (N-D行列) 平均値・標準偏差の計算基準となるデータ。
%   target_data    - (M-D行列) 補正を適用したい対象のデータ (M >= N)。
%   zscore_dim     - (整数)   参照データで統計量を計算する基準次元。
%   common_dims    - (ベクトル) 参照データと標的データで対応する共通次元のリスト。
%
% [OUTPUTS]
%   corrected_data - (M-D行列) 補正後のデータ。サイズはtarget_dataと同じ。

%% 1. 引数の検証
arguments
    reference_data {mustBeNumeric}
    target_data {mustBeNumeric}
    zscore_dim (1,1) double {mustBeInteger, mustBePositive}
    common_dims (1,:) {mustBeInteger, mustBePositive}
end

% 共通次元のサイズが一致するか検証
size_ref = size(reference_data);
size_target = size(target_data);

%{
if ~isequal(size_ref(common_dims), size_target(common_dims))
    error('参照データと標的データの共通次元のサイズが一致しません。');
end
if ~ismember(zscore_dim, common_dims)
    error('zscore_dimはcommon_dimsに含まれている必要があります。');
end
%}

%% 2. 参照データから統計量（移動量と倍率）を計算
mu_ref    = mean(reference_data, zscore_dim);
sigma_ref = std(reference_data, 0, zscore_dim);

%{
disp(mu_ref);
disp(sigma_ref);
%}

% 標準偏差が0の場合は、ゼロ除算を避けるために1に設定
sigma_ref(sigma_ref == 0) = 1;

%% 3. ★ 対象データに補正を適用
corrected_data = (target_data - mu_ref) ./ sigma_ref;

fprintf('Zscoreのブロードキャスト処理が完了しました。\n');
end