function performCorrelationBootstrap(dataA, dataB, plotDataA, plotDataB, plotOptions, matNames, shapeNames)
% performCorrelationBootstrap - Bootstrap解析の管理関数
%
% 入力:
%   dataA, dataB: データ配列 (H, HM, HS, or HMS aligned)
%   plotDataA, plotDataB: データ仕様 (Name, target等)
%   plotOptions: オプション (Mode, Amp, Bootstrap, Split, ShowTitle, Property)
%   matNames: 材質名リスト
%   shapeNames: 形状名リスト

    % タイトルの表示設定
    showTitle = true;
    if isfield(plotOptions, 'ShowTitle')
        showTitle = plotOptions.ShowTitle;
    end

    % HMSモードは複数のFigureを作成するため、特別処理
    if plotOptions.Mode == "HMS"
        % 材質ごとにFigureを作成
        numMats = size(dataA, 2);
        for m = 1:numMats
            processHMS(dataA, dataB, plotDataA, plotDataB, plotOptions, m, matNames, shapeNames, showTitle);
        end
    else
        % H, HM, HSは単一Figure
        fig = figure('Visible', 'off');
        try
            processCombined(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, matNames, shapeNames, showTitle);
            
            % 保存
            saveFigureName(fig, plotDataA.Name, plotDataB.Name, plotOptions.Property, plotOptions.Mode, [], 'Significance', plotOptions.ResultDir, matNames);
        catch ME
            if isvalid(fig), close(fig); end
            rethrow(ME);
        end
    end
end

%% H/HM/HS モードの処理
function processCombined(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, matNames, shapeNames, showTitle)
    t = tiledlayout(fig, 1, 1, 'Padding', 'normal');
    ax = nexttile(t);
    
    switch plotOptions.Mode
        case "H"
            % Hモード
            % タイトル生成
            if showTitle
                titleStr = sprintf("%s vs %s - %s- all condition", plotDataA.Name, plotDataB.Name, plotOptions.Property);
            else
                titleStr = "";
            end
            
            % 計算
            [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
                calculateBootstrapStats(dataA, dataB, plotOptions.Bootstrap, plotOptions.Split);
            
            % プロット
            plotBootstrapGraph(ax, observed_corr, ceiling_distAA, ceiling_distAB, ...
                p_value, bca_ci_AB, 1, 'Amp', plotOptions.Amp, 'Title', titleStr);
            
            addSignificanceNote(ax, plotOptions.Amp);
            
        case {"HM", "HS"}
            % HM/HSモード
            if plotOptions.Mode == "HS"
                % HS: [H, S, P, T] -> permute to align loop
                dataA_r = permute(dataA, [1, 3, 2, 4, 5]); % -> [H, S, ...] (2nd dim is loop target)
                dataB_r = permute(dataB, [1, 3, 2, 4, 5]);
                labels = shapeNames;
                baseTitle = sprintf("%s vs %s - %s- shape", plotDataA.Name, plotDataB.Name, plotOptions.Property);
            else % HM
                dataA_r = dataA; % [H, M, ...]
                dataB_r = dataB;
                labels = matNames;
                baseTitle = sprintf("%s vs %s - %s- material", plotDataA.Name, plotDataB.Name, plotOptions.Property);
            end
            
            if showTitle
                titleStr = baseTitle;
            else
                titleStr = "";
            end
            
            loopLimit = size(dataA_r, 2);
            for i = 1:loopLimit
                dataA_sub = squeeze(dataA_r(:, i, :, :, :));
                dataB_sub = squeeze(dataB_r(:, i, :, :, :));
                
                fprintf("  Processing %s...\n", string(labels(i)));
                
                [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
                    calculateBootstrapStats(dataA_sub, dataB_sub, plotOptions.Bootstrap, plotOptions.Split);
                
                plotBootstrapGraph(ax, observed_corr, ceiling_distAA, ceiling_distAB, ...
                    p_value, bca_ci_AB, i, 'Amp', plotOptions.Amp, 'Title', titleStr);
            end
            
            % 軸ラベル等
            set(ax, 'XTick', 1:length(labels), 'XTickLabel', labels);
            addSignificanceNote(ax, plotOptions.Amp);
    end
end

%% HMS モードの処理
function processHMS(dataA, dataB, plotDataA, plotDataB, plotOptions, matIdx, matNames, shapeNames, showTitle)
    fig = figure('Visible', 'off');
    try
        t = tiledlayout(fig, 1, 1, 'Padding', 'normal');
        ax = nexttile(t);
        
        if showTitle
            titleStr = sprintf("%s vs %s - %s - %s", plotDataA.Name, plotDataB.Name, ...
                plotOptions.Property, string(matNames(matIdx)));
        else
            titleStr = "";
        end
        
        shapeCount = size(dataA, 3);
        for s = 1:shapeCount
            dataA_sub = squeeze(dataA(:, matIdx, s, :, :));
            dataB_sub = squeeze(dataB(:, matIdx, s, :, :));
            
            fprintf("  Processing Mat:%s, Shape:%s...\n", string(matNames(matIdx)), string(shapeNames(s)));
            
            [ceiling_distAA, ceiling_distAB, p_value, observed_corr, ~, bca_ci_AB] = ...
                calculateBootstrapStats(dataA_sub, dataB_sub, plotOptions.Bootstrap, plotOptions.Split);
            
            plotBootstrapGraph(ax, observed_corr, ceiling_distAA, ceiling_distAB, ...
                p_value, bca_ci_AB, s, 'Amp', plotOptions.Amp, 'Title', titleStr);
        end
        
        set(ax, 'XTick', 1:length(shapeNames), 'XTickLabel', shapeNames);
        addSignificanceNote(ax, plotOptions.Amp);
        
        % 保存
        saveFigureName(fig, plotDataA.Name, plotDataB.Name, plotOptions.Property, plotOptions.Mode, matIdx, 'Significance', plotOptions.ResultDir);
        
    catch ME
        if isvalid(fig), close(fig); end
        rethrow(ME);
    end
end

% 保存用ヘルパー
function saveFigureName(fig, nameA, nameB, prop, mode, matIdx, type, resultDir, matNames)
    if isempty(resultDir)
        warning('ResultDir is empty. Plot not saved.');
        return;
    end
    
    suffix = mode;
    if mode == "HMS" && ~isempty(matIdx) && exist('matNames', 'var')
        % HMSモードの場合、材質名をファイル名に含める
        matName = string(matNames(matIdx));
        suffix = sprintf("%s_%s", mode, matName);
    end
    
    fileName = sprintf('%s_vs_%s_%s_%s_%s.jpg', nameA, nameB, prop, suffix, type);
    fullPath = fullfile(resultDir, fileName);
    
    try
        saveas(fig, fullPath);
        fprintf('  -> 保存しました: %s\n', fileName);
    catch ME
        warning('Failed to save figure: %s', ME.message);
    end
    
    close(fig);
end
