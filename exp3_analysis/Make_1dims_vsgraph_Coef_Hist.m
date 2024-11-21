function [] = Make_1dims_vsgraph_Coef_Hist(array1,err_array1,array2,err_array2,Filename)
resultpath = "./results/";
ana_result = "analysis/";
Datapath = "./data/";

MatNames = {'cu0025', 'cu0129', 'pla0075', 'pla0225'};
MatNames1 = {'cu_0.025', 'cu_0.129', 'pla_0.075', 'pla_0.225'};
MatNames2 = {'cu-0.025', 'cu-0.129', 'pla-0.075', 'pla-0.225'};
HDRNames3 = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30];
HDRlNames2 = [19, 39, 78, 80, 102, 125, 152, 203, 226, 227, 230, 232, 243, 278, 281];
HDRNames = [5,19,34,39,42,43,78,80,102,105,125,152,164,183,198,201,202,203,209,222,226,227,230,232,243,259,272,278,281,282];
ShapeNames = {'sphere','bunny','dragon','boardA','boardB','boardC'};

dims = size(array1);

coef_list = zeros(dims);
slop_list = zeros(dims);
idx1 = 1;

figure;
nexttile;
x = array1(:,idx1);
y = array2(:,idx1);
r = corrcoef(x,y);
r_value = r(1,2);
coef_list(idx1) = r_value;
p = polyfit(x,y,1);
p_fit = polyval(p,x);
slop_list(idx1) = p(1);

scatter(x,y,'filled');
hold on;
plot(x,p_fit,'r-','LineWidth',1.5);
hold off;

xlabel('Exp3(VR)');
ylabel('Old(2D)');
title(sprintf('HDR: Coef = %.2f,Slope = %.2f', coef_list(idx1),slop_list(idx1)));

plotname = sprintf('%s/%s_Coef.jpg',ana_result,Filename);
saveas(gcf, plotname);

%histgram
figure;
nexttile;

bar1 = array1(:,idx1);
err1 = err_array1(:,idx1);
bar2 = array2(:,idx1);
err2 = err_array2(:,idx1);
bar_width = 0.35;
x = 1:length(HDRNames);

hold on;
bar_exp3 = bar(x + bar_width/2, bar1, bar_width, 'FaceColor', 'b', 'DisplayName', '3D'); 
errorbar(x + bar_width/2, bar1, err1, 'k', 'linestyle', 'none');
bar_old = bar(x - bar_width/2, bar2, bar_width, 'FaceColor', 'r', 'DisplayName', '3D'); 
errorbar(x - bar_width/2, bar2, err2, 'k', 'linestyle', 'none');
hold off;

ylim([-1.2 1.2]);
set(gca, 'XTick', x);
xticklabels(HDRNames3);
xtickangle(90);
set(gca,'FontSize',6)

xlabel('HDR'); 
ylabel('Normalized z-score');
title(sprintf('HDR: Coef = %.2f,Slope = %.2f', coef_list(idx1),slop_list(idx1)));
legend([bar_exp3, bar_old], {'VR', '2D'}, 'Location', 'southeast','Orientation','vertical');
legend('boxoff');
grid on;

plotname = sprintf('%s/%s_Hist.jpg',ana_result,Filename);
saveas(gcf, plotname);

end