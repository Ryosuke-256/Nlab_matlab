function performSubjectSDTest(dataA, dataB, nameA, nameB, plotOptions)
    % performSubjectSDTest - 個人差（被験者間SD）の対応ありt検定を行う
    %
    % 入力:
    %   dataA, dataB : [H, M, S, P, T] 形式のデータ（アライメント済み）
    %   nameA, nameB : データセット名
    %   plotOptions  : .Mode, .ResultDir, .MatNames, .ShapeNames, .HDRNum, .Amp等
    
    mode = plotOptions.Mode;
    Amp = 1.0;
    if isfield(plotOptions, 'Amp'), Amp = plotOptions.Amp; end
    
    % ShowTitleオプションのデフォルト設定
    if ~isfield(plotOptions, 'ShowTitle')
        plotOptions.ShowTitle = true;
    end
    showTitle = plotOptions.ShowTitle;
    
    fprintf('--- 被験者間SDの統計検定 (Mode: %s) ---\n', mode);
    fprintf('比較対象: %s vs %s\n', nameA, nameB);

    % 1. SDデータの計算 (calculateSubjectSD.m)
    % isPooled=true: 非対象次元を平均せず標本として扱う
    sdA = calculateSubjectSD(dataA, mode, true);
    sdB = calculateSubjectSD(dataB, mode, true);
    
    % 2. 対数変換 (log SD)
    logSDA = log(sdA);
    logSDB = log(sdB);
    
    % 3. 条件ごとに検定を実行 & プロット
    sz = size(logSDA);
    % 最後の次元は被験者数(P)
    numSubjects = sz(end);
    fprintf('被験者数: %d\n', numSubjects);
    
    H = sz(1);
    HDRNum = plotOptions.HDRNum;
    
    switch mode
        case "H"
            % Data: [H, P]
            tValues = zeros(H, 1);
            pValues = zeros(H, 1);
            dfValues = zeros(H, 1);
            cohenDValues = zeros(H, 1);
            
            for hIdx = 1:H
                vecA = squeeze(logSDA(hIdx, :)); 
                vecB = squeeze(logSDB(hIdx, :));
                [~, p, ~, stats] = ttest(vecA, vecB);
                tValues(hIdx) = stats.tstat;
                pValues(hIdx) = p;
                dfValues(hIdx) = stats.df;
                cohenDValues(hIdx) = mean(vecA - vecB) / std(vecA - vecB);
            end
            
            saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, "All", plotOptions);
            
            titleStr = "All Conditions";
            plotTestResult(tValues, pValues, H, HDRNum, Amp, titleStr, nameA, nameB, mode, plotOptions, numSubjects, showTitle);
            
        case "HM"
            % Data: [H, M, P]
            M = sz(2);
            for m = 1:M
                tValues = zeros(H, 1);
                pValues = zeros(H, 1);
                dfValues = zeros(H, 1);
                cohenDValues = zeros(H, 1);
                matName = string(plotOptions.MatNames(m));
                
                for hIdx = 1:H
                    vecA = squeeze(logSDA(hIdx, m, :));
                    vecB = squeeze(logSDB(hIdx, m, :));
                    [~, p, ~, stats] = ttest(vecA, vecB);
                    tValues(hIdx) = stats.tstat;
                    pValues(hIdx) = p;
                    dfValues(hIdx) = stats.df;
                    cohenDValues(hIdx) = mean(vecA - vecB) / std(vecA - vecB);
                end
                
                suffix = mode + "_" + matName;
                saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, suffix, plotOptions);
                
                titleStr = sprintf("Material: %s", matName);
                plotTestResult(tValues, pValues, H, HDRNum, Amp, titleStr, nameA, nameB, suffix, plotOptions, numSubjects, showTitle);
            end
            
        case "HS"
            % Data: [H, S, P]
            S = sz(2);
             for s = 1:S
                tValues = zeros(H, 1);
                pValues = zeros(H, 1);
                dfValues = zeros(H, 1);
                cohenDValues = zeros(H, 1);
                shapeName = string(plotOptions.ShapeNames(s));
                
                for hIdx = 1:H
                    vecA = squeeze(logSDA(hIdx, s, :));
                    vecB = squeeze(logSDB(hIdx, s, :));
                    [~, p, ~, stats] = ttest(vecA, vecB);
                    tValues(hIdx) = stats.tstat;
                    pValues(hIdx) = p;
                    dfValues(hIdx) = stats.df;
                    cohenDValues(hIdx) = mean(vecA - vecB) / std(vecA - vecB);
                end
                
                suffix = mode + "_" + shapeName;
                saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, suffix, plotOptions);
                
                titleStr = sprintf("Shape: %s", shapeName);
                plotTestResult(tValues, pValues, H, HDRNum, Amp, titleStr, nameA, nameB, suffix, plotOptions, numSubjects, showTitle);
            end
            
        case "HMS"
            % Data: [H, M, S, P]
            M = sz(2);
            S = sz(3);
            for m = 1:M
                matName = string(plotOptions.MatNames(m));
                for s = 1:S
                    shapeName = string(plotOptions.ShapeNames(s));
                    tValues = zeros(H, 1);
                    pValues = zeros(H, 1);
                    dfValues = zeros(H, 1);
                    cohenDValues = zeros(H, 1);
                    
                    for hIdx = 1:H
                        vecA = squeeze(logSDA(hIdx, m, s, :));
                        vecB = squeeze(logSDB(hIdx, m, s, :));
                        [~, p, ~, stats] = ttest(vecA, vecB);
                        tValues(hIdx) = stats.tstat;
                        pValues(hIdx) = p;
                        dfValues(hIdx) = stats.df;
                        cohenDValues(hIdx) = mean(vecA - vecB) / std(vecA - vecB);
                    end
                    
            titleStr = sprintf("Mat:%s, Shape:%s", matName, shapeName);
                    suffix = mode + "_" + matName + "_" + shapeName;
                    
                    saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, suffix, plotOptions);
                    
                    xLabelStr = "Illumination";
                    plotTestResult(tValues, pValues, H, HDRNum, Amp, titleStr, nameA, nameB, suffix, plotOptions, numSubjects, showTitle, xLabelStr);
                end
            end
            
        case "Total"
            % Data: [1, N]
            tValues = zeros(1, 1);
            pValues = zeros(1, 1);
            dfValues = zeros(1, 1);
            cohenDValues = zeros(1, 1);
            
            vecA = squeeze(logSDA(1, :));
            vecB = squeeze(logSDB(1, :));
            
            % 自由度などはttest内で計算
            [~, p, ~, stats] = ttest(vecA, vecB);
            tValues(1) = stats.tstat;
            pValues(1) = p;
            dfValues(1) = stats.df;
            cohenDValues(1) = mean(vecA - vecB) / std(vecA - vecB);
            
            saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, "Total", plotOptions);
            
            titleStr = "Total (All Conditions Pooled)";
            xLabelStr = ""; 
            % Use "Total" as tick label
            plotTestResult(tValues, pValues, 1, "Total", Amp, titleStr, nameA, nameB, mode, plotOptions, numSubjects, showTitle, xLabelStr);

        case "S"
            % Data: [S, N]
            szS = size(logSDA);
            S = szS(1);
            
            tValues = zeros(S, 1);
            pValues = zeros(S, 1);
            dfValues = zeros(S, 1);
            cohenDValues = zeros(S, 1);
            
            for s = 1:S
                vecA = squeeze(logSDA(s, :));
                vecB = squeeze(logSDB(s, :));
                [~, p, ~, stats] = ttest(vecA, vecB);
                tValues(s) = stats.tstat;
                pValues(s) = p;
                dfValues(s) = stats.df;
                cohenDValues(s) = mean(vecA - vecB) / std(vecA - vecB);
            end
            
            saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, "S", plotOptions);
            
            % X軸ラベル用にShapeNamesをセット
            if isfield(plotOptions, 'ShapeNames')
                plotOptions.HDRNum = plotOptions.ShapeNames; % XTickLabelsとして利用
            end
            
            titleStr = "Shape Comparison";
            xLabelStr = "Shape";
            plotTestResult(tValues, pValues, S, plotOptions.HDRNum, Amp, titleStr, nameA, nameB, mode, plotOptions, numSubjects, showTitle, xLabelStr);
    end
    
    fprintf('----------------------------------------\n\n');
end

function saveStatsCSV(tValues, pValues, dfValues, cohenDValues, nameA, nameB, mode, suffix, plotOptions)
    if isfield(plotOptions, 'ResultDir') && plotOptions.ResultDir ~= ""
        H = length(tValues);
        % テーブル作成
        tbl = table((1:H)', tValues, dfValues, pValues, cohenDValues, ...
            'VariableNames', {'Index', 't_stat', 'df', 'p_value', 'Cohens_d'});
        
        % 丸め処理
        tbl.t_stat = round(tbl.t_stat, 4);
        tbl.p_value = round(tbl.p_value, 4);
        tbl.Cohens_d = round(tbl.Cohens_d, 4);

        csvFileName = sprintf("SubjectSDTest_Stats_%s_vs_%s_%s.csv", nameA, nameB, suffix);
        writetable(tbl, fullfile(plotOptions.ResultDir, csvFileName));
        fprintf('Saved stats CSV: %s\n', csvFileName);
    end
end

function plotTestResult(tValues, pValues, H, HDRNum, Amp, titleStr, nameA, nameB, suffix, plotOptions, numSubjects, showTitle, xLabelStr)
    % t値のプロット作成
    fig = figure('Visible', 'on'); % 確認用に表示
    
    % t値のバープロット (単一オブジェクトで描画し、色を個別指定する)
    b = bar(tValues, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = repmat([0.7, 0.7, 0.7], length(tValues), 1); % デフォルト: グレー
    
    hold on;
    
    % 有意差がある箇所を赤色に変更 (p < 0.05, 0.01, 0.001)
    for i = 1:length(pValues)
        p = pValues(i);
        if p < 0.001
            b.CData(i, :) = [0.4, 0, 0];   % Darkest Red
        elseif p < 0.01
            b.CData(i, :) = [0.7, 0, 0];   % Dark Red
        elseif p < 0.05
            b.CData(i, :) = [1, 0, 0];     % Red
        end
    end
    
    % 基準線 (t=0)
    yline(0, 'k-', 'LineWidth', 1);
    
    % 凡例
    h1 = plot(nan, nan, 's', 'MarkerFaceColor', [1, 0, 0], 'MarkerEdgeColor', 'none');
    h2 = plot(nan, nan, 's', 'MarkerFaceColor', [0.7, 0, 0], 'MarkerEdgeColor', 'none');
    h3 = plot(nan, nan, 's', 'MarkerFaceColor', [0.4, 0, 0], 'MarkerEdgeColor', 'none');
    legend([h1, h2, h3], {'p < 0.05', 'p < 0.01', 'p < 0.001'}, 'Location', 'bestoutside');
    
    hold off;
    
    grid on;
    box on;
    
    % タイトルと軸ラベル
    if showTitle
        titleVal = sprintf('Paired t-test (logSD): %s\n%s vs %s', titleStr, nameA, nameB);
        title(titleVal, 'Interpreter', 'none', 'FontSize', 12 * Amp);
    end
    ylabel('t-value', 'FontSize', 10 * Amp);
    if nargin < 13 || isempty(xLabelStr)
        % Default fallback if not provided (though we update all calls above)
        % Don't label if empty
    else
        xlabel(xLabelStr, 'FontSize', 10 * Amp);
    end
    
    % X軸設定
    xlim([0.5, H + 0.5]);
    xticks(1:H);
    if ~isempty(HDRNum)
        xticklabels(HDRNum);
        xtickangle(45); % Slightly angled for readability
    end
    
    % 保存
    if isfield(plotOptions, 'ResultDir')
        plotFileName = sprintf('SubjectSDTest_%s_vs_%s_%s.jpg', nameA, nameB, suffix);
        plotFullPath = fullfile(plotOptions.ResultDir, plotFileName);
        saveas(fig, plotFullPath);
        fprintf('  -> 検定結果プロットを保存しました: %s\n', plotFileName);
        close(fig);
    else
        warning('ResultDir is not specified in plotOptions. Plot is not saved.');
    end
end
