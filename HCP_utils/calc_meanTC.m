function [meanTC, maskCft] = calc_meanTC(session, data_type, task, ses_name,...
                                        max_frame_num, N, root_path, cifti_template, ...
                                        if_normalize, if_smooth)
    % prepare parameters
    if ~exist('if_normalize','var') 
        if_normalize = 1;  
    end

    sigma = 4;
    if ~exist('if_smooth','var') 
        if_smooth = 0;
    elseif if_smooth == 1
        sigma = 4;
    elseif if_smooth > 1
        sigma = if_smooth;
    end
    
    % build mean time course data file save name
    if ~exist('result_meanTC','dir') mkdir('result_meanTC'); end
    meanTC_savename = ['result_meanTC/' task '_' ses_name ...
                        '_' int2str(N) 'mean' ...
                        '_Norm' int2str(if_normalize) '.dtseries.nii'];
    meanTCSmooth_savename = ['result_meanTC/' task '_' ses_name ...
                        '_' int2str(N) 'mean' ...
                        '_Norm' int2str(if_normalize) '_Smoothed.dtseries.nii'];
    meanTC = []; 
    
    % task or rest fMRI
    if strcmp(task,'REST1') || strcmp(task,'REST2')
        fMRI_name = 'rfMRI';
        folder_name = fullfile(root_path, 'HCP100_rest');
        hp = 'hp2000';
    else
        fMRI_name = 'tfMRI';
        folder_name = fullfile(root_path, 'HCP100_task');
        hp = 'hp0';
    end
    
    subdir = dir(folder_name);
    if (~exist(meanTC_savename,'file') && if_smooth <= 0) || ...
        (~exist(meanTCSmooth_savename,'file') && if_smooth > 0)

        disp(['Calculating mean time course: ' fMRI_name ' - ' task]);
        N_valid = N;
        for i = 1:N
            id = subdir(i+2).name(1:6);
            
            % ----- build fMRI original and smoothed data path ----- 
            surf_L_path = fullfile(root_path, 'HCP100_structual', ...
                            id, 'MNINonLinear', 'fsaverage_LR32k', ...
                            [id '.L.midthickness_MSMAll.32k_fs_LR.surf.gii']);
            surf_R_path = fullfile(root_path, 'HCP100_structual', ...
                            id, 'MNINonLinear', 'fsaverage_LR32k', ...
                            [id '.R.midthickness_MSMAll.32k_fs_LR.surf.gii']);

            if strcmp(data_type,'fMRI')
                original_path = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_' session], ...
                                    [fMRI_name '_' task '_' session ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean.dtseries.nii']);
                smooth_path = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_' session], ...
                                    [fMRI_name '_' task '_' session ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean' ...
                                    '_smooth_' int2str(sigma)  '.dtseries.nii']);
                if ~exist(smooth_path, 'file') && if_smooth > 0
                    disp(['Smoothed fMRI data not exist. ' ...
                        'Performing spatial smoothing sub-' int2str(i)]);
                    system(['wb_command -cifti-smoothing ' original_path  ' ' ...
                        int2str(sigma) ' ' int2str(sigma) ' -fwhm COLUMN ' ...
                        smooth_path ' -left-surface ' surf_L_path ...
                        ' -right-surface ' surf_R_path]);
                end
                
                
            elseif strcmp(data_type,'fMRI2run')
                original_path.LR = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_LR'], ...
                                    [fMRI_name '_' task '_LR' ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean.dtseries.nii']);
                original_path.RL = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_RL'], ...
                                    [fMRI_name '_' task '_RL'  ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean.dtseries.nii']);
                smooth_path.LR = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_LR' ], ...
                                    [fMRI_name '_' task '_LR' ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean' ...
                                    '_smooth_' int2str(sigma)  '.dtseries.nii']);
                smooth_path.RL = fullfile(folder_name, ...
                                    id, 'MNINonLinear', 'Results', ...
                                    [fMRI_name '_' task '_RL' ], ...
                                    [fMRI_name '_' task '_RL' ...
                                    '_Atlas_MSMAll_' hp '_clean_rclean_tclean' ...
                                    '_smooth_' int2str(sigma)  '.dtseries.nii']);

                if ~exist(smooth_path.LR, 'file') && if_smooth > 0
                    disp(['Smoothed fMRI data not exist. ' ...
                        'Performing spatial smoothing sub-' int2str(i) ' LR']);
                    system(['wb_command -cifti-smoothing ' original_path.LR ...
                        ' -fwhm ' int2str(sigma) ' ' int2str(sigma) ' COLUMN ' ...
                        smooth_path.LR ' -left-surface ' surf_L_path ...
                        ' -right-surface ' surf_R_path ]);
                end
                if ~exist(smooth_path.RL, 'file') && if_smooth > 0
                    disp(['Smoothed fMRI data not exist. ' ...
                        'Performing spatial smoothing sub-' int2str(i) ' RL']);
                    system(['wb_command -cifti-smoothing ' original_path.RL ...
                        ' -fwhm ' int2str(sigma) ' ' int2str(sigma) ' COLUMN ' ...
                        smooth_path.RL ' -left-surface ' surf_L_path ...
                        ' -right-surface ' surf_R_path ]);
                end
            end
            
            % ----- get fMRI data ----- 
            if if_smooth > 0
                data_path = smooth_path;
            else
                data_path = original_path;
            end
            [subjCft, maskCft, num_vert] = read_data(data_path, data_type, max_frame_num);
        
            % ----- subTC normalization -----
            % NOTICE: must do normalization before concatenation, otherwise LR traj
            % will be separated from RL traj.
            subjCft_LR = subjCft(maskCft, 1:max_frame_num);
            subjCft_RL = subjCft(maskCft, (max_frame_num+1):end);
            if if_normalize == 1 % standard normalization
                subjCft(maskCft, :) = [normalize(subjCft_LR, 2) normalize(subjCft_RL, 2)];
            elseif if_normalize == 2 % smooth - mean
                subjCft(maskCft, :) = [subjCft_LR - mean(subjCft_LR,2) ...
                                        subjCft_RL - mean(subjCft_RL,2)];
            elseif if_normalize == 3 % smooth / norm
                subjCft(maskCft, :) = [subjCft_LR ./ (norm(subjCft_LR,2)./size(subjCft_LR,2)) ...
                                        subjCft_RL ./ (norm(subjCft_RL,2)./size(subjCft_RL,2))];
            elseif if_normalize == 4 % detrend
                subjCft(maskCft, :) = [];
            end

            % ----- calculate group meanTC -----
            if isempty(meanTC)
                meanTC = subjCft;
            elseif strcmp(task, 'WM') && (i==32 || i==72 || i==96)
                disp(['omit sub-' int2str(i) ' when calculating mTC']);
                N_valid = N_valid - 1; % and meanTC = meanTC
            elseif strcmp(task, 'RELATIONAL') && ( ...
                (strcmp(data_type, 'fMRI2run') && (i==1 || i==7 || i==11 ...
                    || i==13 || i==14 || i==26 || i==30 || i==36 || i==41 ...
                    || i==48 || i==75 || i==76 || i==95 || i==100)) ...
                || (strcmp(data_type, 'fMRI') && strcmp(session, 'LR') && ...
                    (i==49 || i==75)) )
                disp(['omit sub-' int2str(i) ' when calculating mTC']);
                N_valid = N_valid - 1; % and meanTC = meanTC
            else
                meanTC = meanTC + subjCft;
            end
        end
        meanTC = meanTC ./ N_valid;
        
        % ----- write meanTC (or smoothed meanTC) ----- 
        if if_smooth > 0
            write_cifti_only_surface(cifti_template, meanTC(maskCft,:), meanTCSmooth_savename);
        else
            write_cifti_only_surface(cifti_template, meanTC(maskCft,:), meanTC_savename);
        end

    else
%         if if_smooth > 0
%             meanTC_cifti = cifti_read(meanTCSmooth_savename);
%         else
%             meanTC_cifti = cifti_read(meanTC_savename);
%         end
%         maskNonZero = meanTC_cifti.cdata(:,1)~=0 & meanTC_cifti.cdata(:,2)~=0;
%         num_vert = find(maskNonZero,1,'last');
%     
%         maskCft = maskNonZero(1:num_vert);
%         meanTC = meanTC_cifti.cdata(1:num_vert, :);
        if if_smooth > 0
            meanTC_path = meanTCSmooth_savename;
        else
            meanTC_path = meanTC_savename;
        end
        [meanTC, maskCft, ~] = read_data(meanTC_path, 'fMRI', max_frame_num);
    end
    
end