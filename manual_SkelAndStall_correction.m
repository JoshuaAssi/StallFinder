function [stallogram_new, S_new, stallPrcs_new, volIntPrc_new] = manual_SkelAndStall_correction(S, DDD, stallogram, stallPrcs, volIntPrc)

% edit skeleton
DD = squeeze(mean(DDD, 4));
[S_new, stallogram_new1, stallPrcs_new, volIntPrc_new] = skeletonCorrectionGUI(S, DD, stallogram, stallPrcs, volIntPrc);

% edit stallogram
[stallogram_new] = stallCorrectionGUI(S_new, DDD, stallogram_new1, stallPrcs_new, squeeze(volIntPrc_new(:,3,:)));

end
