function sdData = calculateSubjectSD(data, mode, isPooled)
    % calculateSubjectSD - 被験者間標準偏差（個人差）を計算する
    %
    % 入力:
    %   data : Row_HMSPT [H, M, S, P, T]
    %   mode : "H", "HM", "HS", "HMS"
    %   isPooled : trueならターゲット以外の次元を平均せず標本次元に統合する (default: false)
    %
    % ロジック:
    %   1. 試行回数(5)について標準偏差をとる (Within-subject SD)
    %      -> [H, M, S, P]
    %   2. Modeに応じて条件次元(2,3)を処理
    %      isPooled=false: 平均化 (Mean)
    %      isPooled=true : 統合 (Reshape to Samples)
    
    if nargin < 3
        isPooled = false;
    end
    
    % 1. 試行(5)のSD -> [H, M, S, P]
    trialSDData = std(data, 0, 5, 'omitnan');
    sz = size(trialSDData);
    H=sz(1); M=sz(2); S=sz(3); P=sz(4);
    
    % 2. Modeに応じて処理
    switch mode
        case "H"
            if isPooled
                % [H, M, S, P] -> [H, M*S*P]
                sdData = reshape(trialSDData, H, []);
            else
                % [H, M, S, P] -> 平均(M, S) -> [H, P]
                sdData = mean(trialSDData, [2, 3], 'omitnan');
                sdData = squeeze(sdData); 
            end
            
        case "HM"
            if isPooled
                % [H, M, S, P] -> [H, M, S*P]
                sdData = reshape(trialSDData, H, M, []);
            else
                % [H, M, S, P] -> 平均(S) -> [H, M, P]
                sdData = mean(trialSDData, 3, 'omitnan');
                sdData = squeeze(sdData);
            end
            
        case "HS"
            if isPooled
                % [H, M, S, P] -> [H, S, M*P]
                tmp = permute(trialSDData, [1, 3, 2, 4]);
                sdData = reshape(tmp, H, S, []);
            else
                % [H, M, S, P] -> 平均(M) -> [H, S, P]
                sdData = mean(trialSDData, 2, 'omitnan');
                sdData = squeeze(sdData);
            end
            
        case "HMS"
            % [H, M, S, P]
            % 平均化もプールも構造自体は変わらない（非対象次元がないため）
            sdData = trialSDData;
            
        case "Total"
            if isPooled
                % [H, M, S, P] -> [1, H*M*S*P] (dummy dim as 1st dim)
                % ttest compatible format: [1, N]
                sdData = reshape(trialSDData, 1, []);
            else
                % [H, M, S, P] -> 平均(H, M, S) -> [1, P]
                sdData = mean(trialSDData, [1, 2, 3], 'omitnan');
                sdData = squeeze(sdData)'; % [1, P]
            end

        case "S"
            if isPooled
                % [H, M, S, P] -> [S, H*M*P]
                % [S, H, M, P] に変形してからreshape
                tmp = permute(trialSDData, [3, 1, 2, 4]);
                sdData = reshape(tmp, S, []);
            else
                % [H, M, S, P] -> 平均(H, M) -> [S, P]
                sdData = mean(trialSDData, [1, 2], 'omitnan');
                sdData = squeeze(sdData); % [S, P]
            end
    end
end
