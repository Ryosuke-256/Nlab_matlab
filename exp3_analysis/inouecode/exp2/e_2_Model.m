clear all;
%% モデルの作成を行うプログラム

% 月と日のみを取得 ('mmdd'形式)
%currentDate = datestr(now, 'mmdd');
currentDate = num2str(1229);

poolobj = gcp('nocreate');
delete(poolobj);
parpool(2)

%% 実験データの読み込み
load('./data4analysis/bangou1223.mat','bangou1223');
load('z_conditionList.mat', 'experiment_condition');

material = ["cu" "pla" "glass"];
mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
materialNum = length(material);
meshNum = length(mesh);
[~,roughnessNum] = size(roughness);

illumNum = 30;
[conditionNum, ~] = size(experiment_condition);

%% パラメータ 
pm.cv_num=10;%交差検証の数
pm.analysis_data = 4; % 1: 金属のみ、2:プラスチックのみ、3:glass、4: 全部
pm.outlier_detection_obj = 0; % 物体モデルで外れ値をクックの距離で除外するか否か
pm.ridge_obj = 1; % 物体モデルをridgeにするかどうか
pm.hyper_param = 1; % 照明モデルの選択基準（最小MSE 0（ゆるい正則化） or 最小MSE+1SE（きつめの正則化））
pm.leave_num = 30;%leave-one-outの数(実験で用いた照明数が30なのでその分だけ実施)

%% 物体条件ごとに物体モデル構築
%{
AllAnalysisInfo = cell(materialNum,meshNum,roughnessNum); % 素材、形状、光沢ごとに

for material_type=1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
            [illum, obj] = subfunc.ObjectModelAnalysis(material_type, shape_type, gloss_type, pm);
            AllAnalysisInfo{material_type, shape_type, gloss_type}.obj = obj;
            AllAnalysisInfo{material_type, shape_type, gloss_type}.illum = illum;
        end
    end
end

filename = ['./result/tmpfile_imc_', currentDate, '.mat'];
save(filename, 'AllAnalysisInfo');
%}

%% 照明モデル構築（全条件）
%{
filename = ['./result/tmpfile_imc_', currentDate, '.mat'];
load(filename, 'AllAnalysisInfo');
tic

% モデル構築
[illum, obj] = subfunc.IlluminationModelAnalysis(AllAnalysisInfo, pm);

% データの保存
AllAnalysisInfo_common = cell(1,1);
AllAnalysisInfo_common{1}.illum = illum;
AllAnalysisInfo_common{1}.obj = obj;

filename = ['./result/model_all_condition_', currentDate, '.mat'];
save(filename, 'AllAnalysisInfo', 'AllAnalysisInfo_common');
%}

%% 照明モデル構築に使用しない条件の推定

filename = ['./result/model_all_condition_', currentDate, '.mat'];
load(filename, 'AllAnalysisInfo', 'AllAnalysisInfo_common');
load('./data4analysis/bangou1223.mat');

illum = AllAnalysisInfo_common{1}.illum;
obj = AllAnalysisInfo_common{1}.obj;

illum.result = zeros(illumNum, 3, conditionNum);
coef = illum.coef;
intercept = illum.intercept;

count = 1;
for material_type= 1:materialNum
    for shape_type=1:meshNum
        for gloss_type=1:roughnessNum
            % データ読み込み
            objt = AllAnalysisInfo{material_type, shape_type, gloss_type}.obj;
            illumt = AllAnalysisInfo{material_type, shape_type, gloss_type}.illum;
            
            illum.result(:, 1, count) = objt.result(:,2);
            
            illumX = illumt.all_exp_var(bangou1223',:);
            illum.result(:, 2, count) = illumX * coef' + intercept;
            illum.result(:, 3, count) = illum.result(:, 2, count);
            
            count = count + 1;
        end
    end
end

%% データの保存
AllAnalysisInfo_common = cell(1,1);
AllAnalysisInfo_common{1}.illum = illum;
AllAnalysisInfo_common{1}.obj = obj;

filename = ['./result/model_all_condition_all_result_', currentDate, '.mat'];
save(filename, 'AllAnalysisInfo', 'AllAnalysisInfo_common');
