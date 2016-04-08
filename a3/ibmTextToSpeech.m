function ibmTextToSpeech(text, flac_file_path, voice)

    text = regexprep(text, ' ', '\\ ');
    text = regexprep(text, '''', '\\''');
    username = 'a018dde3-dd3c-4eb7-90e2-0c7b3c703712';
    password = 'KfXQBOas5kwE';
    url = '"https://stream.watsonplatform.net/text-to-speech/api/v1/synthesize?voice=';
    header1 = '--header "Accept: audio/flac" ';
    header2 = '--header "Content-Type: application/json" ';
    data = ['--data {\"text\":\"' text '\"} '];
    
    curl = ['env LD_LIBRARY_PATH='''' curl -u ' username ':' password ' -X POST ' header1 header2 data url voice '" -o ' flac_file_path];
    [status, result] = unix(curl); % 'env LD_LIBRARY_PATH='''''
end

