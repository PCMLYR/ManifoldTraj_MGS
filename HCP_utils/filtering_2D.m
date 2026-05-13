function filtered_X = filtering_2D(X, TR, L, low_pass_f, high_pass_f)
    % Input:
    % 	X            -   2D data matrix - [dim, L]
    % 	TR           -   Sample period, E.g., TRTR - float
    %   L            -   Sample points - int
    %   low_pass_f   -   low pass filtering frequency - float
    %   high_pass_f  -   high pass filtering frequency - float
    % Output:
    %	filtered_X   -   The data after filtering - [dim, L]

    dim = size(X,1);
    
    frequency = 1/TR * (0:L-1)/L;
    idx_left = find(frequency >= low_pass_f & ...
                    frequency <= high_pass_f & ...
                    frequency <= 0.5/TR & ...
                    frequency > 0);
    idx_right = L+2 - idx_left;
    idx = [1 idx_left idx_right];

    Y = fft(X, [], 2);
    
    filtered_Y = complex(zeros(dim,L), zeros(dim,L));
    filtered_Y(:,idx) = Y(:,idx);

    filtered_X = ifft(filtered_Y, [], 2);
    filtered_X = real(filtered_X);

    % normalization
%     filtered_X = filtered_X - repmat(mean(filtered_X,4), [1 1 1 size(filtered_X,4)]);
%     filtered_X = filtered_X ./ repmat(std(filtered_X,0,4), [1 1 1 size(filtered_X,4)]);

end