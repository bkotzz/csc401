function gmms = gmmTrain( dir_train, max_iter, epsilon, M )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixture

    speakers = dir([dir_train, filesep]);
    speakers = speakers(3:end); % Skip . and ..
    N = length(speakers);
    
    gmms = cell(1, N);
    
    for i=1:length(speakers)
        utteranceDir = [dir_train, filesep, speakers(i).name, filesep];
        utterances = dir([utteranceDir, '*.mfcc']);
        
        % Stack the line vectors for all utterances from one speaker
        data = load([utteranceDir, filesep, utterances(1).name]);
        for j=2:length(utterances)
            utterance = utterances(j).name;
            nextData = load([utteranceDir, filesep, utterance]);
            
            % data contains all mfcc data for all frames of all utterances
            % for one specific speaker
            data = [data; nextData];
        end

        % train an m-component GMM per speaker
        theta = train(data, max_iter, epsilon, M);
        
        gmms{i}.name    = speakers(i).name;
        gmms{i}.weights = theta.weights;
        gmms{i}.means   = theta.means;
        gmms{i}.cov     = theta.cov;
    end
end


function theta = train(X, max_iter, epsilon, M)
    % Input: MFCC data X - T x D
    
    X_size = size(X);
    T = X_size(1);
    D = X_size(2);
    
    % Initialize theta
    theta.weights = zeros(1, M) + 1 / M;
    
    random_init_vec = ceil(rand(1, M) * T);
    theta.means = X(random_init_vec, :).';

    theta.cov = zeros(D, D, M);
    for j=1:M
        theta.cov(:, :, j) = eye(D, D);
    end
    
    % i := 0
    i = 0;
    
    % prev L := -Inf ; improvement = -Inf
    prev_L = -Inf;
    improvement = -Inf;
    
    % while i =< MAX ITER and improvement >= epsilon do
    while i < max_iter %&& improvement >= epsilon
        disp(i)
        
    %   L := ComputeLikelihood (X, theta)
        L = computeLikelihood(X, theta, M);
        
    %   theta := UpdateParameters (theta, X, L) ; improvement := L - prev_L
        theta = updateParameters(theta, X, L, M);
        
        sum_L = sum(sum(L, 1), 2); % 1 x 1
        disp(sum_L)
        
        improvement = sum_L - prev_L;
        
    %   prev L := L
        prev_L = sum_L;
        
    %   i := i + 1 end
        i = i + 1;
    % end
    end
end

function L = computeLikelihood(X, theta, M)
    % X: T x D
    X_size = size(X);
    T = X_size(1);
    D = X_size(2);
    
    b = zeros(T, M);
    
    for m=1:M
        % Compute b per dimension
        
        mu_m = theta.means(:, m); % D x 1
        rep_mu_m = repmat(mu_m.', T, 1); % T x D
        
        cov_m = diag(theta.cov(:, :, m)); % D x 1
        rep_cov_m = repmat(cov_m.', T, 1); % T x D
        
        b_m_per_d = normpdf(X, rep_mu_m, rep_cov_m); % T x D 

        % Since we assume dimensional independence, take product across
        % all dimensions to get b.
        b_m = prod(b_m_per_d, 2); % T x 1

        b(:, m) = b_m;
    end
    
    sum_w_b = b * theta.weights.'; % T x 1
    rep_w = repmat(theta.weights, T, 1); % T x M
    rep_sum_w_b = repmat(sum_w_b, 1, M); % T x M
    
    L = rep_w .* b ./ rep_sum_w_b; % T x M
end

function theta = updateParameters(theta, X, L, M)
    % X: T x D
    % L: T x M
    
    X_size = size(X);
    T = X_size(1);
    D = X_size(2);

    % Weights
    sum_L = sum(L, 1); % 1 x M
    theta.weights = sum_L ./ T;
    
    % Means    
    rep_sum_L = repmat(sum_L, D, 1); % D x M
    sum_L_X = X.' * L; % D x M
    theta.means = sum_L_X ./ rep_sum_L;
    
    % Variance
    mu_squared = theta.means .* theta.means; % D x M
    
    X_squared = X .* X; % T x D
    sum_L_X_squared = X_squared.' * L; % D x M
    
    E_X_squared = sum_L_X_squared ./ rep_sum_L; % D x M
    var = E_X_squared - mu_squared; % D x M
    assert(0 == any(any(var < 0)))
    for m=1:M
        theta.cov(:, :, m) = diag(var(:, m));
    end
end

