function Lout = Reinhard(L, pWhite)
    % L : 輝度(XYZのY)
    % pWhite：白色点の輝度
    Lscaled =  L / 1.19;
    Lout = (Lscaled .* (1.0 + Lscaled / pWhite^2)) ./ (1.0 + Lscaled);
end