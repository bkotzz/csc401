test_dir = 'speechdata/Testing';
dir_save_gmm   = './trained_gmms';
num_test_points = 30;
stored_flac_files = './flac';
output_file_name = 'discussion.txt';
M = 8;

try
    load(dir_save_gmm, 'gmms', '-mat');
catch
    disp('Can not load')
    gmms = gmmTrain(dir_train, max_iter, epsilon, M);
    save(dir_save_gmm, 'gmms', '-mat');
end
num_speakers = length(gmms);

output_file = fopen(output_file_name, 'w');

% Part 1: Convert test audio files to text with Watson, and calculate 
% accuracy against reference

% Part 2: Convert the text to audio with Watson, then convert that audio to
% text with Watson, then calculate accuracy against reference

for i=1:num_test_points
    fprintf(output_file, 'Test Utterance: %d\n', i);
    
    % Reference
    txt_file_name = [test_dir, filesep, 'unkn_', int2str(i), '.txt'];
    txt_file = textread(txt_file_name, '%s', 'delimiter', '\n');
    assert(1 == length(txt_file))
    
    reference = lower(txt_file{1});
    reference = regexprep(reference, '[^a-zA-Z0-9 ]', '');
    reference = regexprep(reference, '-', ' ');
    ref_array = strsplit(reference, ' ');
    ref_array = ref_array(3:end); % remove first two numbers
    reference = strjoin(ref_array, ' ');
    ref_length = length(ref_array);
    
    %%%% PART 1 %%%%
    
    flac_file = [test_dir, filesep, 'unkn_', int2str(i), '.flac'];

    % Transcript
    hypothesis1 = ibmSpeechToText(flac_file);
    hypothesis1 = regexprep(hypothesis1, '''', '');
    hyp_array1 = strsplit(hypothesis1, ' '); 
    
    [se, ie, de] = compute_levenshtein(hyp_array1, ref_array);
    dist1 = (se + ie + de) / ref_length * 100;
    
    %%%% PART 2 %%%%
    
    % Load MFCC file
    mfcc_file_name = [test_dir, filesep, 'unkn_', int2str(i), '.mfcc'];
    data = load(mfcc_file_name);
    
    max_likelihood = -Inf;
    max_likelihood_name = '';
    
    % Using the GMMs for all speakers, find the name
    % of the speaker that is the most likely
    for j=1:num_speakers
        theta_j = gmms{j};
        
        % Compute log likelihood with data and theta
        b = calculate_b(data, theta_j, M); % T x M
        sum_w_b = b * theta_j.weights'; % T x 1
        log_sum_w_b = log(sum_w_b); % T x 1
        p_x = sum(log_sum_w_b, 1); % 1 x 1
        
        if p_x > max_likelihood
            max_likelihood = p_x;
            max_likelihood_name = theta_j.name;
        end
    end
    
    % Use a different voice depending on gender of likely speaker
    % Check first character of name string
    if ('M' == max_likelihood_name(1))
        % Male
        voice = 'en-US_MichaelVoice';
        gender = 'Male';
    else
        % Female
        voice = 'en-US_LisaVoice';
        gender = 'Female';
    end

    watson_flac_file = [stored_flac_files, filesep, int2str(i), '.flac'];
    ibmTextToSpeech(reference, watson_flac_file, voice);
    
    hypothesis2 = ibmSpeechToText(watson_flac_file);
    hypothesis2 = regexprep(hypothesis2, '''', '');
    hyp_array2 = strsplit(hypothesis2, ' '); 
    
    [se, ie, de] = compute_levenshtein(hyp_array2, ref_array);
    dist2 = (se + ie + de) / ref_length * 100;
   
    fprintf(output_file, 'Reference: %s\n', reference);
    fprintf(output_file, 'Part 4.1 Hypothesis: %s\n', hypothesis1);
    fprintf(output_file, 'Part 4.1 WER: %f%%\n', dist1);
    fprintf(output_file, 'Part 4.2 Hypothesis: %s\n', hypothesis2);
    fprintf(output_file, 'Part 4.2 WER: %f%% (%s)\n\n', dist2, gender);
end

fclose(output_file);

