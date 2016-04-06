function [hypothesis] = ibmSpeechToText(flac_file_path)

    username = 'c1c0f736-0ff3-4b74-bf41-c3d32c9dce80';
    password = 'KtvYmgDvyVYh';
    url = ' https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?continuous=true';
    header1 = '--header "Content-Type: audio/flac" ';
    header2 = '--header "Transfer-Encoding: chunked" ';
    
    filer_header = ['--data-binary @' flac_file_path];
    
    curl = ['curl -u ' username ':' password ' -X POST ' header1 header2 filer_header url];
    
    [status, result] = unix(curl); % 'env LD_LIBRARY_PATH='''''
    split = strsplit(result, '"');
    hypothesis = strtrim(split(10));
    hypothesis = lower(hypothesis{1});
end

