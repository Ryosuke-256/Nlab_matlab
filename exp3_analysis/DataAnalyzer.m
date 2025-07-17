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
    %======================================================================
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
        ParticipantsNames_Exp3 = {'Jiang','Nakajima','ODA','Satou','ishiguro','kawahara'},
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
        %% --- コンストラクタ ---
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
        
        %% ---頻度ヒストグラム　---
        function plotHistogram(obj, dataSpec, mode)
            % 入力:
                % dataSpecA (struct): データセットAの仕様
                %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
                %     - TargetData:  主データ名 (e.g., "ZsHM")
                % mode : 0:全コンディション、1:それぞれのコンディション
                
            arguments
                obj
                dataSpec (1,1) struct {mustHaveFields(dataSpec, ["SetName", "TargetData"])}
                mode (1,1) double
            end

            targetData = obj.getDataFromSet(dataSpec.SetName,dataSpec.TargetData);
            
            if mode == 0
                %全コンディションモード
                targetData_reshape = reshape(targetData,[],1);
                fprintf('ヒストグラムを作成中: %s の %s\n', dataSpec.SetName, dataSpec.TargetData);

                % ヒストグラムの描画
                fig = figure('Visible', 'off');
                
                PlotHistgram_Frequency(targetData_reshape(:),dataSpec.SetName);
                
                grid on;

                % プロットの保存
                plotFileName = sprintf('%s_hist.jpg', dataSpec.SetName);
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
                        
                        PlotHistgram_Frequency(targetData_reshape(mat,shape,:),dataSpec.SetName);
                        
                        grid on;
                    end
                    % プロットの保存
                    plotFileName = sprintf('%s_%s_hist.jpg', dataSpec.SetName,string(obj.MatNames3(mat)));
                    plotFullPath = fullfile(obj.ResultDir, plotFileName); 
                    
                    saveas(fig, plotFullPath);
                    close(fig);
                    fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
                end
            end
        end

        %% --- 散布図　---  
        function plotScatter(obj, dataSpecA, dataSpecB, options)            
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %     - ErrorData:   エラーデータ名 (e.g., "error_ZsHM")
            %
            %   dataSpecB (struct): データセットBの仕様 (dataSpecAと同様)
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "HdrSet"   (string): 使用するHDR定数セットの名前 (e.g., "HDRNum_30")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "PreDim"   (double): 回帰線の次元、1:線型回帰、2:非線形回帰
            %     - "Mode"     (string): H、HM、HS、HMS
            %     - "Resudual" (string): regression, outlier

            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "ErrorData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData", "ErrorData"])}
                options.Property (1,1) string = "GRI"
                options.HdrSet   (1,1) string {mustBeMember(options.HdrSet, ["HDRNum_15", "HDRNum_30"])} = "HDRNum_30"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.PreDim   (1,1) double {mustBeNumeric} = 1
                options.Mode     (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "H"
                options.Residual (1,1) string {mustBeMember(options.Residual, ["regression", "outlier"])} = "regression"
            end

            fprintf('散布図の作成を開始します...\n');

            % --- 1. データの準備 ---
            % 描画に必要なデータを構造体にまとめる
            plotData.targetA = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            plotData.errorA  = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.ErrorData);
            plotData.targetB = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            plotData.errorB  = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.ErrorData);
            plotData.hdr     = obj.(options.HdrSet);

            % 描画オプションを構造体にまとめる
            plotOptions = options;
            plotOptions.NameA = dataSpecA.SetName;
            plotOptions.NameB = dataSpecB.SetName;
            plotOptions.Title = sprintf('%s vs %s about %s', plotOptions.NameA, plotOptions.NameB, plotOptions.Property);

            % --- 2. 統合されたヘルパー関数を呼び出す ---
            obj.generateScatterPlot(plotData, plotOptions);

            fprintf('プロットの作成が完了しました。\n');
        end
        
        %% 相関係数のノイズ天井検定のBootstrap        
        function plotCorrBootstrap(obj, dataSpecA, dataSpecB, options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %
            %   dataSpecB (struct): データセットBの仕様 (dataSpecAと同様)
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Bootstrap"(double): Bootstrapの反復回数 (デフォルト: 10000)
            %     - "Mode"     (double): 1:H、2:HM、3:HS、4:HMS
            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData"])}
                % オプション引数 (名前/値ペア)
                options.Property  (1,1) string = "GRI"
                options.Amp       (1,1) double {mustBeNumeric} = 1.0
                options.Bootstrap (1,1) double {mustBeInteger, mustBePositive} = 10000
                options.Mode (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "H"
                options.Split     (1,1) double {mustBeInteger, mustBePositive} = 3
                options.Distribution (1,1) logical = false
            end

            fprintf('相関係数のBootstrapを実行中 (Mode: %s)...\n', options.Mode);

            % --- 1. データの準備 ---
            plotDataA.target = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            plotDataB.target = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);

            % --- 2. 描画オプションを構造体にまとめる ---
            plotOptions = options;
            plotOptions.Title = sprintf('%s vs %s about %s', dataSpecA.SetName, dataSpecB.SetName, plotOptions.Property);
            plotDataA.Name = dataSpecA.SetName;
            plotDataB.Name = dataSpecB.SetName;

            % --- 3. 統合された単一のヘルパー関数を呼び出す ---
            obj.generateBootstrapPlot(plotDataA,plotDataB, plotOptions);
            %{
            if options.Distribution
                obj.generateBootstrapDistribution(plotDataA, plotOptions);
                obj.generateBootstrapDistribution(plotDataB, plotOptions);
            end
            %}

            fprintf('プロットの作成が完了しました。\n');
        end
        
        %% 照明モデルに対する相関係数のBootstrapをプロット
        function plotCorrBootstrap_model(obj,dataSpecA,dataSpecB,dataSpecC,options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
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
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData"])}
                dataSpecC (1,1) struct {mustHaveFields(dataSpecC, ["SetName", "TargetData"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.Bootstrap(1,1) double {mustBeNumeric} = 10000
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end
            
            fprintf('相関係数のBootstrap...\n');

            % --- データの抽出 (ヘルパーメソッドを利用) ---
            targetDataA = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            targetDataB = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            targetDataC = obj.getDataFromSet(dataSpecC.SetName, dataSpecC.TargetData);
            
            if options.Mode == 1
                % --- 図の作成と保存 ---
                obj.CorrBootstrap_model_H(targetDataA, targetDataB, targetDataC,...
                    dataSpecA.SetName, dataSpecB.SetName, dataSpecC.SetName, ...
                    options.Bootstrap, options.Amp, options.Property);

                fprintf('プロットの作成が完了しました。\n');
            end
        end
        
        %% 残差の折れ線グラフをプロット
        function plotResiduals(obj, dataSpecA, dataSpecB, options)
            % 2つのデータセットから指定されたデータを取得し、その残差を計算・プロットします。
            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.Save     (1,1)logical = true
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end

            fprintf('残差プロットを作成しています...\n');

            % --- 1. データの抽出と検証 ---
            data1 = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            data2 = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);

            if numel(data1) ~= numel(data2)
                error('比較する2つのデータの要素数が異なります。');
            end

            % --- 2. 残差の計算 ---
            residuals = data1 - data2;
            fprintf('残差の平均: %.4f\n', mean(residuals));
            fprintf('残差の標準偏差: %.4f\n', std(residuals));

            % --- 3. ヘルパー関数を呼び出してプロットと保存を実行 ---
            obj.generateResidualPlot(residuals, dataSpecA, dataSpecB, options);
        end
        
        function plotScatter_indivisual(obj,dataSpecA,dataSpecB,options)
            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.Save     (1,1)logical = true
                options.Mode     (1,1) double {mustBeNumeric} = 1
            end

            fprintf('残差プロットを作成しています...\n');

            % --- 1. データの抽出と検証 ---
            data1 = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            data2 = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);

            if numel(data1) ~= numel(data2)
                error('比較する2つのデータの要素数が異なります。');
            end

            % --- 2. 残差の計算 ---
            residuals = data1 - data2;
            fprintf('残差の平均: %.4f\n', mean(residuals));
            fprintf('残差の標準偏差: %.4f\n', std(residuals));

            % --- 3. ヘルパー関数を呼び出してプロットと保存を実行 ---
            obj.generateResidualPlot(residuals, dataSpecA, dataSpecB, options);
        end
    end
    
    % --- 内部ヘルパーメソッド ---
    methods (Access = private)
        %% 便利ツール
        function [reducedData] = MeanArray(~,array,limit)
            dims = ndims(array);

            reducedData = array;

            for d = dims:-1:limit+1
                reducedData = mean(reducedData, d);
            end
        end
        
        % データをロード
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

        %% --- 散布図  ---
        function generateScatterPlot(obj, plotData, plotOptions)
            % HMSモードはFigureを複数作成するため、特別に処理
            if plotOptions.Mode == "HMS"
                for mat = 1:size(plotData.targetA, 2)
                    obj.drawAndSavePlot(plotData, plotOptions, mat);
                end
            else
                % H, HM, HSモードは単一のFigureを作成
                obj.drawAndSavePlot(plotData, plotOptions);
            end
        end

        % --- 実際の描画と保存を行うヘルパー関数 ---
        function drawAndSavePlot(obj, plotData, plotOptions, mat_idx)
            if nargin < 4
                mat_idx = []; % HMSモードでない場合は空
            end

            fig = [];
            try
                fig = figure('Visible', 'off');

                % モードに応じてループ処理
                switch plotOptions.Mode
                    case "H"
                        titleStr = plotOptions.Title;
                        PlotScatter_ver2(plotData.targetA(:), plotData.targetB(:),"XLabel",plotOptions.NameA,"YLabel",plotOptions.NameB,...
                            "Mode",plotOptions.Residual,"Title",titleStr,"HDRNo",plotData.hdr,"Amp",plotOptions.Amp,"FitType","linear");
                    case {"HM", "HS"}                        
                        if plotOptions.Mode == "HM"
                            tiledlayout(2,2,'TileSpacing', 'compact', 'Padding', 'compact');
                            labels = obj.MatNames3;
                        else % "HS"
                            tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                            labels = obj.ShapeNames;
                        end
                        
                        sgtitle(plotOptions.Title, 'Interpreter', 'none');
                        for i = 1:size(plotData.targetA, 2)
                            nexttile;
                            titleStr = sprintf('%s',string(labels(i)));
                            
                            PlotScatter_ver2(plotData.targetA(:,i), plotData.targetB(:,i),"XLabel",plotOptions.NameA,"YLabel",plotOptions.NameB,...
                                "Mode",plotOptions.Residual,"Title",titleStr,"HDRNo",plotData.hdr,"Amp",plotOptions.Amp,"FitType","linear");
                        end
                    case "HMS"
                        tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                        titleStr = sprintf('%s-%s', plotOptions.Title,string(obj.MatNames3(mat_idx)));
                        sgtitle(titleStr, 'Interpreter', 'none');
                        
                        for shape = 1:size(plotData.targetA, 3)
                            nexttile;
                            titleStr = sprintf('%s',string(obj.ShapeNames(shape)));
                            
                            PlotScatter_ver2(plotData.targetA(:,mat_idx,shape), plotData.targetB(:,mat_idx,shape),...
                                "XLabel",plotOptions.NameA,"YLabel",plotOptions.NameB,...
                                "Mode",plotOptions.Residual,"Title",titleStr,"HDRNo",plotData.hdr,"Amp",plotOptions.Amp,"FitType","linear");
                        end
                end

                % ファイル名の決定と保存
                filename_suffix = plotOptions.Mode;
                if plotOptions.Mode == "HMS"
                    filename_suffix = "HMS_" + string(obj.MatNames3(mat_idx));
                end
                plotFileName = sprintf('%svs%s_%s_%s_scatter.jpg', plotOptions.NameA, plotOptions.NameB, plotOptions.Property, filename_suffix);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                fprintf('  -> 散布図を保存しました\n');

            catch ME
                if ~isempty(fig), close(fig); end
                rethrow(ME);
            end
        end


        %% --- ヒストグラムを作成・保存  ---
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
        
        %% Bootstrap
        function generateBootstrapPlot(obj, plotDataA,plotDataB, plotOptions)
            % ■ 入力:
            %   plotData (struct): データセットAの仕様
            %     - Name:     DataSetsの名前 (e.g., "Set-A")
            %     - target:  主データ
            %
            %   plotOptions (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Bootstrap"(double): Bootstrapの反復回数 (デフォルト: 10000)
            %     - "Mode"     (double): 1:H、2:HM、3:HS、4:HMS
            
            % HMSモードはFigureを複数作成するため、特別に処理
            if plotOptions.Mode == "HMS"
                for mat = 1:size(plotData.target, 2)
                    obj.BootstrapPlot(plotDataA,plotDataB, plotOptions, mat);
                end
            else
                % H, HM, HSモードは単一のFigureを作成
                obj.BootstrapPlot(plotDataA,plotDataB, plotOptions);
            end
        end
        
        function BootstrapPlot(obj, plotDataA,plotDataB, plotOptions,mat_idx)
            if nargin < 4
                mat_idx = [];
            end
            
            dataA = plotDataA.target;
            dataB = plotDataB.target;
            %plotOptions.Amp = 1;
            
            try
                % figureの宣言
                fig_significance = figure('Visible', 'off');
                fig_boxplotA = figure('Visible', 'off');
                
                switch plotOptions.Mode
                    case "H"
                        dataA_r = squeeze(mean(mean(dataA,3),2));
                        dataB_r = squeeze(mean(mean(dataB,3),2));
                        
                        [ceiling_distAA,ceiling_distAB,p_value,observed_corr,all_sampled_dataA,all_sampled_dataB] = Corr_Significance_v2(dataA_r, dataB_r, plotOptions.Bootstrap, plotOptions.Split);
                        
                        % ---plot significance ---
                        t_significance = tiledlayout(fig_significance,1,1, 'Padding', 'normal');
                        ax_significance = nexttile(t_significance);
                        Graph_Significance(ax_significance,observed_corr, ceiling_distAA,ceiling_distAB, p_value,'Amp',plotOptions.Amp,'Title',plotOptions.Title);
                        
                        % ---plot innner correlation coefficient ---
                        t_boxplot = tiledlayout(fig_boxplotA,1,1, 'Padding', 'normal');
                        figListA.boxplot = t_boxplot;
                        
                        plotDataA_r.Original = dataA_r;
                        plotDataA_r.Name = plotDataA.Name;
                        plotDataA_r.Resampled = all_sampled_dataA;
                        
                        if plotOptions.Distribution
                            obj.plotBootstrapDistribution(figListA,plotDataA_r,plotOptions);
                        end

                    case {"HM", "HS"}
                        if plotOptions.Mode == "HS"
                            dataA_r = squeeze(mean(dataA,2));
                            dataB_r = squeeze(mean(dataB,2));
                            labels = obj.ShapeNames;
                            t_boxplot = tiledlayout(fig_boxplotA,2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                        else % HMモード
                            dataA_r = squeeze(mean(dataA,3));
                            dataB_r = squeeze(mean(dataB,3));
                            labels = obj.MatNames3;
                            t_boxplot = tiledlayout(fig_boxplotA,2,2,'TileSpacing', 'compact', 'Padding', 'compact');
                        end
                         
                        
                        % --- initialization significance hist
                        t_significance = tiledlayout(fig_significance,1,1, 'Padding', 'normal');
                        ax_significance = nexttile(t_significance);
                        
                        loopLimit = size(dataA_r, 2);                        
                        for i = 1:loopLimit
                            dataA_r2 = squeeze(dataA_r(:,i,:,:));
                            dataB_r2 = squeeze(dataB_r(:,i,:,:));
                            fprintf("%s",string(labels(i)));
                            
                            % calculate bootstrap
                            [ceiling_distAA,ceiling_distAB,p_value,observed_corr,all_sampled_dataA,all_sampled_dataB] = Corr_Significance_v2(dataA_r2, dataB_r2, plotOptions.Bootstrap, plotOptions.Split);
                            
                            % ---plot significance hist ---
                            Graph_Significance(ax_significance,observed_corr, ceiling_distAA,ceiling_distAB, p_value, i,'Amp',plotOptions.Amp,'Title',plotOptions.Title);
                            
                            % ---plot innner correlation coefficient ---
                            plotDataA_r.Original = dataA_r2;
                            plotDataA_r.Name = plotDataA.Name;
                            plotDataA_r.Resampled = all_sampled_dataA;
                            figListA.boxplot = t_boxplot;
                            plotOptions.Title = string(labels(i));
                            
                            if plotOptions.Distribution
                                obj.plotBootstrapDistribution(figListA,plotDataA_r,plotOptions);
                            end
                        end
                        
                        % --- finalization significance hist ---
                        set(ax_significance, 'XTick', 1:length(labels), 'XTickLabel', labels);
                        
                    case "HMS"
                        [~,MatNum,ShapeNum,~,~] = size(dataA);
                        
                        ceiling_distAA_list = zeros(plotOptions.Bootstrap,MatNum,ShapeNum);
                        ceiling_distAB_list = zeros(plotOptions.Bootstrap,MatNum,ShapeNum);
                        p_value_list = zeros(MatNum,ShapeNum);
                        observed_corr_list = zeros(MatNum,ShapeNum);
                        
                        for mat = 1:MatNum
                            for shape = 1:ShapeNum
                                dataA_r = squeeze(dataA(:,mat,shape,:,:));
                                dataB_r = squeeze(dataB(:,mat,shape,:,:));
                                fprintf("mat:%s, shape:%s",string(obj.MatNames1(mat)),string(obj.ShapeNames(shape)));
                                [ceiling_distAA,ceiling_distAB,p_value,observed_corr] = Corr_Significance(dataA_r, dataB_r, plotOptions.Bootstrap, plotOptions.Split);
                            
                                ceiling_distAA_list(:,mat,shape) = ceiling_distAA;
                                ceiling_distAB_list(:,mat,shape) = ceiling_distAB;
                                p_value_list(mat,shape) = p_value;
                                observed_corr_list(mat,shape) = observed_corr;
                            end
                        end
                        
                        % --- plot histgram ---
                        Graph_Significance_HMS(observed_corr_list, ceiling_distAA_list,ceiling_distAB_list, p_value_list,...
                            plotDataA.Name, plotDataB.Name, obj.MatNames1, obj.ShapeNames, obj.ResultDir, plotOptions.Amp);
                        
                        return;
                end
                
                % ファイル名の決定と保存
                filename_suffix = plotOptions.Mode;
                if plotOptions.Mode == "HMS"
                    filename_suffix = plotOptions.Mode + string(obj.MatNames3(mat_idx));
                end
                % significance hist
                plotFileName = sprintf('%svs%s_%s_Significance_%s.jpg',plotDataA.Name,plotDataB.Name, plotOptions.Property, filename_suffix);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig_significance, plotFullPath);
                
                % about A
                % scatter
                plotFileName = sprintf('%s_%s_boxplot_A_%s.jpg',plotDataA.Name, plotOptions.Property, filename_suffix);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig_boxplotA, plotFullPath);
                
                fprintf('  -> 各種グラフを保存しました\n');

            catch ME
                rethrow(ME);
            end
        end
        
        function plotBootstrapDistribution(obj,figList,plotData,plotOptions)
            arguments
                obj
                figList (1,1) struct 
                plotData (1,1) struct 
                plotOptions (1,1) struct 
            end

            % ---plot scatter ---                       
            sampled_data = reshape(plotData.Resampled,size(plotData.Resampled,1),[]);
            average_data = zscore(obj.MeanArray(plotData.Original,1));
            
            ax_boxplot = nexttile(figList.boxplot);
            sgtitle(ax_boxplot,"", 'Interpreter', 'none');
            plotBoxPlot(ax_boxplot,sampled_data,average_data,'YLabel',plotOptions.Property,'Labels',obj.HDRNum_30,'Amp',plotOptions.Amp,'Title',plotOptions.title);
        end
        
        %% Bootstrap boxplot
        function generateBootstrapDistribution(obj, plotData, plotOptions)
            % ■ 入力:
            %   plotData (struct): データセットAの仕様
            %     - Name:     DataSetsの名前 (e.g., "Set-A")
            %     - target:  主データ
            %
            %   plotOptions (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Bootstrap"(double): Bootstrapの反復回数 (デフォルト: 10000)
            %     - "Mode"     (double): 1:H、2:HM、3:HS、4:HMS
            
            % HMSモードはFigureを複数作成するため、特別に処理
            if plotOptions.Mode == "HMS"
                for mat = 1:size(plotData.target, 2)
                    obj.BootstrapDistribution(plotData, plotOptions, mat);
                end
            else
                % H, HM, HSモードは単一のFigureを作成
                obj.BootstrapDistribution(plotData, plotOptions);
            end
        end
        
        function BootstrapDistribution(obj, plotData, plotOptions,mat_idx)
            if nargin < 4
                mat_idx = [];
            end
            
            data = plotData.target;
            
            try
                % figureの宣言
                boxplot = figure('Visible', 'off');
                
                switch plotOptions.Mode
                    case "H"
                        data_r = squeeze(mean(mean(data,3),2));
                        
                        [all_sampled_data] = Bootstrap_distribution(data_r,plotOptions.Bootstrap, plotOptions.Split);
                        
                        % ---plot scatter ---                       
                        sampled_data = reshape(all_sampled_data,size(all_sampled_data,1),[]);
                        average_data = zscore(obj.MeanArray(data_r,1));
                        title_str = sprintf("%s Boxplot_%s",plotData.Name,plotOptions.Property);
                        ax = axes('Parent', boxplot);
                        plotBoxPlot(ax,sampled_data,average_data,'YLabel',plotOptions.Property,'Labels',obj.HDRNum_30,'Amp',1.0,'Title',title_str);

                    case {"HM", "HS"}
                        if plotOptions.Mode == "HS"
                            % HSモードは次元を入れ替える
                            data_r = squeeze(mean(data,2));
                            labels = obj.ShapeNames;
                            t_boxplot = tiledlayout(boxplot,2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                        else % HMモード
                            data_r = squeeze(mean(data,3));
                            labels = obj.MatNames3;
                            t_boxplot = tiledlayout(boxplot,2,2,'TileSpacing', 'compact', 'Padding', 'compact');
                        end
 
                        loopLimit = size(data_r, 2);
                        
                        sgtitle(sprintf("%s Boxplot_%s",plotData.Name,plotOptions.Property), 'Interpreter', 'none');
                        
                        for i = 1:loopLimit
                            ax = nexttile(t_boxplot);
                            
                            dataA_r2 = squeeze(data_r(:,i,:,:));
                            fprintf("%s",string(labels(i)));
                            [all_sampled_data] = Bootstrap_distribution(dataA_r2,plotOptions.Bootstrap, plotOptions.Split);
                            
                            titleStr = sprintf('%s',string(labels(i)));
                            
                            sampled_data = reshape(all_sampled_data,size(all_sampled_data,1),[]);
                            average_data = zscore(obj.MeanArray(dataA_r2,1));
                            plotBoxPlot(ax,sampled_data,average_data,'Title',titleStr,'YLabel',plotOptions.Property,'Labels',obj.HDRNum_30);
                        end
                        
                    case "HMS"
                        [~,MatNum,ShapeNum,~,~] = size(data);
                        tiledlayout(2,3,'TileSpacing', 'compact', 'Padding', 'compact');
                        sgtitle(sprintf("%s Boxplot_%s",plotData.Name,plotOptions.Property), 'Interpreter', 'none');
                        
                        for shape = 1:ShapeNum
                            nexttile;
                            
                            data_r = squeeze(data(:,mat_idx,shape,:,:));
                            fprintf("mat:%s, shape:%s",string(obj.MatNames1(mat_idx)),string(obj.ShapeNames(shape)));
                            [all_sampled_data] = Bootstrap_distribution(data_r,plotOptions.Bootstrap, plotOptions.Split);
                            
                            titleStr = sprintf('%s',string(obj.ShapeNames(shape)));
                            sampled_data = reshape(all_sampled_data,size(all_sampled_data,1),[]);
                            average_data = zscore(obj.MeanArray(data_r,1));
                            plotBoxPlot(sampled_data,average_data,'Title',titleStr);
                        end
                end
                
                % ファイル名の決定と保存
                filename_suffix = plotOptions.Mode;
                if plotOptions.Mode == "HMS"
                    filename_suffix = plotOptions.Mode + string(obj.MatNames3(mat_idx));
                end
                plotFileNameA = sprintf('%s_%s_%s_Significance_Boxplot.jpg',plotData.Name, plotOptions.Property, filename_suffix);
                plotFullPathA = fullfile(obj.ResultDir, plotFileNameA);
                saveas(boxplot, plotFullPathA);
                
                fprintf('  -> 散布図を保存しました\n');

            catch ME
                rethrow(ME);
            end
        end
        
        %% --- プロット1: 95%信頼区間の描画 ---
        function plotConfidenceIntervals(obj, means, stds, num_trials)
            % 1.pngを再現: 平均値と95%信頼区間をプロット

            ax = gca; % nexttileで作成された現在のAxesを使用
            se = stds / sqrt(num_trials);
            ci_half_width = 1.96 * se;

            errorbar(ax, 1:numel(means), means, ci_half_width, 'o-', 'LineWidth', 1.5, 'CapSize', 10);

            grid(ax, 'on');
            title(ax, '各点の平均と95%信頼区間');
            xlabel(ax, '点のID');
            ylabel(ax, 'サンプル平均');
            axis(ax, 'tight');
        end

        %% --- プロット2: 相関係数分布のヒストグラム描画 ---
        function plotCorrelationDistribution(obj, corr_coeffs)
            % 2.pngを再現: ブートストラップで得られた相関係数の分布をプロット

            ax = gca;
            histogram(ax, corr_coeffs, 'NumBins', 30, 'FaceColor', [0.3, 0.7, 0.9], 'EdgeColor', 'k');

            grid(ax, 'on');
            title(ax, 'Distribution of Bootstrap Correlation Coefficients');
            xlabel(ax, 'Correlation Coefficient');
            ylabel(ax, 'Frequency');
        end

        %% --- プロット3: 2セットのデータの散布図描画 ---
        function plotSampleScatter(obj, data_A, data_B)
            % 3.pngを再現: 2つのデータセットの平均値間の散布図をプロット

            ax = gca;
            x_data = mean(data_A, 1);
            y_data = mean(data_B, 1);

            scatter(ax, x_data, y_data, 50, 'o', 'MarkerEdgeColor', 'k');

            grid(ax, 'on');
            title(ax, 'リサンプリングデータ1 vs データ2');
            xlabel(ax, 'データセットAのサンプル平均');
            ylabel(ax, 'データセットBのサンプル平均');
            axis(ax, 'equal'); % 縦横のスケールを合わせる
        end

        %% vs model
        function CorrBootstrap_model_H(obj,dataA,dataB,dataC,nameA,nameB,nameC,numBootstrap,amp,property)
            dataA_reshaped = reshape(dataA,size(dataA,1),size(dataA,2),size(dataA,3),[]);
            dataB_reshaped = reshape(dataB,size(dataB,1),size(dataB,2),size(dataB,3),[]); 

            
            % 95%信頼区間の下限を確認
            [corrA,corrAB,correlationDiffs] = Corr_Significance_H(dataA_reshaped,dataB_reshaped,numBootstrap);
            sortedDiffs = sort(correlationDiffs);
            threshold = sortedDiffs(round(numBootstrap*0.05)); 

            
            % dataA vs model         
            fig = figure('Visible', 'off');
            hold on;

            Graph_Significance_H(obj.MeanArray(dataA,1),dataC,corrA,corrAB,threshold,amp);

            set(gca, 'XTick', []);
            titleStr = sprintf('%s vs %s about %s\nCorrelaton Coefficient', nameA, nameC, property);
            title(titleStr,'FontSize',18*amp);
            grid on;
            hold off;
            plotFileName = sprintf('%svs%s_%s_Significance.jpg', nameA, nameC, property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            fprintf('  -> 保存しました: %s\n', plotFullPath);
            
            
            % dataB vs model         
            fig = figure('Visible', 'off');
            hold on;

            Graph_Significance_H(obj.MeanArray(dataB,1),dataC,corrA,corrAB,threshold,amp);

            set(gca, 'XTick', []);
            titleStr = sprintf('%s vs %s about %s\nCorrelaton Coefficient', nameB, nameC, property);
            title(titleStr,'FontSize',18*amp);
            grid on;
            hold off;
            plotFileName = sprintf('%svs%s_%s_Significance.jpg', nameB, nameC, property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            fprintf('  -> 保存しました: %s\n', plotFullPath);
        end
        
        %% 残差
        function generateResidualPlot(obj, residuals, dataSpec1, dataSpec2, options)
            % データが3次元配列かチェック
            if ndims(residuals) < 3
                % 2次元以下のデータはシンプルな単一プロットを作成
                obj.createSingleResidualPlot(residuals, dataSpec1, dataSpec2, options);
            else
                % 3次元のデータはタイル表示プロットを作成
                obj.createTiledResidualPlot(residuals, dataSpec1, dataSpec2, options);
            end
        end

        % --- 単一の残差プロットを作成する新しいヘルパー関数 ---
        function createSingleResidualPlot(obj, residuals, dataSpec1, dataSpec2, options)
            try
                fig = figure('Visible', 'off');
                hold on;
                
                % 2次元目でループして、同一グラフにプロット
                for i = 1:size(residuals, 2)
                    data_slice = residuals(:,i);
                    plot(1:numel(data_slice), data_slice, '-o', 'LineWidth', 0.75);
                end
                
                hold off;
                grid on; box on; axis tight;
                
                switch options.Mode
                    case 1
                        legend('Location', 'best','FontSize',3*options.Amp);
                        titleKind = 'All';
                    case 2
                        legend([obj.MatNames3], 'Location', 'best', 'Interpreter', 'none','FontSize',3*options.Amp);
                        titleKind = 'Material';
                    case 3
                        legend([obj.ShapeNames], 'Location', 'best', 'Interpreter', 'none','FontSize',3*options.Amp);
                        titleKind = 'Shape';
                end

                titleStr = sprintf('%s vs %s about %s\nResiduals_%s', dataSpec1.SetName, dataSpec2.SetName, options.Property,titleKind);
                title(titleStr, 'Interpreter', 'none','FontSize',12*options.Amp);
                xlabel('Illumination', 'Interpreter', 'none','FontSize',12*options.Amp);
                ylabel('Residuals', 'Interpreter', 'none','FontSize',12*options.Amp);
                grid on; box on; axis tight;
                
                x = 1:length(obj.HDRNum_30);
                set(gca, 'XTick', x);
                xticklabels(obj.HDRNum_30);
                xtickangle(90);
                set(gca,'FontSize',6 * options.Amp);
                
                ymax = max(abs(residuals),[],'all')*1.1;
                ylim([-ymax ymax]);

                if options.Save
                    plotFileName = sprintf('%svs%s_%s_%s_residual.jpg', ...
                                           dataSpec1.SetName, dataSpec2.SetName, options.Property,titleKind);
                    plotFullPath = fullfile(obj.ResultDir, plotFileName);
                    saveas(fig, plotFullPath);
                    fprintf('  -> 残差プロットを保存しました: %s\n', plotFullPath);
                else
                    set(fig, 'Visible', 'on');
                end
            catch ME
                rethrow(ME);
            end
        end

        % --- タイル表示の残差プロットを作成する新しいヘルパー関数 ---
        function createTiledResidualPlot(obj, residuals, dataSpec1, dataSpec2, options)
            for mat = 1:size(residuals, 2)
                fig = [];
                try
                    fig = figure('Visible', 'off');
                    hold on;

                    % 3次元目(shape)でループして、同一グラフにプロット
                    for shape = 1:size(residuals, 3)
                        data_slice = residuals(:, mat, shape);
                        plot(1:numel(data_slice), data_slice, '-o', 'LineWidth', 0.75);
                    end

                    hold off;

                    grid on; box on; axis tight;

                    legend([obj.ShapeNames], 'Location', 'best', 'Interpreter', 'none','FontSize',3*options.Amp);

                    titleStr = sprintf('%s vs %s about %s\nResiduals_%s', dataSpec1.SetName, dataSpec2.SetName, options.Property,string(obj.MatNames3(mat)));
                    title(titleStr, 'Interpreter', 'none','FontSize',12*options.Amp);
                    xlabel('Illumination', 'Interpreter', 'none','FontSize',12*options.Amp);
                    ylabel('Residuals', 'Interpreter', 'none','FontSize',12*options.Amp);
                    grid on; box on; axis tight;
                    legend('Location', 'best');

                    x = 1:length(obj.HDRNum_30);
                    set(gca, 'XTick', x);
                    xticklabels(obj.HDRNum_30);
                    xtickangle(90);
                    set(gca,'FontSize',6 * options.Amp);

                    ymax = max(abs(residuals),[],'all')*1.1;
                    ylim([-ymax ymax]);

                    % 保存または表示                   
                    if options.Save
                        plotFileName = sprintf('%svs%s_%s_residual_%s.jpg', ...
                                               dataSpec1.SetName, dataSpec2.SetName, options.Property,string(obj.MatNames3(mat)));
                        plotFullPath = fullfile(obj.ResultDir, plotFileName);
                        saveas(fig, plotFullPath);
                        fprintf('  -> 残差プロットを保存しました: %s\n', plotFullPath);
                    else
                        set(fig, 'Visible', 'on');
                    end

                catch ME
                    rethrow(ME);
                end
            end
        end
    end
end