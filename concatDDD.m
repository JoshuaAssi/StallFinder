function [DDD] = concatDDD(dataFileName, returnFileName)

cd(dataFileName)

load '000001_angio.mat'
files = dir('*_angio.*');
[Nz, nx, ny] = size(AG);
T = length(files);
DDD = nan(Nz, nx, ny, T);
DDD(:,:,:,1) = AG;
for t = 2:length(files)
    fileName = files(t);
    fileName = fileName.name;
    load(fileName)
    DDD(:,:,:,t) = AG;
end

cd(returnFileName)

end

