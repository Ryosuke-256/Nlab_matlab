function Lout = Reinhard(L, pWhite)
    Lscaled =  L / 1.19;
    Lout = (Lscaled .* (1.0 + Lscaled / pWhite^2)) ./ (1.0 + Lscaled);
end