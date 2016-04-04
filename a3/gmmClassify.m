dir_train = 'speechdata/Training';
dir_test  = 'speechdata/Testing';
max_iter  = 10;
epsilon   = 0.1;
M         = 8;

gmms = gmmTrain(dir_train, max_iter, epsilon, M);

test_utterances = dir([dir_test, filesep, '*.mfcc']);
num_utterances = length(test_utterances);
num_speakers = length(gmms);


for i=1:num_utterances
    utterance_name = test_utterances(i).name;
    data = load([dir_test, filesep, utterance_name]);
    
    filename = ['unkn', int2str(i), '.lik'];
    ofile = fopen('exp.txt','w');
    
    candidate_likelihood = zeros(1, 5);
    candidate_names = cell(1, 5);
    
    for j=1:num_speakers
        theta_j = gmms{j};
        
        % Compute log likelihood with data and theta
        b = calculate_b(data, theta_j, M); % T x M
        sum_w_b = b * theta.weights.'; % T x 1
        log_sum_w_b = log(sum_w_b); % T x 1
        p_x = sum(log_sum_w_b, 1); % 1 x 1
        
        [min, min_index] = min(candidate_likelihood, [], 2);
        if p_x < min
            candidate_likelihood(min_index) = p_x;
            candidate_names{min_index} = theta_j.name;
        end
        
    end
    
    fprintf(ofile, 'Utterance name: %s: \n', utterance_name);
    for k=1:5
        fprintf(ofile, '   Likelihood: %d, Name: %s\n', ...
        candidate_likelihoods(k), candidate_names{k});
    end
    
    fclose(ofile);
end

