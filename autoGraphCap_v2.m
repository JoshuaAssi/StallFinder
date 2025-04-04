function [S, Sn, Enh, skel, res] = autoGraphCap_v2(DD, net_reg, net, net12_16_final, corrnet)

% cd New-Capillary-Graph\
%
% DD2 = DD;
% DD = imresize3(DD, [size(DD, 1) 2*size(DD, 2) 2*size(DD, 3)], 'linear');
% DD(DD == 0) = mean(DD(DD(:)~=0));
DD = medfilt3(DD);
logDD = DD; % log applied beforehand
logDD = mat2gray(logDD);
[s1, s2, s3] = size(logDD);
m1 = mod([s1 s2 s3],32);
p1 = 0; p2 = 0; p3 = 0;
if m1(1) > 0
    p1 = 32-m1(1);
end
if m1(2) > 0
    p2 = 32-m1(2);
end
if m1(3) > 0
    p3 = 32-m1(3);
end
if sum(m1) > 0
    logDD = padarray(logDD, [p1 p2 p3], 'post');
end
Enh = activations(net_reg, logDD, 'regressionoutput', 'executionenvironment', 'cpu');
Enh = Enh(1:s1,1:s2,1:s3);
Enh2 = activations(net, logDD, 'reg', 'executionenvironment', 'cpu');
Enh2 = Enh2(1:s1,1:s2,1:s3);
logDD = logDD(1:s1,1:s2,1:s3);
Enh = max(Enh,Enh2);
%
[s1, s2, s3] = size(Enh);
m1(1) = mod(s1,12);
m1(2) = mod(s2,16);
m1(3) = mod(s3,16);
p1 = 0; p2 = 0; p3 = 0;
if m1(1) > 0
    p1 = 12-m1(1);
end
if m1(2) > 0
    p2 = 16-m1(2);
end
if m1(3) > 0
    p3 = 16-m1(3);
end
if sum(m1) > 0
    Enh = padarray(Enh, [p1 p2 p3], 'post');
end
seg_approx = semanticseg(Enh,net12_16_final, 'executionenvironment', 'cpu');
seg_approx = double(seg_approx) - 1;
seg = imclose(seg_approx,ones(3,3,3));
seg = seg(1:s1,1:s2,1:s3);
Enh = Enh(1:s1,1:s2,1:s3);
seg = imgaussfilt3(seg,1) > 0.3;
%
c(:,:,:,1) = mat2gray(logDD);
c(:,:,:,2) = Enh;
c(:,:,:,3) = seg;
seg_corr = activations(corrnet,c,'dice', 'executionenvironment','cpu');
seg2 = max(seg_corr(1:s1,1:s2,1:s3,2),seg);
seg2 = seg2>0.3;
seg2 = imclose(seg2,ones(3,3,3));
%remove any small unconnected components
CC  = bwconncomp(seg2);
numPixels = cellfun(@numel,CC.PixelIdxList);
ind = find(numPixels > 30);
res = zeros(size(seg2));
for i = 1:length(ind)
    res(CC.PixelIdxList{ind(i)}) = 1;
end
%
skel = bwskel(res>0);
skel = imdilate(skel, strel('sphere',2));
% skel = imresize3(double(skel), [size(skel,1), size(skel,2)/2, size(skel,3)/2]);
skel = imgaussfilt3(double(skel),1)>0.3; % added double() to account for above comment
skel = bwskel(skel>0);
S = rem_small(skel); % consider using segm3(skel) instead

Sn = 0;
end
