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
        MatNames5 = {'cu','pla'};
        
        HDRNames_15 = [19, 39, 78, 80, 102, 125, 152, 203, 226, 227, 230, 232, 243, 278, 281];
        HDRNames_30 = [5,19,34,39,42,43,78,80,102,105,125,152,164,183,198,201,202,203,209,222,226,227,230,232,243,259,272,278,281,282];
        HDRNum_15 = [2,4,7,8,9,11,12,18,21,22,23,24,25,28,29];
        HDRNum_30 = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
        
        ShapeNames = {'sphere','bunny','dragon','boardA','boardB','boardC'};
        ShapeNames5 = {'bunny','boardA','boardC'};
        
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
        function plotFreqHistogram(obj, dataSpec, mode)
            % ラッパーメソッド: 外部関数を呼び出す
            arguments
                obj
                dataSpec (1,1) struct {mustHaveFields(dataSpec, ["SetName", "TargetData"])}
                mode (1,1) double
            end

            targetData = obj.getDataFromSet(dataSpec.SetName, dataSpec.TargetData);
            plotFreqHistogram(targetData, dataSpec, mode, obj.ResultDir, obj.MatNames3);
        end

        %% ---Heatmap ---
        function Heatmap(obj,dataSpecA,options)
            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "ErrorData"])}
                options.Property (1,1) string = "GRI"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.Mode     (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "H"
            end
            
            fprintf('HeatMapの作成を開始します...\n');

            % --- 1. データの準備 ---
            % 描画に必要なデータを構造体にまとめる
            plotDataA.target = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            plotDataA.error  = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.ErrorData);
            plotDataA.Name = dataSpecA.SetName;

            % 描画オプションを構造体にまとめる
            plotOptions = options;
            plotOptions.Title = sprintf('Heatmap - %s about %s', plotDataA.Name, plotOptions.Property);
            [plotOptions.MatNames, plotOptions.ShapeNames] = obj.selectNamesFromDataSize(plotDataA.target, [], plotOptions.Mode);

            % --- 2. 統合されたヘルパー関数を呼び出す ---
            obj.generateHeatmap(plotDataA,plotOptions);

            fprintf('プロットの作成が完了しました。\n');
        end
        
        
        %% --- Histgram ---
        function HistgramCompare(obj, dataSpecA, dataSpecB, options)            
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %     - ErrorData:   エラーデータ名 (e.g., "error_ZsHM")
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "HdrSet"   (string): 使用するHDR定数セットの名前 (e.g., "HDRNum_30")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            %     - "Mode"     (string): H、HM、HS、HMS

            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData", "ErrorData"])}
                dataSpecB (1,1) struct {mustHaveFields(dataSpecB, ["SetName", "TargetData", "ErrorData"])}
                options.Property (1,1) string = "GRI"
                options.HdrSet   (1,1) string {mustBeMember(options.HdrSet, ["HDRNum_15", "HDRNum_30"])} = "HDRNum_30"
                options.Amp      (1,1) double {mustBeNumeric} = 1.0
                options.Mode     (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "H"
            end

            fprintf('散布図の作成を開始します...\n');

            % --- 1. データの準備 ---
            % 描画に必要なデータを構造体にまとめる
            plotDataA.target = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            plotDataA.error  = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.ErrorData);
            plotDataA.Name = dataSpecA.SetName;
            
            plotDataB.target = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);
            plotDataB.error  = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.ErrorData);
            plotDataB.Name = dataSpecB.SetName;

            % 描画オプションを構造体にまとめる
            plotOptions = options;
            plotOptions.hdr = obj.(options.HdrSet);
            plotOptions.Title = sprintf('%s vs %s about %s', plotDataA.Name, plotDataB.Name, plotOptions.Property);

            % --- 2. 統合されたヘルパー関数を呼び出す ---
            obj.generateHistgramCompare(plotDataA,plotDataB, plotOptions);

            fprintf('プロットの作成が完了しました。\n');
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
            [plotOptions.MatNames, plotOptions.ShapeNames] = obj.selectNamesFromDataSize(plotData.targetA, plotData.targetB, plotOptions.Mode);

            % --- 2. 統合されたヘルパー関数を呼び出す ---
            obj.generateScatterPlot(plotData, plotOptions);

            fprintf('プロットの作成が完了しました。\n');
        end
        
        %% --ANOVA--
        function ANOVA(obj,dataSpecA,dataSpecB,options)
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
                options.InnerFactor (1,:) string = []
                options.OuterFactor (1,:) string =  []
                options.Switch string = "anova"
                options.Mode (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "HMS"
            end

            % --- 1. データの準備 ---
            plotDataA.target = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);
            plotDataB.target = obj.getDataFromSet(dataSpecB.SetName, dataSpecB.TargetData);

            % --- 2. 描画オプションを構造体にまとめる ---
            plotOptions = options;
            plotOptions.Title = sprintf('%s vs %s about %s', dataSpecA.SetName, dataSpecB.SetName, plotOptions.Property);
            plotDataA.Name = dataSpecA.SetName;
            plotDataB.Name = dataSpecB.SetName;
            
            [plotOptions.MatNames, plotOptions.ShapeNames] = obj.selectNamesFromDataSize(plotDataA.target, plotDataB.target, plotOptions.Mode);

            % --- 3. 統合された単一のヘルパー関数を呼び出す ---
            obj.generateANOVAPlot(plotDataA,plotDataB, plotOptions);

            fprintf('ANOVAが完了しました。\n');
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
                options.Save     (1,1) logical = true
                options.Mode     (1,1) string {mustBeMember(options.Mode, ["H", "HM", "HS", "HMS"])} = "H"
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
            fprintf('残差の平均: %.4f\n', mean(residuals(:)));
            fprintf('残差の標準偏差: %.4f\n', std(residuals(:)));

            % --- 3. ヘルパー関数を呼び出してプロットと保存を実行 ---
            obj.generateResidualPlot(residuals, dataSpecA, dataSpecB, options);
        end
        
        %% 被験者ごとの差を見る
        function SubjectTest(obj,dataSpecA,options)
            % ■ 入力:
            %   dataSpecA (struct): データセットAの仕様
            %     - SetName:     DataSetsのキー名 (e.g., "Set-A")
            %     - TargetData:  主データ名 (e.g., "ZsHM")
            %
            %   options (名前/値ペア):
            %     - "Property" (string): 解析対象のプロパティ名 (グラフタイトル用, e.g., "反射率")
            %     - "Amp"      (double): 増幅係数 (デフォルト: 1.5)
            arguments
                obj
                dataSpecA (1,1) struct {mustHaveFields(dataSpecA, ["SetName", "TargetData"])}
                % オプション引数 (名前/値ペア)
                options.Property  (1,1) string = "GRI"
                options.Amp       (1,1) double {mustBeNumeric} = 1.0
            end

            % --- 1. データの準備 ---
            plotDataA.target = obj.getDataFromSet(dataSpecA.SetName, dataSpecA.TargetData);

            % --- 2. 描画オプションを構造体にまとめる ---
            plotOptions = options;
            plotOptions.Title = sprintf('%s about %s', dataSpecA.SetName, plotOptions.Property);
            plotDataA.Name = dataSpecA.SetName;

            % --- 3. 統合された単一のヘルパー関数を呼び出す ---
            obj.generateTestPlot(plotDataA, plotOptions);

            fprintf('Testが完了しました。\n');
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

        % 配列の特定の次元から指定した数だけ要素を抽出する関数
        function extracted_data = extractSlices(obj,data, dim, num_to_extract)
            if num_to_extract > size(data, dim)
                error('抽出したい数 (%d) が、指定された次元 (%d) の大きさ (%d) を超えています。', ...
                      num_to_extract, dim, size(data, dim));
            end
            total_slices = size(data, dim);

            % 動的なインデックスの作成
            num_dims = ndims(data);
            idx = repmat({':'}, 1, num_dims);

            % 1から次元の大きさまでの整数から、重複なしでランダムにインデックスを抽出
            selected_indices = randperm(total_slices, num_to_extract);

            % 抽出対象の次元のインデックスを、ランダムなインデックスで上書き
            idx{dim} = selected_indices;

            % インデックスを使ってデータを抽出
            extracted_data = data(idx{:});
        end
        
        %% --- 統一化されたヘルパーメソッド ---
        
        % モードに応じたレイアウト設定を返す
        function [layoutConfig] = configurePlotLayout(obj, mode, matNum, shapeNum)
            % 入力:
            %   mode (string): "H", "HM", "HS", "HMS"
            %   matNum (double): 材質の数 (2 or 4)
            %   shapeNum (double): 形状の数 (3 or 6)
            % 出力:
            %   layoutConfig (struct): レイアウト設定
            %     - rows: タイルの行数
            %     - cols: タイルの列数
            %     - labels: ラベル配列
            %     - loopCount: ループ回数
            
            layoutConfig = struct();
            
            switch mode
                case "H"
                    layoutConfig.rows = 1;
                    layoutConfig.cols = 1;
                    layoutConfig.labels = {};
                    layoutConfig.loopCount = 1;
                    
                case "HM"
                    layoutConfig.rows = 2;
                    layoutConfig.cols = 2;
                    if matNum == 4
                        layoutConfig.labels = obj.MatNames3;
                    else
                        layoutConfig.labels = obj.MatNames5;
                    end
                    layoutConfig.loopCount = matNum;
                    
                case "HS"
                    layoutConfig.rows = 2;
                    layoutConfig.cols = 3;
                    if shapeNum == 6
                        layoutConfig.labels = obj.ShapeNames;
                    else
                        layoutConfig.labels = obj.ShapeNames5;
                    end
                    layoutConfig.loopCount = shapeNum;
                    
                case "HMS"
                    layoutConfig.rows = 2;
                    layoutConfig.cols = 3;
                    layoutConfig.labels = obj.ShapeNames;
                    layoutConfig.loopCount = 6;
            end
        end
        
        % モードとデータから材質数と形状数を取得
        function [matCount, shapeCount] = getMatShapeCount(obj, data, mode)
            % 入力:
            %   data: データ配列
            %   mode (string): "H", "HM", "HS", "HMS"
            % 出力:
            %   matCount: 材質の数
            %   shapeCount: 形状の数
            %
            % 注意: 各モードでデータの次元構造が異なる
            %   H:   [照明条件] -> matCount=1, shapeCount=1
            %   HM:  [照明条件, 材質条件] -> matCount=次元2, shapeCount=1
            %   HS:  [照明条件, 形状条件] -> matCount=1, shapeCount=次元2
            %   HMS: [照明条件, 材質条件, 形状条件] -> matCount=次元2, shapeCount=次元3
            
            dataSize = size(data);
            
            switch mode
                case "H"
                    matCount = 1;
                    shapeCount = 1;
                    
                case "HM"
                    if length(dataSize) >= 2
                        matCount = dataSize(2);
                    else
                        matCount = 1;
                    end
                    shapeCount = 1;
                    
                case "HS"
                    matCount = 1;
                    if length(dataSize) >= 2
                        shapeCount = dataSize(2);
                    else
                        shapeCount = 1;
                    end
                    
                case "HMS"
                    if length(dataSize) >= 2
                        matCount = dataSize(2);
                    else
                        matCount = 1;
                    end
                    if length(dataSize) >= 3
                        shapeCount = dataSize(3);
                    else
                        shapeCount = 1;
                    end
                    
                otherwise
                    matCount = 1;
                    shapeCount = 1;
            end
        end
        
        % Figure とタイルレイアウトを作成
        function [fig, tLayout] = createFigureWithLayout(obj, mode, matNum, shapeNum)
            % 入力:
            %   mode (string): "H", "HM", "HS", "HMS"
            %   matNum (double): 材質の数
            %   shapeNum (double): 形状の数
            % 出力:
            %   fig: Figure オブジェクト
            %   tLayout: タイルレイアウトオブジェクト
            
            fig = figure('Visible', 'off');
            layoutConfig = obj.configurePlotLayout(mode, matNum, shapeNum);
            
            if mode == "H"
                tLayout = [];
            else
                tLayout = tiledlayout(layoutConfig.rows, layoutConfig.cols, ...
                    'TileSpacing', 'compact', 'Padding', 'compact');
            end
        end
        
        % 統一された命名規則でファイル名を生成して保存
        function saveFigureWithNaming(obj, fig, nameA, nameB, property, mode, matIdx, plotType)
            % 入力:
            %   fig: Figure オブジェクト
            %   nameA, nameB (string): データセット名
            %   property (string): プロパティ名
            %   mode (string): モード
            %   matIdx (double): 材質インデックス (HMS モードのみ)
            %   plotType (string): プロットタイプ ("scatter", "Histgram", "Significance" など)
            
            filename_suffix = mode;
            if mode == "HMS" && ~isempty(matIdx)
                filename_suffix = "HMS_" + string(obj.MatNames3(matIdx));
            end
            
            if isempty(nameB)
                % 単一データセットの場合
                plotFileName = sprintf('%s_%s_%s_%s.jpg', nameA, property, plotType, filename_suffix);
            else
                % 2つのデータセット比較の場合
                plotFileName = sprintf('%svs%s_%s_%s_%s.jpg', nameA, nameB, property, filename_suffix, plotType);
            end
            
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            close(fig);
            fprintf('  -> プロットを保存しました: %s\n', plotFileName);
        end
        
        % モードに応じてデータを準備
        function [preparedData] = prepareDataForMode(obj, data, mode, idx)
            % 入力:
            %   data: 元のデータ配列
            %   mode (string): "H", "HM", "HS", "HMS"
            %   idx (double): インデックス (HMS モードで使用)
            % 出力:
            %   preparedData: 整形されたデータ
            
            switch mode
                case "H"
                    preparedData = data(:);
                    
                case "HM"
                    preparedData = data;
                    
                case "HS"
                    % 次元を並び替え: [hdr, mat, shape, ...] -> [hdr, shape, mat, ...]
                    preparedData = permute(data, [1, 3, 2, 4, 5]);
                    
                case "HMS"
                    % 特定の材質インデックスのデータを抽出
                    if nargin < 4 || isempty(idx)
                        error('HMS モードではインデックスが必要です');
                    end
                    preparedData = data;
            end
        end
        
        % データサイズとモードに基づいて材質名と形状名を自動選択
        function [matNames, shapeNames] = selectNamesFromDataSize(obj, dataA, dataB, mode)
            % 入力:
            %   dataA, dataB: データ配列（どちらか一方でも可）
            %   mode (string): "H", "HM", "HS", "HMS"
            % 出力:
            %   matNames: 材質名の配列
            %   shapeNames: 形状名の配列
            %
            % 注意: 各モードでデータの次元構造が異なる
            %   H:   [照明条件]
            %   HM:  [照明条件, 材質条件]
            %   HS:  [照明条件, 形状条件]
            %   HMS: [照明条件, 材質条件, 形状条件]
            
            % データAとBのサイズを取得（小さい方に合わせる）
            if nargin < 3 || isempty(dataB)
                % データAのみの場合
                numDims = max(ndims(dataA), 3);
                sizeA = ones(1, numDims);
                actualSize = size(dataA);
                sizeA(1:length(actualSize)) = actualSize;
            else
                % 両方ある場合は小さい方に合わせる
                numDims = max(max(ndims(dataA), ndims(dataB)), 3);
                sizeA = ones(1, numDims);
                sizeB = ones(1, numDims);
                
                actualSizeA = size(dataA);
                actualSizeB = size(dataB);
                sizeA(1:length(actualSizeA)) = actualSizeA;
                sizeB(1:length(actualSizeB)) = actualSizeB;
                
                % モードに応じて適切な次元を比較
                switch mode
                    case "H"
                        % H モードでは次元情報なし
                    case "HM"
                        % 次元2が材質
                        matDim = min(sizeA(2), sizeB(2));
                        sizeA(2) = matDim;
                    case "HS"
                        % 次元2が形状
                        shapeDim = min(sizeA(2), sizeB(2));
                        sizeA(2) = shapeDim;
                    case "HMS"
                        % 次元2が材質、次元3が形状
                        matDim = min(sizeA(2), sizeB(2));
                        shapeDim = min(sizeA(3), sizeB(3));
                        sizeA(2) = matDim;
                        sizeA(3) = shapeDim;
                end
            end
            
            % モードに応じて材質名と形状名を選択
            switch mode
                case "H"
                    % H モードではデフォルト値を使用
                    matNames = obj.MatNames3;
                    shapeNames = obj.ShapeNames;
                    
                case "HM"
                    % 次元2が材質条件
                    switch sizeA(2)
                        case 4
                            matNames = obj.MatNames3;
                        case 2
                            matNames = obj.MatNames5;
                        otherwise
                            matNames = obj.MatNames3;
                    end
                    shapeNames = obj.ShapeNames; % デフォルト
                    
                case "HS"
                    % 次元2が形状条件
                    matNames = obj.MatNames3; % デフォルト
                    switch sizeA(2)
                        case 6
                            shapeNames = obj.ShapeNames;
                        case 3
                            shapeNames = obj.ShapeNames5;
                        otherwise
                            shapeNames = obj.ShapeNames;
                    end
                    
                case "HMS"
                    % 次元2が材質、次元3が形状
                    switch sizeA(2)
                        case 4
                            matNames = obj.MatNames3;
                        case 2
                            matNames = obj.MatNames5;
                        otherwise
                            matNames = obj.MatNames3;
                    end
                    switch sizeA(3)
                        case 6
                            shapeNames = obj.ShapeNames;
                        case 3
                            shapeNames = obj.ShapeNames5;
                        otherwise
                            shapeNames = obj.ShapeNames;
                    end
                    
                otherwise
                    % 不明なモードの場合はデフォルト
                    matNames = obj.MatNames3;
                    shapeNames = obj.ShapeNames;
            end
        end
        
        %% --- テスト  ---
        function generateTestPlot(obj,plotDataA, plotOptions)
            dataA = plotDataA.target;
            plotFileName = sprintf('%s_%s_subjectTest1.jpg', plotDataA.Name, plotOptions.Property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);            
            plotSubjectTrialVariability(dataA,"SavePath",plotFullPath);
            
            plotFileName = sprintf('%s_%s_subjectTest2.jpg', plotDataA.Name, plotOptions.Property);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            plotSpaghettiBySubject(dataA,1,"SavePath",plotFullPath);
            
            analyzeSubjectStats(dataA, 1, 6);
        end
        
        %% --- 単純ヒストグラム ---
        function generateHistgramCompare(obj, plotDataA,plotDataB, plotOptions)
            % HMSモードはFigureを複数作成するため、特別に処理
            if plotOptions.Mode == "HMS"
                for mat = 1:size(plotDataA.targetA, 2)
                    obj.drawAndSaveHistgramCompare(plotDataA,plotDataB, plotOptions, mat);
                end
            else
                % H, HM, HSモードは単一のFigureを作成
                obj.drawAndSaveHistgramCompare(plotDataA,plotDataB, plotOptions);
            end
        end
        
        function drawAndSaveHistgramCompare(obj, plotDataA,plotDataB, plotOptions, mat_idx)
            if nargin < 5
                mat_idx = []; % HMSモードでない場合は空
            end

            try
                % モードに応じた材質数と形状数を取得
                [matCount, shapeCount] = obj.getMatShapeCount(plotDataA.target, plotOptions.Mode);
                
                % レイアウト設定を取得
                layoutConfig = obj.configurePlotLayout(plotOptions.Mode, matCount, shapeCount);
                
                % Figure とレイアウトを作成
                [fig, tLayout] = obj.createFigureWithLayout(plotOptions.Mode, matCount, shapeCount);

                % モードに応じてプロット
                switch plotOptions.Mode
                    case "H"
                        obj.plotHistgramSingle(plotDataA, plotDataB, plotOptions, plotOptions.Title);
                        
                    case {"HM", "HS"}
                        sgtitle(tLayout, plotOptions.Title, 'Interpreter', 'none');
                        for i = 1:layoutConfig.loopCount
                            nexttile;
                            titleStr = sprintf('%s', string(layoutConfig.labels(i)));
                            obj.plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr, i);
                        end
                        
                    case "HMS"
                        titleStr = sprintf('%s-%s', plotOptions.Title, string(obj.MatNames3(mat_idx)));
                        sgtitle(tLayout, titleStr, 'Interpreter', 'none');
                        
                        for shape = 1:layoutConfig.loopCount
                            nexttile;
                            titleStr = sprintf('%s', string(obj.ShapeNames(shape)));
                            obj.plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr, mat_idx, shape);
                        end
                end

                % 保存 (ヒストグラムは特殊な命名規則を使用)
                filename_suffix = plotOptions.Mode;
                if plotOptions.Mode == "HMS"
                    filename_suffix = "HMS_" + string(obj.MatNames3(mat_idx));
                end
                plotFileName = sprintf('%s vs %s_%s_%s_Histgram.jpg', plotDataA.Name, plotDataB.Name, plotOptions.Property, filename_suffix);
                plotFullPath = fullfile(obj.ResultDir, plotFileName);
                saveas(fig, plotFullPath);
                close(fig);
                fprintf('  -> Histgramを保存しました\n');

            catch ME
                if exist('fig', 'var') && isvalid(fig)
                    close(fig);
                end
                rethrow(ME);
            end
        end
        
        % 単一のヒストグラムをプロット
        function plotHistgramSingle(obj, plotDataA, plotDataB, plotOptions, titleStr, matIdx, shapeIdx)
            % ラッパーメソッド: 外部関数を呼び出す
            if nargin < 6
                plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr);
            elseif nargin < 7
                plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr, matIdx);
            else
                plotHistgramSingle(plotDataA, plotDataB, plotOptions, titleStr, matIdx, shapeIdx);
            end
        end
        
        %% ---Heatmap---
        function generateHeatmap(obj,plotData,plotOptions)
            fig_heatmap = figure('Visible', 'off');

            % モードに応じてループ処理
            switch plotOptions.Mode
                case "H"
                    fprintf('H,HMSは使えません');                    
                case {"HM", "HS"}
                    if plotOptions.Mode == "HM"
                        labels = plotOptions.MatNames;
                    else % "HS"
                        labels = plotOptions.ShapeNames;
                    end
                   
                    createHeatmap(plotData,"Labels",labels,"Title",plotOptions.Title,"Amp",plotOptions.Amp);
                 case "HMS"
                    fprintf('H,HMSは使えません');   
            end

            % ファイル名の決定と保存
            filename_suffix = plotOptions.Mode;
            plotFileName = sprintf('Heatmap_%s_%s_%s.jpg', plotData.Name, plotOptions.Property, filename_suffix);
            plotFullPath = fullfile(obj.ResultDir, plotFileName);
            saveas(fig_heatmap, plotFullPath);
            fprintf('  -> Heatmapを保存しました\n');

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

            try
                % モードに応じた材質数と形状数を取得
                [matCount, shapeCount] = obj.getMatShapeCount(plotData.targetA, plotOptions.Mode);
                
                % レイアウト設定を取得
                layoutConfig = obj.configurePlotLayout(plotOptions.Mode, matCount, shapeCount);
                
                % Figure とレイアウトを作成
                [fig, tLayout] = obj.createFigureWithLayout(plotOptions.Mode, matCount, shapeCount);

                % モードに応じてプロット
                switch plotOptions.Mode
                    case "H"
                        obj.plotScatterSingle(plotData, plotOptions, plotOptions.Title);
                        
                    case {"HM", "HS"}
                        sgtitle(tLayout, plotOptions.Title, 'Interpreter', 'none');
                        for i = 1:layoutConfig.loopCount
                            nexttile;
                            titleStr = sprintf('%s', string(layoutConfig.labels(i)));
                            obj.plotScatterSingle(plotData, plotOptions, titleStr, i);
                        end
                        
                    case "HMS"
                        titleStr = sprintf('%s-%s', plotOptions.Title, string(plotOptions.MatNames(mat_idx)));
                        sgtitle(tLayout, titleStr, 'Interpreter', 'none');
                        
                        for shape = 1:layoutConfig.loopCount
                            nexttile;
                            titleStr = sprintf('%s', string(plotOptions.ShapeNames(shape)));
                            obj.plotScatterSingle(plotData, plotOptions, titleStr, mat_idx, shape);
                        end
                end

                % 保存
                obj.saveFigureWithNaming(fig, plotOptions.NameA, plotOptions.NameB, ...
                    plotOptions.Property, plotOptions.Mode, mat_idx, 'scatter');

            catch ME
                if exist('fig', 'var') && isvalid(fig)
                    close(fig);
                end
                rethrow(ME);
            end
        end
        
        % 単一の散布図をプロット
        function plotScatterSingle(obj, plotData, plotOptions, titleStr, matIdx, shapeIdx)
            % ラッパーメソッド: 外部関数を呼び出す
            if nargin < 5
                plotScatterSingle(plotData, plotOptions, titleStr);
            elseif nargin < 6
                plotScatterSingle(plotData, plotOptions, titleStr, matIdx);
            else
                plotScatterSingle(plotData, plotOptions, titleStr, matIdx, shapeIdx);
            end
        end
        
        %% ANOVA
        function generateANOVAPlot(obj,plotDataA,plotDataB,plotOptions)
            dataA = plotDataA.target;
            dataB = plotDataB.target;
            
            if plotOptions.Switch == "anova"
                [p_values, anovan_cell] = performMultiwayAnova(dataA, dataB,"InnerFactor", plotOptions.InnerFactor,"OuterFactor", plotOptions.OuterFactor);
                
                rounded_cell = roundCellValues(anovan_cell,"NumDecimals",3);
                disp(rounded_cell);
                csv_file_name = sprintf('%svs%s_%s_anova.csv',plotDataA.Name,plotDataB.Name, plotOptions.Property);
                csv_file_path = fullfile(obj.ResultDir, csv_file_name);
                writecell(rounded_cell, csv_file_path);
                
            elseif plotOptions.Switch == "ranova"
                [ranova_table, rm_model] = performMixedAnova(dataA, dataB, "FactorNames", plotOptions.InnerFactor,"BetweenFactorName", plotOptions.OuterFactor);
                
                rounded_table = roundTableValues(ranova_table,"NumDecimals",3);
                disp(rounded_table);
                csv_file_name = sprintf('%svs%s_%s_ranova.csv',plotDataA.Name,plotDataB.Name, plotOptions.Property);
                csv_file_path = fullfile(obj.ResultDir, csv_file_name);
                writetable(rounded_table(1:end,:),csv_file_path, 'WriteRowNames', true)
            end
            
            fprintf('ANOVA表をCSVに保存しました: %s\n', csv_file_path);
            
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
                for mat = 1:size(plotDataA.target, 2)
                    obj.BootstrapPlot(plotDataA,plotDataB, plotOptions, mat);
                end
            else
                % H, HM, HSモードは単一のFigureを作成
                obj.BootstrapPlot(plotDataA,plotDataB, plotOptions);
            end
        end
        
        function BootstrapPlot(obj, plotDataA,plotDataB, plotOptions,mat_idx)
            if nargin < 5
                mat_idx = [];
            end
            
            dataA = plotDataA.target;
            dataB = plotDataB.target;
            
            try
                % Figure を作成
                fig_significance = figure('Visible', 'off');
                
                % モードに応じて Bootstrap 解析とプロット
                switch plotOptions.Mode
                    case "H"
                        obj.plotBootstrapH(fig_significance, dataA, dataB, plotDataA, plotDataB, plotOptions);
                        
                    case {"HM", "HS"}
                        obj.plotBootstrapHMHS(fig_significance, dataA, dataB, plotDataA, plotDataB, plotOptions);
                        
                    case "HMS"
                        obj.plotBootstrapHMS(fig_significance, dataA, dataB, plotDataA, plotDataB, plotOptions, mat_idx);
                end
                
                % 保存
                obj.saveFigureWithNaming(fig_significance, plotDataA.Name, plotDataB.Name, ...
                    plotOptions.Property, plotOptions.Mode, mat_idx, 'Significance');
                
                fprintf('  -> 各種グラフを保存しました\n');

            catch ME
                if exist('fig_significance', 'var') && isvalid(fig_significance)
                    close(fig_significance);
                end
                rethrow(ME);
            end
        end
        
        % H モードの Bootstrap プロット
        function plotBootstrapH(obj, fig, dataA, dataB, plotDataA, plotDataB, plotOptions)
            % ラッパーメソッド: 外部関数を呼び出す
            plotBootstrapH(fig, dataA, dataB, plotDataA, plotDataB, plotOptions);
        end
        
        % HM/HS モードの Bootstrap プロット
        function plotBootstrapHMHS(obj, fig, dataA, dataB, plotDataA, plotDataB, plotOptions)
            % ラッパーメソッド: 外部関数を呼び出す
            plotBootstrapHMHS(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, obj.MatNames3, obj.ShapeNames);
        end
        
        % HMS モードの Bootstrap プロット
        function plotBootstrapHMS(obj, fig, dataA, dataB, plotDataA, plotDataB, plotOptions, mat_idx)
            % ラッパーメソッド: 外部関数を呼び出す
            plotBootstrapHMS(fig, dataA, dataB, plotDataA, plotDataB, plotOptions, mat_idx, obj.MatNames3, obj.ShapeNames);
        end
        
        % 有意性の注釈を追加
        function addSignificanceNote(obj, ax, amp)
            % ラッパーメソッド: 外部関数を呼び出す
            addSignificanceNote(ax, amp);
        end
        
        function plotBootstrapDistribution(obj,figList,plotData,plotOptions)
            arguments
                obj
                figList (1,1) struct 
                plotData (1,1) struct 
                plotOptions (1,1) struct 
            end

            % ---plot scatter ---
            num_dims_A = ndims(plotData.Original);
            permuted_data = permute(plotData.Resampled,[1,4,2,3]);
            resampled_data_1 = reshape(permuted_data,size(permuted_data,1),[]);
            resampled_data_2 = reshape(permuted_data,size(permuted_data,1),size(permuted_data,2),[]);
            average_data = mean(zscore(plotData.Original, 0, 1), 2:num_dims_A);
            
            ax_boxplot = nexttile(figList.boxplot);
            plotBoxPlot(ax_boxplot,resampled_data_1,average_data,'YLabel',plotOptions.Property,'Labels',obj.HDRNum_30,'Amp',plotOptions.Amp,'Title',plotOptions.Title);
            
            ax_frequency = nexttile(figList.frequency);
            obj.plotCorrelationDistribution(ax_frequency,plotData.Corr,'Amp',plotOptions.Amp,'Title',plotOptions.Title);
            
            ax_scatter1 = nexttile(figList.scatter);
            
            plotScatterWithErrorBars(ax_scatter1,resampled_data_1,average_data,"Title", plotOptions.Title,"Amp", plotOptions.Amp, "YLabel", plotOptions.Property);
            
            ax_scatter2 = nexttile(figList.scatter2);
            obj.plotSampleScatter(ax_scatter2,resampled_data_2,'Amp',plotOptions.Amp,'Title',plotOptions.Title);
        end

        %% --- プロット2: 相関係数分布のヒストグラム描画 ---
        function plotCorrelationDistribution(obj,ax, corrs, plotOptions)
            % 2.pngを再現: ブートストラップで得られた相関係数の分布をプロット
            arguments
                obj
                ax
                corrs
                plotOptions.Title  = ""
                plotOptions.Amp = 1.0
            end

            histogram(ax, corrs, 'NumBins', 30, 'FaceColor', [0.3, 0.7, 0.9], 'EdgeColor', 'k');

            grid(ax, 'on');
            title(ax, plotOptions.Title,'Interpreter', 'none');
            xlabel(ax, 'Correlation Coefficient','Interpreter', 'none','FontSize',8 * plotOptions.Amp);
            ylabel(ax, 'Frequency','Interpreter', 'none','FontSize',8 * plotOptions.Amp);
            set(ax, 'FontSize', 8 * plotOptions.Amp);
        end

        %% --- プロット3: 2セットのデータの散布図描画 ---
        function plotSampleScatter(obj,ax, plotData, plotOptions)
            % 3.pngを再現: 2つのデータセットの平均値間の散布図をプロット
            arguments
                obj
                ax
                plotData 
                plotOptions.Title  = ""
                plotOptions.Amp = 1.0
                plotOptions.Xlabel = "Bootstrap A"
                plotOptions.Ylabel = "Bootstrap B"
            end
            
            a1_data = squeeze(plotData(:,1,:));
            a2_data = squeeze(plotData(:,2,:));
            
            [num_rows, num_cols] = size(a1_data);
            
            random_col_indices_1 = randi(num_cols, num_rows, 1);
            random_col_indices_2 = randi(num_cols, num_rows, 1);
            
            row_indices = (1:num_rows)'; % 行番号は1, 2, ..., 30
            linear_indices_1 = sub2ind(size(a1_data), row_indices, random_col_indices_1);
            linear_indices_2 = sub2ind(size(a2_data), row_indices, random_col_indices_2);

            % 5. 線形インデックスを使って、一気にデータを抽出
            new_data_1 = a1_data(linear_indices_1);
            new_data_2 = a2_data(linear_indices_2);
            
            % --- 統計モデルの構築 (一元化) ---
            mdl = fitlm(new_data_1, new_data_2);
            R2 = mdl.Rsquared.Ordinary;
            r_value = sign(mdl.Coefficients.Estimate(2)) * sqrt(R2);
            
            scatter(ax, new_data_1, new_data_2, 30 * plotOptions.Amp, 'o','MarkerEdgeColor', 'k');

            grid(ax, 'on');
            title(ax, plotOptions.Title);
            xlabel(ax, plotOptions.Xlabel,'FontSize',8 * plotOptions.Amp);
            ylabel(ax, plotOptions.Ylabel,'FontSize',8 * plotOptions.Amp);
            axis(ax, 'equal'); 
            
            x_limits = xlim(ax);
            y_limits = ylim(ax);
            text_x = x_limits(1)+abs(x_limits(1)-x_limits(2))/15;
            text_y = y_limits(2)-abs(x_limits(1)-x_limits(2))/10;
            text(text_x, text_y, sprintf('r = %.2f\nR^2 = %.2f', r_value, R2), ...
                 'VerticalAlignment', 'top', 'FontSize', 8 * plotOptions.Amp, ...
                 'BackgroundColor', 'w', 'EdgeColor', 'k');
            set(ax, 'FontSize', 8 * plotOptions.Amp);
        end

        %% vs model
        function CorrBootstrap_model_H(obj,dataA,dataB,dataC,nameA,nameB,nameC,numBootstrap,amp,property)
            % 注意: このメソッドは HMS モードのデータ構造を前提としています
            % データ構造: [照明条件, 材質条件, 形状条件, ...]
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
            % ラッパーメソッド: 外部関数を呼び出す
            createSingleResidualPlot(residuals, dataSpec1, dataSpec2, options, obj.HDRNum_30, obj.ResultDir, @obj.selectNamesFromDataSize);
        end

        % --- タイル表示の残差プロットを作成する新しいヘルパー関数 ---
        function createTiledResidualPlot(obj, residuals, dataSpec1, dataSpec2, options)
            % ラッパーメソッド: 外部関数を呼び出す
            createTiledResidualPlot(residuals, dataSpec1, dataSpec2, options, obj.HDRNum_30, obj.ResultDir, obj.MatNames3, obj.ShapeNames);
        end
    end
end