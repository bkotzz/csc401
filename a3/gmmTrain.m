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
    N = length(speakers);
    
    gmms = cell(1, N);
    
    for i=1:length(speakers)
        gmms{i}.name = speakers(i).name;
        utteranceDir = [dir_train, filesep, speakers(i).name];
        utterances = dir(utteranceDir);
        
        % Stack the line vectors for all utterances from one speaker
        data = textread([utteranceDir, filesep, utterances(1).name], '%s', 'delimiter', '\n');
        for j=2:length(utterances)
            utterance = utterances(j).name;
            nextData = textread([utteranceDir, filesep, utterance], '%s', 'delimiter', '\n');
            data = [data; nextData];
        end

        theta = train(data, max_iter, epsilon, M);
        gmms{i}.weights = theta.weights;
        gmms{i}.means   = theta.means;
        gmms{i}.cov     = theta.cov;
    end
end


function theta = train(X, max_iter, epsilon, M)
    % Input: MFCC data X begin
    % Initialize ?
    D = length(strsplit(X{1}, ' '));
    
    theta.weights = zeros(1, M) + 1 / M;
    theta.means   = zeros(D, M);
    theta.covs    = ones(D, D, M);
    for j=1:M
        theta.covs(:, :, j) = eye(D, D);
    end
    
    % i := 0
    i = 0;
    
    % prev L := ?? ; improvement = ?
    prev_L = -Inf;
    improvement = Inf;
    
    % while i =< MAX ITER and improvement >= ? do
    while i <= max_iter && improvement >= epsilon
        
    %   L := ComputeLikelihood (X, ?)
        L = computeLikelihood(X, theta, M);
        
    %   ? := UpdateParameters (?, X, L) ; improvement := L ? prev L
        theta = updateParameters(theta, X, L, M);
        improvement = L - prev_L;
        
    %   prev L := L
        prev_L = L;
        
    %   // These two functions can be combined
    %   i := i + 1 end
        i = i + 1;
    % end
    end
end

function L = computeLikelihood(X, theta, M)
    T = length(X);
    b = zeros(M, T);
    L = zeros(M, T);
    
    for t=1:T
        x_t = str2num(X{t});
        for m=1:M
            bPerD = normpdf(x_t, theta.means(:,m), diag(theta.covs(:,:,m)));
            b(m, t) = prod(bPerD);
        end
    end
    
    sum_w_b = theta.weights * b; % 1 x T
    stacked_w = repmat(theta.weights.', 1, M);
    stacked_sum_w_b = repmat(sum_w_b, M, 1);
    
    L = stacked_w .* b ./ stacked_sum_w_b;
end

function theta = updateParameters(theta, X, L, M)
    T = length(X);
    
    theta.weights = mean(L, 1).';
    % GO back and change X to matrix by preprocessing
end

