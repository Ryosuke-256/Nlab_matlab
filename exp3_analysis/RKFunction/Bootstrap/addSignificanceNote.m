function addSignificanceNote(ax, amp)
% addSignificanceNote - 有意性の注釈を追加
%
% 入力:
%   ax: 軸オブジェクト
%   amp: 増幅係数

y_Limits = ylim(ax);
x_Limits = xlim(ax);
text(ax, x_Limits(1)*0.9, y_Limits(2)-0.05, '* : p < 0.05', 'FontSize', 10 * amp);

end
