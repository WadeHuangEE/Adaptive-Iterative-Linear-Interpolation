function out = SILI_pipeline(z, scale_factor)
%   z           : Input image (H x W x C)
%   scale_factor: Scaling factor 
%   out         : Output image 

    [H, W, C] = size(z);
    newH = round(H * scale_factor);
    newW = round(W * scale_factor);

    if C == 3
        out = zeros(newH, newW, 3, class(z));
        for c = 1:3
            out(:,:,c) = SILI_single(z(:,:,c), newH, newW);
        end
    else
        out = SILI_single(z, newH, newW);
    end
end

function out = SILI_single(z, newH, newW)
%   z     : Single-channel input image (H x W)
%   newH  : Target height
%   newW  : Target width
%   out   : Single-channel output image 

    z = im2double(z);              
    [H, W] = size(z);
    out = zeros(newH, newW);

    zp = padarray(z, [2 2], 'replicate', 'both');

    stepx = W / newW;
    stepy = H / newH;

    for i = 1:newH
        yi = (i - 0.5) * stepy + 0.5;   
        for j = 1:newW
            xi = (j - 0.5) * stepx + 0.5; 

            fxf = floor(xi);  fyf = floor(yi);
            xidx = (fxf - 1) + (0:3);   
            yidx = (fyf - 1) + (0:3);   

            f = zp(yidx + 2, xidx + 2);

            xc = ceil(xi);     yc = ceil(yi);
            xf = floor(xi);    yf = floor(yi);

            Vc1 = f(2,1); Vc2 = f(2,2); Vc3 = f(2,3); Vc4 = f(2,4);
            yp  = yi - yf;
            xp  = xi - xf;
            xL  = (xc + 1 - xi) / 3;
            yL  = (yc + 1 - yi) / 3;

            yM = yp - 1;
            xM = xp - 1;

            DxVc12 = Vc2 - Vc1;
            DxVc23 = Vc3 - Vc2;
            DxVc34 = Vc4 - Vc3;

            A1 = f(2,1) - f(1,1);  B1 = f(3,1) - f(2,1);  C1 = f(4,1) - f(3,1);
            A2 = f(2,2) - f(1,2);  B2 = f(3,2) - f(2,2);  C2 = f(4,2) - f(3,2);
            A3 = f(2,3) - f(1,3);  B3 = f(3,3) - f(2,3);  C3 = f(4,3) - f(3,3);
            A4 = f(2,4) - f(1,4);  B4 = f(3,4) - f(2,4);  C4 = f(4,4) - f(3,4);

            Dx2VcL = DxVc23 - DxVc12;
            Dx2VcR = DxVc34 - DxVc23;

            D1 = B1 - A1;  E1 = C1 - B1;
            D2 = B2 - A2;  E2 = C2 - B2;
            D3 = B3 - A3;  E3 = C3 - B3;
            D4 = B4 - A4;  E4 = C4 - B4;

            F1 = E1 - D1;
            F2 = E2 - D2;
            F3 = E3 - D3;
            F4 = E4 - D4;

            Bx1 = B2 - B1;  Bx2 = B3 - B2;  Bx3 = B4 - B3;
            Ex1 = E2 - E1;  Ex2 = E3 - E2;  Ex3 = E4 - E3;
            Fx1 = F2 - F1;  Fx2 = F3 - F2;  Fx3 = F4 - F3;

            BxL = Bx2 - Bx1;  BxR = Bx3 - Bx2;
            ExL = Ex2 - Ex1;  ExR = Ex3 - Ex2;
            FxL = Fx2 - Fx1;  FxR = Fx3 - Fx2;

            V2tmp0    = yL * (-F2)  + E2;
            qx23tmp0  = yL * (-Fx2) + Ex2;
            Dxtmp0    = (-FxL) * yL + ExL;
            Extmp0    = (-FxR) * yL + ExR;

            V2tmp1    = B2  + V2tmp0   * (yM / 2);
            qx23tmp1  = Bx2 + qx23tmp0 * (yM / 2);
            Dxtmp1    = BxL + Dxtmp0   * (yM / 2);
            Extmp1    = BxR + Extmp0   * (yM / 2);

            V2   = Vc2    + V2tmp1   * yp;
            qx23 = DxVc23 + qx23tmp1 * yp;
            Dx   = Dx2VcL + Dxtmp1   * yp;
            Ex   = Dx2VcR + Extmp1   * yp;

            Qx = xL * (Dx - Ex) + Ex;
            qx = Qx * (xM / 2) + qx23;
            fh = V2 + xp * qx;
            out(i,j) = fh;
        end
    end
end