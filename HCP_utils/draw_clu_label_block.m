function figure_id = draw_clu_label_block(clusterIdentifiers, task, data_type, session, offset, max_frame_num, colormap, figure_id)
    if ~exist( 'figure_id', 'var') figure_id = randi(100) + 300; end
    if ~exist('colormap', 'var') colormap = "rainbow-kov"; end

    N_cluster = max(clusterIdentifiers);
    cmp = [[0,0,0]; slanCM(colormap, N_cluster)];
    clusterIdentifiers = clusterIdentifiers + 1;
    num_session = size(clusterIdentifiers,2) / max_frame_num;

    if data_type == "fMRI2run"
        sess = ["LR","RL"];
    else
        sess = [session];
    end
    
    figure(figure_id);
    for i = 1:num_session
        % draw cluster block
        ax1 = subplot(num_session*2, 1, i);
        imagesc( clusterIdentifiers((1+(i-1)*max_frame_num):i*max_frame_num) );
        set(gca, "YTick", [], 'YTickLabel', []);
        set(gca,"Colormap",cmp);
        ylabel(['Cluster - ' sess(i)], "Rotation",0, 'HorizontalAlignment','right', ...
            'FontName', 'Times New Roman', 'FontSize', 8)
        
        % draw task label block
        ax2 = subplot(num_session*2, 1, i+num_session);
        file = load(['color_' task '_' char(sess(i)) '.mat']);
        task_label = [ones(-offset,1); file.frame_task];
        imagesc(task_label(1:max_frame_num)');
        set(gca, "YTick", [], 'YTickLabel', []);
        set(gca,"Colormap", file.colormap);
        ylabel(['Task Label - ' sess(i)], "Rotation",0, 'HorizontalAlignment','right', ...
            'FontName', 'Times New Roman', 'FontSize', 8)
    end

    % draw cluster legend
    hold on;
    h1 = [patch(NaN, NaN, [0,0,0])]; 
    lgd_name1 = ["(no cluster)"];
    for c = 1:N_cluster
        h1 = [h1, patch(NaN, NaN, cmp(c+1,:))]; % pseudal object 
        lgd_name1 = [lgd_name1 string(['cluster' int2str(c)])];
    end
%     ax1 = axes('Visible', 'off');
    lgd1 = legend(ax1, h1, lgd_name1);
%     lgd1 = legend(h1, lgd_name1);
    lgd1.Position = [0.1 0.5 0.8 0.1]; 
    lgd1.Orientation = 'horizontal';
    lgd1.FontName = 'Times New Roman';
    lgd1.FontWeight = "bold";
    lgd1.FontSize = 12;
    lgd1.Interpreter = "none";
    lgd1.NumColumns = fix((N_cluster+1)/2);
    hold off;

    % draw task label legend
%     hold on; 
    N_task = size(file.lgd_name, 2);
    h2 = [];
    lgd_name2 = file.lgd_name;
    for c = 1:N_task
        h2 = [h2, patch(NaN, NaN, file.colormap(c,:))]; % pseudal object 
    end
%     ax2 = axes('position',[0.1 0 0.8 0.1],'visible','on');
    lgd2 = legend(ax2, h2, lgd_name2);
%     lgd2 = legend(h2, lgd_name2);
    lgd2.Position = [0.1 0 0.8 0.1]; 
    lgd2.Orientation = 'horizontal';
    lgd2.FontName = 'Times New Roman';
    lgd2.FontWeight = "bold";
    lgd2.FontSize = 12;
    lgd2.Interpreter = "none";
    lgd2.NumColumns = fix((N_task+1)/2);
    hold off;
end