function draw_signal_with_task(signal, task, session, x_start, offset, figure_id)
    if ~exist('figure_id', 'var') figure_id = randi(100) + 1000; end
    fig = figure(figure_id);
    fig.Position = [700 700 1500 500];
    
    patch_up = max(signal); patch_bottom = min(signal);
    FaceAlpha = 0.4;
    len_signal = size(signal,1);

    task_info_file = load(['color_' task '_' session '.mat']);
    frame_task_labels = task_info_file.frame_task;
    T = min(size(signal,1), size(frame_task_labels,1));
    frame_task_labels = frame_task_labels(1:T);

    change_points = find(diff(frame_task_labels) ~= 0);
    seg_task_label = frame_task_labels([1; change_points+1]);
    seg_starts = [1; change_points + 1]; 
    seg_ends   = [change_points; length(frame_task_labels)];
    
    hold on
    % plot segments during task
    plot_color_patch = []; plot_seg = [];
    for i_seg = 1:size(seg_task_label,1)
        if seg_task_label(i_seg) == 1
            continue;
        else
            head = min(seg_starts(i_seg)-offset, len_signal); 
            tail = min(seg_ends(i_seg)-offset, len_signal);
            color = task_info_file.colormap(seg_task_label(i_seg),:);
            plot_color_patch = [plot_color_patch ...
                patch([head tail tail head]+x_start, ...
                        [patch_bottom patch_bottom patch_up patch_up], ...
                        color, 'FaceAlpha', FaceAlpha, 'EdgeColor', 'none')];
            plot_seg = [plot_seg ...
                plot((head:tail)+x_start, signal(head:tail), ...
                        'Color',color, 'LineWidth',2);];
        end
    end
end