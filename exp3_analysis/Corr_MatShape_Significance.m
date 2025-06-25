function [corrA,corrAB,correlationDiffs,threshold] = Corr_MatShape_Significance(dataA,dataB,bootstrap)
numBootstrap = bootstrap; 
[numIllumination,MatNum,ShapeNum,~] = size(dataA); % 照明環境の数
illumDim = 1;

correlationDiffs = zeros(numBootstrap, MatNum,ShapeNum);
corrA = zeros(numBootstrap,MatNum,ShapeNum);
corrAB = zeros(numBootstrap,MatNum,ShapeNum);
threshold = zeros(MatNum,ShapeNum);

for mat = 1:MatNum
    for shape = 1:ShapeNum        
        for i = 1:numBootstrap
            % === 1. データAでの基準相関係数を計算 ===
            % 1.a.b 条件ごとにブートストラップで平均を計算
            sampleA1 = MeanArray(dataA,illumDim);
            sampleA2 = MeanArray(dataA,illumDim);
            % 1.c 平均値データ間の相関係数
            corrA(i,mat,shape) = corr(sampleA1(:,mat,shape),sampleA2(:,mat,shape));

            % === 2. データAとデータBの相関係数を計算 ===
            if ndims(dataB) == 1
                sampleB = dataB;
            else
                sampleB = MeanArray(dataB,illumDim);
            end
            % 2.b データAとデータB間の相関係数
            corrAB(i,mat,shape) = corr(sampleA1(:,mat,shape),sampleB(:,mat,shape));

            % === 3. 相関係数の差を計算 ===
            correlationDiffs(i,mat,shape) = corrA(i,mat,shape) - corrAB(i,mat,shape);
        end
        
        % === 4. 有意差の判定 ===
        % 相関係数の差を昇順に並べる
        sortedDiffs = sort(correlationDiffs(:,mat,shape));
        % 95%信頼区間の下限を確認
        threshold(mat,shape) = sortedDiffs(round(numBootstrap*0.05)); 
        if threshold(mat,shape) > 0
            disp('AとBに有意差があります（p < 0.05）');
        else
            disp('AとBに有意差はありません（p >= 0.05）');
        end
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
