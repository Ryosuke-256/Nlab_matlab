%%%周波数分解をし、サブバンドコントラストを求める%%%

function h=subfilter(i)






%try

bn=i;



cntrfrq = 2.^bn;
fltwidth = 201;
halfwidth = (fltwidth-1)./2;
%% 理想周波数特性の設計
[f1,f2] = freqspace(fltwidth,'meshgrid');
Hd = zeros(fltwidth);
r = sqrt(f1.^2 + f2.^2);
if cntrfrq~=0 % bandpass
    lowfrq = 2^(log2(cntrfrq)-0.5);
    highfrq = 2^(log2(cntrfrq)+0.5);%0.8と1.3
    Hd((r>lowfrq./halfwidth)&(r<highfrq./halfwidth)) = 1;
    %Hd((r<lowfrq./halfwidth)|(r>highfrq./133)) = 1;  %64cpi用
    

    %print -dpng '64cpi_hd.png'
    %% ガウシアン関数による理想周波数特性を持つFIRフィルタ設計
    % 実空間領域でガウシアン窓の掛け合わせを行うので、可能な限りガウシアン形状を保ったままSDを大きくするべき
    % ガウシアン形状を保つと、フィルタの周波数特性のギザギザがなくなる。SDを大きくすると、周波数のカットオフ特性（周波数がすぱっと落ちる特性）が良くなる
    % win = fspecial('gaussian',fltwidth,fltwidth./5);
    win = fspecial('gaussian',fltwidth,fltwidth./4);
    win = win ./ max(win(:));  % Make the maximum window value be 1.

    h = fwind2(Hd,win);% このhは実空間でのフィルタ
else
    Hd(r<fw./halfwidth) = 1;
    win = fspecial('gaussian',fltwidth,fltwidth./4);
    win = win ./ max(win(:));  % Make the maximum window value be 1.
    h = fwind2(Hd,win);% このhは実空間でのフィルタ
end



end
