
%% Fill out the below information
% DDD = ; % DDD is a concatenation of all of the volumes. A double of size [nz, nx, ny, nt]
% zz = ; % zz is a vector of 2 numbers corresponding to the minimum and maximum z values for cropping 
% saveDir = ; % file name (string) of save location
% scoreThreshold = .25; % determines the sensitivity of the SVM ranging from 0 to 1. Default is .25

%% Main script
currentDir = pwd;
addpath([currentDir '/New-Capillary-Graph/'])

if zz(2)-zz(1) < 31 % the depth range must be at least 32 voxels
    error('Depth range must be at least 32 voxels. Specify a larger range or zero pad the image.')
end

tic
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
[Nz, nx, ny, T] = size(DDD);
DDDc = DDD(zz(1):zz(2),:,:,:);
DDDproc = log(DDDc);
DDavg = mean(DDDproc,4);

% Preprocess DDD

% average every 5 frames
nz = zz(2)-zz(1) + 1;
DDD5avg = nan(nz, nx, ny, floor(T/5));
tI =0;
for t1 = 1:5:(T-4)
    tI = tI+1;
    DDD5avg(:,:,:,tI) = mean(DDDproc(:,:,:,t1:(t1+4)), 4);
end

% skeletonize every 5
load('New-Capillary-Graph/net_unet.mat', 'net')
load('New-Capillary-Graph/net12_16_final.mat')
load('New-Capillary-Graph/corrnet_3layers.mat')
load('New-Capillary-Graph/net_reg.mat')

allSkels = cell(size(DDD5avg, 4), 5);
for tI = 1:size(DDD5avg, 4)
    [allSkels{tI,1}, allSkels{tI,2}, allSkels{tI,3}, allSkels{tI,4}, allSkels{tI,5}] = autoGraphCap_v2(squeeze(DDD5avg(:,:,:,tI)), net_reg, net, net12_16_final, corrnet);
end

% reference skeleton
segMat = cat(4,allSkels{:,5});
avgSeg = squeeze(mean(segMat, 4))>.3;
avgSeg_rescale = imresize3(double(avgSeg), [nz, nx, ny], 'Method', 'nearest');

%remove any small unconnected components
seg2 = avgSeg;
CC  = bwconncomp(seg2);
numPixels = cellfun(@numel,CC.PixelIdxList);
ind = find(numPixels > 30);
res = zeros(size(seg2));
for i = 1:length(ind)
    res(CC.PixelIdxList{ind(i)}) = 1;
end
skel = bwskel(res>0);
skel = imdilate(skel, strel('sphere',2));

skel = imgaussfilt3(double(skel),1)>0.3;
skel = bwskel(skel>0);
skel(:,[1:2, end-1:end],:) = 0;
skel(:,:,[1:2, end-1:end]) = 0;
S = rem_small(skel);
S0 = S;
skel0 = skel;

nS = length(S);
DDavg_exp = rescale(DDavg);
R_avg_exp = cell(1, nS);
mD_exp = nan(1, nS);
R0_avg_exp = nan(1,nS);
parfor vI = 1:nS
    [mD_exp(vI), R_avg_exp{vI}] = find_diam(S{vI}, DDavg_exp, 9);
    R0_avg_exp(vI) = mean(R_avg_exp{vI});
end
S = S(R0_avg_exp>.65);
skel_new = zeros(size(skel));
for vI = 1:length(S)
    s = S{vI};
    for pI = 1:size(s,1)
        skel_new(s(pI, 1),s(pI,2), s(pI,3)) = 1;
    end
end
skel = skel_new;

Ss_segm = cell(8,1);
vFilts_segm = cell(8,1);
skels_segm = cell(8,1);
skels_segm{1} = skel;
S_segm_new = S;
Ss_segm{1} = S;
for voxMin = 6:12
    vFilt_new = [];
    skel_new = zeros(size(skel));
    for vI = 1:length(S_segm_new)
        s = S_segm_new{vI};
        if size(s,1)>= voxMin
            vFilt_new = [vFilt_new vI];
            for pI = 1:size(s,1)
                skel_new(s(pI, 1),s(pI,2), s(pI,3)) = 1;
            end
        end
    end
    S_segm_new = segm(skel_new);
    Ss_segm{voxMin-4} = S_segm_new;
    vFilts_segm{voxMin-4} = vFilt_new;
    skels_segm{voxMin-4} = skel_new;
end
% S = Ss_segm{end};
% nS = length(S);

S_new = Ss_segm{1};
idx = [];
for vI = 1:length(S_new)
    if size(S_new{vI}, 1)<14
        idx = [idx vI];
    end
end
S_new(idx) = [];
S = S_new;
nS = length(S);

disp('Time to generate segmentation and skeletonization:')
toc
tic

% register DDD
csTforms = nan(3, 3,T);
Davg = squeeze(max(DDavg));
mips = squeeze(max(DDDproc));
for t = 1:T
    D0 = squeeze(mips(:,:,t));
    reg = registerCS(D0, Davg);
    csTforms(:,:,t) = reg.Transformation.T;
end

% apply registration
DDDreg = nan(size(DDDproc));
for t = 1:T
    DDDreg(:,:,:,t) = imwarp(squeeze(DDDproc(:,:,:,t)), affine3d(to3Dtform(squeeze(csTforms(:,:,t)))), 'OutputView', imref3d([nz nx ny]));
end
DDDreg(DDDreg==0) = mean(DDDreg, 'all');
DDDproc = DDDreg;

disp('Time to register enface:')
toc
tic

% motion correct
DDD_motionCorrected = DDDproc;
colMeans = squeeze(mean(squeeze(max(DDDproc(:,:,:,:))), 1));
col_t_outliers = isoutlier(colMeans, 2);
for colI = 1:nx
    arr = colMeans(colI,:);
    [~, tMed] = min(abs(arr-median(arr)));
    for t = 1:T
        if col_t_outliers(colI,t)
            DDD_motionCorrected(:,:,colI,t) = DDDproc(:,:,colI,tMed);
        end
    end
end
DDDproc = DDD_motionCorrected;

% histogram match
load('DD_reference.mat')
DDD_hMatch = nan(size(DDDproc));
for t = 1:T
    DDD_hMatch(:,:,:,t) = rescale(imhistmatchn(rescale(DDDproc(:,:,:,t)), rescale(log(DD_reference)), 1000), min(log(DD_reference),[], 'all'),max(log(DD_reference),[], 'all') );
end
DDDproc = DDD_hMatch;

% gaussian filter
for t = 1:T
    DDDproc(:,:,:,t) = imgaussfilt3(squeeze(DDDproc(:,:,:,t)), 1);
end

disp('Time to motion correct, histogram match, and filter:')
toc

saveFile = [saveDir '/DDDprocessed.mat'];
save(saveFile, 'DDDproc', '-v7.3')

tic
% volume int properties
dilRad = 2;
volIntPrc = nan([nS 5 T]);
volStds = nan(nS, T);
parfor vI = 1:nS
    s = S{vI};
    mask = zeros(nz, nx, ny);
    for pI = 2:(size(s,1)-1)
        mask(s(pI,1),s(pI,2),s(pI,3) ) = 1;
    end
    mask = imdilate(mask, strel('sphere', dilRad));
    mask = mask.*(avgSeg_rescale>.3);
    numVox = sum(mask, 'all');
    for t = 1:T
        masked = mask.*DDDproc(:,:,:,t);
        arr = masked(masked~=0);
        volIntPrc(vI,:,t) = prctile(arr, [0 25 50 75 100]);
        volStds(vI,t) = std(arr);
    end
end
disp('Time to compute volume intensity properties:')
toc
tic

% local background
dilRad = 4;
LBvolIntPrc = nan([nS 5 T]);
LBvolStds = nan(nS, T);
parfor vI = 1:nS
    s = S{vI};
    mask = zeros(nz, nx, ny);
    for pI = 2:(size(s,1)-1)
        mask(s(pI,1),s(pI,2),s(pI,3) ) = 1;
    end
    mask = imdilate(mask, strel('sphere', dilRad));
    mask = mask.*(avgSeg_rescale<=.1);
    numVox = sum(mask, 'all');
    for t = 1:T
        masked = mask.*DDDproc(:,:,:,t);
        arr = masked(masked~=0);
        LBvolIntPrc(vI,:,t) = prctile(arr, [0 25 50 75 100]);
        LBvolStds(vI,t) = std(arr);
    end
end
disp('Time to compute difference from local background:')
toc
tic

% difference from average
dilRad = 2;
avgDiffPrcs = nan(nS, 5, T);
DDDproc_avg = mean(DDDproc, 4);
parfor vI = 1:nS
    s = S{vI};
    mask = zeros(nz, nx, ny);
    for pI = 2:(size(s,1)-1)
        mask(s(pI,1),s(pI,2),s(pI,3) ) = 1;
    end
    mask = imdilate(mask, strel('sphere', dilRad));
    mask = mask.*(avgSeg_rescale>.3);
    numVox = sum(mask, 'all');
    for t = 1:T
        masked = squeeze(DDDproc(:,:,:,t))-DDDproc_avg;
        masked = imgaussfilt3(masked, .5).*mask;
        arr = masked(masked~=0);
        avgDiffPrcs(vI,:,t) = prctile(arr, [0 25 50 75 100]);
    end
end
disp('Time to compute difference from average image:')
toc

LBdiff = squeeze(volIntPrc(:, 3,:)-LBvolIntPrc(:,3,:));
maxVolIntPrcs = squeeze(max(volIntPrc, [],3));
maxAvgDiffPrcs = squeeze(max(avgDiffPrcs, [], 3));
maxVolIntMeds = squeeze(max(squeeze(volIntPrc(:,3,:)), [], 2));

tic
% apply SVM
load csSVM_alpha.mat
stallogram = nan(nS,T);
stallScores = nan(nS,T, 2);
for vI = 1:nS
    for t=1:T
        [stallogram(vI,t), stallScores(vI,t,:)] = predict(csSVM_alpha, [volIntPrc(vI, 1:3:4,t),volIntPrc(vI,2,t)-maxVolIntPrcs(vI,2), avgDiffPrcs(vI,1,t)]);
    end
end
stallPrcs = 1./(1+exp(stallScores(:,:,1)));
stallogram = stallPrcs>scoreThreshold;

disp('Time to apply classifier:')
toc

% display results
figure
subplot(2,2,1)
imagesc(squeeze(max(log(squeeze(DDDc(:,:,:,1))))));
colormap gray
axis image
title('Volume 1, original')
subplot(2,2,2)
imagesc(squeeze(max(squeeze(DDDproc(:,:,:,1)))));
colormap gray
axis image
title('Volume 1, processed')
subplot(2,2,3)
imagesc(squeeze(max(avgSeg_rescale)))
colormap gray
axis image
title('Segmentation')
subplot(2,2,3)
imagesc(squeeze(max(skels_segm{end})))
colormap gray
axis image
title('Skeleton')

figure
subplot(1,3,1:2)
plotProbability(S, stallogram, DDavg);
subplot(1,3,3)
imagesc(~stallogram)
colormap gray
title('Predicted Stallogram')

% clear large/uneeded vars and save
clear DDDproc DDD DDDc DD_reference DDD5avg DDD_hMatch DDD_motionCorrected DDDreg net net12_16_final net_reg corrnet ans arr CC col_t_outliers colI colMeans csTforms D0 Davg DD_reference DDavg_exp dilRad i idx ind LBdiff LBvolIntPrc LBvolStds maxAvgDiffPrcs maxVolIntMeds mD_exp mips nS numPixels Nz pI R0_avg_exp R_avg_exp reg res s S_new S_segm_new seg2 segMat skel_new t t1 tI tMed vFilt_new vFilts_segm vI voxMin 
saveFile = [saveDir '/processedData.mat'];
save(saveFile)

