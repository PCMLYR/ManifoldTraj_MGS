clear; clc;
close all;

%% Step 0 : Initiate parameters
% ---------- parameters for fMRI data reading ----------
root_path = '[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/';
session = 'LR';
% session = 'RL';
% data_type = 'fMRI';
data_type = 'fMRI2run';

% 161: abandon EMOTION last task block
task = 'MOTOR'; N_task = 6; max_frame_num = 263;
% task = 'EMOTION'; N_task = 2; max_frame_num = 161; 

cifti_template = cifti_read(fullfile(root_path, 'HCP100_task', ...
                '100307', 'MNINonLinear', 'Results', ...
                ['tfMRI_' task '_' session], ...
                ['tfMRI_' task '_' session , ...
                '_Atlas_MSMAll_hp0_clean_rclean_tclean.dtseries.nii']));

if strcmp(data_type, 'fMRI2run')
    ses_name = 'LRRL';
else
    ses_name = session;
end

N_sub = 100;
max_rest_fnum = 300;

abandon_frames = 5;
cutoff = 0;

if_normalize = 2;
if_smooth = 1;
if_ica_fix = 1;

method = 'concatenate';
% method = 'mean';

after_normalize = 2;
% after_normalize = 1;
% after_normalize = 0;

%% Step 1 : Calculate group averaged fMRI data 
disp('Read group averaged fMRI data');
datetime("now");
[avg_task, maskCft_task] = calc_meanTC(session, data_type, task, ses_name, ...
                                max_frame_num, N_sub, root_path, cifti_template, ...
                                if_normalize, if_smooth);
[avg_rest, maskCft_rest] = calc_meanTC(session, data_type, 'REST1', ses_name, ...
                                max_rest_fnum, N_sub, root_path, cifti_template, ...
                                if_normalize, if_smooth);

%% perform UMAP
close all;
reduction_dir = fullfile('result_reductions', task);
if ~exist(reduction_dir, "dir") mkdir(reduction_dir); end
reduction_path = fullfile(reduction_dir, 'reductions.mat');

if strcmp(task, 'EMOTION') 
    cluster_detail = 'very low'; n_neighbors = 40; offset = cutoff-5;
elseif strcmp(task, 'MOTOR') 
    cluster_detail = 'very low'; n_neighbors = 40; offset = cutoff-6;
end
% metric = 'correlation';
% metric = 'cosine';
metric = 'seuclidean';
% metric = 'euclidean';

% offset = 0;
recalc_reduction = 0; % for debug

if ~exist(reduction_path) || recalc_reduction == 1
    input_mTC = double(avg_task(maskCft_task, (cutoff+1):end));
    [reduction, umap, clusterIdentifiers, extras] = run_umap(input_mTC', ...
        'n_neighbors',n_neighbors,'spread',0.8,'qf_dissimilarity','true',...
        'cluster_output','graphic','NSMethod','exhaustive',...
        'cluster_method_2D','dbm','cluster_detail',cluster_detail,...
        'metric',metric,'n_components',2,'contour_percent',0.0,'min_dist',0.1);
    save(reduction_path, 'reduction', 'clusterIdentifiers', '-v7.3');
else
    load(reduction_path, 'reduction', 'clusterIdentifiers');
end

reduction = reduction - (max(reduction,[],1) + min(reduction,[],1))./2;

%% Draw trajectory and cluster
colormap_name = "rainbow";
draw_task_traj(reduction, ...
    task, data_type, session, offset, max_frame_num, 101);
draw_task_traj(reduction, ...
    task, data_type, session, 0, max_frame_num, 102);
draw_task_traj(reduction(1:max_frame_num,:), ...
    task, 'fMRI', 'LR', offset, max_frame_num, 103);
draw_task_traj(reduction((max_frame_num+1):2*max_frame_num,:), ...
    task, 'fMRI', 'RL', offset, max_frame_num, 104);
draw_cluster(reduction, clusterIdentifiers, colormap_name, 201);
draw_clu_label_block(clusterIdentifiers, ...
    task, data_type, session, offset, max_frame_num, colormap_name, 301);
% 
%% Geodesic distance to (manually specified) resting clusters
if strcmp(task, 'EMOTION')
    restClusters = [1 3]; 
elseif strcmp(task, 'MOTOR')
    restClusters = [1 4]; 
end

geoDist = calc_geodist_on_traj(reduction, clusterIdentifiers, restClusters);

% % Visualization: distance along time + embedding colored by distance
 
draw_signal_with_task_2run(geoDist, task, max_frame_num, offset, 110)
xlabel('Frame (time index)'); ylabel('Geodesic distance to rest cluster');
xlim([1 2*max_frame_num+1]);
 
fig = figure(120);
fig.Position = [1000 1000 800 800];
scatter(reduction(:,1), reduction(:,2), 25, geoDist, 'filled');
colormap(slanCM('heat'));
% colorbar('Location','south'); 
% title('UMAP embedding colored by geodesic distance to resting cluster');
xlabel('UMAP-1'); ylabel('UMAP-2');
xlim([-6 6]); ylim([-7 5.1]);

%% Divide task fMRI into blocks
if strcmp(task, 'EMOTION')
    append_head = 0;
    append_tail = 0;
elseif strcmp(task, 'MOTOR')
    append_head = 0;
    append_tail = 0;
end

% N_task = size(reduction_task, 1);
N_vert = sum(maskCft_rest,1); 

MGS_all = zeros(N_sub, N_vert, 2*N_task);
% for i = 1:3
for i = 1:N_sub
    % MGS = zeros(N_vert, N_task);

    subdir = dir(fullfile(root_path, 'HCP100_task'));
    id = subdir(i+2).name(1:6);
    disp(['Reading and dividing sub-' id ' ' int2str(i) '/' int2str(N_sub)]);
    
    %%% read presaved sub fMRI and perform Baseline Correction 
    % (corp: 3 second; TR = 0.72s);
    tic
    [subTC_rest, maskCft_rest, ...
        subTC_task, maskCft_task, ...
        taskblock_LR, taskblock_RL, N_block] = ...
            get_preread_subTC(id, session, ses_name, data_type, task, ...
                                max_rest_fnum, max_frame_num, root_path, ...
                                pwd, if_normalize, if_smooth);

    % subTC_rest = avg_rest;
    % subTC_task = avg_task;

    %%% divide tfMRI sequence into task cells 
    [meanTC_taskblock, meanTC_restblock, geoDist_block] = ...
            divide_into_sub_taskblock(task, taskblock_LR, taskblock_RL,...
                                        subTC_task, subTC_rest, geoDist, ...
                                        offset, append_head, append_tail,...
                                        max_frame_num, maskCft_task);
    
    %%% Concatenate task and rest fMRI blocks and perform normalization preprocessing
    input_taskblock = meanTC_taskblock;
    input_restblock = meanTC_restblock;
    for i_tsk = 1:N_task
        if after_normalize == 1
            input_taskblock{i_tsk} = normalize(meanTC_taskblock{i_tsk}, 2);
            input_restblock{i_tsk} = normalize(meanTC_restblock{i_tsk}, 2);
        elseif after_normalize == 2
            input_taskblock{i_tsk} = ...
                meanTC_taskblock{i_tsk} ./ vecnorm(meanTC_taskblock{i_tsk},2,2);
            input_restblock{i_tsk} = ...
                meanTC_restblock{i_tsk} ./ vecnorm(meanTC_restblock{i_tsk},2,2);
        end
    end

    % TEST
    % figure(300 + randi(100));
    % vox_ind = 23691; % vox in 64984 
    % vox_ind_afterMask = sum(maskCft_task(1:vox_ind));
    % ind_task = 3;
    % test_task_i = input_taskblock{ind_task};
    % test_rest_i = input_restblock{ind_task};
    % test_geod_i = geoDist_block{ind_task};
    % test_geod_i = 1 - exp(-test_geod_i);
    % time = 1:size(test_task_i, 2);
    % for j = 1:size(test_task_i, 3)  
    %     plot(time, test_task_i(vox_ind_afterMask, :, j), 'r-');
    %     hold on
    %     plot(time, test_rest_i(vox_ind_afterMask, :, j), 'b-');
    %     plot(time, (test_geod_i(:, j))', 'k--');
    % end
    % plot(time, mean(test_task_i(vox_ind_afterMask,:,:), 3), 'r--', 'LineWidth',2);
    % plot(time, mean(test_rest_i(vox_ind_afterMask,:,:), 3), 'b--', 'LineWidth',2);

    
    %%% Calculate MGS (Geodesic Distance-based Coactivation Metric)
    sub_MGS_dir = fullfile('result_MGS_sub', task);
    MGS_savename = fullfile(sub_MGS_dir, [id '_MGS.dtseries.nii']);

    if ~exist(MGS_savename, "file")
        if ~exist(sub_MGS_dir, "file") mkdir(sub_MGS_dir); end
        disp('MGS calculate'); 
        
        MGS = zeros(N_vert, 2*N_task);
        for i_tsk = 1:N_task
            corrs_task = []; corrs_rest = []; 
            for i_block = 1:size(input_taskblock{i_tsk},3)
                % corrs_task = [corrs_task, ...
                %         corr(input_taskblock{i_tsk}(:,:,i_block)',...
                %             geoDist_block{i_tsk}(:,i_block))];
                % corrs_rest = [corrs_rest, ...
                %         corr(input_restblock{i_tsk}(:,:,i_block)',...
                %             geoDist_block{i_tsk}(:,i_block))];
                corrs_task = [corrs_task, ...
                    input_taskblock{i_tsk}(:,:,i_block) * ...
                    weight(geoDist_block{i_tsk}(:,i_block))];
                corrs_rest = [corrs_rest, ...
                    input_restblock{i_tsk}(:,:,i_block) * ...
                    weight(geoDist_block{i_tsk}(:,i_block))];
            end
            MGS(:, i_tsk) = mean(corrs_task,2);
            MGS(:, i_tsk+N_task) = mean(corrs_rest,2);
        end
        
        write_cifti_only_surface(cifti_template, MGS, MGS_savename);
        % MGS_nii_savename = [sub_MGS_dir 'MGS_k' num2str(k) '_on' on_what '.nii'];
        % template_nifti_LR_path = ...
        %         [root_path 'HCPS100_' lower(task) '/' id '_3T_tfMRI_' ...
        %         task '_preproc/' id '/MNINonLinear/Results/' ...
        %         'tfMRI_' task '_LR' '/' 'tfMRI_' task '_LR.nii'];
        % suf2vol(MGS_savename, ...
        %         template_nifti_LR_path, ...
        %         MGS_nii_savename);
        MGS_all(i,:,:) = MGS;
    else
        disp('MGS already calculated. Read results file');

        MGS_cifti = cifti_read(MGS_savename);
        MGS = MGS_cifti.cdata(1:59412, :);
        MGS_all(i,:,:) = MGS;
    end 

    toc
end

%% MGS Group level activation map
MGS_group_dir = fullfile('result_MGS', task);
if ~exist(MGS_group_dir, 'dir') mkdir(MGS_group_dir); end
MGS_group_avg = squeeze(mean(MGS_all,1));

%%% Wilcoxon Rank-Sum Test
MGS_group_z = zeros(N_vert, N_task);
MGS_group_z_sig = zeros(N_vert, N_task);
p = zeros(N_vert, 1); z = zeros(N_vert, 1);
for i_tsk = 1:N_task
    for v = 1:N_vert
        [p(v),~,stats] = signrank(MGS_all(:,v,i_tsk), MGS_all(:,v,i_tsk+N_task), ...
            'alpha',0.05,'method','approximate', 'tail', 'both');
        % [p(v),~,stats] = signrank(MGS_all(:,v,i_tsk), zeros(N_sub,1), ...
        %     'alpha',0.05,'method','approximate', 'tail', 'both');
        z(v) = stats.zval;
    end
    [h, crit_p1, adj_ci_cvrg1, p_fdr] = fdr_bh(p,0.05,'dep','yes');
    % h = p < 0.05;
    MGS_group_z_sig(h, i_tsk) = z(h);
    MGS_group_z(:, i_tsk) = z';
end
write_cifti_only_surface(cifti_template, MGS_group_z, ...
                fullfile(MGS_group_dir, 'MGS_group_z.dtseries.nii'));
write_cifti_only_surface(cifti_template, MGS_group_z_sig, ...
                fullfile(MGS_group_dir, 'MGS_group_z_sig.dtseries.nii'));
disp(' ');

%% TEST
figure(500 + randi(100));
vox_ind = 23691; % vox in 64984 
vox_ind_afterMask = sum(maskCft_task(1:vox_ind));

time = 1:size(subTC_task, 2); 
plot(time, subTC_task(vox_ind_afterMask, :), 'r-');
hold on
plot(time, subTC_rest(vox_ind_afterMask, time), 'b-');

%% FUNCTION
function w = weight(x)
    w = 1 - exp(-x);
end
