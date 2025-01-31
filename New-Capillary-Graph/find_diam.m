function [mD, R] = find_diam(s,ds,sz)

% Input meanings:
% s = vessel
% ds = DD
% sz = 9

SL = zeros(sz);
x = 1:sz;
D = zeros(length(s)-1,1);
R = zeros(length(s)-1,1);
sd = [smooth(s(:,1)), smooth(s(:,2)), smooth(s(:,3))];
for i = 1:size(s,1)-1

   p1 = s(i,1);
   p2 = s(i,2);
   p3 = s(i,3);

    n1 = sd(i+1,1)-sd(i,1);
    n2 = sd(i+1,2)-sd(i,2);
    n3 = sd(i+1,3)-sd(i,3);

    %slice  = extralice(ds,p1,p2,p3,n1,n2,n3,(sz-1)/2);
    slice  = extralice(ds,p1,p2,p3,n1,n2,n3,(sz-1)/2);
    slice(isnan(slice))=0; 
    slice = abs(slice);
    %slm = slice(slice>=0);
%     ms = max(slm(:));
%     if isempty(ms) ==1 
%         ms = 1;
%     end
%     slice = slice/ms;
%     slice(slice <0)= 0; 

%     imagesc(imadjust(slice))
%    colormap(jet)
%    
%     title(num2str(i))
%     pause(0.5)
%     

   
 
    m = round(sz/2);
    sl = mean(slice(m-1:m+1,:),1);
    s2 = mean(slice(:,m-1:m+1),2);
    if sum(isnan(sl(:))) > 5
        continue
    else
        s1 = fillmissing(sl, 'nearest');
        s2 = fillmissing(s2, 'nearest');
    end
    s3 = s1+s2';
    s3 = mat2gray(s3);
    %s3 = s3-min(s3);
    [~, gof] = fit(x',s3','gauss1', 'Lower',[0,m-1,1],'Upper',[1,m+1,8],'StartPoint',[0.8 13 4]);
    pm = find(s3 == max(s3(:)));
    pm = pm(1);
    [~,b1] = min(abs(s3(1:pm)-max(s3)/2));
    [~,b2] = min(abs(s3(pm:end)-max(s3)/2));
    b2 = b2(1)+pm-1;
    fwhm = abs(b1(1)-b2);
    D(i) = fwhm;
    R(i) = gof.rsquare;
    %itt = itt + 1;
end

mD = mean(D(R>0.8));
end