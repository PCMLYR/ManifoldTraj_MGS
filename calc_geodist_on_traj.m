function geoDist = calc_geodist_on_traj(reduction, clusterIdentifiers, restClusters)
    % (1) restMask
    N_vert = size(reduction, 1);
    restMask = ismember(clusterIdentifiers, restClusters);
    
    % (2) Edge weights: segment lengths along trajectory
    dX = diff(reduction, 1, 1);                        % (N-1) x d
    segLen = sqrt(sum(dX.^2, 2));              % (N-1) x 1, ell_t = ||x_{t+1}-x_t||
    
    % (3) Multi-source shortest path on a chain (two-pass DP)
    %     Initialize d(t)=0 for rest points, inf otherwise
    geoDist = inf(N_vert, 1);
    geoDist(restMask) = 0;
    
    % Forward pass: allow paths from left to right
    for t = 2:N_vert
        geoDist(t) = min(geoDist(t), geoDist(t-1) + segLen(t-1));
    end
    % Backward pass: allow paths from right to left
    for t = (N_vert-1):-1:1
        geoDist(t) = min(geoDist(t), geoDist(t+1) + segLen(t));
    end
    
    % (3a) Optional: normalize distance (useful for weights)
    % geoDist_norm = geoDist / max(geoDist);
    
    % (3b) Optional: get the nearest rest index along the chain (for debugging)
    %     e = argmin |arcLen(t)-arcLen(r)| 
    % arcLen = [0; cumsum(segLen)];  % s_t, N x 1
    % restIdx = find(restMask);
    % arcRest = arcLen(restIdx);
    
    % nearest rest by arc-length (not by Euclidean embedding)
    % For each t, find nearest rest arc-length position
    % This is O(N*|R|) if written naively; use knnsearch for speed.
    % nearestRestPos = knnsearch(arcRest, arcLen);   % returns index into restIdx
    % nearestRestIdx = restIdx(nearestRestPos);      % actual frame index

end