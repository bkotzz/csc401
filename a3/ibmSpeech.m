test_dir = 'speechdata/Testing';
dir_save_gmm = './gmms';
num_test_points = 30;
stored_flac_files = './flac';

%gmms = gmmTrain(dir_train, max_iter, epsilon, M);
load(dir_save_gmm, 'gmms', '-mat');

% Part 1: Convert test audio files to text with Watson, and calculate 
% accuracy against reference

% Part 2: Convert the text to audio with Watson, then convert that audio to
% text with Watson, then calculate accuracy against reference

for i=1:num_test_points
    
    % Reference
    txt_file_name = [test_dir, filesep, 'unkn_', int2str(i), '.txt'];
    txt_file = textread(txt_file_name, '%s', 'delimiter', '\n');
    assert(1 == length(txt_file))
    
    reference = lower(txt_file{1});
    reference = regexprep(reference, '[^a-zA-Z0-9'' ]', '');
    reference = regexprep(reference, '-', ' ');
    ref_array = strsplit(' ', reference);
    ref_array = ref_array(3:end); % remove first two numbers
    reference = strjoin(ref_array, ' ');
    ref_length = length(ref_array);
    
    %%%% PART 1 %%%%
    
    flac_file = [test_dir, filesep, 'unkn_', int2str(i), '.flac'];

    % Transcript
    hypothesis1 = ibmSpeechToText(flac_file);
    hyp_array1 = strsplit(' ', hypothesis1); 
    
    [se, ie, de] = compute_levenshtein(hyp_array1, ref_array);
    dist1 = (se + ie + de) / ref_length;
    
    %%%% PART 2 %%%%
    
    % Load MFCC file
    mfcc_file_name = [test_dir, filesep, 'unkn_', int2str(i), '.mfcc'];
    data = load(mfcc_file_name);
    
    max_likelihood = 0;
    max_likelihood_name = '';
    
    % Using the GMMs for all speakers, find the name
    % of the speaker that is the most likely
    for j=1:num_speakers
        theta_j = gmms{j};
        
        % Compute log likelihood with data and theta
        b = calculate_b(data, theta_j, M); % T x M
        sum_w_b = b * theta.weights'; % T x 1
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
    else
        % Female
        voice = 'en-US_LisaVoice';
    end
    
    watson_flac_file = [stored_flac_files, filesep, int2str(i), '.flac'];
    ibmTextToSpeech(reference, watson_flac_file, voice);
    
    hypothesis2 = ibmSpeechToText(watson_flac_file);
    hyp_array2 = strsplit(' ', hypothesis1); 
    
    [se, ie, de] = compute_levenshtein(hyp_array2, ref_array);
    dist2 = (se + ie + de) / ref_length;
   
    disp(reference)
    disp(hypothesis1)
    disp(dist1)
    disp(hypothesis2)
    disp(dist2)
end


