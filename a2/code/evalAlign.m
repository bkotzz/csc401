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
fn_AMFE      = '../data/Hansard/am_hansard';
fn_testF     = '../data/Hansard/Testing/Task5.f';
fn_testgE    = '../data/Hansard/Testing/Task5.google.e';
fn_testE     = '../data/Hansard/Testing/Task5.e';
lm_type      = 'smooth';
delta        = 0.01;
vocabSize    = 20; 
numSentences = 20;
maxIter      = 100;

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
    fre = preprocess(fLines{l}, 'f');
    
    % Decode the test sentence 'fre'
    eng = decode(fre, LM, AM, lm_type, delta, vocabSize);
    
    disp(l)
    disp(strjoin(eng))
    %disp(fre)
    disp(egLines{l})
    disp(eLines{l})
end





% TODO: perform some analysis
% add BlueMix code here 

%[status, result] = unix('')