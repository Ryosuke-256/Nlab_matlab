function PlotHistgram_Frequency(data,dataName,displayName)
histogram(data, 'BinEdges', 0:0.025:1);

xlabel('Bin', 'FontSize', 14);
ylabel('Frequency', 'FontSize', 14);

plotTitle = sprintf('%s - %s (Bin Width: 0.025)', dataName, displayName);
title(plotTitle, 'FontSize', 16, 'Interpreter', 'none');
grid on;
end

