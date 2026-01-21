function out = oscRational_SR2D(img_in, scale_factor, boundary)
%   img_in       : Input image 
%   scale_factor : Scaling factor 
%   boundary     : Boundary handling mode
%   out          : Output image 

    %% Parameter Initialization
    if nargin < 3 || isempty(boundary)
        boundary = 'replicate';
    end
    s = scale_factor;

    %% Image Format Conversion
    % Convert to double [0, 1] range consistently
    if isa(img_in,'uint8')
        img = im2double(img_in);
    else
        img = min(max(img_in,0),1);
    end

    %% Calculate Output Dimensions and Allocate Memory
    [H, W, C] = size(img);
    H2 = H * s;
    W2 = W * s;
    out = zeros(H2, W2, C);

    % Set Kernel support radius (R=2 corresponds to 4 taps)
    R = 2;

    %% Execute Pixel Interpolation Loop
    for yo = 1:H2
        % Calculate vertical mapping coordinates (Center-Aligned)
        y = (yo - 0.5)/s + 0.5;
        y0 = floor(y);
        y_idx = (y0-(R-1)):(y0+R);      % Index range: y0-1 to y0+2
        wy = oscRational_Kernel(y - y_idx);

        for xo = 1:W2
            % Calculate horizontal mapping coordinates
            x = (xo - 0.5)/s + 0.5;
            x0 = floor(x);
            x_idx = (x0-(R-1)):(x0+R);  % Index range: x0-1 to x0+2
            wx = oscRational_Kernel(x - x_idx);

            % Extract local pixel patch (consider boundary handling)
            patch = get_patch(img, y_idx, x_idx, boundary); % Size (4,4,C)

            % Calculate separable weight matrix
            Wxy = wy(:) * wx(:)';

            % Weight normalization 
            den = sum(Wxy(:));
            if abs(den) < 1e-12
                den = 1;
            end

            % Calculate pixel values for each channel
            for ch = 1:C
                out(yo,xo,ch) = sum(sum(patch(:,:,ch) .* Wxy)) / den;
            end
        end
    end

    % Clamp output range to [0, 1]
    out = min(max(out,0),1);
end

%====================== Kernel Function ========================
function h = oscRational_Kernel(t)
    % Oscillatory Rational Interpolation Kernel Function
    t = abs(t);
    h = zeros(size(t));

    % Interval |t| <= 1
    i1 = (t <= 1);
    h(i1) = ( -0.1680*t(i1).^2 - 0.9129*t(i1) + 1.0808 ) ./ ...
            (  t(i1).^2        - 0.8319*t(i1) + 1.0808 );

    % Interval 1 < |t| <= 2
    i2 = (t > 1) & (t <= 2);
    h(i2) = (  0.1953*t(i2).^2 - 0.5858*t(i2) + 0.3905 ) ./ ...
            (  t(i2).^2        - 2.4402*t(i2) + 1.7676 );
end

% ========= Helper Function: Boundary Handling and Patch Extraction =========
function patch = get_patch(img, y_idx, x_idx, boundary)
    % Extract pixel patch based on specified boundary mode
    [H,W,C] = size(img);
    yy = y_idx(:);
    xx = x_idx(:);

    switch lower(boundary)
        case 'replicate'
            % Replicate edge pixels
            yy = min(max(yy,1),H);
            xx = min(max(xx,1),W);

        case 'mirror'
            % Mirror reflection
            yy = mirror_index(yy, H);
            xx = mirror_index(xx, W);

        case 'zero'
            % Zero padding for out-of-bounds (do not modify indices, handle later)
        otherwise
            error("boundary must be 'replicate', 'mirror', or 'zero'.");
    end

    patch = zeros(numel(yy), numel(xx), C);

    for i = 1:numel(yy)
        for j = 1:numel(xx)
            yi = yy(i); xj = xx(j);

            if strcmpi(boundary,'zero')
                if (yi < 1) || (yi > H) || (xj < 1) || (xj > W)
                    patch(i,j,:) = 0;
                else
                    patch(i,j,:) = img(yi,xj,:);
                end
            else
                patch(i,j,:) = img(yi,xj,:);
            end
        end
    end
end

function idx = mirror_index(idx, N)
    % Calculate mirror index: ... 3 2 1 2 3 ... N-1 N N-1 ...
    idx = mod(idx-1, 2*N);
    over = idx >= N;
    idx(over) = 2*N - 1 - idx(over);
    idx = idx + 1;
end