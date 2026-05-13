function write_cifti_only_surface(template_cifti, data, savename)
    new_cifti = template_cifti;
    num_vert = size(data,1); num_frame = size(data,2);
    new_cifti.cdata = zeros(size(template_cifti.cdata,1), num_frame);
    new_cifti.cdata(1:num_vert,:) = data;
    new_cifti.diminfo{1,2}.length = num_frame;
    cifti_write(new_cifti, savename);
end