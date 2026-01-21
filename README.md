### Adaptive-Iterative-Linear-Interpolation


* **`AILI_pipeline.m`**: The main entry point for the AILI super-resolution algorithm that accepts adjustable parameters `M` and `N`.
* **`SILI_pipeline.m`**: Implements the standard SILI algorithm without adjustable parameters to serve as a baseline comparison.
* **`oscRational_SR2D.m`**: Implements the Oscillatory Rational Interpolation algorithm for 2D images for performance comparison.
* **`AILI_Quality_Metrics.m`**: Automatically calculates image quality metrics (PSNR, SSIM, and FSIM) by comparing AILI results to the original image.
* **`FSIMcalc.m`**: An external helper library used to calculate the Feature Similarity (FSIM) index.
* **`sweepMN_AILI_PSNRheatmap.m`**: Sweeps through a range of `M` and `N` parameters to identify the optimal combination and plots 2D heatmaps.
* **`ILI_1D_MSE.m`**: Performs theoretical validation and error analysis using 1D mathematical functions instead of images.
* **`visual_comparison.m`**: Generates a comprehensive visual comparison figure displaying results from multiple algorithms alongside zoomed-in details.
