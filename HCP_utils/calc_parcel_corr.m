function data = calc_parcel_corr(data_path, data_type, atlas_path, atlas_type, parcel_num, parcel_level, par)
    [sub_Cft, mask_Cft, num_vert] = read_data(data_path, data_type);
    data.sub_Cft = sub_Cft;
    data.mask_Cft = mask_Cft;
    data.num_vert = num_vert;
    if exist('par.if_norm','var') && par.if_norm == 1
        data.sub_Cft(mask_Cft,:) = normalize(sub_Cft(mask_Cft,:),2);
    end

    atlas_cifti = ft_read_cifti(atlas_path, 'mapname', 'array');
    if strcmp(atlas_type, 'Schaefer')
        atlas_label = atlas_cifti.dlabel;
        atlas_labellabel = atlas_cifti.dlabellabel;
    elseif strcmp(atlas_type, 'Yeo')
        atlas_label = atlas_cifti.split_components;
        atlas_labellabel = atlas_cifti.split_componentslabel;
    end
    
    network_names = [' ']; network_index = cell(parcel_num, 2);
    p = 1;
    for ind = 1:size(atlas_labellabel,2)
        split_name = split(atlas_labellabel(ind), '_');
        LR_name = [split_name{2}, '_'];
        net_name = split_name{3};
        if size(split_name,1) == 4
            roi_name = '';
            subroi_name = ['_' split_name{4}];
        elseif size(split_name,1) == 5
            roi_name = ['_' split_name{4}];
            subroi_name = ['_' split_name{5}];
        end

        % This section determine the parcellation level of the whole brain
        % For example, if split_name is '7Networks_RH_Default_pCunPCC_9',
        % then take ...
        if strcmp(parcel_level, 'network') % ...'Default' as input
            name = string(net_name); 
        elseif strcmp(parcel_level, 'LR_network') % ...'RH_Default' as input
            name = string([LR_name net_name]); 
        elseif strcmp(parcel_level, 'roi') % ...'Default_pCunPCC' as input
            name = string([net_name, roi_name]); 
        elseif strcmp(parcel_level, 'LR_roi') % ...'RH_Default_pCunPCC' as input
            name = string([LR_name, net_name, roi_name]); 
        elseif strcmp(parcel_level, 'subroi') % ...'Default_pCunPCC_9' as input
            name = string([net_name, roi_name, subroi_name]); 
        elseif strcmp(parcel_level, 'LR_subroi') % ...'RH_Default_pCunPCC_9' as input
            name = string([LR_name, net_name, roi_name, subroi_name]); 
        end

        if ~any(contains(network_names, name)) 
            network_names = [network_names, name]; 
            network_index{p,1} = name;
            network_index{p,2} = find(contains(atlas_labellabel, name));
            p = p + 1;
        end
    end
    data.network_names = network_names(2:end);
    data.network_index = network_index;
    
    data.roi_num = size(network_index, 1);
    data.bold = cell(data.roi_num,1);
    if par.calc_mTC  
        data.mTC = cell(data.roi_num,1); 
    end
    if par.calc_corr  
        data.corr = cell(data.roi_num,1); 
    end
    data.mask_atlas = cell(data.roi_num,1);
    for i = 1:data.roi_num
        label_ind = network_index{i,2};
        atlas_mask = ismember(atlas_label, label_ind);
        netvalid_mask = atlas_mask & mask_Cft;
        data.bold{i} = sub_Cft(netvalid_mask,:);
        if par.calc_mTC  
            data.mTC{i} = mean(data.bold{i}, 1); 
        end
        if par.calc_corr
            data.corr{i}  = corr(data.bold{i}, data.bold{i});
        end 
        data.mask_atlas{i} = atlas_mask(mask_Cft);
    end
end