function performMDSClustering(rawData, dataSetName, matNames, shapeNames, options)
    % performMDSClustering - MDSとクラスタリングを実行し、結果を可視化・保存します。
    %
    % 入力:
    %   rawData : [H, M, S, P, T] 形式の5次元データ
    %   dataSetName : データセット名 (文字列)
    %   matNames    : 材質名のリスト (セルの配列 or string配列)
    %   shapeNames  : 形状名のリスト (セルの配列 or string配列)
    %   options     : オプション構造体
    %       .ResultDir : 結果保存ディレクトリ
    %       .Amp       : フォントなどの拡大率
    
    arguments
        rawData
        dataSetName string
        matNames string
        shapeNames string
        options struct
    end

    fprintf('MDS Cluistering analysis for %s is starting...\n', dataSetName);

    %% 1. 前処理: (被験者・試行平均) -> [H, M, S]
    % [H, M, S, P, T] -> [H, M, S]
    % 4次元目(P)と5次元目(T)を平均化
    meanData = mean(mean(rawData, 5, 'omitnan'), 4, 'omitnan');
    
    [H, M, S] = size(meanData);
    
    % [M*S, H] の行列に変形
    % 各行が「ある材質・形状の組み合わせ」の特徴ベクトル（照明変化）を表す
    featureMatrix = zeros(M*S, H);
    labels = strings(M*S, 1);
    
    idx = 1;
    for m = 1:M
        for s = 1:S
            % ベクトル抽出: [H, 1, 1] -> [1, H]
            vec = squeeze(meanData(:, m, s))'; 
            featureMatrix(idx, :) = vec;
            
            % ラベル作成
            labels(idx) = matNames(m) + "_" + shapeNames(s);
            idx = idx + 1;
        end
    end
    
    %% 2. 距離計算（ピアソン相関距離）
    % d = 1 - r
    % corr は列ごとの相関を計算するため、転置して [H, M*S] にする
    % -> 相関行列は [M*S, M*S] になる
    R = corr(featureMatrix'); 
    distMatrix = 1 - R;
    
    % 正方行列をベクトル形式の距離（pdist形式）に変換
    % squareformは、正方行列<->ベクトルを相互変換する
    % ただし、対角成分が0で対称行列である必要がある（1-rならOKだが、念のためゴミ除去）
    distMatrix = (distMatrix + distMatrix') / 2; % 対称性保証
    distMatrix(eye(size(distMatrix))==1) = 0;    % 対角成分0保証
    
    distVec = squareform(distMatrix);
    
    %% 3. MDS (非計量) - 2次元
    try
        % mdscale(D, p) p次元へ配置
        % 'criterion', 'metricstress' (計量) または 'stress' (非計量)
        % ここでは記述に従い非計量MDS (デフォルトはstress) を使用したいが、
        % 一般的な相関距離のMDSでは計量MDS('metricstress')の方が素直な場合もある。
        % 要件「非計量MDS」に従いデフォルト(stress1)を使用するが、
        % 収束しない場合もあるためtry-catchする。
        [Y, stress] = mdscale(distVec, 2, 'Criterion', 'stress');
        fprintf('  -> MDS Stress: %.4f\n', stress);
    catch ME
        warning('MDS calculation failed or did not converge. Retrying with metric stress.');
        [Y, stress] = mdscale(distVec, 2, 'Criterion', 'metricstress');
        fprintf('  -> (Retry) MDS Metric Stress: %.4f\n', stress);
    end
    
    %% 4. クラスタリング (Ward法 & エルボー法)
    % 階層クラスタリング (Ward法)
    Z = linkage(distVec, 'ward');
    
    % エルボー法によるクラスター数決定
    % 結合距離(Z(:,3))の増分を確認
    distances = Z(:, 3);
    
    % 最後の結合（クラスター数1になる結合）がリストの最後。
    % クラスター数をkとしたとき、結合は (データ数-k) 回行われている。
    % 結合距離の急激なジャンプを探す。
    
    % distancesは昇順に並んでいる。
    % 増分 = dist(i+1) - dist(i)
    % 後ろの方（結合が進んだ段階）でのジャンプが重要。
    % numPoints = M*S
    numPoints = size(featureMatrix, 1);
    maxClustersToCheck = min(numPoints, 10); % チェックする最大クラスター数
    
    % 逆順（最終結合 -> 初期結合）で増分を見る
    % Zの最後は「2つのクラスターを1つにする」結合。
    % その距離が d_last。その一つ前が d_{last-1}。
    % クラスター数が 2 -> 1 になるときの距離が d_last
    % クラスター数が 3 -> 2 になるときの距離が d_{last-1}
    % kクラスターのときの結合距離コストではなく、「kクラスターに減らすために結合した距離」の変化を見ることで、
    % 「無理やり結合した」タイミング（＝自然な分割点）を見つける。
    
    % Zの行iは、(N-i)クラスターから(N-i-1)クラスターへの結合を表す（i=1..N-1）。
    % つまり、最後(N-1)行目は 2->1 クラスター。
    
    % クラスター数 k (2..max) について、 k -> k-1 の結合距離を見る。
    % kクラスター構成時の「凝集度」ではなく、kになる直前の結合コストの変化率を見るのが一般的。
    
    % ここではシンプルに「結合距離の差分（acceleration）」が最大のところをカットオフとする。
    if numPoints > 2
        sortedDist = sort(distances, 'descend'); % 大きい順（結合の後ろの方）
        % sortedDist(1): 2->1 の距離
        % sortedDist(2): 3->2 の距離
        % sortedDist(k-1): k->k-1 の距離
        
        diffs = -diff(sortedDist); % (2->1) - (3->2), (3->2) - (4->3)...
        % diffs(k-1) が大きいということは、kクラスターからk-1クラスターにするのに、
        % 必要以上の距離（非類似度）を結合してしまったことを示唆する -> k個が適当。
        
        % diffsの長さなどで制限をかける
        searchLimit = min(maxClustersToCheck-1, length(diffs));
        [~, maxIdx] = max(diffs(1:searchLimit));
        optimalK = maxIdx + 1; % maxIdx=1 (diffs(1)) なら 2クラスターが最適
        
        fprintf('  -> Optimal Cluster Number (Elbow Method): %d\n', optimalK);
    else
        optimalK = 1;
    end
    
    % クラスタリング実行
    clusterIdx = cluster(Z, 'maxclust', optimalK);
    
    
    %% 5. 可視化
    fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 800]);
    
    % カラーマップ作成
    colors = lines(optimalK);
    
    hold on;
    for k = 1:optimalK
        % クラスターkのデータ点
        idxK = (clusterIdx == k);
        pts = Y(idxK, :);
        
        % 散布図プロット
        scatter(pts(:,1), pts(:,2), 75 * options.Amp, colors(k,:), 'filled', ...
            'DisplayName', sprintf('Cluster %d', k));
        
        % ラベル表示
        text(pts(:,1), pts(:,2), labels(idxK), ...
            'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
            'FontSize', 5 * options.Amp, 'Interpreter', 'none', 'Color', [0.2 0.2 0.2]);
    end
    
    title(sprintf('MDS Clustering: %s (k=%d)', dataSetName, optimalK), 'Interpreter', 'none', 'FontSize', 14 * options.Amp);
    xlabel('Dimension 1', 'FontSize', 12 * options.Amp);
    ylabel('Dimension 2', 'FontSize', 12 * options.Amp);
    grid on;
    
    % 凡例（クラスターごと）
    legend('Location', 'bestoutside','FontSize', 5 * options.Amp);
    
    axis equal;
    hold off;
    
    % 保存
    if options.ResultDir ~= ""
        fileName = sprintf('MDS_Clustering_%s.jpg', dataSetName);
        saveas(fig, fullfile(options.ResultDir, fileName));
        fprintf('  -> Plot saved: %s\n', fileName);
    end
    close(fig);
    
    %% 6. エルボー法のプロット（デバッグ/確認用）
    figElbow = figure('Visible', 'off');
    
    % 結合距離のプロット
    % 横軸: クラスター数 (データ数:-1:1) だが、わかりやすく「結合ステップ」または「クラスター数」にする。
    % ここでは「クラスター数」を横軸にする。
    % Zのi行目の結合によってクラスター数は (N-i+1) -> (N-i) になる。
    % つまり、横軸 k=2..10 に対して、Z(end-k+2, 3) をプロットするのが直感的。
    
    kRange = 2:min(15, numPoints);
    distVals = zeros(length(kRange), 1);
    for i = 1:length(kRange)
        k = kRange(i);
        % k個からk-1個にする結合は、Zの (N-(k-1)) 行目
        distVals(i) = Z(end-k+2, 3);
    end
    
    plot(kRange, distVals, 'o-', 'LineWidth', 2);
    hold on;
    % 推定されたKをマーク
    plot(optimalK, Z(end-optimalK+2, 3), 'rx', 'MarkerSize', 15, 'LineWidth', 3);
    hold off;
    
    title(sprintf('Elbow Method Check: %s (Optimal k=%d)', dataSetName, optimalK), 'Interpreter', 'none');
    xlabel('Number of Clusters');
    ylabel('Linkage Distance (Ward)');
    grid on;
    
    if options.ResultDir ~= ""
        fileNameElbow = sprintf('ElbowCheck_%s.jpg', dataSetName);
        saveas(figElbow, fullfile(options.ResultDir, fileNameElbow));
        fprintf('  -> Elbow plot saved: %s\n', fileNameElbow);
    end
    close(figElbow);

end
