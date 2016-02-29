function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS
  
  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);

  % Initialize AM uniformly 
  AM = initialize(eng, fre);

  % Iterate between E and M steps
  for iter=1:maxIter,
    AM = em_step(AM, eng, fre);
  end

  % Save the alignment model
  save( fn_AM, 'AM', '-mat'); 

  end





% --------------------------------------------------------------------------------
% 
%  Support functions
%
% --------------------------------------------------------------------------------

function retStruct = read_language(files, dataDir)
    retStruct = {};
    lineCount = 1;
    
    for iFile=1:length(files)

        disp(iFile)
        lines = textread([dataDir, filesep, files(iFile).name], '%s', 'delimiter', '\n');

        for l=1:length(lines)

            processedLine =  preprocess(lines{l}, language);
            words = strsplit(' ', processedLine);
            
            retStruct{lineCount} = words;
            lineCount = lineCount + 1;
        end
    end
end

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of 
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%

    % TODO: your code goes here.

    DD_eng = dir([mydir, filesep, '*.e']);
    DD_fre = dir([mydir, filesep, '*.f']);

    eng = read_language(DD_eng, mydir);
    fre = read_language(DD_fre, mydir);

end


function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
    AM = {}; % AM.(english_word).(foreign_word)

    assert(length(eng) == length(fre))
    
    % First pass: For every english word we see,
    % add an entry for every french word in an aligned sentence
    for iSent=1:length(eng)
        engSentence = eng{iSent};
        freSentence = fre{iSent};
        assert(length(engSentence) == length(freSentence));
        
        for iEngWord=1:length(engSentence)
            engWord = engSentence{iEngWord};
            for iFreWord=1:length(freSentence)
                freWord = engSentence{iFreWord};
                AM.(engWord).(freWord) = 1;
            end
        end
    end
    
    % Second pass: For each english word in our alignment model,
    % divide each french word entry by the number of french words
    engFields = fieldnames(AM);
    for iEngField = 1:numel(engFields)
        engField = AM.(engFields{iEngField});
        
        freFields = fieldnames(engField);
        denominator = length(freFields);
        for iFreField = 1:numel(freFields)
            engField.(freFields{iFreField}) = 1 / denominator;
        end
    end
end

function retStruct = safe_add(inStruct, field, toAdd)
    if ~isfield(inStruct, field)
        inStruct.(field) = 0;
    end
    inStruct.(field) = inStruct.(field) + toAdd;
    retStruct = inStruct;
end

function hist = create_histogram(sentence)
    hist = struct();
    for i=1:length(sentence)
        currWord = sentence{i};
        hist = safe_add(hist, currWord, 1);
    end
end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
%   set tcount(f, e) to 0 for all f, e
%   set total(e) to 0 for all e
    tcount = struct();
    total = struct();
    
%   for each sentence pair (F, E) in training corpus:
    for iSent=1:length(eng)
        engSentence = eng{iSent};
        freSentence = fre{iSent};
        assert(length(engSentence) == length(freSentence));
        
        uniqueEng = create_histogram(engSentence);
        uniqueEngWords = fieldnames(uniqueEng);
        uniqueFre = create_histogram(freSentence);
        uniqueFreWords = fieldnames(uniqueFre);

%       for each unique word f in F:
        for iFre=1:length(uniqueFreWords)
            f = uniqueFreWords.(uniqueFreWords{iFre});
            
%           denom_c = 0
            denom_c = 0;
%           for each unique word e in E:
            for iEng=1:length(uniqueEngWords)
                e = uniqueEngWords.(uniqueEngWords{iEng});
                
%               denom_c += P(f|e) * F.count(f)
                denom_c = denom_c + t.(e).(f) * uniqueFre.(f);
            end
%           for each unique word e in E:
            for iEng=1:length(uniqueEngWords)
                e = uniqueEngWords.(uniqueEngWords{iEng});
                
%               total(e) += P(f|e) * F.count(f) * E.count(e) / denom_c            
                toAdd = t.(e).(f) * uniqueFre.(f) * uniqueEng.(e) / denom_c;
                total = safe_add(total, e, toAdd);
                
%               tcount(f, e) += P(f|e) * F.count(f) * E.count(e) / denom_c
                if ~isfield(tcount, e)
                    tcount.(e) = struct();
                end
                tcount.(e) = safe_add(tcount.(e), f, toAdd);
            end
        end
    end
    
%   for each e in domain(total(:)):
    totalFields = fieldnames(total);
    for iTotal=1:length(totalFields)
        e = totalFields{iTotal};
        
%       for each f in domain(tcount(:,e)):
        tcountFields = fieldnames(tcount.(e));
        for iTcount=1:length(tcountFields)
            f = tcountFields{iTcount};
            
%           P(f|e) = tcount(f, e) / total(e)
            t.(e).(f) = tcount.(e).(f) / total.(e);
        end
    end
end


