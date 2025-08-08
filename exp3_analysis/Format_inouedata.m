function Results = Format_inouedata(resultpath, HDRNames_30, HDRNames_15, MatNames, ShapeNames, num_HDRs, num_Materials, num_Shapes, num_Participants, num_Trials)
Row_HMSPT = zeros(num_HDRs, num_Materials, num_Shapes, num_Participants, num_Trials);

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
        %disp(datafile);
        
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
                    Row_HMSPT(hdr, MatIndex, ShapeIndex,SubjectsIndex,Trial) = InoueRowData(Trial,hdr);
                end
            end
        end
    end
end
disp(subject_name);

%---------------------------------------
% (HDR,Material,Shape)
%---------------------------------------
Row_HMS = mean(Row_HMSPT,[4,5]);
% GRI化
GRI_HMS = makeGRI(Row_HMSPT,1,[4,5]);
% 標準誤差
error_HMS = calculateSE(Row_HMSPT,[1,2,3],[4,5]);

%---------------------------------------
% (HDR,Material)
%---------------------------------------
Row_HM = mean(Row_HMS,[3,4,5]);
% GRI
GRI_HM = mean(GRI_HMS,3);
% 標準誤差
error_HM = calculateSE(Row_HMSPT,[1,2],[3,4,5]);

%---------------------------------------
% (HDR,Shape)
%---------------------------------------
Row_HS = mean(permute(Row_HMS,[1,3,2]),3);
%zscore化
GRI_HS = mean(permute(GRI_HMS,[1,3,2]),3);
% 標準誤差
error_HS = calculateSE(Row_HMSPT,[1,3],[2,4,5]);

%---------------------------------------
% (HDR)
%---------------------------------------
Row_H = mean(Row_HM,2);
%zscore化
GRI_H = mean(GRI_HM,2);
% 標準誤差
error_H = calculateSE(Row_HMSPT,[1],[2,3,4,5]);

%% VS Exp1,2
%---------------------------------------
% (bunny,15HDR,Material)
%---------------------------------------
Row_HMPT_30_bny = squeeze(Row_HMSPT(:,:,2,:,:));

% be 15 data
Row_HMPT_15_bny = zeros(15,num_Materials,num_Participants,5);
[common_names, idx30, idx15] = intersect(HDRNames_30, HDRNames_15);
Row_HMPT_15_bny(idx15,:,:,5) = Row_HMPT_30_bny(idx30,:,:,5);

%生データ
Row_HM_15_bny = mean(Row_HMPT_15_bny,[3,4]);
%GRI化
GRI_HM_15_bny = makeGRI(Row_HMPT_15_bny,1,[3,4]);
%errorbar
error_HM_15_bny = calculateSE(Row_HMPT_15_bny,[1,2],[3,4]);

%---------------------------------------
% (bunny,15HDR)
%---------------------------------------
Row_H_15_bny = mean(Row_HM_15_bny,2);
%GRI化
GRI_H_15_bny = mean(GRI_HM_15_bny,2);
%errorbar
error_H_15_bny = calculateSE(Row_HMPT_15_bny,[1],[2,3,4]);


% data save
Results = struct(...
    'Row_HMSPT', Row_HMSPT, ...
    'Row_HMS',Row_HMS,'GRI_HMS', GRI_HMS, 'error_HMS', error_HMS, ...
    'Row_HM',Row_HM,'GRI_HM', GRI_HM, 'error_HM', error_HM, ...
    'Row_HS',Row_HS,'GRI_HS', GRI_HS, 'error_HS', error_HS, ...
    'Row_H',Row_H,'GRI_H', GRI_H, 'error_H', error_H, ...
    'GRI_HM_15', GRI_HM_15_bny, 'error_HM_15', error_HM_15_bny, ...
    'GRI_H_15', GRI_H_15_bny, 'error_H_15', error_H_15_bny ...
);

end