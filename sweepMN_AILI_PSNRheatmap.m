% sweepMN_AILI_PSNRheatmap.m
% Perform AILI parameter (M, N) sweep, calculate PSNR/SSIM/FSIM metrics, and plot heatmaps

clear; clc; close all;

%% Parameter Settings
img_path      = 'head.png';            % Original image path
img_name      = "head";                % Image name (used for chart titles)
scale_factor  = 4;                     % Scaling factor
doShave       = true;                  % Whether to crop borders
step_MN       = 0.5;                   % Scanning step size

% Define parameter scanning range
M_list = -5:step_MN:5;
N_list = -5:step_MN:5;
nM = numel(M_list);
nN = numel(N_list);

%% Load Test Image
if exist(img_path, 'file')
    input_img = imread(img_path);
else
    error('Error: Image file %s not found', img_path);
end

%% Initialize Result Matrices
PSNR_map = nan(nN, nM);
SSIM_map = nan(nN, nM);
FSIM_map = nan(nN, nM);

%% Execute Parameter Sweep
fprintf('Start sweeping M, N parameters...\n');

% Initialize progress bar
total_steps = nN * nM;
count = 0;
hWait = waitbar(0, 'Preparing to start sweep...', 'Name', 'AILI Parameter Sweep');

for iN = 1:nN
    N = N_list(iN);
    for iM = 1:nM
        M = M_list(iM);

        count = count + 1;
        
        try
            % Update progress bar display
            waitbar(count / total_steps, hWait, ...
                sprintf('Sweeping... %.1f%% (N=%.2f, M=%.2f)', (count/total_steps)*100, N, M));
            
            % Calculate image quality metrics
            [PSNR_val, SSIM_val, FSIM_val] = AILI_Quality_Metrics( ...
                input_img, scale_factor, M, N, doShave);

            % Save results
            PSNR_map(iN, iM) = PSNR_val;
            SSIM_map(iN, iM) = SSIM_val;
            FSIM_map(iN, iM) = FSIM_val;

        catch ME
            % Error handling: Fill with NaN and show warning if calculation fails
            warning('Parameter M=%.3f, N=%.3f calculation error: %s', M, N, ME.message);
            PSNR_map(iN, iM) = NaN;
            SSIM_map(iN, iM) = NaN;
            FSIM_map(iN, iM) = NaN;
        end
    end
    fprintf('Row %d / %d (N = %.3f) finished.\n', iN, nN, N_list(iN));
end

% Close progress bar
close(hWait);
fprintf('Parameter sweep finished.\n');

%% Find Best Parameter Combinations
% Find maximum PSNR and its corresponding parameters
[~, idx_psnr] = max(PSNR_map(:));
[row_psnr, col_psnr] = ind2sub(size(PSNR_map), idx_psnr);
best_M_psnr = M_list(col_psnr);
best_N_psnr = N_list(row_psnr);
best_psnr   = PSNR_map(row_psnr, col_psnr);

% Find maximum SSIM and its corresponding parameters
[~, idx_ssim] = max(SSIM_map(:));
[row_ssim, col_ssim] = ind2sub(size(SSIM_map), idx_ssim);
best_M_ssim = M_list(col_ssim);
best_N_ssim = N_list(row_ssim);
best_ssim   = SSIM_map(row_ssim, col_ssim);

% Find maximum FSIM and its corresponding parameters
[~, idx_fsim] = max(FSIM_map(:));
[row_fsim, col_fsim] = ind2sub(size(FSIM_map), idx_fsim);
best_M_fsim = M_list(col_fsim);
best_N_fsim = N_list(row_fsim);
best_fsim   = FSIM_map(row_fsim, col_fsim);

% Output best results to command window
fprintf('\n=== Best parameters within scan range ===\n');
fprintf('PSNR max = %.4f @ (M = %.3f, N = %.3f)\n', best_psnr, best_M_psnr, best_N_psnr);
fprintf('SSIM max = %.4f @ (M = %.3f, N = %.3f)\n', best_ssim, best_M_ssim, best_N_ssim);
fprintf('FSIM max = %.4f @ (M = %.3f, N = %.3f)\n', best_fsim, best_M_fsim, best_N_fsim);

%% Plot PSNR Heatmap
figure;
[M_grid, N_grid] = meshgrid(M_list, N_list);
surf(M_grid, N_grid, PSNR_map);
view(2);            % Set to 2D top-down view
shading interp;     % Enable smooth interpolation display
axis tight;         % Fit axis to data range
colorbar;
xlabel('M'); ylabel('N');
title(sprintf('%s PSNR Smooth Heatmap', img_name));

hold on;
% Mark best point position
plot3(best_M_psnr, best_N_psnr, max(PSNR_map(:))+1, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
text(best_M_psnr, best_N_psnr, max(PSNR_map(:))+1, sprintf(' Max\n %.3f', best_psnr), ...
     'Color','k','FontSize',10,'FontWeight','bold'); 
hold off;

%% Plot SSIM Heatmap
figure;
surf(M_grid, N_grid, SSIM_map);
view(2); shading interp; axis tight; colorbar;
xlabel('M'); ylabel('N');
title(sprintf('%s SSIM Smooth Heatmap (scale = %d)', img_name, scale_factor));

hold on;
z_offset_ssim = max(SSIM_map(:)) + 0.01; 
plot3(best_M_ssim, best_N_ssim, z_offset_ssim, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
text(best_M_ssim, best_N_ssim, z_offset_ssim, sprintf(' Max\n %.4f', best_ssim), ...
     'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
hold off;

%% Plot FSIM Heatmap
figure;
surf(M_grid, N_grid, FSIM_map);
view(2); shading interp; axis tight; colorbar;
xlabel('M'); ylabel('N');
title(sprintf('%s FSIM Smooth Heatmap (scale = %d)', img_name, scale_factor));

hold on;
z_offset_fsim = max(FSIM_map(:)) + 0.01;
plot3(best_M_fsim, best_N_fsim, z_offset_fsim, 'r*', 'MarkerSize', 12, 'LineWidth', 1.5);
text(best_M_fsim, best_N_fsim, z_offset_fsim, sprintf(' Max\n %.4f', best_fsim), ...
     'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
hold off;