function data = calc_parcel(sub_Cft, mask_Cft, atlas_path, atlas_type, parcel_level, par)
    % Calculate networks meanTC based on provided parcellation atlas.
    % parcel_level: 
    %       'network', 
    %       'LR_network', 
    %       'roi', 
    %       'LR_roi', 
    %       'subroi', 
    %       'LR_subroi'

    atlas_cifti = ft_read_cifti(atlas_path, 'mapname', 'array');
    if strcmp(atlas_type, 'Schaefer')
        atlas_label = atlas_cifti.dlabel;
        atlas_labellabel = atlas_cifti.dlabellabel;
    elseif strcmp(atlas_type, 'Yeo')
        atlas_label = atlas_cifti.split_components;
        atlas_labellabel = atlas_cifti.split_componentslabel;
    end
    
    network_names = [' ']; 
%     network_index = cell(parcel_num, 2);
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
        if strcmp(parcel_level, 'network') % 'Default'
            name = string(net_name); 
        elseif strcmp(parcel_level, 'LR_network') % 'RH_Default'
            name = string([LR_name net_name]); 
        elseif strcmp(parcel_level, 'roi') % 'Default_pCunPCC'
            name = string([net_name, roi_name]); 
        elseif strcmp(parcel_level, 'LR_roi') % 'RH_Default_pCunPCC'
            name = string([LR_name, net_name, roi_name]); 
        elseif strcmp(parcel_level, 'subroi') % 'Default_pCunPCC_9'
            name = string([net_name, roi_name, subroi_name]); 
        elseif strcmp(parcel_level, 'LR_subroi')
            name = string([LR_name, net_name, roi_name, subroi_name]); % 'RH_Default_pCunPCC_9'
        end

        if ~any(contains(network_names, name)) 
            network_names = [network_names; name]; 
            network_index{p,1} = name;
            if strcmp(parcel_level, 'subroi') || strcmp(parcel_level, 'LR_subroi')
                pattern = ['^.*' char(name) '$']; % tail digits must be fully matched
                network_index{p,2} = find(cellfun(@(x) ...
                    ~isempty(regexp(x, pattern, 'once')), atlas_labellabel));
%                 disp(atlas_labellabel{1});
%                 disp(pattern);
%                 t = regexp(atlas_labellabel{1}, pattern, 'once');
%                 disp(1);
            else
                network_index{p,2} = find(contains(atlas_labellabel, name));
            end
            p = p + 1;
        end
    end
    
    % initializing data
    data.network_names = network_names(2:end);
    data.network_index = network_index;
    N_roi = size(network_index, 1);
    ind = 0;
%     data.bold = cell(data.roi_num,1);
%     if par.calc_mTC  
%         data.mTC = cell(data.roi_num,1); 
%     end
%     if par.calc_corr  
%         data.corr = cell(data.roi_num,1); 
%     end
%     data.mask_atlas = cell(data.roi_num,1);

    for i = 1:N_roi
        label_ind = network_index{i,2};
        atlas_mask = ismember(atlas_label, label_ind);
        netvalid_mask = atlas_mask & mask_Cft;
        if sum(netvalid_mask) > 0 
            ind = ind + 1;
            data.bold{ind} = sub_Cft(netvalid_mask,:);
            data.mask_atlas{ind} = atlas_mask(mask_Cft);
            if par.calc_mTC  
                data.mTC{ind} = mean(data.bold{ind}, 1); 
            end
            if par.calc_corr
                data.corr{ind}  = corr(data.bold{ind}, data.bold{ind});
            end 
        end        
    end
    data.roi_num = ind;
    data.original_cifti = atlas_cifti; %for debug
end