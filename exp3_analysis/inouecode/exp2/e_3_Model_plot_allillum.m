clear all;

%% モデル結果のプロット

%% データ読み込み
rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment2/analysis';

load(strcat(rootpath, '/AllAnalysisInfo_separate_common_model_all_result.mat'));
coef = AllAnalysisInfo_common{1}.illum.coef;
intercept = AllAnalysisInfo_common{1}.illum.intercept;

load(strcat(rootpath, '/z_conditionList.mat'));
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size015" "board_ang0_size03" "board_ang30_size0" "board_ang30_size015" "board_ang30_size03"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
meshNum = size(mesh);
materialhNum = size(material);
roughnessNum = size(roughness);
illumNum = 30;
allIllumNum = 295;
[conditionNum, ~] = size(experiment_condition(:,1));

leave_num = 30;
hyper_param = 1;
graphNum = [21 22 23 31 32 33 34 35 36];

%% 照明モデルの結果をプロット
illum = AllAnalysisInfo_common{1}.illum;

%% 照明モデルに使用されている条件の読み込み
illum_condition = [];
load(strcat(rootpath, '/z_clusterList.mat'));
for i = 1 : conditionNum
    if clusterList(i, 1) == 1
        illum_condition = [illum_condition i];
    end
end
[~, illum_conditionNum] = size(illum_condition);

%% 各条件と照明モデル
%h1 = figure('Position', [1 1 1301 944], 'Name', 'Illumination model');
%h2 = figure('Position', [1 1 1301 944], 'Name', 'Illumination model (with observer response)');

count = 1;

result = [];
illum_R2_list = [];
illum_r_list = [];

for count1 = 1 : conditionNum
    obj = AllAnalysisInfo{count1,1}.obj;
    result = [squeeze(illum.result(:,:,count1)) obj.result(:,1)];
    
    rss = sum((result(:, 2) - result(:, 1)).^2);
    tss = sum((result(:, 1) - mean(result(:, 1))).^2);%実験結果(目的変数)の平均との差
    R2 = 1-rss./tss;
    %{
    if ismember(count1, graphNum)
        figure(h1)
        subplot(3,4,count);    hold on;
        plot(result(:, 2), result(:, 1), 'o');
        lsline
        maxv = max(max(result(:, 2)));
        minv = min(min(result(:, 1)));
        xlabel('illumination model prediction'); ylabel('object model output');
        xlim([minv maxv])
        ylim([minv maxv])
        plot([minv maxv],[minv maxv],'-k');
        title('Illumination model')
        text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, sprintf('R2 = %1.2f, r=%1.2f', R2, corr(result(:, 2), result(:, 1))))
        
        
        rss = sum((result(:, 4) - result(:, 3)).^2);
        tss = sum((result(:, 4) - mean(result(:, 4))).^2);%実験結果(目的変数)の平均との差
        R2 = 1-rss./tss;
        
        figure(h2)
        subplot(3,4,count);    hold on;
        plot(result(:, 3), result(:, 4), 'o');
        lsline
        maxv = max([result(:, 3);result(:, 4)]);
        minv = min([result(:, 3);result(:, 4)]);
        xlabel('illumination model prediction'); ylabel('experimental results');
        xlim([minv maxv])
        ylim([minv maxv])
        plot([minv maxv],[minv maxv],'-k');
        title('Illumination model (prediction of psychological value)')
        r2infostring = sprintf('R2 = %1.2f, r=%1.2f ', R2, corr(result(:, 3), obj.result(:, 1)));
        text((maxv-minv)*0.2+minv,(maxv-minv)*0.8+minv, r2infostring);
        
        count = count + 1;
    end
    %}
    illum_R2_list = [illum_R2_list;R2];
    illum_r_list = [illum_r_list;corr(result(:, 3), result(:, 4))];
    
    yyy = sprintf('Illumination_model(with_observer_response) %s_%s_%s : R2= %1.2f ,r= %1.2f', ...
        experiment_condition(count1, 1), ...
        experiment_condition(count1, 2), ...
        experiment_condition(count1, 3), ...
        R2, corr(result(:, 3), obj.result(:, 1)));
    disp(yyy);
end

h3 = figure('Position', [1 1 1301 944], 'Name', 'Illumination model R2');
h4 = figure('Position', [1 1 1301 944], 'Name', 'Illumination model r');
%{
result_labels = cell(1, 23);

% 各ラベルを生成し、セル配列に格納
for i = 1:23
    label1 = experiment_condition(illum_condition(i), 1);
    label2 = experiment_condition(illum_condition(i), 2);
    label3 = experiment_condition(illum_condition(i), 3);

    result_labels{i} = [label1 '_' label2 '_' label3];
    result_labels{i} = strjoin(result_labels{i}, '');
end
%}

figure(h3)
bar(illum_R2_list)

figure(h4)
bar(illum_r_list)
