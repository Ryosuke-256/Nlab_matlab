function performRawDataTtest(rawDataA, rawDataB, nameA, nameB, options)
% performRawDataTtest - 生データ(試行平均)に対する対応のあるt検定を行い、結果をプロットします。
%
% [INPUTS]
%   rawDataA - (N-D array) [H, M, S, P, T]
%   rawDataB - (N-D array)
%   nameA, nameB - データ名
%   options.Mode - "H", "HM", "HS", "HMS"
%   options.SubNames - 条件名のリスト (Modeに応じて変動)
%       Mode="H": [] or ["All"]
%       Mode="HS": ShapeNames
%       Mode="HM": MatNames
%       Mode="HMS": Mat_Shape Names (combined)

arguments
    rawDataA
    rawDataB
    nameA string
    nameB string
    options.Mode string = "H"
    options.Amp double = 1.0
    options.ResultDir string = ""
    options.SubNames (1,:) string = []
    options.XLabel string = "Illumination Index"
    options.XTickLabels (1,:) string = []
end

%% 1. データの整合性チェック
if ~isequal(size(rawDataA), size(rawDataB))
    error('DataA and DataB must have the same size.');
end

%% 2. データの前処理
% データ形式は [H, M, S, P, T] を想定
szA = size(rawDataA);
szB = size(rawDataB);

H=szA(1); M=szA(2); S=szA(3); P=szA(4); T=szA(5);
% numTotalSamples = P * T; % OLD: 試行もサンプルとしていた

% [H, M, S, P] に変形 (試行平均)
% 偽反復を防ぐため、試行回数(T)については平均し、被験者(P)のみをサンプル状の単位として扱います。
% ただし、Modeによっては MやS もサンプル次元(3次元目以降)に展開されるため、
% 最終的な自由度は Mode の集約設定に依存します (例: H Modeなら N = M*S*P)。

meanDataA = mean(rawDataA, 5, 'omitnan'); % [H, M, S, P, 1]
meanDataB = mean(rawDataB, 5, 'omitnan');

sampleDataA = meanDataA; % [H, M, S, P] (dim5 is singleton)
sampleDataB = meanDataB;

% Modeに応じた整形
% ユーザー要望により、ターゲット以外の次元は平均し、サンプル次元は被験者(P)のみとする。
% N = P (自由度 P-1)
switch options.Mode
    case "H"
        % [H, M, S, P] -> Mean(M,S) -> [H, 1, P]
        tmpA = mean(sampleDataA, [2, 3], 'omitnan'); % [H, 1, 1, P]
        tmpB = mean(sampleDataB, [2, 3], 'omitnan');
        
        procDataA = reshape(tmpA, H, 1, []); % [H, 1, P]
        procDataB = reshape(tmpB, H, 1, []);
        
        numSubConds = 1;
        if isempty(options.SubNames), subNames = "All"; else, subNames = options.SubNames; end

    case "HM"
        % [H, M, S, P] -> Mean(S) -> [H, M, P]
        tmpA = mean(sampleDataA, 3, 'omitnan'); % [H, M, 1, P]
        tmpB = mean(sampleDataB, 3, 'omitnan');
        
        procDataA = reshape(tmpA, H, M, []);
        procDataB = reshape(tmpB, H, M, []);
        
        numSubConds = size(procDataA, 2);
        subNames = options.SubNames;

    case "HS"
        % [H, M, S, P] -> Permute[H, S, M, P] -> Mean(M) -> [H, S, P]
        tmpA_p = permute(sampleDataA, [1, 3, 2, 4]); % [H, S, M, P]
        tmpB_p = permute(sampleDataB, [1, 3, 2, 4]);
        
        tmpA = mean(tmpA_p, 3, 'omitnan'); % [H, S, 1, P]
        tmpB = mean(tmpB_p, 3, 'omitnan');
        
        procDataA = reshape(tmpA, H, S, []);
        procDataB = reshape(tmpB, H, S, []);
        
        numSubConds = size(procDataA, 2);
        subNames = options.SubNames;

    case "HMS"
        % [H, M, S, P] -> [H, M*S, P]
        % 平均化なし (全条件展開)
        procDataA = reshape(sampleDataA, H, M*S, []);
        procDataB = reshape(sampleDataB, H, M*S, []);
        
        numSubConds = M*S;
        subNames = options.SubNames;
        
    case "Total"
        % [H, M, S, P] -> Mean(H,M,S) -> [1, 1, P]
        tmpA = mean(sampleDataA, [1, 2, 3], 'omitnan'); % [1, 1, 1, P]
        tmpB = mean(sampleDataB, [1, 2, 3], 'omitnan');
        
        procDataA = reshape(tmpA, 1, 1, []);
        procDataB = reshape(tmpB, 1, 1, []);
        
        numSubConds = 1;
        if isempty(options.SubNames), subNames = "Total"; else, subNames = options.SubNames; end
        
        if options.XLabel == "Illumination Index", options.XLabel = "Total"; end

    case "S"
        % [H, M, S, P] -> Permute[S, H, M, P] -> Mean(H,M) -> [S, 1, P]
        tmpA_p = permute(sampleDataA, [3, 1, 2, 4]); % [S, H, M, P]
        tmpB_p = permute(sampleDataB, [3, 1, 2, 4]);
        
        tmpA = mean(tmpA_p, [2, 3], 'omitnan'); % [S, 1, 1, P]
        tmpB = mean(tmpB_p, [2, 3], 'omitnan');
        
        procDataA = reshape(tmpA, S, 1, []);
        procDataB = reshape(tmpB, S, 1, []);
        
        numSubConds = 1;
        if isempty(options.SubNames), subNames = "Shape"; else, subNames = options.SubNames; end
        
        if options.XLabel == "Illumination Index", options.XLabel = "Shape Index"; end
        
    otherwise
        error('Unsupported Mode: %s', options.Mode);
end

% SubNamesの数チェック
if length(subNames) ~= numSubConds
    warning('SubNames count (%d) does not match data dimension (%d). Generating dummy names.', length(subNames), numSubConds);
    subNames = "Cond" + (1:numSubConds);
end

numSubjects = size(procDataA, 3);
H_dim = size(procDataA, 1);

%% 3. ループ処理 (条件ごとにプロット)
for k = 1:numSubConds
    currentName = subNames(k);
    
    sliceA = reshape(procDataA(:, k, :), H_dim, numSubjects);
    sliceB = reshape(procDataB(:, k, :), H_dim, numSubjects);
    
    % t検定 (各Hについて)
    pValues = zeros(H_dim, 1);
    tValues = zeros(H_dim, 1);
    dfValues = zeros(H_dim, 1);
    cohenDValues = zeros(H_dim, 1);
    
    fprintf('\n--- T-test Results for Condition: %s ---\n', currentName);
    % Header update to include Effect Size
    fprintf('Idx |   t-value |   p-value |      df | Cohen''s d | Sig.\n');
    fprintf('------------------------------------------------------------\n');
    
    for i = 1:H_dim
        valA = sliceA(i, :)';
        valB = sliceB(i, :)';
        
        diffSq = (valA - valB).^2;
        
        if std(valA-valB) == 0
            tValues(i) = 0;
            pValues(i) = 1;
            dfValues(i) = numSubjects - 1;
            cohenDValues(i) = 0;
        else
            [~, p, ~, stats] = ttest(valA, valB);
            pValues(i) = p;
            tValues(i) = stats.tstat;
            dfValues(i) = stats.df;
            
            % Cohen's d (Paired) calculation
            % d = MeanDiff / StdDiff
            meanDiff = mean(valA - valB);
            stdDiff = std(valA - valB);
            cohenDValues(i) = meanDiff / stdDiff;
        end
        
        sigMark = "";
        if pValues(i) < 0.001, sigMark = "***";
        elseif pValues(i) < 0.01, sigMark = "**";
        elseif pValues(i) < 0.05, sigMark = "*";
        end
        
        fprintf('%3d | %9.4f | %9.4f | %7d | %9.4f | %s\n', ...
            i, tValues(i), pValues(i), dfValues(i), cohenDValues(i), sigMark);
    end
    
    % --- 結果保存 (CSV) ---
    if options.ResultDir ~= ""
        % テーブル作成
        tbl = table((1:H_dim)', tValues, dfValues, pValues, cohenDValues, ...
            'VariableNames', {'Index', 't_stat', 'df', 'p_value', 'Cohens_d'});
        
        % 丸め処理 (Index以外)
        tbl.t_stat = round(tbl.t_stat, 4);
        tbl.p_value = round(tbl.p_value, 4);
        tbl.Cohens_d = round(tbl.Cohens_d, 4);

        csvFileName = sprintf("RawDataTtest_Stats_%s_vs_%s_%s_%s.csv", nameA, nameB, options.Mode, currentName);
        writetable(tbl, fullfile(options.ResultDir, csvFileName));
        fprintf('Saved t-test stats: %s\n', csvFileName);
    end

    % プロットと保存
    plotRawDataTtestResult(tValues, pValues, nameA, nameB, options, numSubjects, currentName);
end

end

function plotRawDataTtestResult(tValues, pValues, nameA, nameB, options, numSubjects, subName)
    
    fig = figure('Visible', 'off', 'Position', [100, 100, 1000, 500]);
    
    % バープロット
    b = bar(tValues, 'FaceColor', 'flat', 'EdgeColor', 'none');
    b.CData = repmat([0.7, 0.7, 0.7], length(tValues), 1); % デフォルト: グレー
    
    hold on;
    
    % 色分け
    for i = 1:length(pValues)
        p = pValues(i);
        if p < 0.001
            b.CData(i, :) = [0.4, 0, 0];   
        elseif p < 0.01
            b.CData(i, :) = [0.7, 0, 0];   
        elseif p < 0.05
            b.CData(i, :) = [1, 0, 0];     
        end
    end

    yline(0, 'k-', 'LineWidth', 1);
    
    % 臨界値
    df = numSubjects - 1;
    if exist('tinv', 'file')
        tcrit = tinv(1 - 0.01/2, df);
        yline(tcrit, 'b--', 'LineWidth', 0.5);
        yline(-tcrit, 'b--', 'LineWidth', 0.5);
    end

    title(sprintf('%s vs %s\nMode: %s, Cond: %s', nameA, nameB, options.Mode, subName), 'Interpreter', 'none');
    ylabel('t-value');
    xlabel(options.XLabel);
    xlim([0.5, length(tValues)+0.5]);
    
    % XTickLabelsの設定
    if ~isempty(options.XTickLabels)
        xticks(1:length(tValues));
        xticklabels(options.XTickLabels);
    end
    
    grid on;
    box on;
    
    % 凡例
    h1 = plot(nan, nan, 's', 'MarkerFaceColor', [1, 0, 0], 'MarkerEdgeColor', 'none');
    h2 = plot(nan, nan, 's', 'MarkerFaceColor', [0.7, 0, 0], 'MarkerEdgeColor', 'none');
    h3 = plot(nan, nan, 's', 'MarkerFaceColor', [0.4, 0, 0], 'MarkerEdgeColor', 'none');
    legend([h1, h2, h3], {'p < 0.05', 'p < 0.01', 'p < 0.001'}, 'Location', 'bestoutside');
    
    hold off;
    
    % 結果保存
    if options.ResultDir ~= ""
        saveFileName = sprintf("RawDataTtest_%s_vs_%s_%s_%s.png", nameA, nameB, options.Mode, subName);
        saveas(fig, fullfile(options.ResultDir, saveFileName));
        fprintf('Saved t-test plot: %s\n', saveFileName);
    end
    close(fig);
end
