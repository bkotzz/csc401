function [SE, IE, DE, LEV_DIST] = Levenshtein(hypothesis, annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	LEV_DIST: proportion of overall error in all hypotheses

    hyp_file = textread(hypothesis, '%s', 'delimiter', '\n');
    N_hypotheses = length(hyp_file);
    
    SE = 0;
    IE = 0;
    DE = 0;
    num_reference_words = 0;
    
    for i=1:N_hypotheses
        ref_file_name = ['unkn_', int2str(i), '.txt'];
        ref_file = textread([annotation_dir, filesep, ref_file_name], '%s', 'delimiter', '\n');
        assert(1 == length(ref_file))
        
        ref_split = strsplit(' ', ref_file{1});
        ref_sent = ref_split(3:end);
        
        num_reference_words = num_reference_words + length(ref_split);
        
        hyp_split = strsplit(' ', hyp_file{i});
        hyp_sent = hyp_split(3:end);
        
        disp(strjoin(ref_sent, ' '))
        disp(strjoin(hyp_sent, ' '))
        
        [se_toAdd, ie_toAdd, de_toAdd] = levenshtein(hyp_sent, ref_sent);
        disp([se_toAdd, ie_toAdd, de_toAdd])
        
        SE = SE + se_toAdd;
        IE = IE + ie_toAdd;
        DE = DE + de_toAdd;
    end
    
    SE = SE / num_reference_words;
    IE = IE / num_reference_words;
    DE = DE / num_reference_words;
    
    LEV_DIST = SE + IE + DE;
end

function [SE, IE, DE] = levenshtein(hyp, ref)

% Input: REF: reference array of words
% Input: HYP: hypothesis array of words

    UP      = 1; % DEL
    LEFT    = 2; % INS

% begin
    % n ? The number of words in REF
    n = length(ref);
    
    % m ? The number of words in HYP
    m = length(hyp);
    
    % R ? zeros(n + 1, m + 1) // Matrix of distances
    R = zeros(n + 1, m + 1);
    
    % B ? zeros(n + 1, m + 1) // Backtracking matrix
    B = zeros(n + 1, m + 1);
    
    % For all i, j s.t. i = 0 or j = 0, set R[i, j] ? ?, except R[0, 0] ? 0
    R(1, :) = Inf;
    R(:, 1) = Inf;
    R(1, 1) = 0;
    
    % for i = 1..n do
    for i=2:n+1
        % for j = 1..m do
        for j=2:m+1
            % del ? R[i ? 1, j] + 1
            del = R(i - 1, j) + 1;
            
            % sub ? R[i ? 1, j ? 1] + (REF[i] == HYP[j]) ? 0 : 1
            % When REF[i] == HYP[j] sub_hit will be the correct minimum
            % When REF[i] ~= HYP[j] sub_miss will be the correct minimum
            sub_miss = R(i - 1, j - 1) + 1;
            sub_hit  = R(i - 1, j - 1) + ~strcmp(ref{i - 1}, hyp{j - 1});
            
            % ins ? R[i, j ? 1] + 1
            ins = R(i, j - 1) + 1;
            
            % R[i, j] ? Min ( del, sub, ins )
            [R(i, j), argmin] = min([del, ins, sub_miss, sub_hit], [], 2);
            
            B(i, j) = argmin; % where argmin is {DEL, INS, SUB_MISS, SUB_HIT}
        % end
        end
    % end
    end
    
    % Count up the different types of errors as we backtrack
    % {DEL, INS, SUB_MISS, SUB_HIT}
    del_ins_sub_counter = zeros(1, 4);
    
    i = n + 1;
    j = m + 1;

    while ~((1 == i) && (1 == j))
            argmin = B(i, j);
            del_ins_sub_counter(argmin) = 1 + del_ins_sub_counter(argmin);
            
            i = i - (argmin ~= LEFT);
            j = j - (argmin ~= UP);
    end

    DE = del_ins_sub_counter(1);
    IE = del_ins_sub_counter(2);
    SE = del_ins_sub_counter(3);
    
% end
end