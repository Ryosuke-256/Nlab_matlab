function saveAnovaResults(anova_table, csv_path, image_path)
%saveAnovaResults ANOVAの分散分析表をCSVとPNG画像の両方で保存します。
%
% [INPUTS]
%   anova_table - (セル配列) anovanなどから出力された分散分析表。
%   csv_path    - (string) 保存するCSVファイルへのパス。
%   png_path    - (string) 保存するPNG画像へのパス。

%% 1. 引数の検証
arguments
    anova_table cell
    csv_path (1,1) string
    image_path (1,1) string
end

%% 2. CSVファイルとして保存
try
    writecell(anova_table, csv_path);
    fprintf('ANOVA表をCSVに保存しました: %s\n', csv_path);
catch ME
    warning('CSVファイルの保存中にエラーが発生しました: %s', ME.message);
end

%% 3. PNG画像として保存
fig = [];
try
    % 非表示のFigureを作成
    fig = figure('Visible', 'off', 'Name', 'ANOVA Table');
    
    % uitableでFigure上に表を作成
    uit = uitable(fig, ...
        'Data', anova_table(2:end, :), ...         % データ部分
        'ColumnName', anova_table(1, :), ...      % ヘッダー（列名）
        'Units', 'normalized', ...
        'Position', [0, 0, 1, 1]);
    
    % uitableがFigure全体に広がるようにサイズを調整
    drawnow; % uitableの描画を強制的に完了させる
    uit.Position(3) = uit.Extent(3); % 幅をコンテンツに合わせる
    uit.Position(4) = uit.Extent(4); % 高さをコンテンツに合わせる
    fig.Position(3) = uit.Position(3) + 40; % Figureの幅を調整
    fig.Position(4) = uit.Position(4) + 60; % Figureの高さを調整
    
    % 高画質でPNGとして保存
    %print(fig, png_path, '-dpng', '-r150'); % 150 DPI
    saveas(fig, image_path);
    fprintf('ANOVA表をPNG画像に保存しました: %s\n', image_path);

catch ME
    warning('PNG画像の保存中にエラーが発生しました: %s', ME.message);
end

if ~isempty(fig)
    close(fig);
end

end