function [corrA,corrAB,correlationDiffs,threshold] = Corr_Significance_HS(dataA,dataB,bootstrap)
numBootstrap = bootstrap; 
[numIllumination,MatNum,ShapeNum,~] = size(dataA); % 照明環境の数
illumDim = 1;

correlationDiffs = zeros(numBootstrap, ShapeNum);
corrA = zeros(numBootstrap,ShapeNum);
corrAB = zeros(numBootstrap,ShapeNum);
threshold = zeros(ShapeNum);


for shape = 1:ShapeNum        
    for i = 1:numBootstrap
        % === 1. データAでの基準相関係数を計算 ===
        % 1.a.b 条件ごとにブートストラップで平均を計算
        sampleA1 = MeanArray(dataA,illumDim);
        sampleA2 = MeanArray(dataA,illumDim);
        % 1.c 平均値データ間の相関係数
        corrA(i,shape) = corr(sampleA1(:,shape),sampleA2(:,shape));

        % === 2. データAとデータBの相関係数を計算 ===
        if ndims(dataB) == 1
            sampleB = dataB;
        else
            sampleB = MeanArray(dataB,illumDim);
        end
        % 2.b データAとデータB間の相関係数
        corrAB(i,shape) = corr(sampleA1(:,shape),sampleB(:,shape));

        % === 3. 相関係数の差を計算 ===
        correlationDiffs(i,shape) = corrA(i,shape) - corrAB(i,shape);
    end

    % === 4. 有意差の判定 ===
    % 相関係数の差を昇順に並べる
    sortedDiffs = sort(correlationDiffs(:,shape));
    % 95%信頼区間の下限を確認
    threshold(shape) = sortedDiffs(round(numBootstrap*0.05)); 
    if threshold(shape) > 0
        disp('AとBに有意差があります（p < 0.05）');
    else
        disp('AとBに有意差はありません（p >= 0.05）');
    end
end
end


% 入力：配列、ベースとする次元(今回は照明) = 1次元目)
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
    
    %今回は照明、材質、形状の情報を残したいので4次元目までを平均
    for d = dims:-1:4
        reducedData = mean(reducedData, d);
    end
end
