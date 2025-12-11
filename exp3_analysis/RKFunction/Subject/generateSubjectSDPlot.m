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

    fprintf('被験者間SD解析を実行中: Mode=%s, Compare=%d\n', mode, isCompare);

    % SDデータの計算 (共通ロジック: [H, P] or [H, M, P] etc.)
    sdDataA_raw = calculateSubjectSD(dataA, mode);
    % プロット用に被験者次元を平均化
    sdDataA = mean(sdDataA_raw, ndims(sdDataA_raw), 'omitnan');

    if isCompare
        sdDataB_raw = calculateSubjectSD(dataB, mode);
        sdDataB = mean(sdDataB_raw, ndims(sdDataB_raw), 'omitnan');
    end

    % プロット処理
    switch mode
        case "H"
            % sdData: [H]
            if isCompare
                plotCompareSD(sdDataA, sdDataB, nameA, nameB, "All Conditions", setName, property, "H", ResultDir, HDRNum, amp);
            else
                plotSingleSD(sdDataA, "All Conditions", setName, property, "H", ResultDir, HDRNum, amp);
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
                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp);
                else
                    % Singleの場合は既存仕様通り、ループ終了後にまとめてプロットする
                    % ここでは何もしない
                end
            end

            % Singleの場合（既存の動作）: 材質ごとに1つのグラフにまとめる
            if ~isCompare
                plotMultiLineSD(sdDataA, MatNames, "Material Comparison", setName, property, "HM", ResultDir, HDRNum, amp);
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

                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp);
                end
            else
                % Singleの場合: 形状ごとに1つのグラフにまとめる
                plotMultiLineSD(sdDataA, ShapeNames, "Shape Comparison", setName, property, "HS", ResultDir, HDRNum, amp);
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
                        plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp);
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
                    plotMultiLineSD(currentSDA_Mat, ShapeNames, titleStr, setName, property, suffix, ResultDir, HDRNum, amp);
                end
            end
    end
end

% --- ヘルパー関数 ---

function plotCompareSD(sdDataA, sdDataB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
    % A vs B の比較プロット(2本線)
    fig = figure('Visible', 'off');
    hold on;

    % A: Red
    plot(sdDataA, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', nameA);
    % B: Blue
    plot(sdDataB, '-bo', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'DisplayName', nameB);

    hold off;

    setupAxes(gca, titleStr, setName, property, HDRNum, amp);
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 10 * amp);

    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotSingleSD(sdData, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
    % 単一データのプロット(1本線: Red)
    fig = figure('Visible', 'off');
    plot(sdData, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');

    setupAxes(gca, titleStr, setName, property, HDRNum, amp);
    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotMultiLineSD(sdData, legendLabels, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
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

    setupAxes(gca, titleStr, setName, property, HDRNum, amp);
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 10 * amp);

    savePlot(fig, setName, property, suffix, ResultDir);
end

function setupAxes(ax, titleStr, setName, property, HDRNum, amp)
    grid(ax, 'on');
    box(ax, 'on');

    title(ax, sprintf('Between-Subject SD: %s\n%s - %s', titleStr, setName, property), ...
          'Interpreter', 'none', 'FontSize', 12 * amp);
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
