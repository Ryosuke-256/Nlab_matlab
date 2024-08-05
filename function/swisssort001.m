% Simulate observer's responses in paired comparison experiment using swiss-draw algorithm.
% is used for checking efficiency of experiment and analysis methods in
% conventional paired comparison and swiss-draw one.
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage:
%     [mtx, OutOfNum, NumGreater] = TNT_FCN_ObsResSimulation_swiss(sv, cmbs, sessionnum, sd, ploton, algorithm);
% 
% Input:
%     sv:   psychological values (sensations) for each stimulus
%     cmbs: stimulus combinations used in the experiment
%     snum: number of sessions
%     sd:   standard deviation of observer's response
%     method: method of optimization (1: customized fminsearch, 2: normal fminsearch, 3: customized method using fmincon with constrained range)
%
% Output:
%     mtx: 　　　　Table of winning rate
%     OutOfNum:   Trials in each stimulus pair
%     NumGreater: Trials in each stimulus pair in which 'row stimulus' wins
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

function [mtx, OutOfNum, NumGreater] = swisssort001(sv, snum, sd)

stimnum = length(sv); % number of stimulus
npair = floor(stimnum/2); % number of stimulus pairs in each session

mtx = zeros(stimnum, stimnum);  
NumGreater = zeros(stimnum, stimnum);
OutOfNum = zeros(stimnum, stimnum);

% swiss-draw procedure
sv_change = zeros(stimnum, snum); % variable to store all estimated_svs

for s=1:snum
    % determine stimulus pairs in the session
        % initial guess by z-score
    estimated_sv = TNT_FCN_PCanalysis_Thurston(mtx, 0.005);
    estimated_sv = estimated_sv - mean(estimated_sv);
    
    sv_change(:, s) = estimated_sv;
    
    % add order jitter
    r = ceil(rand(1,1).*2);
    if r==2
        ind = [ind(2:end) ind(1)]; 
    end
    
        % stimulus pair
    stimpairs = zeros(npair, 2);
    for p=1:npair
        stimpairs(p, :) = [ind((p-1).*2+1) ind((p-1).*2+2)];
    end
    
    % simulation of experiment
    for p=1:npair
        ind1 = stimpairs(p, 1);
        ind2 = stimpairs(p, 2);
        [res1, res2] = TNT_FCN_ObsResSimulation_OneTrial(sv(ind1), sv(ind2), sd, 1);
        OutOfNum(ind1, ind2) = OutOfNum(ind1, ind2)+1;
        OutOfNum(ind2, ind1) = OutOfNum(ind2, ind1)+1;
        NumGreater(ind1, ind2) = NumGreater(ind1, ind2) + res1;
        NumGreater(ind2, ind1) = NumGreater(ind2, ind1) + res2;
        mtx(ind1, ind2) = NumGreater(ind1, ind2)./OutOfNum(ind1, ind2);
        mtx(ind2, ind1) = NumGreater(ind2, ind1)./OutOfNum(ind2, ind1);
    end
end

% winning ratio calculation
for a=1:stimnum
    for b=1:stimnum
        if OutOfNum(a,b)==0
            mtx(a,b)=nan;
        end
    end
end
