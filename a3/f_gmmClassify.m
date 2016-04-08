function [accuracy] = f_gmmClassify(gmm_path, train_path, test_path, lik_path, max_iter, epsilon, M, speaker_limit)

    compute_accuracy = true;
    num_utterances = 30;

    try
        load(gmm_path, 'gmms', '-mat');
    catch
        gmms = gmmTrain(train_path, max_iter, epsilon, M);
        save(gmm_path, 'gmms', '-mat');
    end

    num_speakers = length(gmms);

    if compute_accuracy
        test_ids = textread([test_path, filesep, 'TestingIDs1-15.txt'], '%s', 'delimiter', '\n');
        num_correct = 0;
    end

    for i=1:num_utterances

        utterance_name = ['unkn_', int2str(i), '.mfcc'];
        data = load([test_path, filesep, utterance_name]);

        filename = [lik_path, filesep, 'unkn', int2str(i), '.lik'];
        if ~strcmp('none', lik_path)
            ofile = fopen(filename, 'w');
            save_lik = true;
        else
            ofile = 1;
            save_lik = false;
        end

        candidate_likelihood = zeros(1, 5) - Inf;
        candidate_names = cell(1, 5);

        for j=1:min(num_speakers, speaker_limit)
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


        [sorted_likelihoods, sorted_indices] = sort(candidate_likelihood, 'descend');

        if compute_accuracy && i <= 15
            split = strsplit(test_ids{i + 1}, ':');
            correct_speaker = split{2};
            best_guess = candidate_names{sorted_indices(1)};
            num_correct = num_correct + strcmp(correct_speaker(2:end), best_guess);
        end

        if save_lik
            fprintf(ofile, 'Utterance name: %s: \n', utterance_name);
            for k=1:5
                fprintf(ofile, '   Likelihood: %f, Name: %s\n', ...
                sorted_likelihoods(k), candidate_names{sorted_indices(k)});
            end
            fclose(ofile);
        end
    end

    accuracy = 100 * num_correct / 15;
    
    if compute_accuracy
        disp('Accuracy: ')
        disp(accuracy);
    end
end

