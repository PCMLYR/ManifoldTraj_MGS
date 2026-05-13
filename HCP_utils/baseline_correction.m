function [fMRI_masked_LR, fMRI_masked_RL] = baseline_correction( ...
    fmri_dir, crop, TR, fMRI_masked_LR, fMRI_masked_RL, ...
    task_name, tasks)

% baseline_correction
% 输入:
%   fmri_dir       - fMRI 数据的根目录
%   crop           - baseline 选取时的范围(任务block内前几帧），不含任务间间隔
%   TR             - repetition time
%   fMRI_masked_LR - LR session 的 fMRI 数据 (voxel x time)
%   fMRI_masked_RL - RL session 的 fMRI 数据 (voxel x time)
%   task_name     - 任务名称，例如 'MOTOR' 或 'EMOTION'
%   tasks          - cell 数组，例如 {'lf','lh','rf','rh','t'}

% 定义 session
sessions = {'LR', 'RL'};

% 读取所有 task 时间信息到结构体
task_data = struct();
for s = 1:numel(sessions)
    sess = sessions{s};
    for c = 1:numel(tasks)
        task = tasks{c};
        file_path = fullfile(fmri_dir, ...
            ['tfMRI_' task_name '_' sess], 'EVs', [task '.txt']);
        
        % 每个 txt 文件是一个数值数组
        task_data.(sess).(task) = load(file_path);
    end
end

% 保存 baseline 索引
baseline_LR = {};
baseline_RL = {};

for ti = 1:length(tasks)
    task = tasks{ti};
    
    % 从结构体里取时间点数组
    LR = task_data.LR.(task);
    RL = task_data.RL.(task);
    
    % baseline: LR_task1
    idx = max(1, fix(LR(1)/TR) - 3) : ...
          min(size(fMRI_masked_LR,2), fix(LR(1)/TR) + crop);
    baseline_LR{end+1} = idx;

    % baseline: LR_task2
    idx = max(1, fix(LR(2)/TR) - 3) : ...
          min(size(fMRI_masked_LR,2), fix(LR(2)/TR) + crop);
    baseline_LR{end+1} = idx;

    % baseline: RL_task1
    idx = max(1, fix(RL(1)/TR) - 3) : ...
          min(size(fMRI_masked_RL,2), fix(RL(1)/TR) + crop);
    baseline_RL{end+1} = idx;

    % baseline: RL_task2
    idx = max(1, fix(RL(2)/TR) - 3) : ...
          min(size(fMRI_masked_RL,2), fix(RL(2)/TR) + crop);
    baseline_RL{end+1} = idx;
end

% 转为数组并去重
baseline_LR = unique([baseline_LR{:}]);
baseline_RL = unique([baseline_RL{:}]);

% baseline correction
mean_baseline_LR = mean(fMRI_masked_LR(:, baseline_LR), 2);
fMRI_masked_LR = fMRI_masked_LR - mean_baseline_LR;

mean_baseline_RL = mean(fMRI_masked_RL(:, baseline_RL), 2);
fMRI_masked_RL = fMRI_masked_RL - mean_baseline_RL;

end
