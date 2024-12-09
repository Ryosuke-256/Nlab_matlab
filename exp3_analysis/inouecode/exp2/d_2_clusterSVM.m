%% データの読み込み

load('z_conditionList.mat', 'experiment_condition');
load('z_psvList.mat', 'psvList');
load('z_clusterList.mat', 'clusterList');
clusterList(clusterList==3) = 2; % クラスターの調整

mesh = ["sphere" "bunny" "dragon" "board_ang0_size0" "board_ang0_size03" "board_ang0_size015" "board_ang30_size0" "board_ang30_size03" "board_ang30_size015"];
material = ["cu" "pla" "glass"];
roughness = ["0.025" "0.129"; "0.075" "0.225"; "0.05" "0.5"];
meshNum = length(mesh);
materialNum = length(material);
[~,roughnessNum] = size(roughness);
illumNum = 30;
[conditionNum,~] = size(experiment_condition);

%% 法線特徴量の計算

imagesize = 256;

dot_var_0 = zeros(9,1);
dot_var_45 = zeros(9,1);
dot_var_60 = zeros(9,1);
dot_mean_0= zeros(9,1);
dot_mean_45= zeros(9,1);
dot_mean_60= zeros(9,1);
count = 1;

vector_0 = [0, sin(deg2rad(0)), cos(deg2rad(0))];
vector_45 = [0, sin(deg2rad(45)), cos(deg2rad(45))];
vector_60 = [0, sin(deg2rad(60)), cos(deg2rad(60))]; 

for material_type = 1
    for shape_type = 1:meshNum
        for gloss_type = 1
            filename = './data4analysis/image_normal/'+mesh(shape_type) +'_normal.mat';
            load(filename, 'np_data');
            
            %% ベクトルの分散
            normal_dot_0 = [];
            normal_dot_45 = [];
            normal_dot_60 = [];
            
            for i = 1:imagesize
                for j = 1:imagesize
                    if all(np_data(i,j,:) == 0)
                        continue; % 0ベクトルをスキップ
                    else
                        np_reshaped = reshape(np_data(i,j,:), [1, 3]);
                        normal_dot_0 = [normal_dot_0; dot(vector_0, np_reshaped)];
                        normal_dot_45 = [normal_dot_45; dot(vector_45, np_reshaped)];
                        normal_dot_60 = [normal_dot_60; dot(vector_60, np_reshaped)];
                    end
                end
            end
            
            dot_var_0(count,1) = var(normal_dot_0);
            dot_var_45(count,1) = var(normal_dot_45);
            dot_var_60(count,1) = var(normal_dot_60);
            dot_mean_0(count,1) = mean(normal_dot_0);
            dot_mean_45(count,1) = mean(normal_dot_45);
            dot_mean_60(count,1) = mean(normal_dot_60);
            count = count + 1;
        end
    end
end

%% SVMの説明変数を作成

load('./data4analysis/bangou1223.mat','bangou1223')  
setumei = [];
count = 1;

for material_type = 1 :materialNum
    for shape_type = 1 : meshNum
        for gloss_type = 1 : roughnessNum
            load('./data4analysis/object_explanatory/' +mesh(shape_type)+ '_'+ material(material_type) +'_'+ roughness(material_type, gloss_type)+ '.mat','ob_explanatory');%説明変数を読み込み
            object_explanatory = ob_explanatory(bangou1223,:);
            
            for feature_num = 1:17
                setumei(count,:,feature_num) = transpose(object_explanatory(:,feature_num)); 
            end
            
            setumei(count,1:illumNum,18) = dot_var_0(shape_type);
            setumei(count,1:illumNum,19) = dot_var_45(shape_type);
            setumei(count,1:illumNum,20) = dot_var_60(shape_type);
            setumei(count,1:illumNum,21) = dot_mean_0(shape_type);
            setumei(count,1:illumNum,22) = dot_mean_45(shape_type);
            setumei(count,1:illumNum,23) = dot_mean_60(shape_type);

            count = count + 1;
        end
    end 
end
features_allnum = length(setumei(1,1,:));

%% SVM

filename = 'SVM_accuracy_coef.mat';

if exist(filename, 'file') == 2
    load(filename,'SVM_accuracy', 'all_avg_weights');
    disp('load');
else
    SVM_accuracy = [];
    all_avg_weights = cell(illumNum, 1);
end

% parmeter
[SVM_start,~] = size(SVM_accuracy);
SVM_start = SVM_start + 1;
numIterations = 30;

for illum = SVM_start : illumNum

    setumei_illum = squeeze(setumei(:, illum, :));
    classes = clusterList;
    
    accuracies = zeros(numIterations, 1);
    weights = cell(numIterations, 1); % 各試行の重みベクトルを保存するセル配列
    predicted_scores = zeros(length(classes), 1);  % To store predicted scores

    for iter = 1:numIterations
        disp(iter);

        idxClass1 = find(classes == 1);
        idxClass2 = find(classes == 2);
        minClass = min(length(idxClass1), length(idxClass2));
        idxClass2 = datasample(idxClass2, minClass, 'Replace', true); % ブートストラップによるバギング
        
        finalIndices = [idxClass1(:); idxClass2(:)];
        finalSetumei = setumei_illum(finalIndices, :);
        finalClasses = classes(finalIndices);
        
        correct = 0;
        
        for i = 1 : length(finalClasses)
            test_data = finalSetumei(i, :);
            test_label = finalClasses(i);

            train_data = finalSetumei([1:i-1, i+1:end], :);
            train_label = finalClasses([1:i-1, i+1:end]);
            
            % 標準化
            mean_train_data = mean(train_data);
            std_train_data = std(train_data);
            train_data = (train_data - mean_train_data) ./ std_train_data;
            test_data = (test_data - mean_train_data) ./ std_train_data;
            
            % ハイパーパラメータチューニングとSVMモデルのフィッティング
            t = templateSVM('KernelFunction', 'linear', 'KernelScale', 'auto');
            opt = struct('Optimizer', 'bayesopt', 'UseParallel', true,'MaxObjectiveEvaluations', 10,'ShowPlots', false, 'Verbose', 0, 'CVPartition', cvpartition(train_label, 'LeaveOut'), 'AcquisitionFunctionName', 'expected-improvement-plus');
            SVMModel = fitcsvm(train_data, train_label, 'KernelFunction', 'linear', 'OptimizeHyperparameters', 'auto', 'HyperparameterOptimizationOptions', opt);
          
            [label, score] = predict(SVMModel, test_data);  %prediction

            if label == test_label
                correct = correct + 1;  %evaluate
            end
            
        end
        
        accuracies(iter) = correct / length(finalClasses);
        weights{iter} = SVMModel.Beta;  % 各試行で得られた重みベクトルを保存
    end

    % accuracy
    mean_accuracy = mean(accuracies);
    disp(['Average Accuracy: ', num2str(mean_accuracy * 100), '%']);  

    % coef
    avg_weights = zeros(features_allnum, 1);
    for i = 1:numIterations
        weight_vector = weights{i};
        avg_weights = avg_weights + weight_vector;  % i番目のセルのベクトルの各要素をavg_weightsに加算
    end
    avg_weights = avg_weights / numIterations;
	all_avg_weights{illum} = avg_weights;
    normalized_weights = abs(avg_weights) / sum(abs(avg_weights));
    
    % data save
    SVM_accuracy = [SVM_accuracy;mean_accuracy normalized_weights'];
    
    save(filename,'SVM_accuracy');
    save(filename, 'all_avg_weights', '-append');

end


%% 可視化
%{
names = {'サブバンドコントラスト1', 'サブバンドコントラスト2', 'サブバンドコントラスト3', 'サブバンドコントラスト4', 'サブバンドコントラスト5', 'サブバンドコントラスト6', ...
         '輝度平均', '歪度', 'サブバンド歪度1', 'サブバンド歪度2', 'サブバンド歪度3', 'サブバンド歪度4', 'サブバンド歪度5', 'サブバンド歪度6', ...
         '輝度標準偏差', 'ハイライトコントラスト', 'ハイライトカバレッジ', '法線内積0°分散', '法線内積45°分散', '法線内積60°分散', ...
         '法線内積0°平均', '法線内積45°平均', '法線内積60°平均'};

coefs = mean(SVM_accuracy(:,2:24));

h1 = figure('Position', [1 1 1301 944], 'Name', 'SVMによる照明ごとのクラスター判別率');
figure(h1)
bar(SVM_accuracy(:,1));
%title('SVMによる照明ごとのクラスター判別率');
xlabel('照明番号', 'FontSize', 20); ylabel('SVM分類精度', 'FontSize', 20);
ylim([0.5 1]);


h2 = figure('Position', [1 1 1301 944], 'Name', '各特徴量の寄与率');
figure(h2)
bar(coefs);
% title('各特徴量の寄与率');
xlabel('特徴量', 'FontSize', 20); ylabel('寄与率', 'FontSize', 20);
xticks(1:numel(names));
xticklabels(names);
xtickangle(90); % x軸のラベルを90度傾ける
%}

