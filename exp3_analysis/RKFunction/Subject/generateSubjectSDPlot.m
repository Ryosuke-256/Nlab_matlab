function generateSubjectSDPlot(plotData, plotOptions, ResultDir)
    % generateSubjectSDPlot - 被験者間標準偏差（個人差）のプロット
    %
    % 入力:
    %   plotData    : プロットデータ(targetA, NameA, [targetB, NameB])
    %   plotOptions : オプション(Mode, Amp, Property, MatNames, ShapeNames, HDRNum 等)
    %   ResultDir   : 保存先ディレクトリ

    % データの取得とモード判定
    dataA = plotData.targetA;
    nameA = plotData.NameA;

    if isfield(plotData, 'targetB') && ~isempty(plotData.targetB)
        isCompare = true;
        dataB = plotData.targetB;
        nameB = plotData.NameB;
        setName = sprintf("%svs%s", nameA, nameB);
    else
        isCompare = false;
        setName = nameA;
    end

    mode = plotOptions.Mode;
    property = plotOptions.Property;
    amp = plotOptions.Amp;

    % オプションから名前リストを展開
    MatNames = plotOptions.MatNames;
    ShapeNames = plotOptions.ShapeNames;
    HDRNum = plotOptions.HDRNum;

    % ShowTitleオプションのデフォルト設定
    if ~isfield(plotOptions, 'ShowTitle')
        plotOptions.ShowTitle = true;
    end
    showTitle = plotOptions.ShowTitle;

    fprintf('被験者間SD解析を実行中: Mode=%s, Compare=%d\n', mode, isCompare);

    % SDデータの計算 (共通ロジック: [H, P] or [H, M, P] etc.)
    sdDataA_raw = calculateSubjectSD(dataA, mode);
    % プロット用に被験者次元を平均化
    sdDataA = mean(sdDataA_raw, ndims(sdDataA_raw), 'omitnan');

    pValuesData = [];
    if isCompare
        sdDataB_raw = calculateSubjectSD(dataB, mode);
        sdDataB = mean(sdDataB_raw, ndims(sdDataB_raw), 'omitnan');
        
        % --- 統計検定 (SubjectSDTestと同じロジック) ---
        % calculateSubjectSD(..., true) でプールされたデータを取得 (Last Dim = Samples)
        sdA_pool = calculateSubjectSD(dataA, mode, true);
        sdB_pool = calculateSubjectSD(dataB, mode, true);
        
        % 対数変換
        logA = log(sdA_pool);
        logB = log(sdB_pool);
        
        % t検定 (最後の次元に対して実行)
        pValuesData = runPairwiseTtest(logA, logB);
    end

    % プロット処理
    switch mode
        case "H"
            % sdData: [H]
            if isCompare
                plotCompareSD(sdDataA, sdDataB, nameA, nameB, "All Conditions", setName, property, "H", ResultDir, HDRNum, amp, showTitle, pValuesData);
            else
                plotSingleSD(sdDataA, "All Conditions", setName, property, "H", ResultDir, HDRNum, amp, showTitle);
            end

        case "HM"
            % sdData: [H, M]
            % HMモード比較: 材質mについて、AとBをプロット -> 材質数分グラフを作る
            matCount = size(sdDataA, 2);
            for m = 1:matCount
                currentSDA = squeeze(sdDataA(:, m));
                matName = string(MatNames(m));
                titleStr = sprintf("Material: %s", matName);
                suffix = "HM_" + matName;

                if isCompare
                    currentSDB = squeeze(sdDataB(:, m));
                    currentP = [];
                    if ~isempty(pValuesData), currentP = pValuesData(:, m); end
                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle, currentP);
                else
                    % Singleの場合は既存仕様通り、ループ終了後にまとめてプロットする
                    % ここでは何もしない
                end
            end

            % Singleの場合（既存の動作）: 材質ごとに1つのグラフにまとめる
            if ~isCompare
                plotMultiLineSD(sdDataA, MatNames, "Material Comparison", setName, property, "HM", ResultDir, HDRNum, amp, showTitle);
            end

        case "HS"
            % sdData: [H, S]
            if isCompare
                % 形状ごとにループ(Compare)
                shapeCount = size(sdDataA, 2);
                for s = 1:shapeCount
                    currentSDA = squeeze(sdDataA(:, s));
                    currentSDB = squeeze(sdDataB(:, s));
                    shapeName = string(ShapeNames(s));
                    titleStr = sprintf("Shape: %s", shapeName);
                    suffix = "HS_" + shapeName;

                    currentP = [];
                    if ~isempty(pValuesData), currentP = pValuesData(:, s); end
                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle, currentP);
                end
            else
                % Singleの場合: 形状ごとに1つのグラフにまとめる
                plotMultiLineSD(sdDataA, ShapeNames, "Shape Comparison", setName, property, "HS", ResultDir, HDRNum, amp, showTitle);
            end

        case "HMS"
            % sdData: [H, M, S]
            matCount = size(sdDataA, 2);
            shapeCount = size(sdDataA, 3);

            for m = 1:matCount
                matName = string(MatNames(m));
                
                % 形状ごとにループしてプロット
                for s = 1:shapeCount
                    currentSDA = squeeze(sdDataA(:, m, s));
                    shapeName = string(ShapeNames(s));
                    titleStr = sprintf("Material: %s, Shape: %s", matName, shapeName);
                    suffix = sprintf("HMS_%s_%s", matName, shapeName);

                    if isCompare
                        currentSDB = squeeze(sdDataB(:, m, s));
                        currentP = [];
                        if ~isempty(pValuesData), currentP = squeeze(pValuesData(:, m, s)); end
                        plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle, currentP);
                    else
                        % Singleの場合は HMS_Material ごとに形状を系列にしてプロット（ループ後に処理）
                    end
                end

                % Single(HMS) 既存ロジック：材質ごとにまとめてプロット（形状比較）
                if ~isCompare
                    currentSDA_Mat = squeeze(sdDataA(:, m, :));
                    % [H, S]
                    suffix = "HMS_" + matName;
                    titleStr = sprintf("Material: %s", matName);
                    plotMultiLineSD(currentSDA_Mat, ShapeNames, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle);
                end
            end
    end
end

% --- ヘルパー関数 ---

function pValues = runPairwiseTtest(dataA, dataB)
    % 最後の次元（標本次元）に対してペアt検定を行う
    % 返り値は [H, (M, S)] の形（最後の次元が消えたもの）
    dim = ndims(dataA);
    [~, p] = ttest(dataA, dataB, 'Dim', dim);
    % pはサイズがdataAと同じで、dim次元が1になっているのでsqueezeする
    % ただしH次元(dim=1)が消えないように注意が必要だが、Hは通常>1
    % squeezeは1の次元をすべて消すので、Hが1の場合などが怖いが、
    % 今回のデータ構造的に [H, ...] なので、squeezeしてOK
    % ただし [H, 1] になってしまうと Hが消える？ -> H次元は残したい。
    
    % 明示的に最後の次元を削除
    sz = size(p);
    if length(sz) == 2 && sz(2) == 1
        % [H, 1] -> [H, 1] (Do nothing to keep column vector)
        pValues = p;
    else
        pValues = squeeze(p);
    end
end

function plotCompareSD(sdDataA, sdDataB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle, pValues)
    % A vs B の比較プロット(2本線)
    fig = figure('Visible', 'off');
    hold on;

    % A: Red
    hA = plot(sdDataA, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', nameA);
    % B: Blue
    hB = plot(sdDataB, '-bo', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'DisplayName', nameB);

    % 凡例用ハンドルリスト
    handles = [hA, hB];
    labels = {nameA, nameB};

    % 有意差マーカーの表示
    if exist('pValues', 'var') && ~isempty(pValues)
        % Y軸の上限を少し上げてマーカー用スペースを確保
        allData = [sdDataA(:); sdDataB(:)];
        maxY = max(allData, [], 'all', 'omitnan');
        if isnan(maxY), maxY = 1; end
        
        % マーカーを描画するためのY位置 (プロット位置より少し上)
        offset = maxY * 0.05; 
        
        hasSig = false;
        for i = 1:length(pValues)
            p = pValues(i);
            txt = "";
            if p < 0.001
                txt = "***";
                hasSig = true;
            elseif p < 0.01
                txt = "**";
                hasSig = true;
            elseif p < 0.05
                txt = "*";
                hasSig = true;
            end
            
            if txt ~= ""
                % AとBの高い方を取得
                yPos = max(sdDataA(i), sdDataB(i)) + offset;
                text(i, yPos, txt, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 12, 'Color', 'k');
            end
        end
        
        % 凡例に注釈を追加 (ダミープロット)
        if hasSig
            hDummy1 = plot(nan, nan, 'LineStyle', 'none', 'Marker', 'none', 'Color', 'none', 'DisplayName', '***: p < 0.001');
            hDummy2 = plot(nan, nan, 'LineStyle', 'none', 'Marker', 'none', 'Color', 'none', 'DisplayName', '**: p < 0.01');
            hDummy3 = plot(nan, nan, 'LineStyle', 'none', 'Marker', 'none', 'Color', 'none', 'DisplayName', '*: p < 0.05');
            
            % 配列結合時に次元を合わせる
            handles = [handles, hDummy1, hDummy2, hDummy3];
            labels = [labels, {'***: p < 0.001', '**: p < 0.01', '*: p < 0.05'}];
        end
    end

    hold off;

    setupAxes(gca, titleStr, setName, property, HDRNum, amp, showTitle);
    
    % YLimitの再調整 (マーカーが見切れないように)
    ax = gca;
    currentYLim = ylim(ax);
    ylim(ax, [currentYLim(1), currentYLim(2) * 1.05]); % setupAxesで既に1.1倍されているが、さらに微調整

    legend(handles, labels, 'Location', 'bestoutside', 'Interpreter', 'none', 'FontSize', 10 * amp);

    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotSingleSD(sdData, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle)
    % 単一データのプロット(1本線: Red)
    fig = figure('Visible', 'off');
    plot(sdData, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');

    setupAxes(gca, titleStr, setName, property, HDRNum, amp, showTitle);
    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotMultiLineSD(sdData, legendLabels, titleStr, setName, property, suffix, ResultDir, HDRNum, amp, showTitle)
    % 複数系列のプロット(Singleデータ用, カラフル)
    fig = figure('Visible', 'off');
    hold on;
    numSeries = size(sdData, 2);
    colors = lines(numSeries);

    for i = 1:numSeries
        plot(sdData(:, i), '-o', 'Color', colors(i, :), ...
             'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', string(legendLabels{i}));
    end
    hold off;

    setupAxes(gca, titleStr, setName, property, HDRNum, amp, showTitle);
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 10 * amp);

    savePlot(fig, setName, property, suffix, ResultDir);
end

function setupAxes(ax, titleStr, setName, property, HDRNum, amp, showTitle)
    grid(ax, 'on');
    box(ax, 'on');

    if showTitle
        title(ax, sprintf('Between-Subject SD: %s\n%s - %s', titleStr, setName, property), ...
              'Interpreter', 'none', 'FontSize', 12 * amp);
    end
    xlabel(ax, 'Illumination', 'Interpreter', 'none', 'FontSize', 10 * amp);
    ylabel(ax, 'Standard Deviation (Within-Subject)', 'Interpreter', 'none', 'FontSize', 10 * amp);

    set(ax, 'XTick', 1:length(HDRNum));
    set(ax, 'XTickLabel', HDRNum);
    xtickangle(ax, 90);
    xlim(ax, [0.5, length(HDRNum) + 0.5]);

    % Y軸範囲の自動調整(下限0)
    currentYLim = ylim(ax);
    ylim(ax, [0, currentYLim(2) * 1.1]);
end

function savePlot(fig, setName, property, suffix, ResultDir)
    plotFileName = sprintf('SubjectSD_%s_%s_%s.jpg', setName, property, suffix);
    plotFullPath = fullfile(ResultDir, plotFileName);
    saveas(fig, plotFullPath);
    close(fig);
    fprintf('  -> プロットを保存しました: %s\n', plotFileName);
end
