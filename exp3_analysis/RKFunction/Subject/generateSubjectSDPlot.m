function generateSubjectSDPlot(plotData, plotOptions, ResultDir)
% generateSubjectSDPlot - 被験者間標準偏差（個人差）のプロット
%
% 入力:
%   plotData: プロットデータ (targetA, NameA, [targetB, NameB])
%   plotOptions: オプション (Mode, Amp, Property, MatNames, ShapeNames, HDRNum 等)
%   ResultDir: 保存先ディレクトリ

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

    % SDデータの計算 (共通ロジック)
    sdDataA = calculateSubjectSD(dataA, mode);
    
    if isCompare
        sdDataB = calculateSubjectSD(dataB, mode);
    end
    
    % プロット処理
    switch mode
        case "H"
            % sdData: [H]
            if isCompare
                plotCompareSD(sdDataA, sdDataB, nameA, nameB, "All Conditions", setName, property, "H", ...
                    ResultDir, HDRNum, amp);
            else
                plotSingleSD(sdDataA, "All Conditions", setName, property, "H", ...
                    ResultDir, HDRNum, amp);
            end
            
        case "HM"
            % sdData: [H, M]
            % 材質ごとにまとめてプロットするか、比較の場合は材質ごとxデータセットごとは複雑になるので
            % HMモードの場合は「材質」を系列にするのが標準だが、比較の場合どうするか？
            % 要望：「2つのデータに対して同じグラフ内に標準偏差をプロット」
            % HMモード比較: 材質mについて、AとBをプロット -> 材質数分グラフを作るのが自然
            
            matCount = size(sdDataA, 2);
            for m = 1:matCount
                currentSDA = squeeze(sdDataA(:, m));
                matName = string(MatNames(m));
                titleStr = sprintf("Material: %s", matName);
                suffix = "HM_" + matName;
                
                if isCompare
                    currentSDB = squeeze(sdDataB(:, m));
                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ...
                        ResultDir, HDRNum, amp);
                else
                     % Singleの場合はまとめてプロット（既存仕様：系列=材質）
                     % ※ここで分岐：SingleのHMは「系列=材質」で1枚の図だったが、
                     % 比較（Compare）の実装に合わせて「材質ごとに別図」にするか、
                     % それともCompareのときだけ別図にするか。
                     % ここではCompareのときだけ「材質ごとに別図」にする（見やすさのため）
                     % しかしループの外でまとめてプロットする既存コード（Single）は維持したい
                end
            end
            
            % Singleの場合（既存の動作）
            if ~isCompare
                 plotMultiLineSD(sdDataA, MatNames, "Material Comparison", setName, property, "HM", ...
                    ResultDir, HDRNum, amp);
            end
            
        case "HS"
            % sdData: [H, S]
            % 形状ごとにループ (Compare)
            if isCompare
                shapeCount = size(sdDataA, 2);
                for s = 1:shapeCount
                    currentSDA = squeeze(sdDataA(:, s));
                    currentSDB = squeeze(sdDataB(:, s));
                    shapeName = string(ShapeNames(s));
                    titleStr = sprintf("Shape: %s", shapeName);
                    suffix = "HS_" + shapeName;
                    
                    plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ...
                        ResultDir, HDRNum, amp);
                end
            else
                % Single
                plotMultiLineSD(sdDataA, ShapeNames, "Shape Comparison", setName, property, "HS", ...
                    ResultDir, HDRNum, amp);
            end
            
        case "HMS"
            % sdData: [H, M, S]
            % 材質ごとにループ
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
                        plotCompareSD(currentSDA, currentSDB, nameA, nameB, titleStr, setName, property, suffix, ...
                            ResultDir, HDRNum, amp);
                    else
                         % Singleの場合は HMS_Material ごとに 形状を系列にしてプロット（既存）
                    end
                end
                
                % Single (HMS) 既存ロジック：材質ごとにまとめてプロット
                if ~isCompare
                    currentSDA_Mat = squeeze(sdDataA(:, m, :)); % [H, S]
                    suffix = "HMS_" + matName;
                    titleStr = sprintf("Material: %s", matName);
                    plotMultiLineSD(currentSDA_Mat, ShapeNames, titleStr, setName, property, suffix, ...
                        ResultDir, HDRNum, amp);
                end
            end
    end
end

% --- ヘルパー関数 ---

function sdData = calculateSubjectSD(data, mode)
    % Row_HMSPT: [H, M, S, P, T]
    
    % 1. 試行(5)を平均化 -> [H, M, S, P]
    trialMeanData = mean(data, 5, 'omitnan');
    
    % 2. Modeに応じて条件を平均化し、被験者間SD(4)を計算
    switch mode
        case "H"
            % [H, 1, 1, P] -> [H, P] -> SD -> [H]
            condMeanData = mean(trialMeanData, [2, 3], 'omitnan');
            sdData = std(squeeze(condMeanData), 0, 2, 'omitnan'); 
            
        case "HM"
            % [H, M, 1, P] -> SD(4) -> [H, M]
            condMeanData = mean(trialMeanData, 3, 'omitnan');
            sdData = std(condMeanData, 0, 4, 'omitnan');
            
        case "HS"
            % [H, 1, S, P] -> SD(4) -> [H, 1, S] -> [H, S]
            condMeanData = mean(trialMeanData, 2, 'omitnan');
            tmpSD = std(condMeanData, 0, 4, 'omitnan');
            sdData = squeeze(tmpSD);
            
        case "HMS"
            % [H, M, S, P] -> SD(4) -> [H, M, S]
            sdData = std(trialMeanData, 0, 4, 'omitnan');
    end
end

function plotCompareSD(sdDataA, sdDataB, nameA, nameB, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
    % A vs B の比較プロット (2本線)
    fig = figure('Visible', 'off');
    hold on;
    
    % A: Red
    plot(sdDataA, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', nameA);
    % B: Blue
    plot(sdDataB, '-bo', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', 'DisplayName', nameB);
    
    hold off;
    
    setupAxes(gca, titleStr, setName, property, HDRNum, amp);
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 10*amp);
    
    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotSingleSD(sdData, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
    % 単一データのプロット (1本線: Red)
    fig = figure('Visible', 'off');
    plot(sdData, '-ro', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    
    setupAxes(gca, titleStr, setName, property, HDRNum, amp);
    savePlot(fig, setName, property, suffix, ResultDir);
end

function plotMultiLineSD(sdData, legendLabels, titleStr, setName, property, suffix, ResultDir, HDRNum, amp)
    % 複数系列のプロット (Singleデータ用, カラフル)
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
    legend('Location', 'best', 'Interpreter', 'none', 'FontSize', 10*amp);
    
    savePlot(fig, setName, property, suffix, ResultDir);
end

function setupAxes(ax, titleStr, setName, property, HDRNum, amp)
    grid(ax, 'on');
    box(ax, 'on');
    
    title(ax, sprintf('Between-Subject SD: %s\n%s - %s', titleStr, setName, property), ...
        'Interpreter', 'none', 'FontSize', 12*amp);
    xlabel(ax, 'Illumination', 'Interpreter', 'none', 'FontSize', 10*amp);
    ylabel(ax, 'Standard Deviation (Between-Subject)', 'Interpreter', 'none', 'FontSize', 10*amp);
    
    set(ax, 'XTick', 1:length(HDRNum));
    set(ax, 'XTickLabel', HDRNum);
    xtickangle(ax, 90);
    xlim(ax, [0.5, length(HDRNum) + 0.5]);
    
    % Y軸範囲の自動調整 (下限0)
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
