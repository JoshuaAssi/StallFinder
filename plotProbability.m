function [] = plotProbability(S, stallogram, DDavg)

P = sum(stallogram, 2)/size(stallogram,2);

scalingFactor = 4.4; % T=80 -> 4.4; T=100-> 4.65

imagesc(rescale(squeeze(max(DDavg))))
colormap gray
axis image
hold on
stallingVessels = find(P>0);
P = P(stallingVessels);
S = S(stallingVessels);

if 1 % log scale colormap
%     P = rescale(log(P))*max(P)+1/80;
%     C = round(P.*256);
    
    P = (log(P)+scalingFactor)/scalingFactor;
    C = round(P.*256);

else % linear colormap
    P = rescale(P)*max(P);
    C = round(P.*256)+1;
end

jetMap = jet;
C = jetMap(C,:);
if size(S{1},1)==1
    mSize = 30;
else
    mSize = 10;
end

for vI = 1:length(S)
    s = S{vI};
    plot(s(:,3),s(:,2), 'LineWidth', 3, 'Color',C(vI,:), 'Marker','.', 'MarkerSize', mSize)
end

cb = colorbar;
colormap(cb, jet);
caxis([0 1])

cb.Ticks = 0:1;
cb.TickLabels = [1 size(stallogram, 2)];
ylabel(cb, 'Cumulative Stall Duration (# of frames)')
title('Stalling Vessel Cumulative Stall Duration')
xticks([]); yticks([])

end