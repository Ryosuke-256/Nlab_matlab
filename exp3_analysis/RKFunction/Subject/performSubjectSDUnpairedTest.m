function performSubjectSDUnpairedTest(dataA, dataB, nameA, nameB, plotOptions)
    % performSubjectSDUnpairedTest - 個人差（被験者間SD）の対応なしU検定を行う
    %
    % 入力:
    %   dataA, dataB : [H, M, S, P, T] 形式のデータ (Pは異なっていても良い)
    %   nameA, nameB : データセット名
    %   plotOptions  : .ResultDir, .HDRNum, .Amp 等 (.Modeは 'H' 推奨だが一応受け取る)
    %
    % ロジック:
    %   1. calculateSubjectSD(..., "H") で照明ごとの個人SD [H, P] を取得
    %      (材質・形状は平均化して次元を縮約する)
    %   2. 対数変換 -> log(SD)
    %   3. H（照明条件）ごとに、マン・ホイットニーのU検定 (ranksum) を実施
    %      対応がないので、ベクトルサイズが異なっていても実行可能
    %   4. 結果（Z値）をプロットし、有意差がある箇所を強調表示

    % モードはユーザー指定があれば従うが、基本は "H" (材質・形状平均化) で行う
    mode = "H"; 
    % もしユーザーが明示的に他のモードで比較したい場合は拡張可能だが、
    % 今回の要件「次元の縮約:材質と形状について平均をとり」に従い "H" 固定、または "H" として処理する。
    
    Amp = 1.0;
    if isfield(plotOptions, 'Amp'), Amp = plotOptions.Amp; end
    
    fprintf('--- 被験者間SDの対応なし統計検定 (U検定, Mode: H) ---\n');
    fprintf('比較対象: %s vs %s\n', nameA, nameB);

    % 1. SDデータの計算 (calculateSubjectSD.m)
    % 強制的に Mode="H" で計算し、[H, P] を得る
    sdA = calculateSubjectSD(dataA, "H");
    sdB = calculateSubjectSD(dataB, "H");
    
    % 2. 対数変換 (log SD)
    logSDA = log(sdA);
    logSDB = log(sdB);
    
    % データサイズ確認
    szA = size(logSDA);
    szB = size(logSDB);
    H = szA(1);
    numSubjectsA = szA(2);
    numSubjectsB = szB(2);
    
    fprintf('条件数(H): %d\n', H);
    fprintf('被験者数(TargetA): %d, (TargetB): %d\n', numSubjectsA, numSubjectsB);
    
    HDRNum = [];
    if isfield(plotOptions, 'HDRNum'), HDRNum = plotOptions.HDRNum; end

    % 3. 条件ごとに検定を実行
    zValues = zeros(H, 1);
    pValues = zeros(H, 1);
    
    for hIdx = 1:H
        vecA = squeeze(logSDA(hIdx, :)); 
        vecB = squeeze(logSDB(hIdx, :));
        
        % Mann-Whitney U test (Wilcoxon rank sum test)
        [p, ~, stats] = ranksum(vecA, vecB);
        
        zValues(hIdx) = stats.zval;
        pValues(hIdx) = p;
    end
    
    % 4. プロット作成
    titleStr = "All Conditions (Mode H)";
    
    % 図の作成
    fig = figure('Visible', 'on');
    
    % Z値のバープロット
    b = bar(zValues, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = repmat([0.7, 0.7, 0.7], H, 1); % デフォルト: グレー
    
    hold on;
    
    % 有意差がある箇所を赤色に変更 (p < 0.05)
    sigIndices = find(pValues < 0.05);
    if ~isempty(sigIndices)
        b.CData(sigIndices, :) = repmat([1, 0, 0], length(sigIndices), 1); % 赤
    end
    
    % 基準線 (Z=0)
    yline(0, 'k-', 'LineWidth', 1);
    
    % 参考クリティカルライン (Z=1.96, p=0.05 近似) - 必須ではないが表示しても良い
    % yline(1.96, 'b--', 'p=0.05');
    % yline(-1.96, 'b--');
    
    hold off;
    
    grid on;
    box on;
    
    % タイトルと軸ラベル
    titleVal = sprintf('Mann-Whitney U Test (logSD): %s\n%s vs %s', titleStr, nameA, nameB);
    title(titleVal, 'Interpreter', 'none', 'FontSize', 12 * Amp);
    ylabel('Z-value', 'FontSize', 10 * Amp);
    xlabel('Illumination', 'FontSize', 10 * Amp);
    
    % X軸設定
    xlim([0.5, H + 0.5]);
    xticks(1:H);
    if ~isempty(HDRNum)
        xticklabels(HDRNum);
        xtickangle(90);
    end
    
    % 保存
    if isfield(plotOptions, 'ResultDir')
        plotFileName = sprintf('SubjectSDUnpaired_%s_vs_%s.jpg', nameA, nameB);
        plotFullPath = fullfile(plotOptions.ResultDir, plotFileName);
        saveas(fig, plotFullPath);
        fprintf('  -> 検定結果プロットを保存しました: %s\n', plotFileName);
        close(fig);
    else
        warning('ResultDir is not specified in plotOptions. Plot is not saved.');
    end
    
    fprintf('----------------------------------------\n\n');
end
