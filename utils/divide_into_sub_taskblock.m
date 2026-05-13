function [meanTC_taskblock, meanTC_restblock, geoDist_taskblock] = ...
    divide_into_sub_taskblock(task, taskblock_LR, taskblock_RL,...
                                subTC_task, subTC_rest, geoDist, ...
                                offset, append_head, append_tail,...
                                max_frame_num, maskCft_task)
    offset = abs(offset);
    N_task = taskblock_LR.n_task;
    N_block = size(taskblock_LR.task_info_table, 1);
    
    meanTC_taskblock = cell(N_task, 1);
    meanTC_restblock = cell(N_task, 1);
    geoDist_taskblock = cell(N_task, 1);
    

    if strcmp(task, 'EMOTION')
        N_block = N_block - 1; % abandon EMOTION last task block
    end

    for i_blk = 1:N_block
        % For HCP Motor data, taskblock_LR is not the same as taskblock_RL,
        % so LR session and RL session should be divided separately.
        ind_task_LR = find(taskblock_LR.task_name ...
                    == taskblock_LR.task_info_table{i_blk,3});
        ind_task_RL = find(taskblock_RL.task_name ...
                    == taskblock_RL.task_info_table{i_blk,3});
        head_LR = taskblock_LR.task_info_table{i_blk,1} + offset - append_head;
        tail_LR = taskblock_LR.task_info_table{i_blk,2} + offset + append_tail;
        head_RL = taskblock_RL.task_info_table{i_blk,1} + offset - append_head;
        tail_RL = taskblock_RL.task_info_table{i_blk,2} + offset + append_tail;
        
        % concatenate task LR and RL separetly to prevent RL tail out of
        % bound. But rest LR and RL is not necessary
        task_TC_LR = subTC_task(maskCft_task, head_LR:tail_LR);
        rest_TC_LR = subTC_rest(maskCft_task, head_LR:tail_LR);
        geoDist_LR = geoDist(head_LR:tail_LR);
        if tail_RL <= max_frame_num
            task_TC_RL = subTC_task(maskCft_task, ...
                        (head_RL+max_frame_num):(tail_RL+max_frame_num));
            rest_TC_RL = subTC_rest(maskCft_task, ...
                        (head_RL+max_frame_num):(tail_RL+max_frame_num));
            geoDist_RL = geoDist((head_RL+max_frame_num):(tail_RL+max_frame_num));
        else
            task_TC_RL = [subTC_task(maskCft_task, ...
                            (head_RL+max_frame_num):2*max_frame_num), ...
                          subTC_task(maskCft_task, ...
                            1:(tail_RL-max_frame_num))];
            rest_TC_RL = [subTC_rest(maskCft_task, ...
                            (head_RL+max_frame_num):2*max_frame_num), ...
                          subTC_rest(maskCft_task, ...
                            1:(tail_RL-max_frame_num))];
            geoDist_RL = [geoDist((head_RL+max_frame_num):2*max_frame_num); ...
                          geoDist(1:(tail_RL-max_frame_num))];
        end

        last_times_LR = size(meanTC_taskblock{ind_task_LR},2);
        if last_times_LR~=0 && last_times_LR < size(task_TC_LR,2)
            task_TC_LR = task_TC_LR(:, 1:last_times_LR);
            rest_TC_LR = rest_TC_LR(:, 1:last_times_LR);
            geoDist_LR = geoDist_LR(1:last_times_LR);
        end
        last_times_RL = size(meanTC_taskblock{ind_task_RL},2);
        if last_times_RL~=0 && last_times_RL < size(task_TC_RL,2)
            task_TC_RL = task_TC_RL(:, 1:last_times_RL);
            rest_TC_RL = rest_TC_RL(:, 1:last_times_RL);
            geoDist_RL = geoDist_RL(1:last_times_RL);
        end
        
        meanTC_taskblock{ind_task_LR} = ...
            cat(3, meanTC_taskblock{ind_task_LR}, task_TC_LR);
        meanTC_taskblock{ind_task_RL} = ...
            cat(3, meanTC_taskblock{ind_task_RL}, task_TC_RL);
        geoDist_taskblock{ind_task_LR} = ...
            cat(2, geoDist_taskblock{ind_task_LR}, geoDist_LR);
        geoDist_taskblock{ind_task_RL} = ...
            cat(2, geoDist_taskblock{ind_task_RL}, geoDist_RL);
        meanTC_restblock{ind_task_LR} = ...
            cat(3, meanTC_restblock{ind_task_LR}, rest_TC_LR);
        meanTC_restblock{ind_task_RL} = ...
            cat(3, meanTC_restblock{ind_task_RL}, rest_TC_RL);
    end

end