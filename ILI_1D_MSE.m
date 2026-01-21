clc; clear; close all;

%% ===== 1. Parameter Settings and Data Generation =====
Ts   = 1/8;           % Sampling interval
Tend = 2*pi;          % Total simulation length

% Generate sampling points and values
x_s  = 0:Ts:Tend;     
y_s  = func(x_s);     

% Generate high-resolution true waveform (for error comparison)
x_fine = 0:0.001:Tend;
y_true = func(x_fine);

% AILI parameter settings
M = 0.69;
N = 0.59;
AILI_sprintf = sprintf('AILI( [M,N]=[%.2f,%.2f] )',M,N );

%% ===== 2. Execute Various Interpolation Algorithms =====
% 1D Linear Interpolation
fh_linear = interp1(x_s, y_s, x_fine, 'linear','extrap');

% Cubic Interpolation (MATLAB built-in)
fh_cubic  = interp1(x_s, y_s, x_fine, 'cubic');

% Lanczos Interpolation (using custom convolution function)
fh_lanczos2 = custom_interp(x_s, y_s, x_fine, @lanczos2_Kernel, 2);
fh_lanczos3 = custom_interp(x_s, y_s, x_fine, @lanczos3_Kernel, 3);

% SILI Interpolation
fh_SILI = custom_interp(x_s, y_s, x_fine, @SILI_Kernel, 2);

% AILI Interpolation (requires passing M, N)
fh_AILI = custom_interp(x_s, y_s, x_fine, @AILI_Kernel, 2, M, N);

% oscRational Interpolation
fh_oscRational = custom_interp(x_s, y_s, x_fine, @oscRational_Kernel, 2);

%% ===== 3. Error Calculation and Algorithm Selection =====
% [Settings Area]: Select algorithms to enable and display (true = enable)
% Corresponding order: Bilinear, Cubic, Lanczos2, Lanczos3, OscRational, SILI, AILI
use_flags = [true, true, true, true, true, true, true]; 

% Define names, data, and plotting styles for all candidate algorithms
raw_names  = {'Bilinear', 'Bicubic', 'lanczos2', 'lanczos3', 'oscRational', 'SILI', AILI_sprintf};
raw_F      = {fh_linear, fh_cubic, fh_lanczos2, fh_lanczos3, fh_oscRational, fh_SILI, fh_AILI};
raw_styles = {'--',      '-.',     '-.',        ':',        ':',           '-',     '-'};
raw_widths = {1,         1,        1,           1,          1,             1.2,     1.2};

% Filter items to display based on settings
methods    = raw_names(use_flags);
F          = raw_F(use_flags);
lineStyles = raw_styles(use_flags);
lineWidths = raw_widths(use_flags);

% Calculate and display errors (MSE, MAE)
Err = cell(size(F)); 
L = numel(x_fine);
fprintf('Sampling interval Ts = %.4f, 0 ~ 2π\n', Ts);

for k = 1:numel(F)
    e  = (F{k}(1:L) - y_true(1:L));
    Err{k} = e; 
    MSE = mean(e.^2, 'omitnan');
    MAE = mean(abs(e), 'omitnan');
    fprintf('%-15s : MSE = %.3e, MAE = %.3e\n', methods{k}, MSE, MAE);
end

%% ===== 4. Plotting: Error Curves (Figure 1) =====
figure; hold on; grid on;
for k = 1:numel(F)
    plot(x_fine(1:L), abs(Err{k}), ...
         'DisplayName', methods{k}, ...
         'LineStyle', lineStyles{k}, ...
         'LineWidth', lineWidths{k});
end
xlim([0 6]);
legend('show', 'Location', 'best', 'FontSize', 15); 
xlabel('x', 'FontSize', 14);
ylabel('Error e = f_{interp} - y_{true}', 'FontSize', 14);
title('Error curves', 'FontSize', 14);

%% ===== 5. Plotting: Waveform Comparison (Figure 2) =====
figure;
% Plot true waveform and sample points
plot(x_fine, y_true, 'k', 'LineWidth', 1.5, 'DisplayName', 'true'); hold on;
plot(x_s, y_s, 'ko', 'MarkerSize', 10, 'DisplayName', 'samples'); 

% Plot interpolation results for each algorithm
for k = 1:numel(F)
    % Slightly thicken lines for better waveform observation
    current_width = lineWidths{k} * 2; 
    if current_width < 1.5, current_width = 1.5; end 

    plot(x_fine, F{k}, ...
         'DisplayName', methods{k}, ...
         'LineStyle', lineStyles{k}, ...
         'LineWidth', current_width);
end

xlim([3.65 3.85]);   
ylim([0.19 0.23]);  

legend('show', 'Location', 'best', 'FontSize', 15);
title('Interpolation results comparison', 'FontSize', 14);
xlabel('x', 'FontSize', 14); ylabel('f(x)', 'FontSize', 14);
grid on;

%% ===== Helper Functions =====
function y = func(x)
    % Test target function
    y = sin(x.^2) ./ (x + 1);
end

%% ===== Kernel Function Definitions =====
function h = AILI_Kernel(t, M, N)
    % AILI interpolation kernel function
    h = zeros(size(t));
    % Region -2 < t < -1
    i1 = (t > -2) & (t < -1);
    h(i1) = (N/2) .* (t(i1) + 1) .* (t(i1) + 2);
    % Region -1 <= t < 0
    i2 = (t >= -1) & (t < 0);
    h(i2) = 0.5 .* (t(i2) + 1) .* ((M - 2*N) .* t(i2) + 2);
    % Region 0 <= t < 1
    i3 = (t >= 0) & (t < 1);
    h(i3) = (-M + N/2) .* t(i3).^2 + (M - N/2 - 1) .* t(i3) + 1;
    % Region 1 <= t < 2
    i4 = (t >= 1) & (t < 2);
    h(i4) = (M/2) .* (t(i4) - 1) .* (t(i4) - 2);
end

function h = SILI_Kernel(t)
    % SILI interpolation kernel function
    t = abs(t);
    h = zeros(size(t));
    i1 = (t < 1);
    h(i1) = 0.5*t(i1).^3 - t(i1).^2 - 0.5*t(i1) + 1;
    i2 = (t > 1) & (t < 2);
    h(i2) = -((1/6)*t(i2).^3 - t(i2).^2 + (11/6)*t(i2) - 1);
end

function h = oscRational_Kernel(t)
    % Oscillatory Rational interpolation kernel function
    t = abs(t);
    h = zeros(size(t));
    i1 = (t <= 1);
    h(i1) = ( -0.1680*t(i1).^2 - 0.9129*t(i1) + 1.0808 ) ./ ( t(i1).^2 - 0.8319*t(i1) + 1.0808 );
    i2 = (t > 1) & (t <= 2);
    h(i2) = (  0.1953*t(i2).^2 - 0.5858*t(i2) + 0.3905 ) ./ ( t(i2).^2 - 2.4402*t(i2) + 1.7676 );
end

function w = lanczos2_Kernel(t)
    % Lanczos2 interpolation kernel function (a=2)
    a = 2; t = double(t); w = zeros(size(t));
    mask = abs(t) < a; tt = t(mask);
    w(mask) = sinc(tt) .* sinc(tt/a);
end

function w = lanczos3_Kernel(t)
    % Lanczos3 interpolation kernel function (a=3)
    a = 3; t = double(t); w = zeros(size(t));
    mask = abs(t) < a; tt = t(mask);
    w(mask) = sinc(tt) .* sinc(tt / a);
end

%% ===== Custom 1D Interpolation Function =====
function y_fine = custom_interp(x_s, y_s, x_fine, kernelFunc, radius, varargin)
    % custom_interp: Convolution-based universal interpolation engine
    %
    % Input:
    %   x_s, y_s   : Original sampling points and values
    %   x_fine     : Target interpolation points
    %   kernelFunc : Kernel function handle (e.g., @AILI_Kernel)
    %   radius     : Kernel function support radius
    %   varargin   : Optional parameters (e.g., M, N)

    x_s = x_s(:).'; y_s = y_s(:).'; x_fine = x_fine(:).';
    Ts = x_s(2) - x_s(1); % Assume equal spacing
    y_fine = zeros(size(x_fine));
    
    % Check if M, N parameters are passed
    hasMN = (numel(varargin) >= 2);
    if hasMN, M = varargin{1}; N = varargin{2}; end
    
    k_nargin = nargin(kernelFunc);
    
    % Iterate through each target interpolation point
    for k = 1:numel(x_fine)
        % Calculate normalized distance from original sample points (Unit: Sample)
        t = (x_fine(k) - x_s) / Ts;
        
        % Filter sample points within the support range
        mask = abs(t) <= radius;
        tt = t(mask);
        
        % Processing for AILI: Dynamically adjust M, N based on relative position
        if hasMN
            cell_idx = floor(x_fine(k) / Ts);
            frac = (x_fine(k) / Ts) - cell_idx;
            % Use original parameters if closer to the left point; swap M, N if closer to the right point
            if frac <= 0.5
                M_use = M; N_use = N; 
            else
                M_use = N; N_use = M; 
            end
        end
        
        % Call kernel function to calculate weights
        if k_nargin == 1
            w = kernelFunc(tt);
        else
            if hasMN
                w = kernelFunc(tt, M_use, N_use); 
            else
                w = kernelFunc(tt); 
            end
        end
        
        % Weight normalization (Sum = 1)
        s = sum(w); 
        if s ~= 0, w = w / s; end
        
        % Execute convolution (weighted sum)
        y_fine(k) = sum(y_s(mask) .* w);
    end
end