function data = Format_forExp5(data)
arguments
    data struct
end

Mat_extract = [1,2];
Shape_extract = [2,4,6];

data.Row_HMSPT = data.Row_HMSPT(:,Mat_extract,Shape_extract,:,:);
data.GRI_HMSPT = data.GRI_HMSPT(:,Mat_extract,Shape_extract,:,:);
data.Row_HMS = data.Row_HMS(:,Mat_extract,Shape_extract);
data.GRI_HMS = data.GRI_HMS(:,Mat_extract,Shape_extract);
data.error_HMS = data.error_HMS(:,Mat_extract,Shape_extract);
data.Row_HM = data.Row_HM(:,Mat_extract);
data.GRI_HM = data.GRI_HM(:,Mat_extract);
data.error_HM = data.error_HM(:,Mat_extract);
data.Row_HS = data.Row_HS(:,Shape_extract);
data.GRI_HS = data.GRI_HS(:,Shape_extract);
data.error_HS = data.error_HS(:,Shape_extract);
data.GRI_HM_15 = data.GRI_HM_15(:,Mat_extract);

end

