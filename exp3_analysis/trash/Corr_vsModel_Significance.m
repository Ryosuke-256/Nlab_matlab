function [corrA,corrAB,correlationDiffs] = Corr_vsModel_Significance(dataA,dataB,dataModel,bootstrap)

numBootstrap = bootstrap; 
illumDim = 1;

% 結果保存用
correlationDiffs = zeros(numBootstrap, 1);
corrA = zeros(numBootstrap,1);
corrAB = zeros(numBootstrap,1);

for i = 1:numBootstrap
    % === 1. データAでの基準相関係数を計算 ===
    % 1.a.b 条件ごとにブートストラップで平均を計算
    sampleA1 = MeanArray(dataA,illumDim);
    sampleA2 = MeanArray(dataA,illumDim);

    % 1.c 平均値データ間の相関係数
    corrA(i) = corr(sampleA1(:),sampleA2(:));

    % === 2. データAとデータBの相関係数を計算 ===
    if ndims(dataB) == 1
        sampleB = dataB;
    else
        sampleB = MeanArray(dataB,illumDim);
    end
    % 2.b データAとデータB間の相関係数
    corrAB(i) = corr(sampleA1(:),sampleB(:));

    % === 3. 相関係数の差を計算 ===
    correlationDiffs(i) = corrA(i) - corrAB(i);
end
end

% 入力：配列、ベースとする次元(今回は照明条件 = 1次元目)
function [reducedData] = MeanArray(array,baseDim)
    dims = ndims(array);
    %baseDim = 1;
    shuftleDim = dims;
    
    reducedData = zeros(size(array));
    
    for i = 1:size(array,baseDim)
        % 並び替えるためのランダム配列
        random_idx = randi(size(array, dims), [1, size(array, dims)]);
    
        % array側の挿入する配列
        subs_target = repmat({':'}, 1, dims);
        subs_target{baseDim} = i;
        subs_target{shuftleDim} = random_idx;
    
        % reducedData側で挿入される配列
        subs_receive = repmat({':'}, 1, dims);
        subs_receive{baseDim} = i;
    
        % データの挿入
        reducedData(subs_receive{:}) = array(subs_target{:});
    end
    
    for d = dims:-1:2
        reducedData = mean(reducedData, d);
    end
end