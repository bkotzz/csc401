function outSentence = preprocess( inSentence, language )
%
%  preprocess
%
%  This function preprocesses the input text according to language-specific rules.
%  Specifically, we separate contractions according to the source language, convert
%  all tokens to lower-case, and separate end-of-sentence punctuation 
%
%  INPUTS:
%       inSentence     : (string) the original sentence to be processed 
%                                 (e.g., a line from the Hansard)
%       language       : (string) either 'e' (English) or 'f' (French) 
%                                 according to the language of inSentence
%
%  OUTPUT:
%       outSentence    : (string) the modified sentence
%
%  Template (c) 2011 Frank Rudzicz 

    global CSC401_A2_DEFNS

    % first, convert the input sentence to lower-case and add sentence marks
    % string is array of characters, place spaces in between
    inSentence = [CSC401_A2_DEFNS.SENTSTART ' ' lower(inSentence) ' ' CSC401_A2_DEFNS.SENTEND];

    % trim whitespaces down
    % \s matches any whitespace character
    inSentence = regexprep(inSentence, '\s+', ' '); 

    % initialize outSentence
    outSentence = inSentence;

    % perform language-agnostic changes
    % TODO: your code here
    %    e.g., outSentence = regexprep( outSentence, 'TODO', 'TODO');
    
    % Seperate EOS punctuation
    outSentence = regexprep(outSentence, '[.?!]$', ' $0');
    
    % Seperate ,:;()[]{}"
    outSentence = regexprep(outSentence, '[,:;"()[]{}]', ' $0 ');
    
    % Seperate math operators <>=+-/*^
    outSentence = regexprep(outSentence, '[<>=+-/*^]', ' $0 ');

    switch language
    case 'e'
        % Seperate apostrophe
        outSentence = regexprep(outSentence, '''', ' ''');

    case 'f'
        % Seperate leading l' from concatenated word
        outSentence = regexprep(outSentence, '\<l''(\w)', 'l'' $1');
        
        % Seperate leading consonant and apostrophe from concatenated word
        outSentence = regexprep(outSentence, '\<(\w)''(\w)', '$1'' $2');
        
        % Seperate leading qu' from concatenated word
        outSentence = regexprep(outSentence, '\<qu''(\w)', 'qu'' $1');
        
        % Seperate following on or il
        outSentence = regexprep(outSentence, '(\w)''(on|il)\>', '$1'' $2');
    end

    % Trim extra spaces
    outSentence = regexprep(outSentence, '\s+', ' '); 
    outSentence = strtrim(outSentence);
    
    % change unpleasant characters to codes that can be keys in dictionaries
    outSentence = convertSymbols(outSentence);

