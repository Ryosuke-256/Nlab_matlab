function mustHaveFields(s, fields)
% mustHaveFields - 構造体が指定されたフィールドをすべて持っているか検証するカスタム関数
%
% 使い方:
%   arguments
%       myStruct (1,1) struct {mustHaveFields(myStruct, ["Field1", "Field2"])}
%   end

% 入力が構造体でない場合はエラー
if ~isstruct(s)
    % MATLAB標準のエラーIDに合わせることで、より自然なエラーメッセージにする
    error('MATLAB:validators:mustBeStruct', '値は構造体でなければなりません。');
end

% 指定されたフィールドのうち、構造体に存在しないものを見つける
missingFields = setdiff(string(fields), fieldnames(s));

% もし存在しないフィールドが一つでもあれば、エラーをスローする
if ~isempty(missingFields)
    error('DataAnalyzer:MissingFields', ...
          '構造体に必須フィールドがありません: %s', strjoin(missingFields, ', '));
end

end