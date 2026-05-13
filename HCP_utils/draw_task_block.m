function figure_id = draw_task_block(task_info_Cell, figure_id, colormap)
    if ~exist('figure_id', 'var') figure_id = randi(100) + 400; end
    if ~exist('colormap', 'var') colormap = "rainbow-kov"; end
    
    cmp = [[1,1,1]; slanCM(colormap, task_info_Cell{1}.n_task)];

    N = size(task_info_Cell, 1);
    for i = 1:N
        task_info = task_info_Cell{i};    
        subplot(N,1,i);
        imagesc(task_info.task_mask);
        set(gca, "YTick", [], 'YTickLabel', []);
        set(gca, 'FontName', 'Times New Roman', 'FontSize', 8);
        set(gca,"Colormap",cmp);
        ylabel(['sub-' num2str(i)], "Rotation",0, 'HorizontalAlignment','right', ...
            'FontName', 'Times New Roman', 'FontSize', 12)
    end 
    
    % draw legend
    hold on;
    h = [patch(NaN, NaN, cmp(1,:))]; % empty task
    for i = 2:task_info.n_task+1
        hi = patch(NaN, NaN, cmp(i,:)); % pseudo object 
        h = [h, hi];
    end
    ax = axes('Visible', 'off');
    lgd_name = ["(empty)", task_info.task_name];
    lgd = legend(ax, h, lgd_name);
    lgd.Position = [0.1 0 0.8 0.1]; 
    lgd.Orientation = 'horizontal';
    lgd.FontName = 'Times New Roman';
    lgd.FontWeight = "bold";
    lgd.FontSize = 12;
    lgd.Interpreter = "none";
    hold off;
end