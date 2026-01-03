function Results = Format_Thurstondata(resultpath, HDRNames, MatNames, ShapeNames, num_HDRs, num_Materials, num_Shapes, num_Participants)
Row_HMSPT = zeros(num_HDRs, num_Materials, num_Shapes, num_Participants, 1);
subject_name = {};


%allfileload
dirInfo = dir(resultpath);
filesNames = {dirInfo(~ismember({dirInfo(:).name}, {'.', '..'})).name};
numFiles = sum(~ismember({dirInfo(:).name}, {'.', '..'}));

%name
for foldernum =1:numFiles
    words = split(filesNames{foldernum},{'_', '.'});
    if ~any(strcmp(subject_name,words{1}))
        subject_name{end + 1} = words{1};
    end
end

for foldernum =1:numFiles
    filename = fullfile(resultpath, filesNames{foldernum});
    disp(filename);
    for materialnum = 1:length(MatNames)
        sheetName = MatNames{materialnum};
        sheetData = readtable(filename, 'Sheet', sheetName, 'ReadVariableNames', false);
        
        names = sheetData{:, 1};
        scores = sheetData{:, 2};

        words = split(filesNames{foldernum},{'_', '.'});

        for i = 1:length(names)
            nameStr = names{i};
            idStr = regexp(nameStr, '\d+', 'match');
            idNum = str2double(idStr(end));
            HDRIndex = find(HDRNames == idNum);
            MatIndex = find(strcmp(MatNames, sheetName));
            ParticipantsIndex = find(strcmp(subject_name,words{1}));
            if ~isempty(HDRIndex) && ~isempty(MatIndex) && ~isempty(ParticipantsIndex)
                Row_HMSPT(HDRIndex,MatIndex,1,ParticipantsIndex,1) = Row_HMSPT(HDRIndex,MatIndex,1,ParticipantsIndex) + scores(i)/5;
            end
        end
    end
end


disp(subject_name);

%---------------------------------------
% (HDR,Material,Shape)
%---------------------------------------
Row_HMS = mean(Row_HMSPT,4);
% GRI化
GRI_HMS = makeGRI(Row_HMSPT,1,4);
% 標準誤差
error_HMS = calculateSE(Row_HMSPT,[1,2,3],4);

%---------------------------------------
% (HDR,Material,Shape,Participants,Trial)
%---------------------------------------

GRI_HMSPT = BroadcastZscore(Row_HMS, Row_HMSPT, 1, [1,2,3]);

%---------------------------------------
% (HDR,Material)
%---------------------------------------
Row_HM = mean(Row_HMS,[3,4]);
% GRI
GRI_HM = mean(GRI_HMS,3);
% 標準誤差
error_HM = calculateSE(Row_HMSPT,[1,2],[3,4]);

%---------------------------------------
% (HDR,Shape)
%---------------------------------------
Row_HS = mean(permute(Row_HMS,[1,3,2]),3);
%zscore化
GRI_HS = mean(permute(GRI_HMS,[1,3,2]),3);
% 標準誤差
error_HS = calculateSE(Row_HMSPT,[1,3],[2,4]);

%---------------------------------------
% (HDR)
%---------------------------------------
Row_H = mean(Row_HM,2);
%zscore化
GRI_H = mean(GRI_HM,2);
% 標準誤差
error_H = calculateSE(Row_HMSPT,1,[2,3,4]);

% data save
Results = struct(...
    'Row_HMSPT', Row_HMSPT, 'GRI_HMSPT',GRI_HMSPT,...
    'Row_HMS',Row_HMS,'GRI_HMS', GRI_HMS, 'error_HMS', error_HMS, ...
    'Row_HM',Row_HM,'GRI_HM', GRI_HM, 'error_HM', error_HM, ...
    'Row_HS',Row_HS,'GRI_HS', GRI_HS, 'error_HS', error_HS, ...
    'Row_H',Row_H,'GRI_H', GRI_H, 'error_H', error_H ...
);
end

