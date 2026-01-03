function createTiledResidualPlot(residuals, dataSpec1, dataSpec2, options, HDRNum_30, ResultDir, MatNames3, ShapeNames)
% createTiledResidualPlot - タイル表示の残差プロットを作成
%
% 注意: このメソッドは HMS モードのデータ構造を前提としています
% residuals 構造: [照明条件, 材質条件, 形状条件]
%
% 入力:
%   residuals: 残差データ
%   dataSpec1, dataSpec2: データ仕様
%   options: オプション（Amp, Property, Save フィールドを含む）
%   HDRNum_30: HDR番号配列
%   ResultDir: 結果ディレクトリ
%   MatNames3: 材質名配列
%   ShapeNames: 形状名配列

% オプションデフォルト設定
if ~isfield(options, 'FigureSize'), options.FigureSize = "slender"; end
if ~isfield(options, 'ShowTitle'), options.ShowTitle = true; end
if ~isfield(options, 'TitleLocation'), options.TitleLocation = "top"; end

% 図のサイズ設定
if options.FigureSize == "slender"
    figPos = [100, 100, 1200, 300]; % 横長 (Default for residuals)
    % Tiledの場合は元々DefaultSize指定がないが、指定があれば従う
else
    figPos = [100, 100, 800, 600];  % 通常
end

for mat = 1:size(residuals, 2)
    fig = [];
    try
        fig = figure('Visible', 'off');
        % Positionをセット (デフォルトではFigure作成時にセットされていないコードだったが、ここで適用)
        % ただし既存コードは figure('Visible', 'off') だけだったので、サイズ指定を追加する
        set(fig, 'Position', figPos);
        
        hold on;

        % 3次元目(shape)でループして、同一グラフにプロット
        for shape = 1:size(residuals, 3)
            data_slice = residuals(:, mat, shape);
            plot(1:numel(data_slice), data_slice, '-o', 'LineWidth', 0.75);
        end

        hold off;

        grid on; box on; axis tight;

        legend(ShapeNames, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 3*options.Amp);

        titleStr = sprintf('%s vs %s about %s\\nResiduals_%s', dataSpec1.SetName, dataSpec2.SetName, options.Property, string(MatNames3(mat)));
        
        if ~options.ShowTitle
            titleStr = "";
        end

        if options.TitleLocation == "top"
            if titleStr ~= ""
                 title(titleStr, 'Interpreter', 'none', 'FontSize', 12*options.Amp);
            end
            xlabel('Illumination', 'Interpreter', 'none', 'FontSize', 12*options.Amp);
        else
             % bottom
             if titleStr ~= ""
                 xlabel({'Illumination', titleStr}, 'Interpreter', 'none', 'FontSize', 12*options.Amp);
             else
                 xlabel('Illumination', 'Interpreter', 'none', 'FontSize', 12*options.Amp);
             end
        end

        ylabel('Residuals', 'Interpreter', 'none', 'FontSize', 12*options.Amp);
        grid on; box on; axis tight;
        legend('Location', 'best');

        x = 1:length(HDRNum_30);
        set(gca, 'XTick', x);
        xticklabels(HDRNum_30);
        xtickangle(90);
        set(gca, 'FontSize', 6 * options.Amp);

        ymax = max(abs(residuals), [], 'all') * 1.1;
        ylim([-ymax ymax]);

        if options.Save
            plotFileName = sprintf('%svs%s_%s_%s_residual.jpg', ...
                                   dataSpec1.SetName, dataSpec2.SetName, options.Property, string(MatNames3(mat)));
            plotFullPath = fullfile(ResultDir, plotFileName);
            saveas(fig, plotFullPath);
            fprintf('  -> 残差プロットを保存しました: %s\n', plotFullPath);
            close(fig);
        else
            set(fig, 'Visible', 'on');
        end
    catch ME
        if ~isempty(fig) && isvalid(fig)
            close(fig);
        end
        rethrow(ME);
    end
end

end
