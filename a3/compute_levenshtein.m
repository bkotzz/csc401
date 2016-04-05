function [SE, IE, DE] = compute_levenshtein(hyp, ref)

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