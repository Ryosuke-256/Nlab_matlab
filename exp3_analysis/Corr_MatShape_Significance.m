function [corrA,corrAB,correlationDiffs] = Corr_MatShape_Significance(dataA,dataB,bootstrap)
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
            sampleA1 = mean(dataA(:,:,:, randi(size(dataA, 4), [1, size(dataA, 4)])), 4);
            sampleA2 = mean(dataA(:,:,:, randi(size(dataA, 4), [1, size(dataA, 4)])), 4);
            % 1.c 平均値データ間の相関係数
            corrA(i,mat,shape) = corr(sampleA1(:,mat,shape),sampleA2(:,mat,shape));

            % === 2. データAとデータBの相関係数を計算 ===
            sampleB = mean(dataB(:,:,:, randi(size(dataB, 4), [1, size(dataB, 4)])), 4);
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
