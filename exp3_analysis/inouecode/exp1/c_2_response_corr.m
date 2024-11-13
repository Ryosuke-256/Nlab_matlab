clear all;

%% 1. 実験条件・照明環境ごとの選好尺度値（被験者平均）
% 実験2との比較用
load('/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/z_conditionList.mat');
experiment2_condition = experiment_condition;
[experiment2_conditionNum, ~] = size(experiment2_condition);

load('/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis/z_psvList.mat');
psv_experiment2 = psvList;

%% 実験1の選好尺度値のリストを作る
load('z_conditionList.mat');

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1/data/psvList';
subject = ["aso","dogu", "horiuchi", "son", "takanashi"];
directory = '5';

illumNum = 30;
[conditionNum,~] = size(experiment_condition);
[~, subjectNum] = size(subject);

psvListAll = zeros(experiment2_conditionNum, illumNum, subjectNum);

for j = 1 : subjectNum
    condition_count = 1;
    current_subject = subject(j);
    for i = 1 : conditionNum
        for k = 1 : experiment2_conditionNum
            if(experiment2_condition(k,1) == experiment_condition(i,1) && experiment2_condition(k,2) == experiment_condition(i,2) && experiment2_condition(k,3) == experiment_condition(i,3))
                filename = strcat(current_subject,directory,'_', experiment_condition(i,1),'_',experiment_condition(i,2),'_', experiment_condition(i,3),'.mat');
                filepath = strcat(rootpath, '/', current_subject,'/',directory,'/', filename);
                
                load(filepath);
                
                psvListAll(condition_count,:, j) = illumiPsvAll(5,:);
                condition_count = condition_count + 1;
            end
        end
    end
end

psvList = mean(psvListAll,3);

%% 実験間で形状ごとの光沢知覚量を比較
psv_experiment1 = psvList;
corr_List = [];

for i = 1 : experiment2_conditionNum
    
    correlation = corrcoef(psv_experiment1(i,:), psv_experiment2(i,:));
    corr_List = [corr_List correlation(1,2)]; 
    output = sprintf('(%s %s %s) : r = %1.2f', experiment2_condition(i,1),experiment2_condition(i,2),experiment2_condition(i,3),correlation(1,2));
    disp(output)
end

bar(corr_List);