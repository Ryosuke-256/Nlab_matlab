function plotFreqHistogram(targetData, dataSpec, mode, ResultDir, MatNames3)
% plotFreqHistogram - 頻度ヒストグラムのプロット
%
% 入力:
%   targetData: ターゲットデータ配列
%   dataSpec: データ仕様（SetName, TargetData フィールドを含む構造体）
%   mode: 0=全コンディション、1=材質・形状ごと
%   ResultDir: 結果ディレクトリ
%   MatNames3: 材質名の配列

if mode == 0
    % 全コンディションモード
    targetData_reshape = reshape(targetData, [], 1);
    fprintf('ヒストグラムを作成中: %s の %s\n', dataSpec.SetName, dataSpec.TargetData);

    % ヒストグラムの描画
    fig = figure('Visible', 'off');
    
    PlotHistgram_Frequency(targetData_reshape(:), dataSpec.SetName);
    
    grid on;

    % プロットの保存
    plotFileName = sprintf('%s_hist.jpg', dataSpec.SetName);
    plotFullPath = fullfile(ResultDir, plotFileName); 

    saveas(fig, plotFullPath);
    close(fig);
    fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
    
elseif mode == 1
    % 材質、形状ごとの頻度を見るモード
    targetData_per = permute(targetData, [2, 3, 1, 4, 5]);
    targetData_reshape = reshape(targetData_per, size(targetData_per, 1), size(targetData_per, 2), []);

    fprintf('ヒストグラムを作成中: %s の %s\n', dataSpec.SetName, dataSpec.TargetData);

    % ヒストグラムの描画
    for mat = 1:size(targetData_reshape, 1)
        fig = figure('Visible', 'off', 'Position', [50, 50, 1300, 840]);
        tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
        for shape = 1:size(targetData_reshape, 2)
            nexttile;
            
            PlotHistgram_Frequency(targetData_reshape(mat, shape, :), dataSpec.SetName);
            
            grid on;
        end
        % プロットの保存
        plotFileName = sprintf('%s_%s_hist.jpg', dataSpec.SetName, string(MatNames3(mat)));
        plotFullPath = fullfile(ResultDir, plotFileName); 
        
        saveas(fig, plotFullPath);
        close(fig);
        fprintf('  -> プロットを保存しました: %s\n', plotFullPath);
    end
end

end
