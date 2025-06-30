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
        function plotHistogram(obj, dataSpec, mode)
            % 入力:
                % dataSpecA (struct): データセットAの仕様
                %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
                %     - TargetData:  主データ名 (e.g., "ZsHM")
                %     - DisplayName: プロットで表示する名前 (e.g., "銅")
                % mode : 0:全コンディション、1:それぞれのコンディション
                
            arguments
                obj
                dataSpec (1,1) struct {mustHaveFields(dataSpec, ["SetName", "TargetData", "DisplayName"])}
                mode (1,1) double
            end

            targetData = obj.getDataFromSet(dataSpec.SetName,dataSpec.TargetData);
            
            if mode == 0
                %全コンディションモード
                targetData_reshape = reshape(targetData,[],1);
                fprintf('ヒストグラムを作成中: %s の %s\n', dataSpec.SetName, dataSpec.TargetData);

                % ヒストグラムの描画
                fig = figure('Visible', 'off');
                
                PlotHistgram_Frequency(targetData_reshape(:),dataSpec.SetName, dataSpec.DisplayName);
                
                grid on;

                % プロットの保存
                plotFileName = sprintf('%s_%s_hist.jpg', dataSpec.SetName, dataSpec.DisplayName);
                plotFullPath = fullfile(obj.ResultDir, plotFileName); 

                saveas(fig, plotFullPath);
                close(fig);
                fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
            elseif mode == 1
                %材質、形状ごとの頻度を見るモード
                targetData_per = permute(targetData,[2,3,1,4,5]);
                targetData_reshape = reshape(targetData_per,size(targetData_per,1),size(targetData_per,2),[]);

                fprintf('ヒストグラムを作成中: %s の %s\n', dataSpec.SetName, dataSpec.TargetData);

                % ヒストグラムの描画
                for mat = 1:size(targetData_reshape,1)
                    fig = figure('Visible', 'off','Position',[50,50,1300,840]);
                    tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                    for shape = 1:size(targetData_reshape,2)
                        nexttile;
                        
                        PlotHistgram_Frequency(targetData_reshape(mat,shape,:),dataSpec.SetName, dataSpec.DisplayName);
                        
                        grid on;
                    end
                    % プロットの保存
                    plotFileName = sprintf('%s_%s_%s_hist.jpg', dataSpec.SetName, dataSpec.DisplayName,string(obj.MatNames3(mat)));
                    plotFullPath = fullfile(obj.ResultDir, plotFileName); 
                    
                    saveas(fig, plotFullPath);
                    close(fig);
                    fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
                end
            end
        end
        
        % --- 最適化された散布図プロットメソッド ---
        function plotScatter(obj, dataSpecA, dataSpecB, options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %     - ErrorData:   エラーデータ名 (e.g., "error_ZsHM")
            %     - DisplayName: プロットで表示する名前 (e.g., "銅")
            %
            %   dataSpecB (struct): データセットBの仕様 (dataSpecAと同様)
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "HdrSet"   (string): 使用するHDR定数セットの名前 (e.g., "HDRNum_30")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "PreDim"   (double): 回帰線の次元、1:線型回帰、2:非線形回帰
            %     - "Mode"     (double): 1:H、2:HM、3:HS、4:HMS

            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "ErrorData", "DisplayName"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData", "ErrorData", "DisplayName"])}
                options.Property (1,1) string = "GRI"
                options.HdrSet   (1,1) string {mustBeMember(options.HdrSet, ["HDRNum_15", "HDRNum_30"])} = "HDRNum_30"
                options.Amp      (1,1) double {mustBeNumeric} = 1.5
                options.PreDim   (1,1) double {mustBeNumeric} = 1
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end

            fprintf('散布図とヒストグラムの作成を開始します...\n');

            % --- データの抽出 (ヘルパーメソッドを利用) ---
            targetDataA = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            errorDataA  = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.ErrorData);
            targetDataB = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            errorDataB  = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.ErrorData);

            hdrData = obj.(options.HdrSet);
            
            if options.Mode == 1
                graphtitle = sprintf('%s vs %s about %s', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                % --- 散布図の作成と保存 ---
                obj.createAndSaveScatterPlot_H(targetDataA, targetDataB, hdrData, ...
                    dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property, graphtitle, options.Amp,options.PreDim);

                % --- ヒストグラムの作成と保存 ---
                obj.createAndSaveHistogram(targetDataA, errorDataA, targetDataB, errorDataB, ...
                    hdrData, graphtitle, options.Amp, dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);

                fprintf('プロットの作成が完了しました。\n');
                
            elseif options.Mode == 2
                graphtitle = sprintf('%s vs %s about %s', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                % --- 散布図の作成と保存 ---
                obj.createAndSaveScatterPlot_HM(targetDataA, targetDataB, hdrData, ...
                    dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property, graphtitle, options.Amp,options.PreDim);
                
            elseif options.Mode == 3
                graphtitle = sprintf('%s vs %s about %s', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                % --- 散布図の作成と保存 ---
                obj.createAndSaveScatterPlot_HS(targetDataA, targetDataB, hdrData, ...
                    dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property, graphtitle, options.Amp,options.PreDim);
                
            elseif options.Mode == 4
                graphtitle = sprintf('%s vs %s about %s', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                % --- 散布図の作成と保存 ---
                obj.createAndSaveScatterPlot_HMS(targetDataA, targetDataB, hdrData, ...
                    dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property, graphtitle, options.Amp,options.PreDim);
            end
        end
        
        function plotCorrBootstrap(obj,dataSpecA,dataSpecB,options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %     - DisplayName: プロットで表示する名前 (e.g., "銅")
            %
            %   dataSpecB (struct): データセットBの仕様 (dataSpecAと同様)
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Bootstrap"(double): Bootstrapの反復回数 (デフォルト: 10000)
            %     - "Mode"     (double): 1:H、2:HMS

            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "DisplayName"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData", "DisplayName"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.5
                options.Bootstrap(1,1) double {mustBeNumeric} = 10000
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end
            
            fprintf('相関係数のBootstrap...\n');

            % --- データの抽出 (ヘルパーメソッドを利用) ---
            targetDataA = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            targetDataB = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            
            if options.Mode == 1
                graphtitle = sprintf('%s vs %s about %s\nCorrelaton Coefficient', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                
                % --- 図の作成と保存 ---
                obj.CorrBootstrap_H(targetDataA, targetDataB, dataSpecA.DisplayName, dataSpecB.DisplayName, ...
                    options.Bootstrap, graphtitle, options.Amp, options.Property);

                fprintf('プロットの作成が完了しました。\n');
                
            elseif options.Mode == 2
               
                % --- 図の作成と保存 ---
                obj.CorrBootstrap_HMS(obj,targetDataA,targetDataB, dataSpecA.DisplayName, dataSpecB.DisplayName,...
                    options.Bootstrap, options.Amp);
                
                fprintf('プロットの作成が完了しました。\n');
            end
        end
        
        function plotCorrBootstrap_model(obj,dataSpecA,dataSpecB,options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %     - DisplayName: プロットで表示する名前 (e.g., "銅")
            %
            %   dataSpecB (struct): データセットBの仕様 (dataSpecAと同様)
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Bootstrap"(double): Bootstrapの反復回数 (デフォルト: 10000)
            %     - "Mode"     (double): 1:H、2:HMS

            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "DisplayName"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData", "DisplayName"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.5
                options.Bootstrap(1,1) double {mustBeNumeric} = 10000
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end
            
            fprintf('相関係数のBootstrap...\n');

            % --- データの抽出 (ヘルパーメソッドを利用) ---
            targetDataA = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            targetDataB = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            
            if options.Mode == 1
                graphtitle = sprintf('%s vs %s about %s\nCorrelaton Coefficient', dataSpecA.DisplayName, dataSpecB.DisplayName, options.Property);
                
                % --- 図の作成と保存 ---
                obj.CorrBootstrap_H(targetDataA, targetDataB, dataSpecA.DisplayName, dataSpecB.DisplayName, ...
                    options.Bootstrap, graphtitle, options.Amp, options.Property);

                fprintf('プロットの作成が完了しました。\n');
                
            elseif options.Mode == 2
               
                % --- 図の作成と保存 ---
                obj.CorrBootstrap_HMS(obj,targetDataA,targetDataB, dataSpecA.DisplayName, dataSpecB.DisplayName,...
                    options.Bootstrap, options.Amp);
                
                fprintf('プロットの作成が完了しました。\n');
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
        
        % --- 指定されたデータセットからデータを取得 ---
        function data = getDataFromSet(obj, setName, dataName)
            % データセットとデータの存在をチェックしてデータを返す
            if ~isKey(obj.DataSets, setName)
                error('DataAnalyzer:DataSetNotFound', '"%s" という名前のデータセットは存在しません。', setName);
            end
            dataSet = obj.DataSets(setName);
            if ~isfield(dataSet, dataName)
                error('DataAnalyzer:PropertyNotFound', 'データセット"%s"に "%s" というデータは存在しません。', setName, dataName);
            end
            data = dataSet.(dataName);
        end

        % --- 散布図  ---
        function createAndSaveScatterPlot_H(obj, dataA, dataB, hdrData, nameA, nameB, property, titleStr, amp, predictionDimention)
            fig = figure('Visible', 'off');
            try
                PlotScatter_ver1(dataA(:), dataB(:), ...
                               sprintf('%s-%s', nameA, property), ...
                               sprintf('%s-%s', nameB, property), ...
                               titleStr, hdrData, amp, predictionDimention);

                % プロットの保存
                grid on;
                plotFileName = sprintf('%svs%s_%s_H_scatter.jpg', nameA, nameB, property);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                fprintf('  -> 散布図を保存しました: %s\n', plotFullPath);
            catch ME
                close(fig);
                rethrow(ME);
            end
            close(fig);
        end
        
        function createAndSaveScatterPlot_HM(obj, dataA, dataB, hdrData, nameA, nameB, property, titleStr, amp, predictionDimention)
            fig = figure('Visible', 'off');
            try
                tiledlayout(2,2,'TileSpacing', 'compact', 'Padding', 'compact');
                for mat = 1:size(dataA,2)
                    nexttile;
                    PlotScatter_ver1(dataA(:,mat), dataB(:,mat), ...
                               sprintf('%s-%s', nameA, property), ...
                               sprintf('%s-%s', nameB, property), ...
                               titleStr, hdrData, amp, predictionDimention);
                end

                % プロットの保存
                grid on;
                plotFileName = sprintf('%svs%s_%s_HM_scatter.jpg', nameA, nameB, property);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                fprintf('  -> 散布図を保存しました: %s\n', plotFullPath);
            catch ME
                close(fig);
                rethrow(ME);
            end
            close(fig);
        end
        
        function createAndSaveScatterPlot_HS(obj, dataA, dataB, hdrData, nameA, nameB, property, titleStr, amp, predictionDimention)
            fig = figure('Visible', 'off');
            try
                tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                for shape = 1:size(dataA,2)
                    nexttile;
                    PlotScatter_ver1(dataA(:,shape), dataB(:,shape), ...
                               sprintf('%s-%s', nameA, property), ...
                               sprintf('%s-%s', nameB, property), ...
                               titleStr, hdrData, amp, predictionDimention);
                end

                % プロットの保存
                grid on;
                plotFileName = sprintf('%svs%s_%s_HS_scatter.jpg', nameA, nameB, property);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                fprintf('  -> 散布図を保存しました: %s\n', plotFullPath);
            catch ME
                close(fig);
                rethrow(ME);
            end
            close(fig);
        end
        
        function createAndSaveScatterPlot_HMS(obj, dataA, dataB, hdrData, nameA, nameB, property, titleStr, amp, predictionDimention)
            try
                for mat = 1:size(dataA,2)
                    fig = figure('Visible', 'off');
                    tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                    for shape = 1:size(dataA,3)
                        nexttile;
                        title = sprintf('%s\n%s',titleStr,string(obj.MatNames3(mat)));
                        PlotScatter_ver1(dataA(:,mat,shape),dataB(:,mat,shape), ...                             
                                    sprintf('%s-%s', nameA, property), ...
                                    sprintf('%s-%s', nameB, property), ...
                                    title, hdrData, amp, predictionDimention);
                    end                   
                    % プロットの保存
                    grid on;
                    plotFileName = sprintf('%svs%s_%s_HMS_%s_scatter.jpg', nameA, nameB, property,string(obj.MatNames3(mat)));
                    plotFullPath = fullfile(obj.ResultDir, plotFileName);
                    saveas(fig, plotFullPath);
                    fprintf('  -> 散布図を保存しました: %s\n', plotFullPath);
                    
                    close(fig);
                end
            catch ME
                rethrow(ME);
            end
        end

        % --- ヒストグラムを作成・保存  ---
        function createAndSaveHistogram(obj, dataA, errA, dataB, errB, hdrData, titleStr, amp, nameA, nameB, property)
            fig = figure('Visible', 'off');
            try
                PlotHistgram_ver1(dataA(:), errA(:), dataB(:), errB(:), ...
                                   'HDR', hdrData, 'Normalized z-score', titleStr, amp);

                % プロットの保存
                grid on;
                plotFileName = sprintf('%svs%s_%s_histgram.jpg', nameA, nameB, property);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                fprintf('  -> ヒストグラムを保存しました: %s\n', plotFullPath);
            catch ME
                close(fig);
                rethrow(ME);
            end
            close(fig);
        end
        
        function CorrBootstrap_H(obj,dataA,dataB,nameA,nameB,numBootstrap,titleStr,amp,property)
            dataA_reshaped = reshape(dataA,size(dataA,1),size(dataA,2),size(dataA,3),[]);
            dataB_reshaped = reshape(dataB,size(dataB,1),size(dataB,2),size(dataB,3),[]); 

            [corrA,corrAB,correlationDiffs] = Corr_Significance(dataA_reshaped,dataB_reshaped,numBootstrap);

            % 95%信頼区間の下限を確認
            sortedDiffs = sort(correlationDiffs);
            threshold = sortedDiffs(round(numBootstrap*0.05)); 

            % coef hisgram
            x = obj.MeanArray(dataA);
            y = obj.MeanArray(dataB);
            fig = figure('Visible', 'off');
            hold on;

            Graph_Significance(x,y,corrA,corrAB,threshold,amp);

            set(gca, 'XTick', []);
            title(titleStr,'FontSize',18*amp);

            % プロットの保存
            grid on;
            hold off;
            plotFileName = sprintf('%svs%s_%s_CorrCoef.jpg', nameA, nameB, property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            fprintf('  -> ヒストグラムを保存しました: %s\n', plotFullPath);
        end
        
        function CorrBootstrap_HMS(obj,dataA,dataB,nameA,nameB,numBootstrap,amp)
            dataA_reshaped = reshape(dataA,size(dataA,1),size(dataA,2),size(dataA,3),[]);
            dataB_reshaped = reshape(dataB,size(dataB,1),size(dataB,2),size(dataB,3),[]); 

            [corrA,corrAB,correlationDiffs,threshold] = Corr_MatShape_Significance(dataA_reshaped,dataB_reshaped,numBootstrap);

            Graph_MatShape_Significance(mean(dataA_reshaped,4),mean(dataA_reshaped,4),corrA,corrAB,threshold,...
                nameA,nameB,numBootstrap,obj.MatNames1,obj.ShapeNames,obj.ResultDir,amp);
        end
        
        function CorrBootstrap_model_H(obj,dataA,dataB,nameA,nameB,numBootstrap,titleStr,amp,property)
            dataA_reshaped = reshape(dataA,size(dataA,1),size(dataA,2),size(dataA,3),[]);
            dataB_reshaped = reshape(dataB,size(dataB,1),size(dataB,2),size(dataB,3),[]); 

            [corrA,corrAB,correlationDiffs] = Corr_Significance(dataA_reshaped,dataB_reshaped,numBootstrap);

            % 95%信頼区間の下限を確認
            sortedDiffs = sort(correlationDiffs);
            threshold = sortedDiffs(round(numBootstrap*0.05)); 

            % coef hisgram
            x = obj.MeanArray(dataA);
            y = obj.MeanArray(dataB);
            fig = figure('Visible', 'off');
            hold on;

            Graph_Significance(x,y,corrA,corrAB,threshold,amp);

            set(gca, 'XTick', []);
            title(titleStr,'FontSize',18*amp);

            % プロットの保存
            grid on;
            hold off;
            plotFileName = sprintf('%svs%s_%s_CorrCoef.jpg', nameA, nameB, property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            fprintf('  -> ヒストグラムを保存しました: %s\n', plotFullPath);
        end
        
        function [reducedData] = MeanArray(obj,array)
            dims = ndims(array);

            reducedData = array;

            for d = dims:-1:2
                reducedData = mean(reducedData, d);
            end
        end
    end
end