clear all;

%% 3.クラスター分析
%% データ読み込み
load('z_conditionList.mat');
material_idx = 1;
shape_idx = 2;
roughness_idx = 3;
condition_names = strcat(experiment_condition(:, shape_idx), '-', experiment_condition(:, material_idx), '-', experiment_condition(:, roughness_idx));

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';
filename = strcat(rootpath, '/z_psvList.mat');

load(filename);

illumNum = 30;
[conditionNum, ~] = size(experiment_condition);

for i = 1 : conditionNum 
    response_Z(i,:) = zscore(psvList(i,:));
end

X = corrcoef(response_Z');

%% クラスター分析
%1. 相関行列を距離行列に
Y = squareform(pdist(X));

% 2.MDSによる距離行列の可視化
D = Y.^2; % 距離行列の2乗を取る
m = 2; % MDSの次元数
[Y_mds, stress] = mdscale(D, m); % MDSによる次元削減


h1 = figure('Position', [1 1 1920 1200], 'Name', 'MDSによる光沢知覚量の条件間距離関係');
figure(h1)
scatter(Y_mds(:,1), Y_mds(:,2), 100, 'LineWidth', 2);
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定

xlabel('MDS 次元 1','FontSize', 30);
ylabel('MDS 次元 2','FontSize', 30);
% title('MDSによる光沢知覚量の条件間距離関係');

% 3.階層的クラスタリング
Z = linkage(Y, 'ward'); % Ward法を使用して階層クラスタリングを実行

% エルボー法による最適なクラスター数の決定
cutoffs = Z(end-10:end, 3); % 最後の10つのマージのクラスター間距離を取得
diffs = diff(cutoffs); % クラスター間距離の変化を計算
k_values = 2:numel(diffs)+1; % クラスター数の範囲
wcss = cumsum(diffs); % クラスター内誤差平方和を計算
diff_ratios = diffs ./ wcss(1:end); % 変化の比率を計算
[~, optimal_index] = max(diff_ratios); % 変化の比率が最大のインデックスを取得
optimal_cluster_num = k_values(optimal_index + 1); % 最適なクラスター数を取得

% クラスター数の自動選択
T = cluster(Z, 'MaxClust', optimal_cluster_num); % クラスター数を指定せずにクラスター分割

%% クラスター番号の入れ替え（最大クラスターを１にする）
counts = zeros(1, optimal_cluster_num);
newT = zeros(size(T));
for i = 1:optimal_cluster_num   
    counts(i) = sum(T == i);    
end
[~, rank] = sort(counts, 'descend');

for i = 1:optimal_cluster_num   
    newT(T == rank(i)) = i; 
end

clusterList = newT;

%% 各データポイントをクラスターごとにプロット

h2 = figure('Position', [1 1 1920 1200], 'Name', '光沢知覚量の階層的クラスタリング');
figure(h2)
for i = 1:optimal_cluster_num
    scatter(Y_mds(clusterList == i, 1), Y_mds(clusterList == i, 2),100, 'LineWidth', 2);
    hold on;
end

% テキストの位置を動的に調整

for i = 1:length(condition_names)
    % 最も近い隣接点を見つける
    distances = sqrt(sum((Y_mds - Y_mds(i, :)).^2, 2));
    distances(i) = max(distances); % 自分自身を除外
    [~, closestIndex] = min(distances);
    
    % 隣接点に対する相対的な位置を計算
    offsetX = (Y_mds(i, 1) - Y_mds(closestIndex, 1)) * 0.1;
    offsetY = (Y_mds(i, 2) - Y_mds(closestIndex, 2)) * 0.1;
    
    % テキストをプロット
    text(Y_mds(i, 1) + offsetX, Y_mds(i, 2) + offsetY, condition_names{i}, 'FontSize', 8);
end


% 軸ラベルとタイトルの追加
ax = gca; % 現在の軸を取得
ax.FontSize = 20; % フォントサイズを設定
ax.LineWidth = 2; % 軸の線の太さを設定

xlabel('MDS 次元 1', 'FontSize', 30);
ylabel('MDS 次元 2', 'FontSize', 30);
% title('光沢知覚量の階層的クラスタリング');

legend(arrayfun(@(x) sprintf('Cluster %d', x), 1:optimal_cluster_num, 'UniformOutput', false),'FontSize', 20, 'Location', 'best'); % 凡例を追加

% グラフを表示
hold off;

%% 保存
save('z_clusterList.mat', 'clusterList');