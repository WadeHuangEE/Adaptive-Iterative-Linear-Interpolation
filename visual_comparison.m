% visual_comparison.m
% Compare visual results of various super-resolution algorithms, including full image and ROI zoom-in display

close all; clc; clear;

%% === Parameter Settings ===
imgPath      = 'baby.png';      % Original HR image path
scale_factor = 3;               % Scaling factor

% --- AILI Parameter Settings (Three sets for comparison) ---
% Set 1: Optimized for 1D MSE
M_1 = 0.69; 
N_1 = 0.59;
AILI_figName_1 = sprintf('AILI ([M,N]=[%.2f,%.2f])', M_1, N_1);

% Set 2: Emphasize high contrast
M_2 = 1.9; 
N_2 = 1.8;
AILI_figName_2 = sprintf('AILI ([M,N]=[%.2f,%.2f])', M_2, N_2);

% Set 3: Emphasize smoothness 
M_3 = -0.3; 
N_3 = 0.2;
AILI_figName_3 = sprintf('AILI ([M,N]=[%.2f,%.2f])', M_3, N_3);

%% 1. Read and Preprocess HR Image
img_in = imread(imgPath);
HR = img_in;

% Ensure format is uint8 for subsequent processing
if ~isa(HR, 'uint8')
    HR = im2uint8(HR);
end

% Crop image size to match scaling factor (Modcrop)
[H, W, ~] = size(HR);
Hc = H - mod(H, scale_factor);
Wc = W - mod(W, scale_factor);
HR = HR(1:Hc, 1:Wc, :);      
HR_rgb = im2double(HR);      

%% 2. Generate LR Image (Downsampling)
% Use Bicubic method to downscale image to simulate low-resolution input
LR_rgb = imresize(HR_rgb, 1/scale_factor, 'bicubic');

%% 3. Execute Various Super-Resolution Algorithms
% AILI (Three parameters)
img_out_AILI_1 = AILI_pipeline(LR_rgb, scale_factor, M_1, N_1);
img_out_AILI_2 = AILI_pipeline(LR_rgb, scale_factor, M_2, N_2);
img_out_AILI_3 = AILI_pipeline(LR_rgb, scale_factor, M_3, N_3);

% SILI
img_out_SILI   = SILI_pipeline(LR_rgb, scale_factor);

% Traditional interpolation methods
img_out_BiCubic  = imresize(LR_rgb, scale_factor, 'bicubic');
img_out_BiLinear = imresize(LR_rgb, scale_factor, 'bilinear');
img_out_lanczos2 = imresize(LR_rgb, scale_factor, 'lanczos2');
img_out_lanczos3 = imresize(LR_rgb, scale_factor, 'lanczos3');

% OscRational
img_out_oscRational = oscRational_SR2D(LR_rgb, scale_factor, 'replicate');

%% 4. Set Region of Interest (ROI)
% Define ROI coordinates and size (x, y, width, height)
x0 = 100;
y0 = 70;
w  = 60;
h  = 60;
cropROI = @(img) img(y0:y0+h-1, x0:x0+w-1, :);

%% 5. Visualization Comparison and Plotting
% Define display list (labels and corresponding images)
img_list = {
    'Ground Truth',     img_in;
    'Bicubic',          img_out_BiCubic;
    'SILI',             img_out_SILI;
    AILI_figName_1,     img_out_AILI_1; 
    AILI_figName_2,     img_out_AILI_2; 
    AILI_figName_3,     img_out_AILI_3; 
    'BiLinear',         img_out_BiLinear;
    'Lanczos2',         img_out_lanczos2;
    'Lanczos3',         img_out_lanczos3;
    'OscRational',      img_out_oscRational;
};

num_imgs = size(img_list, 1);

% Set window size and properties
fig_width_px  = 1400; 
fig_height_px = 800;
figure('Name', 'Algorithm Comparison', 'NumberTitle', 'off', 'Color', 'w', ...
       'Position', [100, 100, fig_width_px, fig_height_px]);

% Get image aspect ratio (assume all result sizes are the same)
[img_H, img_W, ~] = size(img_list{1,2});
img_ratio = img_H / img_W; 

% Layout parameter calculation
nCols = 5;
nRows = ceil(num_imgs / nCols);

marg_l = 0.01;   % Left margin
marg_r = 0.01;   % Right margin
gap_w  = 0.01;   % Horizontal gap
gap_h  = 0.04;   % Vertical gap (reserve space for text)

% Calculate subplot width (Normalized)
sub_w = (1 - marg_l - marg_r - (nCols-1)*gap_w) / nCols;

% Calculate subplot height based on image ratio to ensure no whitespace
sub_h = sub_w * img_ratio * (fig_width_px / fig_height_px);

% Check if window height is sufficient
total_H_needed = nRows * sub_h + (nRows-1)*gap_h + 0.15;
if total_H_needed > 1
    warning('Window height insufficient, suggest increasing fig_height_px to avoid overlap');
end

start_y = 1 - 0.02; % Start Y position
inset_ratio = 0.35; % Ratio of ROI inset to main image

% Loop to plot all results
for i = 1:num_imgs
    algo_name = img_list{i, 1};
    img_data  = img_list{i, 2};
    
    row_idx = ceil(i / nCols);
    col_idx = mod(i-1, nCols) + 1;
    
    % Calculate subplot position
    pos_x = marg_l + (col_idx-1) * (sub_w + gap_w);
    pos_y = start_y - row_idx * sub_h - (row_idx-1) * gap_h;
    
    % --- Plot Main Image ---
    ax = axes('Position', [pos_x, pos_y, sub_w, sub_h]);
    imshow(img_data); hold on;
    
    % --- Plot Zoomed-in ROI ---
    roi_img = cropROI(img_data);
    % Add white border
    roi_img_border = padarray(roi_img, [2 2], 255); 
    [rH, rW, ~] = size(roi_img_border);
    
    % Calculate ROI display size and position (fixed at bottom-left)
    disp_w = img_W * inset_ratio;       
    disp_h = disp_w * (rH / rW);    
    x_data = [1, disp_w];
    y_data = [img_H - disp_h + 1, img_H];
    
    image('CData', roi_img_border, 'XData', x_data, 'YData', y_data);
    
    % --- Add Bottom Description Text ---
    label_str = sprintf('(%s) %s', char(96+i), algo_name);
    text(0.5, -0.015, label_str, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'top', ... 
        'FontName', 'Times New Roman', ...
        'FontSize', 14, ...
        'FontWeight', 'bold');
end