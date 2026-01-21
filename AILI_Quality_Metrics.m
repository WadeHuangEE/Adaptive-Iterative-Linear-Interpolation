function [PSNR_val, SSIM_val, FSIM_val] = AILI_Quality_Metrics(input_img, scale_factor, M, N, doShave)
%   input_img    : Original HR image (RGB, uint8, or double)
%   scale_factor : Image scaling factor
%   M            : AILI parameter M
%   N            : AILI parameter N
%   doShave      : Whether to crop borders (default: true)
%   PSNR_val     : Output PSNR value (based on Y channel)
%   SSIM_val     : Output SSIM value (based on RGB channels)
%   FSIM_val     : Output FSIM value (based on RGB channels)

    if nargin < 5
        doShave = true;
    end

    %% Image Pre-processing
    % Convert to uint8 and crop to match scaling factor dimensions
    HR = input_img;
    if ~isa(HR, 'uint8')
        HR = im2uint8(HR);
    end

    [H, W, ~] = size(HR);
    Hc = H - mod(H, scale_factor);
    Wc = W - mod(W, scale_factor);
    HR = HR(1:Hc, 1:Wc, :);      
    HR_rgb = im2double(HR);      

    %% Color Space Conversion and Downsampling
    % Convert to YCbCr space and separate channels
    HR_ycb = rgb2ycbcr(HR_rgb);
    HR_Y   = HR_ycb(:,:,1);
    HR_Cb  = HR_ycb(:,:,2);
    HR_Cr  = HR_ycb(:,:,3);

    % Perform downsampling to generate LR images
    LR_Y  = HR_Y (1:scale_factor:end, 1:scale_factor:end);
    LR_Cb = HR_Cb(1:scale_factor:end, 1:scale_factor:end);
    LR_Cr = HR_Cr(1:scale_factor:end, 1:scale_factor:end);

    %% Perform Super-Resolution Reconstruction
    % Apply AILI algorithm to Y channel
    SR_Y = AILI_pipeline(LR_Y, scale_factor, M, N);
    
    % Alternative algorithms for reference (uncomment to switch)
    %SR_Y = SILI_pipeline(LR_Y, scale_factor);
    %SR_Y = imresize(LR_Y, scale_factor, 'bicubic');
    %SR_Y = imresize(LR_Y, scale_factor, 'bilinear');
    %SR_Y = imresize(LR_Y, scale_factor, 'lanczos2');
    %SR_Y = imresize(LR_Y, scale_factor, 'lanczos3');
    %SR_Y = oscRational_SR2D(LR_Y, scale_factor, 'replicate');

    % Upscale chroma channels (Cb/Cr) using Bicubic interpolation
    SR_Cb = imresize(LR_Cb, scale_factor, 'bicubic');
    SR_Cr = imresize(LR_Cr, scale_factor, 'bicubic');

    % Merge channels and convert back to RGB space
    SR_ycb = cat(3, SR_Y, SR_Cb, SR_Cr);
    SR_rgb = ycbcr2rgb(SR_ycb);

    %% Border Shaving
    % Remove border pixels to ensure accurate assessment
    if doShave
        s = scale_factor;
        HR_rgb = HR_rgb(1+s:end-s, 1+s:end-s, :);
        SR_rgb = SR_rgb(1+s:end-s, 1+s:end-s, :);
    end

    %% Calculate Image Quality Metrics
    % PSNR (based on Y channel)
    PSNR_val = psnr(SR_Y, HR_Y, 1);

    % SSIM (based on RGB channels)
    SSIM_val = ssim(SR_rgb, HR_rgb);

    % FSIM (based on RGB channels, uint8 format)
    HR_u8 = im2uint8(HR_rgb);
    SR_u8 = im2uint8(SR_rgb);
    FSIM_val = FSIMcalc(HR_u8, SR_u8);
end