# StallFinder
 MATLAB software to automatically detect capillary stalling in time series Optical Coherence Tomography Angiography

Requirements:
-MATLAB (tested on R2023a)
-Computer Vision Toolbox
-Curve Fitting Toolbox
-Deep Learning Toolbox
-Image Processing Toolbox
-Signal Processing Toolbox
-Statistics and Machine Learning Toolbox

Instructions:
1. Load your 4D dataset and use stallFinder_main.m to run the automatic pipeline. The saved output inludes processed images, vessel segmentations and skeletons, a predicted stallogram, and other useful vessel metrics.
2. If necessary, use skeletonCorrectionGUI.m to correct the skeleton.
3. Finally, use stallCorrectionGUI.m to correct the stallogram.

*This is an early version of the software and we are continuing development based on your feedback. Please direct any inquiries to joshua_assi@alumni.brown.edu
