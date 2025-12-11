function sdData = calculateSubjectSD(data, mode)
    % calculateSubjectSD - 被験者間標準偏差（個人差）を計算する
    %
    % 入力:
    %   data : Row_HMSPT [H, M, S, P, T]
    %   mode : "H", "HM", "HS", "HMS"
    %
    % ロジック:
    %   1. 試行回数(5)について標準偏差をとる (Within-subject SD)
    %      -> [H, M, S, P]
    %   2. その後、Modeに応じて条件次元(2,3)のみを平均化する
    %      -> 被験者次元(4)は保持する: [H, P] や [H, M, P] など
    
    % 1. 試行(5)のSD -> [H, M, S, P]
    trialSDData = std(data, 0, 5, 'omitnan');
    
    % 2. Modeに応じて条件を平均化 (被験者は保持)
    switch mode
        case "H"
            % [H, M, S, P] -> 平均(M, S) -> [H, 1, 1, P] -> [H, P]
            sdData = mean(trialSDData, [2, 3], 'omitnan');
            sdData = squeeze(sdData); % [H, P]
            
        case "HM"
            % [H, M, S, P] -> 平均(S) -> [H, M, 1, P] -> [H, M, P]
            sdData = mean(trialSDData, 3, 'omitnan');
            sdData = squeeze(sdData); % [H, M, P]
            
        case "HS"
            % [H, M, S, P] -> 平均(M) -> [H, 1, S, P] -> permute -> [H, S, P]
            sdData = mean(trialSDData, 2, 'omitnan');
            % squeezeすると [H, S, P] になるはずだが、次元サイズによっては挙動が変わるので注意
            % data size: [H, 1, S, P] -> squeeze -> [H, S, P] (if H,S,P > 1)
            sdData = squeeze(sdData); 
            
        case "HMS"
            % [H, M, S, P] -> 平均なし -> [H, M, S, P]
            sdData = trialSDData;
            % squeeze不要 (次元5が消えているので4次元)
    end
end
