function [corrA,corrAB,correlationDiffs] = Corr_Significance(dataA,dataB,bootstrap)
%{
データの準備
dimsA = ndims(arrayA);
dataA = reshape(arrayA,dimsA(1:reshapeNum),[]);
dimsB = ndims(arrayB);
dataB = reshape(arrayB,dimsB(1:reshapeNum),[]);
%}

numBootstrap = bootstrap; 

% 結果保存用
correlationDiffs = zeros(numBootstrap, 1);
corrA = zeros(numBootstrap,1);
corrAB = zeros(numBootstrap,1);

for i = 1:numBootstrap
    % === 1. データAでの基準相関係数を計算 ===
    % 1.a.b 条件ごとにブートストラップで平均を計算
    sampleA1 = MeanArray(dataA);
    sampleA2 = MeanArray(dataA);

    % 1.c 平均値データ間の相関係数
    corrA(i) = corr(sampleA1(:),sampleA2(:));

    % === 2. データAとデータBの相関係数を計算 ===
    if ndims(dataB) == 1
        sampleB = dataB;
    else
        sampleB = MeanArray(dataB);
    end
    % 2.b データAとデータB間の相関係数
    corrAB(i) = corr(sampleA1(:),sampleB(:));

    % === 3. 相関係数の差を計算 ===
    correlationDiffs(i) = corrA(i) - corrAB(i);
end
end

% 
function [reducedData] = MeanArray(array)
    dims = ndims(array);
    random_idx = randi(size(array, dims), [1, size(array, dims)]);
    subs = repmat({':'}, 1, dims);
    subs{dims} = random_idx;
    reducedData = array(subs{:});
    for d = dims:-1:2
        reducedData = mean(reducedData, d);
    end
end