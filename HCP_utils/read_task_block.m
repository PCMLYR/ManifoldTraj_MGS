function task_info = read_task_block(dir_path, task, max_frame_num)
    TR = 0.72;
    if strcmp(task, 'MOTOR')
        task_name = ["cue", "lf", "lh", "rf", "rh", "t"];
    elseif strcmp(task, 'EMOTION')
        task_name = ["fear", "neut"];
    elseif strcmp(task, 'LANGUAGE')
%         task_name = ["cue","math","present_math","question_math",...
%                         "story","present_story","question_story"];
        task_name = ["cue","math","story"];
%         task_name = ["cue","math","present_math","question_math"];
%         task_name = ["cue","story","present_story","question_story"];
    elseif strcmp(task, 'WM')
%         task_name = ["0bk_body", "0bk_faces", "0bk_places", "0bk_tools",...
%                     "2bk_body", "2bk_faces", "2bk_places", "2bk_tools",...
%                     "0bk_cor","0bk_err","0bk_nlr","2bk_cor","2bk_err","2bk_nlr"];
        task_name = ["0bk_body", "0bk_faces", "0bk_places", "0bk_tools",...
                    "2bk_body", "2bk_faces", "2bk_places", "2bk_tools"];
%         task_name = ["0bk_cor","0bk_err","0bk_nlr","2bk_cor","2bk_err","2bk_nlr"];
    elseif strcmp(task, 'RELATIONAL')
        task_name = ["match", "relation"];
    end
    
    if ~exist('max_frame_num','var') max_frame_num = 1; end

    task_info = struct();
    task_info.task_info_table = [];
    task_info.task_name = task_name;
    task_info.task_mask = zeros(1, max_frame_num);
    start = []; n_frame = 0;

    for i = 1:size(task_name,2)
        path = [dir_path char(task_name(i)) '.txt'];
        task_block = readcell(path);
        for line = 1:size(task_block, 1)
           task_block{line,2} = ceil((task_block{line,1}+task_block{line,2}) / TR);
           task_block{line,1} = ceil(task_block{line,1} / TR);
           task_block{line,3} = task_name(i);
           task_info.task_mask(1, task_block{line,1}:task_block{line,2}) = i;
           start = [start; task_block{line,1}];
           n_frame = max(n_frame, task_block{line,2});
        end
        task_info.task_info_table = [task_info.task_info_table; task_block];
    end
    
    [~,ind] = sort(start);
    task_info.task_info_table = task_info.task_info_table(ind,:);
    task_info.n_task = size(task_name,2);
    task_info.n_frame = n_frame;
end