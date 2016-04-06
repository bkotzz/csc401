dir_train   = 'speechdata/Training';
M           = 8;
Q           = 3;
initType    = 'kmeans';
max_iter    = 3;
output_file = './hmm';
bnt_path    = './bnt';

% 1. Load phoneme data

speakers = dir([dir_train, filesep]);
speakers = speakers(3:end); % Skip . and ..
N_speakers = length(speakers);

phoneme_struct = struct();

% For each speaker
for i=1:N_speakers
    speaker = speakers(i).name;
    speaker_dir = [dir_train, filesep, speaker];
    
    utterances = dir([speaker_dir, filesep, '*.mfcc']);
    N_utterances = length(utterances);
    
    % For each utterance
    for j=1:N_utterances
        mfcc_file = utterances(j).name;
        split = strsplit(mfcc_file, '.');
        split{2} = 'phn';
        phn_file = strjoin(split, '.');

        % Load mfcc data
        mfcc_data = load([speaker_dir, filesep, mfcc_file]);
        mfcc_rows = size(mfcc_data, 1);

        % Read phoneme data for this speaker's utterance
        phoneme_transcription = textread([speaker_dir, filesep, phn_file], '%s', 'delimiter', '\n');
        N_phonemes = length(phoneme_transcription);
        
        % For each phoneme in utterance
        for k=1:N_phonemes
            phoneme_data  = strsplit(phoneme_transcription{k}, ' ');
            
            % Manipulate indices such that
            % 0   - 256 maps to [1, 2]
            % 256 - 512 maps to [3, 4]
            phoneme_start = str2num(phoneme_data{1});
            phoneme_start = (phoneme_start / 128) + 1;
            phoneme_end   = str2num(phoneme_data{2});
            phoneme_end   = min(phoneme_end / 128, mfcc_rows);
            
            phoneme       = phoneme_data{3};
            if strcmp(phoneme, 'h#')
                phoneme = 'sil';
            end
            
            mfcc_slice = mfcc_data(phoneme_start:phoneme_end, :);
            
            % If we haven't seen this phoneme yet, create an empty
            % cell array
            if ~isfield(phoneme_struct, phoneme)
                phoneme_struct.(phoneme) = cell(0);
            end
            
            % Take the relevant mfcc slice, and append to cell array for
            % this phoneme
            num_phn_sequences = length(phoneme_struct.(phoneme));
            phoneme_struct.(phoneme){num_phn_sequences + 1} = mfcc_slice';
        end
    end
end

addpath(genpath(bnt_path));

% Init and train an HMM for each of the unique phonemes seen
phonemes_seen = fields(phoneme_struct);
num_phonemes_seen = length(phonemes_seen);
for i_phn=1:num_phonemes_seen
    curr_phn_name = phonemes_seen{i_phn};
    data = phoneme_struct.(curr_phn_name);
    
    HMM = initHMM(data, M, Q, initType);
    [HMM, LL] = trainHMM(HMM, data, max_iter);
    
    save([output_file, filesep, curr_phn_name], 'HMM', '-mat');
end

rmpath(genpath(bnt_path));
