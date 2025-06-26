function Results = Format_inouedata(resultpath, HDRNames_30, HDRNames_15, MatNames, ShapeNames, num_HDRs, num_Materials, num_Shapes, num_2DParticipants, num_Trials)
RowHMSPT = zeros(num_HDRs, num_Materials, num_Shapes, num_2DParticipants, num_Trials);

%indivsual folder
dirInfo1 = dir(resultpath);
FolderNames1 = {dirInfo1(~ismember({dirInfo1(:).name}, {'.', '..'})).name};
numFolders1 = sum(~ismember({dirInfo1(:).name}, {'.', '..'}));

%indivisual name
subject_name = {};

for foldernum1 = 1:numFolders1
    namefolder = fullfile(resultpath, FolderNames1{foldernum1});
    %exp data
    dirInfo2 = dir(namefolder);
    FileNames2 = {dirInfo2(~ismember({dirInfo2(:).name}, {'.', '..'})).name};
    numFile2 = sum(~ismember({dirInfo2(:).name}, {'.', '..'}));
    for foldernum2 = 1:numFile2
        datafile = fullfile(namefolder,FileNames2{foldernum2});
        disp(datafile);
        
        load(datafile);
        InoueRowData = illumiPsvAll;

        %words
        words = split(FileNames2{foldernum2},{'_', '.'});
        if ~any(strcmp(subject_name,words{1}))
            subject_name{end + 1} = words{1};
        end

        for Trial = 1:size(InoueRowData,1)
            for hdr = 1:size(InoueRowData,2)
                [isMatch,~] = ismember(MatNames,words);
                MatIndex = find(isMatch);
                [isMatch,~] = ismember(ShapeNames,words);
                ShapeIndex = find(isMatch);
                SubjectsIndex = foldernum1;
                if ~isempty(MatIndex) && ~isempty(ShapeIndex)
                    RowHMSPT(hdr, MatIndex, ShapeIndex,SubjectsIndex,Trial) = InoueRowData(Trial,hdr);
                end
            end
        end
    end
end
disp(subject_name);
%Trial情報統合
RowHMSP = mean(RowHMSPT,5);
%zscore化
ZsHMSP = zeros(size(RowHMSP));
for subject = 1:size(RowHMSP,4)
    for model = 1:size(RowHMSP,3)
        for material = 1:size(RowHMSP,2)
            ZsHMSP(:, material,model,subject) = zscore(RowHMSP(:,material,model,subject));
        end
    end
end

%---------------------------------------
% (HDR,Material,Shape)
%---------------------------------------
RowHMS = mean(RowHMSP,4);
%zscore化
ZsHMS = zeros(size(RowHMS));
for model = 1:size(RowHMS,3)
    for material = 1:size(RowHMS,2)
        ZsHMS(:, material,model) = zscore(RowHMS(:,material,model));
    end
end

% 標準誤差
error_ZsHMS = std(RowHMSP, 0, 4) / sqrt(size(RowHMSP, 4));

%正規化
NormHMS = zeros(size(ZsHMS));
error_NormHMS = zeros(size(error_ZsHMS));
for i = 1:size(ZsHMS, 3)
    for j = 1:size(ZsHMS,2)
        hdr_min = min(ZsHMS(:, j, i));
        hdr_max = max(ZsHMS(:, j, i));
        
        NormHMS(:, j, i) = 2 * (ZsHMS(:, j, i) - hdr_min) / (hdr_max - hdr_min)-1;
        error_NormHMS(:, j, i) = error_ZsHMS(:, j, i) / (hdr_max - hdr_min);
    end
end
%---------------------------------------
% (HDR,Material)
%---------------------------------------
RowHM = mean(RowHMS,3);
%zscore化
ZsHM = zeros(size(RowHM));
for material = 1:size(RowHM,2)
    ZsHM(:, material) = zscore(RowHM(:,material));
end

% 標準誤差
RowHM_reshaped = reshape(RowHMSP,size(RowHMSP,1),size(RowHMSP,2),[]);
error_ZsHM = std(RowHM_reshaped, 0, 3)/ sqrt(size(RowHMSP,3)+size(RowHMSP,4));
%正規化
NormHM = zeros(size(ZsHM));
error_NormHM = zeros(size(error_ZsHM));
for i = 1:size(ZsHM, 2)
    hdr_min = min(ZsHM(:, i));
    hdr_max = max(ZsHM(:, i));
    
    NormHM(:,i) = 2 * (ZsHM(:, i) - hdr_min) / (hdr_max - hdr_min)-1;
    error_NormHM(:, i) = error_ZsHM(:, i) / (hdr_max - hdr_min);
end
%---------------------------------------
% (HDR,Shape)
%---------------------------------------
RowHS = mean(permute(RowHMS,[1,3,2]),3);
%zscore化
ZsHS = zeros(size(RowHS));
for model = 1:size(RowHS,2)
    ZsHS(:, model) = zscore(RowHS(:,model));
end

% 標準誤差
RowHMSP_per = permute(RowHMSP,[1,3,2,4]);
HS_reshaped = reshape(RowHMSP_per,size(RowHMSP_per,1),size(RowHMSP_per,2),[]);
error_ZsHS = std(HS_reshaped, 0, 3)/ sqrt(size(RowHMSP_per,3)+size(RowHMSP_per,4));
%正規化
NormHS = zeros(size(ZsHS));
error_NormHS = zeros(size(error_ZsHS));
for i = 1:size(ZsHS, 2)
        hdr_min = min(ZsHS(:,i));
        hdr_max = max(ZsHS(:,i));
        
        NormHS(:,i) = 2 * (ZsHS(:,i) - hdr_min) / (hdr_max - hdr_min)-1;
        error_NormHS(:,i) = error_ZsHS(:,i) /(hdr_max - hdr_min);
end
%---------------------------------------
% (HDR)
%---------------------------------------
RowH = mean(RowHM,2);
%zscore化
ZsH = zeros(size(RowH));
ZsH(:) = zscore(RowH(:));

% 標準誤差
H_reshaped = reshape(RowHMSP,size(RowHMSP,1),[]);
error_ZsH = std(H_reshaped, 0, 2)/ sqrt(size(RowHMSP,2)+size(RowHMSP,3)+size(RowHMSP,4));
%正規化
NormH = zeros(size(ZsH));
error_NormH = zeros(size(error_ZsH));
hdr_min = min(ZsH(:));
hdr_max = max(ZsH(:));

NormH(:) = 2 * (ZsH(:) - hdr_min) / (hdr_max - hdr_min)-1;
error_NormH(:) = error_ZsH(:) /(hdr_max - hdr_min);
%---------------------------------------
% VS Exp1,2 (bunny,15HDR,Material)
%---------------------------------------
InoueRow30bnyHMP = RowHMSP(:,:,2,:);

% be 15 data
Row15bnyHMP = zeros(15,num_Materials,length(subject_name));
[common_names, idx30, idx15] = intersect(HDRNames_30, HDRNames_15);
Row15bnyHMP(idx15,:,:) = InoueRow30bnyHMP(idx30,:,:);

Row15bnyHM = mean(Row15bnyHMP,3);
%zscore化
Zs15bnyHM = zeros(size(Row15bnyHM));
for material = 1:size(Zs15bnyHM,2)
    Zs15bnyHM(:,material) = zscore(Row15bnyHM(:,material));
end

%errorbar
error_HM15 = std(Row15bnyHMP,0,3)/sqrt(size(Row15bnyHMP,3));

%---------------------------------------
% VS Exp1,2 (bunny,15HDR)
%---------------------------------------
Row15bnyH = mean(Row15bnyHM,2);

%zscore化
Zs15bnyH = zeros(size(Row15bnyH));
Zs15bnyH(:) = zscore(Row15bnyH(:));

%errorbar
Row15bnyHMP_reshape = reshape(Row15bnyHMP,size(Row15bnyHMP,1),[]);
error_H15 = std(Row15bnyHMP_reshape,0,3)/sqrt(size(Row15bnyHMP,3)+size(Row15bnyHMP,2));

% data save
Results = struct(...
    'RowHMSPT', RowHMSPT, ...
    'RowHMS',RowHMS,'ZsHMS', ZsHMS, 'error_ZsHMS', error_ZsHMS, ...
    'RowHM',RowHM,'ZsHM', ZsHM, 'error_ZsHM', error_ZsHM, ...
    'RowHS',RowHS,'ZsHS', ZsHS, 'error_ZsHS', error_ZsHS, ...
    'RowH',RowH,'ZsH', ZsH, 'error_ZsH', error_ZsH, ...
    'Zs15bnyHM', Zs15bnyHM, 'error_HM15', error_HM15, ...
    'Zs15bnyH', Zs15bnyH, 'error_H15', error_H15 ...
);

end