function vol2suf(nifti_path, cifti_template_path, out_cifti_path)
    BIGN = 300000; N_mask = 64984;
    cifti_template = ft_read_cifti(cifti_template_path);
    data_nii_file = load_nii(nifti_path);
    T = size(data_nii_file.img, 4);
    data_mat = reshape(data_nii_file.img, 91*109*91, T);
    data_mat = data_mat(BIGN:BIGN+N_mask-1,:);
    data_dtseries = zeros(size(cifti_template.dtseries,1), T);
    data_dtseries(1:N_mask, :) = data_mat;
    data_dtseries(isnan(data_dtseries)) = 0;
    cifti_template.dtseries = data_dtseries;
    cifti_template.dimord = 'pos';
    ft_write_cifti(out_cifti_path, cifti_template, 'parameter', 'dtseries');
end