function out = convertSymbols(in)
%
%  convertSymbols
%
%  This function converts [symbols that cannot be used in 
%  Matlab's dictionary as keys] to [special words that can].
%
%

csc401_a2_defns

out = in;

out = regexprep(out, '\*', CSC401_A2_DEFNS.STAR);
out = regexprep(out, '\-', CSC401_A2_DEFNS.DASH);
out = regexprep(out, '\+', CSC401_A2_DEFNS.PLUS);
out = regexprep(out, '\=', CSC401_A2_DEFNS.EQUALS);
out = regexprep(out, '\,', CSC401_A2_DEFNS.COMMA);
out = regexprep(out, '\.', CSC401_A2_DEFNS.PERIOD);
out = regexprep(out, '\?', CSC401_A2_DEFNS.QUESTION);
out = regexprep(out, '\!', CSC401_A2_DEFNS.EXCLAM);
out = regexprep(out, ':', CSC401_A2_DEFNS.COLON);
out = regexprep(out, ';', CSC401_A2_DEFNS.SEMICOLON);
out = regexprep(out, '''', CSC401_A2_DEFNS.SINGQUOTE);
out = regexprep(out, '"', CSC401_A2_DEFNS.DOUBQUOTE);
out = regexprep(out, '`', CSC401_A2_DEFNS.BACKQUOTE);
out = regexprep(out, '\(', CSC401_A2_DEFNS.OPENPAREN);
out = regexprep(out, '\)', CSC401_A2_DEFNS.CLOSEPAREN);
out = regexprep(out, '\[', CSC401_A2_DEFNS.OPENBRACK);
out = regexprep(out, '\]', CSC401_A2_DEFNS.CLOSEBRACK);
out = regexprep(out, '/', CSC401_A2_DEFNS.SLASH);
out = regexprep(out, '\$', CSC401_A2_DEFNS.DOLLAR);
out = regexprep(out, '\%', CSC401_A2_DEFNS.PERCENT);
out = regexprep(out, '\&', CSC401_A2_DEFNS.AMPERSAND);
out = regexprep(out, '<', CSC401_A2_DEFNS.LESS);
out = regexprep(out, '>', CSC401_A2_DEFNS.GREATER);
out = regexprep(out, '^(\d)', 'N$1');  % leading digit only
out = regexprep(out, '\s(\d)', ' N$1');  % leading digit only

return