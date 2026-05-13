clear, clc
close all

%% Initiate parameters
task = 'EMOTION'; N_task = 2;

root_path = '[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/';
subdir = dir(fullfile(root_path, 'HCP100_task'));
N_sub = size(subdir,1) - 2;

result_1st_dir = fullfile('result_GLM', task, '1st_level');

%% Run SPM12 GLM script

for i = 1:N_sub
    tic
    id = subdir(i+2).name(1:6);
    disp(['Processing sub-' id ' ' int2str(i) '/' int2str(N_sub)]);
    
    result_1st_sub_dir = fullfile(result_1st_dir, id);
    if ~exist(result_1st_sub_dir, 'dir') mkdir(result_1st_sub_dir); end
    
    % unzip .nii.gz file into .nii file
    fmri_LR_nifti_path = fullfile(root_path, 'HCP100_task', ...
                        id, 'MNINonLinear', 'Results', ['tfMRI_' task '_LR'], ...
                        ['tfMRI_' task '_LR_hp0_clean_rclean_tclean.nii']);
    fmri_LR_cifti_path = fullfile(root_path, 'HCP100_task', ...
                        id, 'MNINonLinear', 'Results', ['tfMRI_' task '_LR'], ...
                        ['tfMRI_' task ...
                        '_LR_Atlas_MSMAll_hp0_clean_rclean_tclean.dtseries.nii']);
    fmri_RL_nifti_path = fullfile(root_path, 'HCP100_task', ...
                        id, 'MNINonLinear', 'Results', ['tfMRI_' task '_RL'], ...
                        ['tfMRI_' task '_RL_hp0_clean_rclean_tclean.nii']);
    fmri_RL_cifti_path = fullfile(root_path, 'HCP100_task', ...
                        id, 'MNINonLinear', 'Results', ['tfMRI_' task '_RL'], ...
                        ['tfMRI_' task ...
                        '_RL_Atlas_MSMAll_hp0_clean_rclean_tclean.dtseries.nii']);
    
    if ~exist(fmri_LR_nifti_path, 'file')
        gunzip([fmri_LR_nifti_path '.gz']);
    end
    if ~exist(fmri_RL_nifti_path, 'file')
        gunzip([fmri_RL_nifti_path '.gz']);
    end
    
    fmri_suf2vol_LR_path = fullfile(result_1st_sub_dir, 'suf2vol_LR.nii');
    fmri_suf2vol_RL_path = fullfile(result_1st_sub_dir, 'suf2vol_RL.nii');
    suf2vol(fmri_LR_cifti_path, fmri_LR_nifti_path, fmri_suf2vol_LR_path);
    suf2vol(fmri_RL_cifti_path, fmri_RL_nifti_path, fmri_suf2vol_RL_path);
    fmri_suf2vol_all = {fmri_suf2vol_LR_path, fmri_suf2vol_RL_path};

    % SPM12 GLM stats
    if ~exist(fullfile(result_1st_sub_dir, 'SPM.mat'), 'file')
        matlabbatch = GLM_1st_level(result_1st_sub_dir, fmri_suf2vol_all);
        spm_jobman('run', matlabbatch)
    end

    % convert volume results into surface file
    prefix = 'con'; 
    for t = 1:N_task
        GLM_nifti_path = fullfile(result_1st_sub_dir, [prefix '_000' char(num2str(t)) '.nii']);
        GLM_cifti_path = fullfile(result_1st_sub_dir, [prefix '_000' char(num2str(t))]); 
        % ft_write_cifti function will automatically add '.dscalar.nii' postfix

        vol2suf(GLM_nifti_path, fmri_LR_cifti_path, GLM_cifti_path);
    end
    toc
end

%%
function matlabbatch = GLM_1st_level(tagetpath, f_fmri_total)

    matlabbatch{1}.spm.stats.fmri_spec.dir = {tagetpath};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 0.72;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = {f_fmri_total{1}};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).name = 'neut';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).onset = [10.995
                                                                53.138];
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).duration = 18;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(1).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).name = 'fear';
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).onset = [32.067
                                                                74.21];
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).duration = 18;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond(2).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = {f_fmri_total{2}};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).name = 'neut';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).onset = [10.996
                                                                53.219];
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).duration = 18;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(1).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).name = 'fear';
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).onset = [32.094
                                                                74.291];
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).duration = 18;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond(2).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0;
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Emotion_Face';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 0.5 0 0.5];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;

    matlabbatch{3}.spm.stats.con.spmmat(2) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Emotion_Shape';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0.5 0 0.5 0];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
end