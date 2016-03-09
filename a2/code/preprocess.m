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
    inSentence = [CSC401_A2_DEFNS.SENTSTART ' ' strtrim(lower(inSentence)) ' ' CSC401_A2_DEFNS.SENTEND];

    % trim whitespaces down
    % \s matches any whitespace character one or more times
    inSentence = regexprep(inSentence, '\s+', ' '); 

    % initialize outSentence
    outSentence = inSentence;

    % perform language-agnostic changes
    % TODO: your code here
    %    e.g., outSentence = regexprep( outSentence, 'TODO', 'TODO');
    
    % Seperate EOS punctuation, which we will take to be .?!, whether or
    % not it is followed by double quotes or two single quotes.  We only
    % separate periods at the end, in order to not break up things like Mr.
    % but separate ?! anywhere in the sentence, as they could be in quotes.
    % If we see multiple periods, we can safely separate.
    outSentence = regexprep(outSentence, ['\.("|'''')?' ' ' CSC401_A2_DEFNS.SENTEND], ' $0');
    outSentence = regexprep(outSentence, '\.\.+', ' $0 ');
    outSentence = regexprep(outSentence, '[?!]+', ' $0 ');
    
    % Separate multiple 
    
    % Seperate ,:;()[]{}"&`$
    outSentence = regexprep(outSentence, '[,:;"&()[]{}`$]', ' $0 ');
    
    % Seperate math operators %<>=+-/*^
    % Note: can't split minus operator, because this is the same as a dash,
    %       and we are only splitting dashes inside parantheses
    outSentence = regexprep(outSentence, '[%<>=+/*^]', ' $0 ');
    
    % Now we split the dash/minus operator, but only within parantheses ()
    outSentence = regexprep(outSentence, '(?<=\(.*)-(?=.*\))', ' - ');

    switch language
    case 'e'
        % Seperate apostrophe for cases like
        % dogs -> dogs '
        % dog's -> dog 's
        % we've -> we 've
        outSentence = regexprep(outSentence, '''', ' ''');
        
        % Put back clitics that like wouldn't that were
        % separated incorrectly. This is the only case I can think
        % of that requires carrying the letter preceding the apostrophe
        % with the clitic.
        % wouldn 't -> would n't
        outSentence = regexprep(outSentence, 'n\> ''t', ' n''t');

    case 'f'
        % Seperate leading l' from concatenated word
        outSentence = regexprep(outSentence, '\<l''([a-z])', 'l'' $1');
        
        % Seperate leading consonant and apostrophe from concatenated word
        outSentence = regexprep(outSentence, '\<([a-z])''([a-z])', '$1'' $2');
        
        % Seperate leading qu' from concatenated word
        outSentence = regexprep(outSentence, '\<qu''([a-z])', 'qu'' $1');
        
        % Seperate following on or il
        outSentence = regexprep(outSentence, '([a-z])''(on|il)\>', '$1'' $2');
        
        % Put back togther the following words
        % d'abord d'accord d'ailleurs d'habitude
        outSentence = regexprep(outSentence, '\<d'' (abord|accord|ailleurs|habitude)\>', 'd''$1');
    end

    % Trim extra spaces
    outSentence = regexprep(outSentence, '\s+', ' '); 
    outSentence = strtrim(outSentence);
    
    % change unpleasant characters to codes that can be keys in dictionaries
    outSentence = convertSymbols(outSentence);

