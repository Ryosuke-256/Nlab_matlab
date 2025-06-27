classdef DataAnalyzer < handle
    % 使い方:
    %  % 1. インスタンスを作成（コンストラクタでデータパスを渡す）
    %  analyzer = DataAnalyzer('ResultsPath',{'DataPathA','NameA'},{'DataPathB','NameB'});
    %
    %  % 2. 解析メソッドを実行
    %  summary = analyzer.getSummary();
    %  disp(summary);
    %
    %  % 3. プロットメソッドを実行
    %  analyzer.plotData();

    %======================================================================
    % 定数プロパティ
    %================================D======================================
    properties (Constant)
        % インスタンスを作成しなくても `DataAnalyzer.MIN_SAMPLES` のようにアクセス可能です。
        MatNames1 = {'cu0025', 'cu0129', 'pla0075', 'pla0225'};
        MatNames2 = {'cu_0.025', 'cu_0.129', 'pla_0.075', 'pla_0.225'};
        MatNames3 = {'cu-0.025', 'cu-0.129', 'pla-0.075', 'pla-0.225'};
        HDRNames_15 = [19, 39, 78, 80, 102, 125, 152, 203, 226, 227, 230, 232, 243, 278, 281];
        HDRNames_30 = [5,19,34,39,42,43,78,80,102,105,125,152,164,183,198,201,202,203,209,222,226,227,230,232,243,259,272,278,281,282];
        HDRNum_15 = [2,4,7,8,9,11,12,18,21,22,23,24,25,28,29];
        HDRNum_30 = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
        ShapeNames = {'sphere','bunny','dragon','boardA','boardB','boardC'};
    end
    
    %======================================================================
    % ユーザーがアクセス可能なプロパティ
    %======================================================================
    properties (SetAccess = private, GetAccess = public)
        % 解析データを格納するコンテナマップ
        % キー: データセット名 (e.g., 'DataA')
        % 値:   データ本体を含む構造体
        DataSets containers.Map
        
        % 解析結果を保存するディレクトリ
        ResultDir (1,1) string
    end
    
    %======================================================================
    % 内部でのみ利用するプロパティ
    %======================================================================
    properties (SetAccess = private, GetAccess = public)
        IsDataLoaded (1,1) logical = false; % データロード完了フラグ 
    end

    %======================================================================
    % メソッド定義
    %======================================================================
    methods
        % --- コンストラクタ ---
        function obj = DataAnalyzer(resultDir, varargin)
            % インスタンスを作成し、複数のデータセットをロードします。
            %
            % 入力:
            %   resultDir (string): 解析結果の保存先フォルダパス
            %   varargin (cell):  ファイルパスとデータセット名のペア
            %                     例: 'path1', 'name1', 'path2', 'name2', ...
            
            arguments
                resultDir (1,1) string
            end
            arguments (Repeating)
                varargin (1,2) cell % {filePath, dataSetName} のペア
            end

            fprintf('DataAnalyzerクラスのインスタンスを作成中...\n');
            
            % 結果保存ディレクトリを設定
            obj.ResultDir = resultDir;

            % データセットを格納するMapオブジェクトを初期化
            obj.DataSets = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            % 可変長引数をループで処理
            for i = 1:numel(varargin)
                filePath = varargin{i}{1};
                dataName = varargin{i}{2};
                
                fprintf('データセット "%s" をロードしています...\n  - ファイル: %s\n', dataName, filePath);
                
                % ファイルの存在チェック
                if ~isfile(filePath)
                    error('DataAnalyzer:FileNotFound', '指定されたファイルが見つかりません: %s', filePath);
                end
                
                % データロードと構造化を行うプライベートメソッドを呼び出し
                try
                    dataStruct = obj.loadAndStructureData(filePath);
                    obj.DataSets(dataName) = dataStruct; % Mapに格納
                    fprintf('  -> ロード成功\n');
                catch ME
                    fprintf('エラー: データセット "%s" のロードに失敗しました。\n', dataName);
                    rethrow(ME);
                end
            end
            fprintf('インスタンスの作成が完了しました。\n');
        end
        
        % ---頻度ヒストグラム　---
        function plotHistogram(obj, dataSetName, propertyName, mode)
            % 入力:
            % dataSetName (string): 対象のデータセット名 ('Set-A')
            % propertyName (string): プロットしたいデータの名前 ('RowHMS')
            % mode : 0:全コンディション、1:それぞれのコンディション
            arguments
                obj
                dataSetName (1,1) string
                propertyName (1,1) string
                mode (1,1) double
            end
            
            % データセットとプロパティの存在をチェック
            if ~isKey(obj.DataSets, dataSetName)
                error('DataAnalyzer:DataSetNotFound', '"%s" という名前のデータセットは存在しません。', dataSetName);
            end
            dataSet = obj.DataSets(dataSetName);
            if ~isfield(dataSet, propertyName)
                error('DataAnalyzer:PropertyNotFound', 'データセット"%s"に "%s" というデータは存在しません。', dataSetName, propertyName);
            end

            targetData = dataSet.(propertyName);
            
            if mode == 0
                %全コンディションモード
                targetData_reshape = reshape(targetData,[],1);
                fprintf('ヒストグラムを作成中: %s の %s\n', dataSetName, propertyName);

                % ヒストグラムの描画
                fig = figure('Visible', 'off'); % バックグラウンドで図を作成
                histogram(targetData_reshape(:), 'BinEdges', 0:0.025:1);

                xlabel('Bin', 'FontSize', 14);
                ylabel('Frequency', 'FontSize', 14);

                plotTitle = sprintf('%s - %s (Bin Width: 0.025)', dataSetName, propertyName);
                title(plotTitle, 'FontSize', 16, 'Interpreter', 'none');
                grid on;

                % プロットの保存
                plotFileName = sprintf('%s_%s_hist.jpg', dataSetName, propertyName);
                plotFullPath = fullfile(obj.ResultDir, plotFileName); 

                saveas(fig, plotFullPath);
                close(fig);
                fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
            elseif mode == 1
                %材質、形状ごとの頻度を見るモード
                targetData_per = permute(targetData,[2,3,1,4,5]);
                targetData_reshape = reshape(targetData_per,size(targetData_per,1),size(targetData_per,2),[]);

                fprintf('ヒストグラムを作成中: %s の %s\n', dataSetName, propertyName);

                for mat = 1:size(targetData_reshape,1)
                    fig = figure('Visible', 'off','Position',[50,50,1300,840]);
                    tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                    for shape = 1:size(targetData_reshape,2)
                        nexttile;
                        histogram(targetData_reshape(mat,shape,:), 'BinEdges', 0:0.025:1);

                        xlabel('Bin', 'FontSize', 14);
                        ylabel('Frequency', 'FontSize', 14);

                        plotTitle = sprintf('%s - %s (Bin Width: 0.025)', dataSetName, propertyName);
                        title(plotTitle, 'FontSize', 16, 'Interpreter', 'none');
                        grid on;
                    end
                    % プロットの保存
                    plotFileName = sprintf('%s_%s_%s_hist.jpg', dataSetName, propertyName,string(obj.MatNames3(mat)));
                    plotFullPath = fullfile(obj.ResultDir, plotFileName); 
                    
                    saveas(fig, plotFullPath);
                    close(fig);
                    fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
                end
            end
        end
    end
    
    % --- 内部ヘルパーメソッド ---
    methods (Access = private)
        function dataStruct = loadAndStructureData(~, filePath)
            % .matファイルをロードし、一貫した構造体に整理する
            loadedData = load(filePath);
            dataStruct = struct();
            
            % .matファイルに含まれる変数を動的に構造体のフィールドに割り当て
            fields = fieldnames(loadedData);
            for i = 1:numel(fields)
                fieldName = fields{i};
                dataStruct.(fieldName) = loadedData.(fieldName);
            end
        end
    end
end