function suf2vol(cifti_path, nifti_template_path, out_nifti_path)
    BIGN = 300000; N_mask = 64984;
    nifti_template = load_nii(nifti_template_path);
    data_cifti_file = ft_read_cifti(cifti_path);
    data_dtseries = data_cifti_file.dtseries;
    T = size(data_dtseries, 2);
    data_mat = zeros(91*109*91, T);
    data_mat(BIGN:BIGN+N_mask-1,:) = data_dtseries(1:N_mask,:);
    data_mat = reshape(data_mat, 91,109,91,T);
    nifti_template.img = data_mat;
    save_nii(nifti_template, out_nifti_path);
end