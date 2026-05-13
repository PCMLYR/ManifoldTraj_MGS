function [D, embed_coord] = mTC_isomap(varargin) 
% Dimension reduction function using ISOMAP for mTC(mean Time Course) matrices.
% Support two modes: calculate or read existing result
%
% Input: (calculate mode) - mTC_isomap(dFC, par, 'calc')
%           mTC -- [N,T] double -- mean Time Course
%           par -- struct        -- parameters
%             par.epsilon
%             par.n_frame
%             par.delete_DistanceMatrix -- 1 for debug
%             par.dist_type
%             par.n_dim
%             par.options.display
%             par.options.overlay
%             par.save_embedding_coord
%        (read mode)      - mTC_isomap(path_embedding_coord, 'read')
%             path_embedding_coord -- string -- file path of saved low dimensional coordinate embedding result 
% Onput: [D, embed_coord]
%           D           -- [T,T] double         -- distance between each FC time point
%           embed_coord -- [par.n_dim,T] double -- dFC coordinates in low dim space embedded by Isomap
    
    if nargin == 3 && (strcmp(varargin{3}, 'calc') || varargin{3} == 1)
    % mode 1: Calculate mode
        
        mTC = varargin{1};
        par = varargin{2};
        if par.add_identity == 1
            mTC = [zeros(size(mTC,1),1) mTC];
        elseif par.add_identity == 2
            mTC = [mean(mTC,2) mTC];
        end
        % -------- step 1 : read fMRI mTC sequence -------- 
        N = size(mTC,1);
        T = size(mTC,2);
        
        % -------- step 2 : calculate distance matrix --------
        if par.delete_DistanceMatrix ~= 0
            delete('D.mat') 
        end
        if ~exist('D.mat','file')
            if par.dist_type == 'S'
                mTC = (mTC - mean(mTC,1)) ./ std(mTC,0,1); %
                D = mTC'*mTC / (N-1);
%                 D = acos(mTC'*mTC/ (N-1));
            elseif par.dist_type == 'E'
                XY = mTC'*mTC; % TN * NT
                X2 = repmat(diag(XY), 1, T);
                D = sqrt(X2' + X2 - 2.*XY);
            end
            save('D.mat', 'D');
        else
            load('D.mat')
        end    

        % -------- step 3 : Isomap dimension reduction -------- 
        n_fcn = 'k';
        n_size = par.k;
        par.options.dims = 1:par.n_dim;
        [Y1, ~, ~] = Isomap(D, n_fcn, n_size, par.options);
        embed_coord = (Y1.coords{par.n_dim})';

        if par.add_identity == 1 || par.add_identity == 2
            embed_coord = embed_coord - ones(size(embed_coord,1),1) * embed_coord(1,:);
        end

    elseif nargin == 2 && (strcmp(varargin{3}, 'read') || varargin{2} == 0)
    % mode 2: Read mode

        path_embedding_coord = varargin{1};
        s = load(path_embedding_coord);
        embed_coord = s.embed_coord;
        D = None;
    else
        error('mTC_isomap: Invalid Input args')
    end
end