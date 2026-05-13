clear; clc;
close all;
%%
root_path = '[YOUR_HCP_ROOT]/HCP_100_unrelated_2025/';

task = 'MOTOR'; 
% task = 'LANGUAGE';
% task = 'WM';
% task = 'EMOTION'; 
% task = 'RELATIONAL';

subdir = dir([root_path 'HCP100_task/']);
session = 'LR';
% session = 'RL'; 

N = 1;
max_frame_num = 1; % just set 1 is ok
maxn = 0; minn = 10000;

%% Plot
% draw task color band
fig1 = figure(1);
fig1.Position = [1600 1600 1200 100];
task_info_Cell = cell(N,1);
for i = 1:N
    id = subdir(i+2).name(1:6);
    dir_path = [root_path 'HCP100_task/' id '/MNINonLinear/Results/tfMRI_' ...
                task '_' session '/EVs/'];
    task_info = read_task_block(dir_path, task, max_frame_num);
    if strcmp(task, 'EMOTION')
        task_info.task_name = ["face","shape"];
    end
    maxn = max(maxn, task_info.n_frame);
    minn = min(maxn, task_info.n_frame);
    task_info_Cell{i} = task_info;
end
disp(maxn); disp(minn);

colormap = [[0,0,0]; slanCM("rainbow-kov", task_info.n_task)]; % non emotion
% colormap = [[0,0,0]; flip(slanCM("rainbow-kov", task_info.n_task),1)]; % emotion

figure_id = draw_task_block(task_info_Cell, colormap);

%% save mask and colormap

frame_task = task_info.task_mask'+1;
frame_color = colormap(frame_task,:);
lgd_name = ["(empty)", task_info.task_name];
n_task = task_info.n_task;
save(['color_' task '_' session '.mat'] ,"frame_color","frame_task","lgd_name","colormap","n_task");
saveas(1, ['color_' task '_' session '.jpg']);

%% FUCTION
function figure_id = draw_task_block(task_info_Cell, cmp, figure_id)
    if ~exist('figure_id', 'var') figure_id = randi(100) + 400; end


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
    lgd.Position = [0.1 0.1 0.8 0.1]; 
    lgd.Orientation = 'horizontal';
    lgd.FontName = 'Times New Roman';
    lgd.FontWeight = "bold";
    lgd.FontSize = 12;
    lgd.Interpreter = "none";
    hold off;
end