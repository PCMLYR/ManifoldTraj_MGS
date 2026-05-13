function [subjCft, maskCft, num_vert] = read_data(subjFilePath, type, max_frame_num)
    if strcmp(type, 'fMRI')
        cifti = cifti_read(subjFilePath);
        num_vert = cifti.diminfo{1}.models{1,1}.numvert;
        [outdata_L, outmask_L] = cifti_struct_dense_extract_surface_data(cifti, 'CORTEX_LEFT');
        [outdata_R, outmask_R] = cifti_struct_dense_extract_surface_data(cifti, 'CORTEX_RIGHT');
        subjCft = [outdata_L; outdata_R];
        maskCft = [outmask_L; outmask_R];

    elseif strcmp(type, 'MRLEE')
        S = load(subjFilePath);
        subjCft = (imag(S.act_cc))';
        maskCft = abs(subjCft(:,1)) > 1e-8;
        num_vert = size(subjCft,1) / 2;

    elseif strcmp(type, 'fMRI2run')
        cifti_LR = cifti_read(subjFilePath.LR);
        num_vert = cifti_LR.diminfo{1}.models{1,1}.numvert;
        [outdata_L, outmask_L] = cifti_struct_dense_extract_surface_data(cifti_LR, 'CORTEX_LEFT');
        [outdata_R, outmask_R] = cifti_struct_dense_extract_surface_data(cifti_LR, 'CORTEX_RIGHT');
        subjCft_LR = [outdata_L; outdata_R];
        maskCft_LR = [outmask_L; outmask_R];

        cifti_RL = cifti_read(subjFilePath.RL);
        num_vert = cifti_LR.diminfo{1}.models{1,1}.numvert;
        [outdata_L, outmask_L] = cifti_struct_dense_extract_surface_data(cifti_RL, 'CORTEX_LEFT');
        [outdata_R, outmask_R] = cifti_struct_dense_extract_surface_data(cifti_RL, 'CORTEX_RIGHT');
        subjCft_RL = [outdata_L; outdata_R];
        maskCft_RL = [outmask_L; outmask_R];
        
        if exist('max_frame_num','var')
            subjCft = [subjCft_LR(:,1:max_frame_num) subjCft_RL(:,1:max_frame_num)];
        else
            subjCft = [subjCft_LR subjCft_RL];
        end
        maskCft = maskCft_LR & maskCft_RL;

    elseif strcmp(type, 'MRLEE2run')
        S_LR = load(subjFilePath.LR);
        subjCft_LR = (imag(S_LR.act_cc))';
        maskCft_LR = abs(subjCft_LR(:,1)) > 1e-8;
        num_vert = size(subjCft_LR,1) / 2;

        S_RL = load(subjFilePath.RL);
        subjCft_RL = (imag(S_RL.act_cc))';
        maskCft_RL = abs(subjCft_RL(:,1)) > 1e-8;
        num_vert = size(subjCft_RL,1) / 2;

        if exist('max_frame_num','var')
            subjCft = [subjCft_LR(:,1:max_frame_num) subjCft_RL(:,1:max_frame_num)];
        else
            subjCft = [subjCft_LR subjCft_RL];
        end
        maskCft = maskCft_LR & maskCft_RL;
    end
end