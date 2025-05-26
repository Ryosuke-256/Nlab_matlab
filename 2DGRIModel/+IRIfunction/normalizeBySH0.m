function [normalized_hdr] = normalizeBySH0(hdr_image)
% 入力: hdr_image (HxWx3のHDR画像, RGB)
% 出力: normalized_hdr (0次成分で正規化されたHDR画像)

    % Step 1: RGB → 輝度（Y成分）に変換
    luminance = rgb2luminance(hdr_image);

    % Step 2: 球面調和関数0次成分を計算（定数倍×全体の平均）
    % L_0 ∝ mean(luminance)
    SH0 = mean(luminance(:));  % 0次成分に相当

    % Step 3: HDR画像全体を0次成分で正規化
    normalized_hdr = hdr_image / SH0;

end

function Y = rgb2luminance(rgb_img)
% RGB → XYZ → 輝度Y（XYZの2番目）へ変換
    % sRGB to linear RGB（ガンマ補正除去）
    %{
    rgb_img(rgb_img <= 0.04045) = rgb_img(rgb_img <= 0.04045) / 12.92;
    rgb_img(rgb_img > 0.04045) = ((rgb_img(rgb_img > 0.04045) + 0.055) / 1.055).^2.4;
    %}

    % RGB → XYZ 変換行列（sRGB D65）
    M = [ ...
         0.4124564, 0.3575761, 0.1804375; ...
         0.2126729, 0.7151522, 0.0721750; ...
         0.0193339, 0.1191920, 0.9503041];

    [H, W, ~] = size(rgb_img);
    reshaped = reshape(rgb_img, [], 3)';
    XYZ = M * reshaped;  % 3 x (H*W)

    Y = reshape(XYZ(2,:), H, W);  % 輝度成分（Y）
end