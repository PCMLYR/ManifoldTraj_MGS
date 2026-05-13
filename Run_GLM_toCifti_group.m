clear, clc
close all

%% Initiate parameters
% task = 'EMOTION'; N_task = 2; task_names = {'fear', 'neut'};
task = 'MOTOR'; N_task = 5; task_names = {'t','lh','rh','lf','rf'};

root_path = '[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/';
subdir = dir(fullfile(root_path, 'HCP100_task'));
N_sub = size(subdir,1) - 2;

result_1st_dir = fullfile('result_GLM', task, '1st_level');
result_2nd_dir = fullfile('result_GLM', task, '2nd_level');

%% Run SPM12 GLM script
for i_tsk = 1:N_task
    folders = dir(result_1st_dir);
    
    % build con_000*.nii paths
    con_all = cell(N_sub, 1);
    for i_sub = 1:N_sub
        con_task_path = fullfile(folders(i_sub+2).folder, ...
                                folders(i_sub+2).name, ...
                                ['con_000' char(num2str(i_tsk))]);
        con_all{i_sub} = [con_task_path '.nii'];
    end
    savedir_task = fullfile(result_2nd_dir, ['000' char(num2str(i_tsk))]);

    % SPM12 GLM stats
    if ~exist(fullfile(savedir_task, 'SPM.mat'), 'file')
        matlabbatch = GLM_2nd_level(savedir_task, con_all);
        spm_jobman('run', matlabbatch)
    end
end

%% NOTICE

%%% ==== Run SPM12:Results manually to check results and generate 
%%% ==== con_000*.nii and spmT_000*.nii file

% Fill below t_threshold array manually according to the graphic SPM
% results
% t_threshold = [2.202 2.268];
% t_threshold = [2.234 2.402 2.308 2.240 2.283];

t_threshold = ones(100,1)*5.09336;

%% convert SPM12 result to cifti file
prefix = 'spmT';

for i_tsk = 1:N_task
    if ~exist(fullfile(result_2nd_dir, prefix), "dir")
        mkdir(fullfile(result_2nd_dir, prefix));
    end
    savedir_task = fullfile(result_2nd_dir, ['000' char(num2str(i_tsk))]);
    template_cifti_path = fullfile(root_path, 'HCP100_task', ...
                        '100307', 'MNINonLinear', 'Results', ['tfMRI_' task '_LR'], ...
                        ['tfMRI_' task ...
                        '_LR_Atlas_MSMAll_hp0_clean_rclean_tclean.dtseries.nii']);
    % used as cifti template

    GLM_group_path = fullfile(result_2nd_dir, prefix, ...
                                ['GLM_group_' task_names{i_tsk}]);
    
    vol2suf(fullfile(savedir_task, [prefix '_0001.nii']), ...
            template_cifti_path, ...
            GLM_group_path);

    GLM_group_cifti = cifti_read([GLM_group_path '.dscalar.nii']);
    cdata = GLM_group_cifti.cdata;
    t = t_threshold(i_tsk);
    cdata(cdata<t & cdata>-t) = nan; % 2.234 2.402 
%     cdata(cdata>-5.0933) = 0;
%     c_data_all = [c_data_all cdata];
    GLM_group_cifti.cdata = cdata;
    cifti_write(GLM_group_cifti, [GLM_group_path '.dscalar.nii']);
end

% merge t map
GLM_group_all_path = fullfile(result_2nd_dir, prefix, 'GLM_group_all.dscalar.nii');
command = ['wb_command -cifti-merge ' GLM_group_all_path];
for i_tsk = 1:N_task
    GLM_group_task_path = fullfile(result_2nd_dir, prefix, ['/GLM_group_' ...
                            task_names{i_tsk} '.dscalar.nii']);
    command = [command ' -cifti ' GLM_group_task_path];
end
system(command);

%%
% average beta map
if ~exist(fullfile(result_2nd_dir, 'beta'), "dir")
    mkdir(fullfile(result_2nd_dir, 'beta'));
end
for i_tsk = 1:N_task
    folders = dir(result_1st_dir);
    GLM_group_beta_task_path = fullfile(result_2nd_dir, 'beta', ...
                        ['GLM_group_beta_' task_names{i_tsk} '.dscalar.nii']);
    command = ['wb_command -cifti-average ' GLM_group_beta_task_path];
   
    for i_sub = 1:N_sub
        % convert to cifti for visulazation
        con_task_path = fullfile(folders(i_sub+2).folder, ...
                                folders(i_sub+2).name, ...
                                ['con_000' char(num2str(i_tsk))]);
        command = [command ' -cifti ' con_task_path '.dscalar.nii'];
    end
    system(command);
end

% merge bata map
GLM_group_all_path = fullfile(result_2nd_dir, 'beta', ...
                                'GLM_group_beta_all.dscalar.nii');
command = ['wb_command -cifti-merge ' GLM_group_all_path];
for i_tsk = 1:N_task
    GLM_group_task_path = fullfile(result_2nd_dir, 'beta', ...
                        ['GLM_group_beta_' task_names{i_tsk} '.dscalar.nii']);
    command = [command ' -cifti ' GLM_group_task_path];
end
system(command);

%%
function matlabbatch = GLM_2nd_level(tagetpath, con_all)
    matlabbatch{1}.spm.stats.factorial_design.dir = {tagetpath};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = con_all;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    matlabbatch{2}.spm.stats.fmri_est.spmmat = {fullfile(tagetpath, 'SPM.mat')};
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
end