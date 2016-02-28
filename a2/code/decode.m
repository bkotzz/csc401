function english = decode( french, LM, AM, lmtype, delta, vocabSize )
%
%  decode
%
%
%  This function returns an approximation of an english sentence given a french,
%  a language model of english, and the alignment model
%
%  INPUTS:
%
%       french    : (string) a preprocessed french sentence
%       LM        : a language model of english as defined in lm_train.m      
%       AM        : an alignment model of french given english as defined in align_ibm1.m  
%       lmtype    : (string) either '' (default) or 'smooth' for add-delta smoothing 
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% 
% (c) 2011 Siavash Kazemian 

  % We initially assume that the english sentence has as many words as the french sentence 
  % and that the i^th french word translates to the i^th english word. 
  frenchWords = strsplit(' ', french );
  englishWords = cell(1, length(frenchWords));
  
  
  % the align vector. 
  %  here, align(i) is the index of the french word that produced the i^th english word
  %  e.g., if align(2)=3, then that means that we translate the 3rd french word to get the 
  %  2nd english word
  align = initialize_trans(frenchWords,AM);
  english = greedy_word_order_exchange(align,LM);
  english = {english.trans};

end

function output = greedy_word_order_exchange(trans,LM)
	output = trans;
	score = calc_trans_score(trans,LM);
	for i=1:length(trans),
		%currently, we reorder the words in the translation to find the most probable translation
		candidates = {trans(i+1:length(trans))};
		temp_trans = trans;
		for j=1:length(candidates),
			temp = temp_trans(i);
			temp_trans(i) = temp_trans(j);
			temp_trans(j) = temp;
			temp_score = calc_trans_score(temp_trans,LM);
			if temp_score > score
				score = temp_score;
				output = temp_trans;
			end
		end
	end
end

function output_struct = initialize_trans(french_words, AM)
	output = cell(1,length(french_words));
	output_prob = cell(1,length(french_words));
	for j=1:length(french_words),
		%[trans,trans_prob] = get_max_struct(AM.(french_words{j}));
		[trans,trans_prob] = argmaxN_targetlanguage(french_words{j},AM,1);
		output{j} = trans;
		output_prob{j} = trans_prob;
	end
	output_struct = struct('trans',output,'trans_prob',output_prob);
end

function [output,prob] = argmaxN_targetlanguage(target_word,align_model,N)
%returns N most likely english words that are translations of word_in_target_lang
%now ingnores N and returns the most likely candidate only
	source_words = fieldnames(align_model);
	prob = -Inf;
	output = 'UNK';
	for i=1:length(source_words),
		if (isfield(align_model.(source_words{i}),target_word))
			if align_model.(source_words{i}).(target_word) > prob
				prob = align_model.(source_words{i}).(target_word);
				output = source_words{i};
			end
		end
	end
end

function [output,output_val] = get_max_struct(the_struct)
	the_fieldnames = fieldnames(the_struct);
	temp = -Inf;
	for i=1:length(the_fieldnames),
		if the_struct.(the_fieldnames{i}) > temp
			temp_key = the_fieldnames{i};
			temp = the_struct.(cell2mat(the_fieldnames(i)));
		end
	end
	output = temp_key;
	output_val = temp;
end

function score = calc_trans_score(trans,LM)
	score = calc_LM_score({trans.trans},LM);
	for i=1:length(trans),
		score = score + log2(trans(i).trans_prob);
	end
end

function score = calc_LM_score(trans,LM)
	index = 1;
	score = 0;
	bigram_count = num_bigrams(LM);
	unigram_count = calc_sum_over_struct(LM.uni);
	while (index <= length(trans))
		if (index < length(trans))
			if (isfield(LM.uni,trans{index}) && isfield(LM.bi,trans{index}) )
				if (isfield(LM.bi.(trans{index}),trans{index+1 }))
					score_uni = log2(LM.uni.(trans{index})/unigram_count);
					score_uni = score_uni + log2(LM.uni.(trans{index+1})/unigram_count);
					score_bi = log2(LM.bi.(trans{index}).(trans{index+1})/bigram_count);
					if (score_uni > score_bi)
						score = score + score_uni;
						index = index + 1;
					else
						score = score + score_bi;
						index = index + 2;
					end
				else
					score = score + log2(LM.uni.(trans{index})/unigram_count);
					index = index + 1;
				end

			elseif(isfield(LM.uni,trans{index}))
				score = score + log2(LM.uni.(trans{index})/unigram_count);
				index = index + 1;
			else
				index = index + 1;
			end
		else
			if (isfield(LM.uni,trans{index}))
				score = score + log2(LM.uni.(trans{index})/unigram_count);
			end
			index = index + 1;
		end
	end
end

function output = calc_sum_over_struct(the_struct)
	output = 0;
	the_fieldnames = fieldnames(the_struct);
	for i=1:length(the_fieldnames);
		output = output + the_struct.(the_fieldnames{i});
	end
end

function output = num_bigrams(LM)
	output = 0;
	the_fieldnames = fieldnames(LM.bi);
	for i=1:length(the_fieldnames);
		output = output + calc_sum_over_struct(LM.bi.(the_fieldnames{i}));
	end
end
