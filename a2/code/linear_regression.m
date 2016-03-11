function [params, N_r, X, Y] = linear_regression(LM)
    lmFields = fields(LM.uni);
    numLmFields = length(lmFields);

    N_r = struct();
    for i=1:numLmFields
        r = LM.uni.(lmFields{i});
        rField = ['r' int2str(r)];
        N_r = safe_add(N_r, rField, 1);

        if r > 50000
            disp(lmFields{i})
        end
    end
    nrFields = fields(N_r);
    numNrFields = length(nrFields);
    
    X = ones(numNrFields, 2);
    Y = ones(numNrFields, 1);
    
    for j=1:numNrFields
        rField = nrFields{j};
        r = str2num(rField(2:end));
        logr = log(r);
        X(j, 2) = logr;
        
        Nr = N_r.(rField);
        logNr = log(Nr);
        Y(j, 1) = logNr;
    end
    
    [X, sortedIndex] = sort(X);
    Y = Y(sortedIndex(:, 2));
    
    params = X\Y;
end

function retStruct = safe_add(inStruct, field, toAdd)
    if ~isfield(inStruct, field)
        inStruct.(field) = 0;
    end
    inStruct.(field) = inStruct.(field) + toAdd;
    retStruct = inStruct;
end