function [bleu, histogram] = bleu_score(candidate, references, n)
% Test: bleu_score('I fear David', {'I am afraid Dave', 'I am scared Dave', 'I have fear David'}, 2)
%       Should equal 0.5067

    histogram = create_histogram(references);
    
    % Hardcoded to only use up to trigrams
    words = strsplit(' ', candidate);
    num_cand_words = length(words); % Skip SENTSTART/SENDEND

    unigram_count = 0;
    bigram_count = 0;
    trigram_count = 0;
    
    % Skip SENTSTART/SENDEND
    secondWord = words{1};
    thirdWord = words{2};
    for j=3:length(words)
        firstWord = secondWord;
        secondWord = thirdWord;
        thirdWord = words{j};
        
        if isfield(histogram, firstWord)
            unigram_count = unigram_count + 1;
            if isfield(histogram.(firstWord), secondWord)
                bigram_count = bigram_count + 1;
                if isfield(histogram.(firstWord).(secondWord), thirdWord)
                    trigram_count = trigram_count + 1;
                end
            end
        end
    end
    
    % Finish off last two unigrams and last bigram
    if isfield(histogram, secondWord)
        unigram_count = unigram_count + 1;
        if isfield(histogram.(secondWord), thirdWord)
            bigram_count = bigram_count + 1;
        end
    end
    if isfield(histogram, thirdWord)
        unigram_count = unigram_count + 1;
    end
    
    unigram_precision = unigram_count / num_cand_words;
    bigram_precision  = (n > 1) * bigram_count /  (num_cand_words - 1) + (n <= 1);
    trigram_precision = (n > 2) * trigram_count / (num_cand_words - 2) + (n <= 2);
    
    penalty = bleu_penalty(candidate, references);
    
    bleu = penalty * (unigram_precision * bigram_precision * trigram_precision).^(1 / n);
end

function pen = bleu_penalty(candidate, references)
    closest_ref = 0;
    smallest_delta = Inf;
    cand_len = length(strsplit(' ', candidate)); % Subtract START/END
    
    for j=1:length(references)
        ref_len = length(strsplit(' ', references{j})); % Subtract START/END
        if abs(ref_len - cand_len) < smallest_delta
            closest_ref = ref_len;
            smallest_delta = abs(ref_len - cand_len);
        end
    end

    brevity = max(1, closest_ref / cand_len);
    pen = exp(1 - brevity);
    assert(pen <= 1);
end

function hist = create_histogram(references)
    % Modified histogram, only counts existences of
    % uni/bi/tri-grams
    hist = struct();
    for i=1:length(references)
        reference = references{i};
        words = strsplit(' ', reference);
        
        % Skip SENTSTART/SENTEND
        secondWord = words{1};
        thirdWord = words{2};
        for j=3:length(words)
            firstWord = secondWord;
            secondWord = thirdWord;
            thirdWord = words{j};
            hist.(firstWord).(secondWord).(thirdWord) = 1;
        end
        
        % Add remaining uni- and bi-grams
        hist.(secondWord).(thirdWord) = 1;
        hist.(thirdWord) = 1;
    end
end
