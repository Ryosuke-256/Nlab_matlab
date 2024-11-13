clear all;

%% 1. 実験条件・照明環境ごとの選好尺度値（被験者平均）
load('z_conditionList.mat');

rootpath = '/home/nagailab/デスクトップ/inoue_programs/experiment1/data/psvList';
subject = ["aso","dogu", "horiuchi", "son", "takanashi"];
directory = '5';

illumNum = 30;
[conditionNum,~] = size(experiment_condition);
[~, subjectNum] = size(subject);

psvListAll = zeros(conditionNum, illumNum, subjectNum);

no_conditions = ["makihiraA", "makihiraB", "makihiraC"];

for j = 1 : subjectNum
    current_subject = subject(j);
    for i = 1 : conditionNum
            filename = strcat(current_subject,directory,'_', experiment_condition(i,2),'_',experiment_condition(i,1),'_', experiment_condition(i,3),'.mat');
            filepath = strcat(rootpath, '/', current_subject,'/',directory,'/', filename);
            
            disp(filename);
            load(filepath);
            
            psvListAll(i,:, j) = illumiPsvAll(5,:);
    end
end

psvList = mean(psvListAll,3);

%% 牧平実験の選好尺度値を加える
load('/home/nagailab/デスクトップ/inoue_programs/experiment1/data/bangou0825.mat');

material = ["material1", "material2"];
mesh = ["shape1", "shape2", "shape3"];
roughness = ["gloss1", "gloss2"];
[~, meshNum] = size(mesh);
[~, materialNum] = size(material);
[~, roughnessNum] = size(roughness);

for mesh_type = 1 : meshNum
    for material_type = 1 : materialNum
        for roughness_type = 1 : roughnessNum
            filename = strcat('response_', roughness(roughness_type),'_',material(material_type),'_', mesh(mesh_type),'.mat');
            filepath = strcat(rootpath, '/makihira/', filename);
            
            load(filepath);
            
            [sorted_bangou, sorted_index] = sort(bangou0825);
            sorted_Object_response = zscore(Object_response(sorted_index));
            
            psvList = [psvList; sorted_Object_response'];
        end
    end
end
psvList_org = psvList;

psvList =[psvList_org(1:18,:); psvList_org(55:60,:);psvList_org(19:36,:);psvList_org(61:66,:);psvList_org(37:54,:)];

save('z_psvList_withMK.mat', 'psvList');
