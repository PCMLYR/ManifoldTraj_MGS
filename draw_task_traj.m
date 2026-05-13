function figure_id = draw_task_traj(embed_data, task, data_type, session, offset, max_frame_num, figure_id)
    if ~exist('offset', 'var') offset = 0; end
    if ~exist('figure_id', 'var') figure_id = randi(100) + 100; end
    fig = figure(figure_id);
    fig.Position = [900 900 800 800];

    if strcmp(data_type, 'fMRI')
        draw_task_traj_one_run(embed_data, task, session, offset, figure_id);
    elseif strcmp(data_type, 'fMRI2run')
        draw_task_traj_one_run(embed_data(1:max_frame_num,:), task, 'LR', offset, figure_id);
        hold on
        draw_task_traj_one_run(embed_data((max_frame_num+1):end,:), task, 'RL', offset, figure_id);
    else
        error('Wrong input: data_type');
    end
    xlabel('UMAP-1'); ylabel('UMAP-2');
    add_legend(task, figure_id);
end

function draw_task_traj_one_run(embed_data, task, session, offset, figure_id)
    figure(figure_id)
    file = load(['color_' task '_' session '.mat']);
    if strcmp(task, 'REST1')
        N_frame = size(embed_data,1);
        frame_color = repmat([0,0,0], [N_frame 1]);
    else
        frame_color = file.frame_color;
        N_frame = min(size(frame_color,1), size(embed_data,1));
    end

    if strcmp(session, "LR")
        LineStyle = '-';  % LR session
    elseif strcmp(session, "RL")
        LineStyle = '--'; % RL session
    end

    % draw lines
    for i = 1:N_frame-1
        ind = max(i+offset-1,0) + 1;
        if i == 1
            Marker = 'o';
        else
            Marker = '*';
        end
        if size(embed_data,2) == 2
            line([embed_data(i,1),embed_data(i+1,1)], ...
                 [embed_data(i,2),embed_data(i+1,2)], ...
                'color',frame_color(ind,:), 'LineStyle',LineStyle, 'Marker',Marker);
            % text(embed_data(i+1,1) + 0.1, embed_data(i+1,2), num2str(i+1), ...
            %     "FontSize",8,'color',frame_color(ind,:));
        elseif size(embed_data,2) == 3
            line([embed_data(i,1),embed_data(i+1,1)], ...
                 [embed_data(i,2),embed_data(i+1,2)], ...
                 [embed_data(i,3),embed_data(i+1,3)], ...
                'color',frame_color(ind,:), 'LineStyle',LineStyle, 'Marker',Marker);
            % text(embed_data(i+1,1) + 0.1, embed_data(i+1,2), embed_data(i+1,3), num2str(i+1), ...
            %     "FontSize",8,'color',frame_color(ind,:));
        end
        hold on;
    end
    hold on;
    xlim([-6 6]); ylim([-7 5.1]);
end

function add_legend(task, figure_id)
    figure(figure_id)
    file = load(['color_' task '_LR.mat']);
    colormap = file.colormap;
    lgd_name = file.lgd_name;
    n_task = file.n_task;
    h = [patch(NaN, NaN, colormap(1,:))]; % empty task
    for i = 2:n_task+1
        hi = patch(NaN, NaN, colormap(i,:)); % pseudo object 
        h = [h, hi];
    end
    h = [h, line(NaN, NaN, 'color',[0,0,0], 'LineStyle','-'), ...
        line(NaN, NaN, 'color',[0,0,0], 'LineStyle','--')];
    ax = axes('Visible', 'off');
    lgd = legend(ax, h, [lgd_name, "LR session", "RL session"]);
    lgd.Position = [0.1 0 0.8 0.1]; 
    lgd.Orientation = 'horizontal';
    lgd.FontName = 'Times New Roman';
    lgd.FontWeight = "bold";
    lgd.FontSize = 10;
    lgd.Interpreter = "none";
    lgd.NumColumns = fix((n_task+3)/2);
    hold off;
end
