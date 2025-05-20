function [newData] = makihiraToinoue(originalData,desireOrder)
numRows = height(originalData);
newData = table();

for i = 1:length(desireOrder)
    varName = desireOrder{i};
    if ismember(varName, originalData.Properties.VariableNames)
        newData.(varName) = originalData.(varName);
    else
        newData.(varName) = zeros(numRows, 1);
    end
end

disp(newData);

end