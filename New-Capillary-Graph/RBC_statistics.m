clear Flux_ad id_t Flux_ad_std
path_uid =  'D:\kwalek';
%path_id = {'170622_AD1', '170630_AD3', '170714_AD1', '170725_AD3','170801_AD1','170814_AD3','170907_AD1', '170914_AD6','170916_AD7','170917_AD9','170919_AD3','170923_AD10','171002_AD1','171007_AD6','171007_AD7','171007_AD8','171008_AD9','171016_AD3','171022_AD10','171030_AD1','171104_AD6','171104_AD7','171104_AD8','171104_AD9','171113_AD3','171118_AD6','171118_AD10'}
path_id = {{'emp', 'emp', '170801_AD1rbc','170907_AD1rbc','171002_AD1rbc','171030_AD1rbc','171127_AD1rbc'}, ...
{'emp', '170725_AD3', '170814_AD3rbc', 'emp', 'emp', '171113_AD3rb', '171208_AD3r'},...
{'170914_AD6','171007_AD6','171104_AD6','171118_AD6','171211_AD6','180122_AD6','180223_AD6'},...
{'170916_AD7','171007_AD7','171104_AD7','171202_AD7','171216_AD7r', 'emp', 'emp'},...
{'170916_AD8rbc','171007_AD8rbc','171104_AD8rbc','171202_AD8r','171216_AD8r','180204_AD8r','180224_AD8r'},...
{'170917_AD9rbc','171008_AD9rbc','171104_AD9rbc','171202_AD9r','171216_AD9r','180204_AD9r','180224_AD9r'},...
{'emp','171022_AD10rbc','171118_AD10rbc','171216_AD10r','180122_AD10r','180213_AD10r','180311_AD10r'}};
T = [];

for i = 1:length(path_id)
    nd = length(path_id{i});
    Flux_sub = zeros(1,nd);
    Flux_cov_sub = zeros(1,nd);
    for j = 1:nd
        if strcmp(path_id{i}{j}, 'emp')
            Flux_sub(j) = nan;
            continue
        else
            load([path_uid '\' path_id{i}{j} '\rbc_flux'], 'F' )
            Flux_sub(j) = nanmean(F);
            Flux_cov_sub(j) = nanstd(F)./nanmean(F);
         
         
        end
    end
    Flux_ad{i} = Flux_sub;
    Flux_ad_cov{i} = Flux_cov_sub;
end

Flux_ad = cell2mat(Flux_ad');
Flux_ad_cov = cell2mat(Flux_ad_cov');
Flux_ad_cov(Flux_ad_cov(:) == 0) = nan;
age = repmat(1:7,size(Flux_ad,1),1);
group = categorical(cellstr(repmat('AD',length(Flux_ad(:)),1)));
ad_id = {'ad1', 'ad3', 'ad6', 'ad7', 'ad8', 'ad9', 'ad10'};
for i = 1:length(ad_id)
id_t(i,:) = repmat(categorical(cellstr(ad_id{i})),1,7);
end
flux_tab_ad = table(Flux_ad(:), Flux_ad_cov(:), age(:), id_t(:),group, 'variablenames', {'mean_flux','cov_flux', 'age', 'id', 'group'});

%%
clear id_wt Flux_wt Flux_wt_std


   path_uid =  'D:\kwalek';
path_id = {{'emp','170802_WT1r','170909_WT1r','171003_WT1rbc','171103_WT1rbc','171201_WT1rbc','171211_WT1r'},...
    {'170717_WT3r','emp','170915_WT3rbc','171007_WT3rbc','171104_WT3rbc','171203_WT3r','171217_WT3r'},...
    {'emp','emp','170915_WT4rbc','171007_WT4rbc','171104_WT4rbc','171203_WT4r','171217_WT4r'},...
    {'emp','emp','170919_WT7rbc','171024_WT7rbc','171117_WT7rbc','171204_WT7r','180123_WT7r'},...
    {'emp','emp','170930_WT9rbc','171028_WT9rbc','171118_WT9rbc','171215_WT9r','180123_WT9r'},...
    {'emp','emp','170930_WT10rbc','171028_WT10rbc','171118_WT10rbc','171216_WT10r','emp'}};
for i = 1:length(path_id)
    nd = length(path_id{i});
    Flux_sub = zeros(1,nd);
    Flux_cov_sub = zeros(1,nd);
    for j = 1:nd
        if strcmp(path_id{i}{j}, 'emp')
            Flux_sub(j) = nan;
            continue
        else
        load([path_uid '\' path_id{i}{j} '\rbc_flux'], 'F')
        Flux_sub(j) = nanmean(F);
        Flux_cov_sub(j) = nanstd(F)./nanmean(F);
        end
    end
    Flux_wt{i} = Flux_sub;
    Flux_wt_cov{i} = Flux_cov_sub;
end
Flux_wt = cell2mat(Flux_wt');
age = repmat(1:7,size(Flux_wt,1),1);

Flux_wt_cov = cell2mat(Flux_wt_cov');
Flux_wt_cov(Flux_wt_cov(:) == 0) = nan;
group = categorical(cellstr(repmat('WT',length(Flux_wt(:)),1)));
wt_id = {'wt1', 'wt3', 'wt4', 'wt7', 'wt9', 'wt10'};

for i = 1:length(wt_id)
id_wt(i,:) = repmat(categorical(cellstr(wt_id{i})),1,7);
end
flux_tab_wt = table(Flux_wt(:), Flux_wt_cov(:), age(:), id_wt(:), group, 'variablenames', {'mean_flux', 'cov_flux','age', 'id', 'group'});

    %%
    
    flux_tab = [flux_tab_ad ;flux_tab_wt];