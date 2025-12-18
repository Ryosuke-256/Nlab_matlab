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
end

%% 1. データの整合性チェック
if ~isequal(size(rawDataA), size(rawDataB))
    error('DataA and DataB must have the same size.');
end

%% 2. データの前処理
% データ形式は [H, M, S, P, T] を想定
% ユーザー要望により、試行(Dim5)を平均せず、被験者(Dim4)と統合し、
% [H, M, S, P*T] という形にしてサンプル数を増やす。

szA = size(rawDataA);
szB = size(rawDataB);

% Dim4とDim5を統合して最後の次元にする
% reshape用に次元サイズ計算
H=szA(1); M=szA(2); S=szA(3); P=szA(4); T=szA(5);
numTotalSamples = P * T;

% [H, M, S, P*T] に変形
sampleDataA = reshape(rawDataA, H, M, S, numTotalSamples);
sampleDataB = reshape(rawDataB, H, M, S, numTotalSamples);

% Modeに応じた整形: [H, NumSubConds, NumSamples] に中身を統一する
% H次元(dim1)は常に30個の要素として維持し、横軸に使用する。

switch options.Mode
    case "H"
        % [H, M, S, Samples] -> [H, Samples] (M, S 平均)
        % Dim2(M)とDim3(S)を平均化して潰す
        % mean(..., 2) -> [H, 1, S, Samples] -> mean(..., 3) -> [H, 1, 1, Samples]
        tmpA = squeeze(mean(mean(sampleDataA, 3, 'omitnan'), 2, 'omitnan')); % [H, Samples]
        tmpB = squeeze(mean(mean(sampleDataB, 3, 'omitnan'), 2, 'omitnan')); 
        
        % [H, 1, Samples] に変形
        numSubConds = 1;
        procDataA = reshape(tmpA, size(tmpA, 1), 1, []);
        procDataB = reshape(tmpB, size(tmpB, 1), 1, []);
        
        if isempty(options.SubNames), subNames = "All"; else, subNames = options.SubNames; end

    case "HM"
        % [H, M, S, Samples] -> [H, M, Samples] (S 平均)
        tmpA = squeeze(mean(sampleDataA, 3, 'omitnan')); % [H, M, Samples]
        tmpB = squeeze(mean(sampleDataB, 3, 'omitnan'));
        
        % [H, M, Samples]
        procDataA = tmpA;
        procDataB = tmpB;
        numSubConds = size(procDataA, 2);
        subNames = options.SubNames;

    case "HS"
        % [H, M, S, Samples] -> [H, S, Samples] (M 平均)
        tmpA = mean(sampleDataA, 2, 'omitnan'); % [H, 1, S, Samples]
        tmpB = mean(sampleDataB, 2, 'omitnan');
        
        % [H, S, Samples] にsqueeze
        tmpA = squeeze(tmpA); 
        tmpB = squeeze(tmpB);
        
        procDataA = tmpA;
        procDataB = tmpB;
        numSubConds = size(procDataA, 2);
        subNames = options.SubNames;

    case "HMS"
        % [H, M, S, Samples]
        % [H, M*S, Samples] に変形
        
        procDataA = reshape(sampleDataA, H, M*S, numTotalSamples);
        procDataB = reshape(sampleDataB, H, M*S, numTotalSamples);
        
        numSubConds = M*S;
        subNames = options.SubNames;
        
    otherwise
        error('Unsupported Mode: %s', options.Mode);
end

% SubNamesの数チェック
if length(subNames) ~= numSubConds
    % 数が合わない場合はダミー生成
    warning('SubNames count (%d) does not match data dimension (%d). Generating dummy names.', length(subNames), numSubConds);
    subNames = "Cond" + (1:numSubConds);
end

numSubjects = size(procDataA, 3);
H_dim = size(procDataA, 1);

%% 3. ループ処理 (条件ごとにプロット)
for k = 1:numSubConds
    currentName = subNames(k);
    
    % [H, P] スライスを抽出
    % squeezeで [H, P] になるはずだが、P=1の場合など注意。
    % reshapeで確実に [H, P] にする
    sliceA = reshape(procDataA(:, k, :), H_dim, numSubjects);
    sliceB = reshape(procDataB(:, k, :), H_dim, numSubjects);
    
    % t検定 (各Hについて)
    pValues = zeros(H_dim, 1);
    tValues = zeros(H_dim, 1);
    
    fprintf('\n--- T-test Results for Condition: %s ---\n', currentName);
    fprintf('Idx |   t-value |   p-value | Sig.\n');
    fprintf('------------------------------------\n');
    
    for i = 1:H_dim
        valA = sliceA(i, :)';
        valB = sliceB(i, :)';
        
        % 差がない場合はt=0, p=1
        if std(valA-valB) == 0
            tValues(i) = 0;
            pValues(i) = 1;
            stats.tstat = 0;
        else
            [~, p, ~, stats] = ttest(valA, valB);
            pValues(i) = p;
            tValues(i) = stats.tstat;
        end
        
        % 有意性マーク
        sigMark = "";
        if pValues(i) < 0.001, sigMark = "***";
        elseif pValues(i) < 0.005, sigMark = "**";
        elseif pValues(i) < 0.01, sigMark = "*";
        end
        
        fprintf('%3d | %9.4f | %9.4f | %s\n', i, tValues(i), pValues(i), sigMark);
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
            b.CData(i, :) = [0.4, 0, 0];   % Darkest Red
        elseif p < 0.005
            b.CData(i, :) = [0.7, 0, 0];   % Dark Red
        elseif p < 0.01
            b.CData(i, :) = [1, 0, 0];     % Red
        end
    end

    % 基準線
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
    xlabel('Illumination Index');
    xlim([0.5, length(tValues)+0.5]);
    grid on;
    box on;
    
    % 凡例
    h1 = plot(nan, nan, 's', 'MarkerFaceColor', [1, 0, 0], 'MarkerEdgeColor', 'none');
    h2 = plot(nan, nan, 's', 'MarkerFaceColor', [0.7, 0, 0], 'MarkerEdgeColor', 'none');
    h3 = plot(nan, nan, 's', 'MarkerFaceColor', [0.4, 0, 0], 'MarkerEdgeColor', 'none');
    legend([h1, h2, h3], {'p < 0.01', 'p < 0.005', 'p < 0.001'}, 'Location', 'bestoutside');
    
    hold off;
    
    % 結果保存
    if options.ResultDir ~= ""
        % ファイル名にSubNameを含める
        saveFileName = sprintf("RawDataTtest_%s_vs_%s_%s_%s.png", nameA, nameB, options.Mode, subName);
        saveas(fig, fullfile(options.ResultDir, saveFileName));
        fprintf('Saved t-test plot: %s\n', saveFileName);
    end
    close(fig);
end
