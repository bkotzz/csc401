function [SE, IE, DE, LEV_DIST] = Levenshtein(hypothesis, annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	LEV_DIST: proportion of overall error in all hypotheses

    output_file_name = 'discussion_levenshtein.txt';
    output_file = fopen(output_file_name, 'w');

    hyp_file = textread(hypothesis, '%s', 'delimiter', '\n');
    N_hypotheses = length(hyp_file);
    
    SE = 0;
    IE = 0;
    DE = 0;
    num_reference_words = 0;
    
    for i=1:N_hypotheses
        ref_file_name = ['unkn_', int2str(i), '.txt'];
        ref_file = textread([annotation_dir, filesep, ref_file_name], '%s', 'delimiter', '\n');
        assert(1 == length(ref_file))
        
        ref_split = strsplit(ref_file{1}, ' ');
        ref_sent = ref_split(3:end);
        
        ref_length = length(ref_split);
        num_reference_words = num_reference_words + length(ref_split);
        
        hyp_split = strsplit(hyp_file{i}, ' ');
        hyp_sent = hyp_split(3:end);
        
        fprintf(output_file, 'Reference: %s\n',  strjoin(ref_sent, ' '));
        fprintf(output_file, 'Hypothesis: %s\n', strjoin(hyp_sent, ' '));
        
        [se_toAdd, ie_toAdd, de_toAdd] = compute_levenshtein(hyp_sent, ref_sent);
        fprintf(output_file, 'SE: %f\n', se_toAdd / ref_length);
        fprintf(output_file, 'IE: %f\n', ie_toAdd / ref_length);
        fprintf(output_file, 'DE: %f\n\n', de_toAdd / ref_length);
        fprintf(output_file, 'Total: %f\n\n', (se_toAdd + ie_toAdd + de_toAdd) / ref_length);
        
        SE = SE + se_toAdd;
        IE = IE + ie_toAdd;
        DE = DE + de_toAdd;
    end
    
    SE = SE / num_reference_words;
    IE = IE / num_reference_words;
    DE = DE / num_reference_words;
    
    LEV_DIST = SE + IE + DE;
    
    fprintf(output_file, '----\n\n');
    fprintf(output_file, 'Entire SE: %f\n', SE);
    fprintf(output_file, 'Entire IE: %f\n', IE);
    fprintf(output_file, 'Entire DE: %f\n\n', DE);
    fprintf(output_file, 'Entire Total: %f\n\n', LEV_DIST);
    
    fclose(output_file);
end
