% TNT_FCN_PCanalysis_Thurston (ver 1.0.1)
%
% Analyzes results of Thurston's paired comparison experiment based on z-score.
% This is a classical method to estimate sensation magnitude from paired
% comparison experiment.
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage: 
%     ps = TNT_FCN_PCanalysis_Thurston(mtx, lambda)
% 
% Input:
%     mtx:        Table of winning rate
%     lambda:     small value to adjust z-scores.
% 
% Output:
%     ps:         Sensation magnitude (Psi Values) estimated
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Created by Takehiro Nagai on 04/01/2020 (ver1.0.1)
%



function ps = TNT_FCN_PCanalysis_Thurston(mtx, lambda)

stimnum = size(mtx, 1);
ps = zeros(1,stimnum);

for s = 1:stimnum
    % ignore 'nan' data
    data = mtx(s, :);
    finiteind = isfinite(data);
    
    % calculate mean z-score
    ps(s) = mean(TNT_norminv(data(finiteind).*(1-lambda.*2)+lambda));
end