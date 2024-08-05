% Simulate observer's responses in paired comparison experiment using swiss-draw algorithm.
% is used for checking efficiency of experiment and analysis methods in
% conventional paired comparison and swiss-draw one.
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage:
%     [mtx, OutOfNum, NumGreater] = Exp1_swissSort(imagestruct, snum);
% 
% Input:
%     imagestruct:   psychological values (sensations) for each stimulus
%     snum: number of sessions
%
% Output:
%     mtx: 　　　　Table of winning rate
%     OutOfNum:   Trials in each stimulus pair
%     NumGreater: Trials in each stimulus pair in which 'row stimulus' wins
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

function [mtx, OutOfNum, NumGreater] = Exp1_swissSort(imagestruct, snum ,window ,xCenter, yCenter)

stimnum = length(imagestruct); % number of stimulus
npair = floor(stimnum/2); % number of stimulus pairs in each session

mtx = zeros(stimnum, stimnum);  
NumGreater = zeros(stimnum, stimnum);
OutOfNum = zeros(stimnum, stimnum);

% swiss-draw procedure
sv_change = zeros(stimnum, snum); % variable to store all estimated_svs

for s=1:snum
    %配列が奇数の時の処理
    datajudge = mod(stimnum,2);
    if datajudge == 1
        %ランダムな配列を一旦除外する
        targetIndex = randi([1,stimnum]);
        targetData = imagestruct(targetIndex);
        imagestruct(targetIndex) = [];
        UseDataLength = stimnum-1;
    else
        UseDataLength = stimnum;
    end
    
    % 勝ち点順にサンプルをソート
    scores = [imagestruct.score];
    [~, sortIndex] = sort(scores); 
    sortedData = imagestruct(sortIndex);

    %同じスコアをランダム化する
    finalData = struct('ID',{},'score',{},'name',{},'image',{});
    unique_scores = unique(scores);
    for score = unique_scores
        same_score_structs = sortedData([sortedData.score] == score);
        rand_indices = randperm(length(same_score_structs));
        same_score_structs = same_score_structs(rand_indices);
        finalData = [finalData,same_score_structs];
    end
    imagestruct = finalData;
    
    %除外したデータを戻す
    if datajudge == 1
        imagestruct(end+1) = targetData;
    end

    % stimulus pair
    stimpairs = zeros(npair, 2);
    for p=1:npair
        stimpairs(p, :) = [imagestruct((p-1).*2+1).ID,imagestruct((p-1).*2+2).ID];
    end

    % simulation of experiment
    for p=1:npair
        ind1 = stimpairs(p, 1);
        ind2 = stimpairs(p, 2);
        [res1, res2] = Exp1_Onetrial(imagestruct(ind1).image, imagestruct(ind2).image ,window ,xCenter, yCenter);
        OutOfNum(ind1, ind2) = OutOfNum(ind1, ind2)+1;
        OutOfNum(ind2, ind1) = OutOfNum(ind2, ind1)+1;
        NumGreater(ind1, ind2) = NumGreater(ind1, ind2) + res1;
        NumGreater(ind2, ind1) = NumGreater(ind2, ind1) + res2;
        mtx(ind1, ind2) = NumGreater(ind1, ind2)./OutOfNum(ind1, ind2);
        mtx(ind2, ind1) = NumGreater(ind2, ind1)./OutOfNum(ind2, ind1);
    end

    % initial guess by z-score
    estimated_sv = TNT_FCN_PCanalysis_Thurston(mtx, 0.005);
    estimated_sv = estimated_sv - mean(estimated_sv);  
    sv_change(:, s) = estimated_sv;

    % ID順にサンプルをソート
    id = [imagestruct.ID];
    [~, sortIndex] = sort(id); 
    imagestruct = imagestruct(sortIndex);

    % スコアを更新
    for i = 1:stimnum
        imagestruct(i).score = estimated_sv(i);
    end

    Screen('Flip', window);
    WaitSecs(1);
end

% winning ratio calculation
for a=1:stimnum
    for b=1:stimnum
        if OutOfNum(a,b)==0
            mtx(a,b)=nan;
        end
    end
end
