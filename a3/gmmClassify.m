dir_train      = 'speechdata/Training';
dir_test       = 'speechdata/Testing';
dir_save_gmm   = './trained_gmms';
lik_dir        = './lik';
max_iter       = 150;
epsilon        = 0.5;
M              = 8;
num_utterances = 30;

compute_accuracy = true;

try
    load(dir_save_gmm, 'gmms', '-mat');
catch
    gmms = gmmTrain(dir_train, max_iter, epsilon, M);
    save(dir_save_gmm, 'gmms', '-mat');
end

num_speakers = length(gmms);

if compute_accuracy
    test_ids = textread([dir_test, filesep, 'TestingIDs1-15.txt'], '%s', 'delimiter', '\n');
    num_correct = 0;
end

for i=1:num_utterances
    disp(i)
    
    utterance_name = ['unkn_', int2str(i), '.mfcc'];
    data = load([dir_test, filesep, utterance_name]);
    
    filename = [lik_dir, filesep, 'unkn', int2str(i), '.lik'];
    ofile = fopen(filename, 'w');
    
    candidate_likelihood = zeros(1, 5) - Inf;
    candidate_names = cell(1, 5);
    
    for j=1:num_speakers
        theta_j = gmms{j};
        
        % Compute log likelihood with data and theta
        b = calculate_b(data, theta_j, M); % T x M
        sum_w_b = b * theta_j.weights'; % T x 1
        log_sum_w_b = log(sum_w_b); % T x 1
        p_x = sum(log_sum_w_b, 1); % 1 x 1
        
        % Take the worst score in our top 5, and if the current is better
        % than the worst score, then replace it with the current.
        [min_val, min_index] = min(candidate_likelihood, [], 2);
        if p_x > min_val
            candidate_likelihood(min_index) = p_x;
            candidate_names{min_index} = theta_j.name;
        end
        
    end
    
    fprintf(ofile, 'Utterance name: %s: \n', utterance_name);
    
    [sorted_likelihoods, sorted_indices] = sort(candidate_likelihood, 'descend');
    for k=1:5
        fprintf(ofile, '   Likelihood: %f, Name: %s\n', ...
        sorted_likelihoods(k), candidate_names{sorted_indices(k)});
    end
    
    if compute_accuracy && i <= 15
        split = strsplit(test_ids{i + 1}, ':');
        correct_speaker = split{2};
        best_guess = candidate_names{sorted_indices(1)};
        num_correct = num_correct + strcmp(correct_speaker(2:end), best_guess);
    end
    
    fclose(ofile);
end

if compute_accuracy
    disp('Accuracy: ')
    disp(100 * num_correct / 15);
end

