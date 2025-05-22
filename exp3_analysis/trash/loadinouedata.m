clear all;

% activate at ' exp3_analysis '

%% 1. 実験条件・照明環境ごとの選好尺度値（被験者平均）
load('./inouedata/exp2/z_conditionList.mat');

load('./inouedata/exp1/z_psvList.mat');
psv_experiment1 = psvList;

load('/inouedata/exp2/z_psvList.mat')
psv_experiment2 = psvList;

[conditionNum, ~] = size(psv_experiment2);

corr_List = [];
for i = 1 : conditionNum
    correlation = corrcoef(psv_experiment1(i,:), psv_experiment2(i,:));
    corr_List = [corr_List, correlation(1,2)];
    output = sprintf('(%s %s %s) : r = %1.2f', experiment_condition(i,1),experiment_condition(i,2),experiment_condition(i,3),correlation(1,2));
    disp(output)
end

bar(corr_List);
xlabel('照明番号'); ylabel('光沢知覚量');
title('物体条件ごとの実験１と実験２の光沢知覚量の相関')