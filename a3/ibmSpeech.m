test_dir = 'speechdata/Testing';
num_test_points = 30;

username = 'c1c0f736-0ff3-4b74-bf41-c3d32c9dce80';
password = 'KtvYmgDvyVYh';
url = ' https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true';
header1 = '--header "Content-Type: audio/flac" ';
header2 = '--header "Transfer-Encoding: chunked" ';

for i=1:num_test_points
    flac_file = [test_dir, filesep, 'unkn_', int2str(i), '.flac'];
    filer_header = ['--data-binary @' flac_file];
    
    curl = ['curl -u ' username ':' password ' -X POST ' header1 header2 filer_header url];
    
    % Transcript
    [status, result] = unix(curl); % 'env LD_LIBRARY_PATH='''''
    split = strsplit('"', result);
    hypothesis = strtrim(split(10));
    hypothesis = lower(hypothesis{1});
    hyp_array = strsplit(' ', hypothesis); 
    
    % Reference
    txt_file_name = [test_dir, filesep, 'unkn_', int2str(i), '.txt'];
    txt_file = textread(txt_file_name, '%s', 'delimiter', '\n');
    assert(1 == length(txt_file))
    
    reference = lower(txt_file{1});
    reference = regexprep(reference, '[^a-zA-Z0-9'' ]', '');
    reference = regexprep(reference, '-', ' ');
    ref_array = strsplit(' ', reference);
    ref_array = ref_array(3:end); % remove first two numbers
    reference = strjoin(ref_array, ' ');
    ref_length = length(ref_array);
    
    [se, ie, de] = compute_levenshtein(hyp_array, ref_array);
    dist = (se + ie + de) / ref_length;
    
    disp(hypothesis)
    disp(reference)
    disp(dist)
end


