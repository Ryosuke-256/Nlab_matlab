function sz = getSizeAt(dims, idx)
    % getSizeAt - 指定したインデックスの次元サイズを取得（存在しない場合は1）
    if length(dims) >= idx
        sz = dims(idx);
    else
        sz = 1;
    end
end
