function plotAnovaInteraction( dataA, dataB, options)
%% 1. 引数の検証と次元の動的認識
arguments
    dataA {mustBeNumeric}
    dataB {mustBeNumeric}
    options.FactorNames (1,:) string = []
    % ★プロットしたい2つの要因のインデックスを指定
    options.FactorsToPlot (1,2) double {mustBeInteger, mustBePositive} = [1, ndims(dataA)-1] % デフォルトは第1要因とデータソース
    options.Title (1,1) string = ""
    options.SavePath (1,1) string = ""
end

num_dims = ndims(dataA);
dims_to_average = [num_dims - 1, num_dims]; % 被験者と試行
num_factors = num_dims - 2;

% FactorNamesの整合性をチェック
if isempty(options.FactorNames) || numel(options.FactorNames) ~= (num_factors + 1)
    error('正しい数のFactorNamesを指定してください (要因数%d + データ元1つ)。', num_factors);
end
if any(options.FactorsToPlot > (num_factors + 1))
    error('FactorsToPlotで指定されたインデックスが要因数を超えています。');
end

%% 2. データの平均化と統合
dataA_avg = mean(dataA, dims_to_average);
dataB_avg = mean(dataB, dims_to_average);

% データソース(A/B)を新しい次元としてデータを統合
% 例: 2x3x4 のデータ2つ -> 2x3x4x2 のデータに
all_data_avg = cat(num_dims - 1, dataA_avg, dataB_avg);

%% 3. ★プロット用データの計算
% 指定された2要因以外を全て平均化する
all_dims = 1:ndims(all_data_avg);
x_factor_dim = options.FactorsToPlot(1);
legend_factor_dim = options.FactorsToPlot(2);
dims_to_collapse = setdiff(all_dims, [x_factor_dim, legend_factor_dim]);

% squeezeで、サイズが1になった不要な次元を削除
means_for_plot = squeeze(mean(all_data_avg, dims_to_collapse));

% プロットのために次元の順番を調整 (x軸要因, 凡例要因)
% 例えば、[4, 2]をプロットする場合、4次元目が1番目、2次元目が2番目にくるように並べ替え
[~, permute_order] = sort([x_factor_dim, legend_factor_dim]);
if permute_order(1) == 2
    means_for_plot = means_for_plot';
end

%% 4. グラフの作成
fig = figure('Visible', 'off');
cleanupObj = onCleanup(@() close(fig));

plot(means_for_plot, '-o', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
ax = gca;

% グラフの体裁を調整
x_factor_name = options.FactorNames(x_factor_dim);
legend_factor_name = options.FactorNames(legend_factor_dim);

if isempty(options.Title)
    title(sprintf('%s と %s の交互作用', x_factor_name, legend_factor_name), 'FontSize', 16);
else
    title(options.Title, 'FontSize', 16);
end

xlabel(sprintf('%s のレベル', x_factor_name), 'FontSize', 12);
ylabel('測定値の平均', 'FontSize', 12);
xticks(1:size(means_for_plot, 1));

% 凡例のテキストを動的に生成
num_legend_levels = size(means_for_plot, 2);
legend_labels = strings(1, num_legend_levels);
for i = 1:num_legend_levels
    legend_labels(i) = sprintf('%s = Level %d', legend_factor_name, i);
end
legend(legend_labels, 'Location', 'best');

%% 5. 保存または表示
if ~isempty(options.SavePath)
    try
        print(fig, options.SavePath, '-dpng', '-r300');
        fprintf('交互作用プロットを保存しました: %s\n', options.SavePath);
    catch ME
        warning('グラフの保存中にエラーが発生しました: %s', ME.message);
    end
else
    set(fig, 'Visible', 'on');
    delete(cleanupObj);
end

end