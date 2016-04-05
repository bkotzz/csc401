dir_test    = 'speechdata/Testing';
dir_hmm     = 'hmm';
bnt_path    = './bnt';

utterances = dir([dir_test, filesep, '*.phn']);
N_utterances = length(utterances);

correct_classifications = 0;
total_classifications   = 0;

addpath(genpath(bnt_path));

%for each unkn_*phn,
for i=1:N_utterances
    phn_file = utterances(i).name;
    
    split = strsplit('.', phn_file);
    split{2} = 'mfcc';
    mfcc_file = strjoin(split, '.');
    
    % Load mfcc data
    mfcc_data = load([dir_test, filesep, mfcc_file]);
    mfcc_rows = size(mfcc_data, 1);
    
    % Read phoneme data for this speaker's utterance
    phoneme_transcription = textread([dir_test, filesep, phn_file], '%s', 'delimiter', '\n');
    N_phonemes = length(phoneme_transcription);
    
    total_classifications = total_classifications + N_phonemes;
    
    % For each phoneme in unknown speaker's utterance
    for j=1:N_phonemes
        phoneme_data  = strsplit(' ', phoneme_transcription{j});

        % Manipulate indices such that
        % 0   - 256 maps to [1, 2]
        % 256 - 512 maps to [3, 4]
        phoneme_start = str2num(phoneme_data{1});
        phoneme_start = (phoneme_start / 128) + 1;
        phoneme_end   = str2num(phoneme_data{2});
        phoneme_end   = min(phoneme_end / 128, mfcc_rows);
        phoneme       = phoneme_data{3};
        
        mfcc_slice = mfcc_data(phoneme_start:phoneme_end, :);

%       calculate log probability of MFCC in each trained HMM

        trained_hmms = dir([dir_hmm, filesep]);
        trained_hmms = trained_hmms(3:end); % Skip . and ..
        N_hmms = length(trained_hmms);
        
        highest_log_prob = -Inf;
        most_probable_phn = '';
        
        for k=1:N_hmms
            curr_hmm_name = trained_hmms(k).name;
            load([dir_hmm, filesep, curr_hmm_name], 'HMM', '-mat');
            
            data = mfcc_slice';
            curr_log_prob = loglikHMM(HMM, data);
            
            if curr_log_prob > highest_log_prob
                highest_log_prob  = curr_log_prob;
                most_probable_phn = curr_hmm_name;
            end
        end
        
%       if the HMM for the phoneme PHN gives the highest probability,
%       this is a correct classification, otherwise it's wrong.
        if strcmp(phoneme, most_probable_phn)
            correct_classifications = correct_classifications + 1;
        end
    end
end

% Report on the proportion of correct classifications,
% divided by the total number of all phones in all *phn files in Testing/
percent_correct = correct_classifications / total_classifications;
disp(percent_correct)

