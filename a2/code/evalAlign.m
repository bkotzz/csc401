function evalAlign()
    %
    % evalAlign
    %
    %  This is simply the script (not the function) that you use to perform your evaluations in 
    %  Task 5. 

    % some of your definitions
    trainDir     = '/u/cs401/A2_SMT/data/Hansard/Training';
    testDir      = '/u/cs401/A2_SMT/data/Hansard/Testing';
    fn_LME       = '/u/cs401/A2_SMT/data/Hansard/lm_e_hansard';
    fn_LMF       = '/u/cs401/A2_SMT/data/Hansard/lm_f_hansard';
    fn_testF     = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.f';
    fn_testgE    = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.google.e';
    fn_testE     = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.e';
    fn_log       = 'Task5.txt';
    lm_type      = '';
    delta        = 0;
    numSentences = 1000;
    maxIter      = 10;

    % Bluemix credentials
    username = '"2ece4403-60be-49d6-963d-6bb104400af0"';
    password = '"gx9cb8kXuexn"';
    url = '"https://gateway.watsonplatform.net/language-translation/api/v2/translate"';

    % Open log file
    fileID = fopen(fn_log, 'w');

    % Train your language models. This is task 2 which makes use of task 1
    LM = lm_train( trainDir, 'e', fn_LME );
    %LM = lm_train( trainDir, 'f', fn_LMF );
    %load(fn_LME, '-mat', 'LM');
    %load(fn_LMF, '-mat', 'LMF');

    vocabSize = length(fieldnames(LM.uni));

    % Train your alignment model of French, given English 
    for i=[1, 10, 15, 30]
        f = ['/u/cs401/A2_SMT/data/Hansard/am_hansard_' num2str(i) 'k'];
        %load(f, '-mat', 'AM');
        AM = align_ibm1( trainDir, i * 1000, maxIter, f);
        s_am.(['am' num2str(i)]) = AM;
    end

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

        ref1 = remove_start_end(preprocess(egLines{l}, 'e'));
        ref2 = remove_start_end(preprocess(eLines{l}, 'e'));
        ref3 = remove_start_end(preprocess(result, 'e'));

        % Decode the test sentence 'fre'
        fre1 = preprocess(fLines{l}, 'f');
        % Valid to remove SENTSTART/SENTEND before decoding because
        % decode2 only uses LM/AM through the fields in VE, which doesn't
        % include LM
        fre2 = remove_start_end(fre1);
        
        fprintf(fileID, 'Test Line: %d\n', l);
        fprintf(fileID, 'French Sentence: %s\n', fre2);
        %disp(['Candidate: ' cand1])
        fprintf(fileID, 'Google Translate: %s\n', ref1);
        fprintf(fileID, 'Hansard: %s\n', ref2);
        fprintf(fileID, 'IBM Watson: %s\n', ref3);
        
        for i=[1, 10, 15, 30]
            %eng1 = decode(fre1, LM, AM, lm_type, delta, vocabSize);
            eng2 = decode2(fre2, LM, s_am.(['am' num2str(i)]), lm_type, delta, vocabSize);

            %cand1 = remove_start_end(strjoin(eng1));
            cand2 = eng2; % Decode2 doesn't use START/END

            fprintf(fileID, '\nAM: %dk Sentences\n', i);
            fprintf(fileID, 'Candidate: %s\n', cand2);

            % Compute Bleu scores
            for n=1:3
                %disp(bleu_score(cand1, {ref1, ref2, ref3}, n))
                bleu = bleu_score(cand2, {ref1, ref2, ref3}, n);
                fprintf(fileID, 'BLEU Score (n = %d): %f\n', n, bleu);
            end
            
            fprintf(fileID, '\n');
        end
        
        fprintf(fileID, '\n---------\n\n');
    end
    
    fclose(fileID);
end

function outSent = remove_start_end(inSent)
    outSent = regexprep(inSent, 'SENT(START|END) ?', '');
    outSent = regexprep(outSent, ' $', '');
end
