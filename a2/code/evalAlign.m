function evalAlign()
    %
    % evalAlign
    %
    %  This is simply the script (not the function) that you use to perform your evaluations in 
    %  Task 5. 

    % some of your definitions
    trainDir     = '../data/Hansard/Training';
    testDir      = '../data/Hansard/Testing';
    fn_LME       = '../data/Hansard/lm_e_hansard';
    fn_LMF       = '../data/Hansard/lm_f_hansard';
    fn_AMFE      = '../data/Hansard/am_hansard_1k';
    fn_testF     = '../data/Hansard/Testing/Task5.f';
    fn_testgE    = '../data/Hansard/Testing/Task5.google.e';
    fn_testE     = '../data/Hansard/Testing/Task5.e';
    lm_type      = '';
    delta        = 0;
    vocabSize    = 20; 
    numSentences = 1000;
    maxIter      = 10;

    % Bluemix credentials
    username = '"2ece4403-60be-49d6-963d-6bb104400af0"';
    password = '"gx9cb8kXuexn"';
    url = '"https://gateway.watsonplatform.net/language-translation/api/v2/translate"';

    % Train your language models. This is task 2 which makes use of task 1
    %LME = lm_train( trainDir, 'e', fn_LME );
    %LMF = lm_train( trainDir, 'f', fn_LMF );
    load(fn_LME, '-mat', 'LM');
    %load(fn_LMF, '-mat', 'LMF');

    % Train your alignment model of French, given English 
    %AMFE = align_ibm1( trainDir, numSentences, maxIter, fn_AMFE);
    load(fn_AMFE, '-mat', 'AM');

    % TODO: a bit more work to grab the English and French sentences. 
    %       You can probably reuse your previous code for this  

    fLines = textread(fn_testF, '%s', 'delimiter', '\n');
    egLines = textread(fn_testgE, '%s', 'delimiter', '\n');
    eLines = textread(fn_testE, '%s', 'delimiter', '\n');

    for l=1:length(fLines)
        
        curl = ['curl -u ' username ':' password ' -X POST -F "text=' fLines{l} '" -F "source=fr" -F "target=en" ' url];
        disp(curl);
        [status, result] = unix(curl); % 'env LD_LIBRARY_PATH='''''
        disp(status)
        
        % Decode the test sentence 'fre'
        fre = preprocess(fLines{l}, 'f');
        eng1 = decode(fre, LM, AM, lm_type, delta, vocabSize);
        eng2 = decode2(fre, LM, AM, lm_type, delta, vocabSize);

        cand1 = strjoin(eng1);
        cand2 = strjoin(eng2);
        ref1 = preprocess(egLines{l}, 'f');
        ref2 = preprocess(eLines{l}, 'f');
        ref3 = preprocess(result, 'f');
        
        disp(l)
        disp(['French Sentence: ' fre])
        disp(['Candidate: ' cand1])
        disp(['Candidate: ' cand2])
        disp(['Google Translate: ' ref1])
        disp(['Hansard: ' ref2])
        disp(['IBM Watson: ' ref3])
        disp(bleu_score(strjoin(eng1), {ref1, ref2, ref3}, 1))
    end
end

function pen = bleu_penalty(candidate, references)
    closest_ref = Inf;
    cand_len = length(candidate) - 2; % Subtract START/END
    for j=1:length(references)
        ref_len = length(strsplit(' ', references{j})) - 2; % Subtract START/END
        closest_ref = min(closest_ref, abs(ref_len - cand_len));
    end
    
    brevity = min(1, closest_ref / cand_len);
    pen = exp(1 - brevity);
end

function hist = create_histogram(references)
    hist = struct();
    for i=1:length(references)
        reference = references{i};
        words = strsplit(' ', reference);
        
        % Skip SENTSTART/SENTEND
        secondWord = words{2};
        thirdWord = words{3};
        for j=4:length(words) - 1
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


function bleu = bleu_score(candidate, references, n)
    histogram = create_histogram(references);
    
    % Hardcoded to only use up to trigrams
    words = strsplit(' ', candidate);
    num_cand_words = length(words) - 2; % Skip SENTSTART/SENDEND
    
    unigram_count = 0;
    bigram_count = 0;
    trigram_count = 0;
    
    % Skip SENTSTART/SENDEND
    secondWord = words{2};
    thirdWord = words{3};
    for j=4:length(words) - 1
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
    
    unigram_precision = unigram_count / length(num_cand_words);
    bigram_precision  = (n > 1) * bigram_count /  (length(num_cand_words) - 1) + (n <= 1);
    trigram_precision = (n > 2) * trigram_count / (length(num_cand_words) - 2) + (n <= 2);
    
    penalty = bleu_penalty(candidate, references);
    
    bleu = penalty * (unigram_precision * bigram_precision * trigram_precision).^(1 / n);
end