import sys

import csv
import itertools

import re
import HTMLParser

import StringIO
import string


def split_sentences(sentences):
    tokens = [x.strip().split(' ') for x in sentences]
    return [y.split('/') for x in tokens for y in x]


def first_person_pronouns(sentences, token_split):
    candidate_words = ['i', 'me', 'my', 'mine', 'we', 'us', 'our', 'ours']
    return [x[0].lower() in candidate_words for x in token_split].count(True)


def second_person_pronouns(sentences, token_split):
    candidate_words = ['you', 'your', 'yours', 'u', 'ur', 'urs']
    return [x[0].lower() in candidate_words for x in token_split].count(True)


def third_person_pronouns(sentences, token_split):
    candidate_words = ['he', 'him', 'his', 'she', 'her', 'hers', 'it', 'its', 'they', 'them', 'their', 'theirs']
    return [x[0].lower() in candidate_words for x in token_split].count(True)


def coordinating_conjunctions(sentences, token_split):
    candidate_words = ['CC']
    return [x[1] in candidate_words for x in token_split].count(True)


def past_tense_verbs(sentences, token_split):
    candidate_words = ['VBD']
    return [x[1] in candidate_words for x in token_split].count(True)


def future_tense_verbs(sentences, token_split):
    candidate_words = ["'ll", 'will', 'gonna']
    count = [x[0].lower() in candidate_words for x in token_split].count(True)
    
    # We also want to count sequences of going+to+VB
    count += [token_split[i][0].lower() == 'going' and token_split[i + 1][0].lower() == 'to' and token_split[i + 2][1] == 'VB' for i in range(len(token_split) - 2)].count(True)
    return count


def commas(sentences, token_split):
    candidate_words = [',']
    return [x[1] in candidate_words for x in token_split].count(True)


def colons(sentences, token_split):
    candidate_words = [':', ';']
    return [x[0] in candidate_words for x in token_split].count(True)


def dashes(sentences, token_split):
    candidate_words = ['-']
    return [x[0] in candidate_words for x in token_split].count(True)


def parantheses(sentences, token_split):
    candidate_words = ['(', ')']
    return [x[0] in candidate_words for x in token_split].count(True)


def ellipses(sentences, token_split):
    candidate_words = ['...']
    return [x[0] in candidate_words for x in token_split].count(True)


def common_nouns(sentences, token_split):
    candidate_words = ['NN', 'NNS']
    return [x[1] in candidate_words for x in token_split].count(True)


def proper_nouns(sentences, token_split):
    candidate_words = ['NNP', 'NNPS']
    return [x[1] in candidate_words for x in token_split].count(True)


def adverbs(sentences, token_split):
    candidate_words = ['RB', 'RBR', 'RBS']
    return [x[1] in candidate_words for x in token_split].count(True)


def wh_words(sentences, token_split):
    candidate_words = ['WDT', 'WP', 'WP$', 'WRB']
    return [x[1] in candidate_words for x in token_split].count(True)


def slang_acronyms(sentences, token_split):
    candidate_words = ['smh', 'fwb',  'lmfao', 'lmao', 'lms', 'tbh',  'rofl', 'wtf',
                       'bff', 'wyd',  'lylc',  'brb',  'atm', 'imao', 'sml',  'btw',
                       'bw',  'imho', 'fyi',   'ppl',  'sob', 'ttyl', 'imo',  'ltr',
                       'thx', 'kk',   'omg',   'ttys', 'afn', 'bbs',  'cya',  'ez',
                       'f2f', 'gtr',  'ic',    'jk',   'k',   'ly',   'ya',   'nm',  'np',
                       'plz', 'ru',   'so',    'tc',   'tmi', 'ym',   'ur',   'u',   'sol']
    return [x[0].lower() in candidate_words for x in token_split].count(True)


def upper_case_words(sentences, token_split):
    return [x[0].isupper() and len(x[0]) > 1 for x in token_split].count(True)


def sentence_length(sentences, token_split):
    return len(token_split) / float(len(sentences))


def token_length(sentences, token_split):
    candidate_words = ['#', '$', '.', ',', ':', '(', ')', '"', 'POS']
    token_lengths = [len(x[0]) for x in token_split if x[1] not in candidate_words]
    return sum(token_lengths) / float(len(token_lengths))


def number_sentences(sentences, token_split):
    return len(sentences)


def prep_arff(output_file):
    output_file.write("@relation sentiment\n\n")
    
    feature_set = [
                "first_person_pronouns", 
                "second_person_pronouns", 
                "third_person_pronouns",
                "coordinating_conjunctions",
                "past_tense_verbs",
                "future_tense_verbs",
                "commas",
                "colons",
                "dashes",
                "parantheses",
                "ellipses",
                "common_nouns",
                "proper_nouns",
                "adverbs",
                "wh_words",
                "slang_acronyms",
                "upper_case_words",
                "sentence_length",
                "token_length",
                "number_sentences"
               ]
    
    for feature in feature_set:
        output_file.write("@attribute " + feature + " numeric\n")
        
    output_file.write("@attribute class {0, 4}\n\n")
    
    output_file.write("@data\n")


def compute_feature_vector(sentences, label):
    feature_string = ""
    if 0 == len(sentences):
        return feature_string
    
    if "\n" == sentences[0]:
        #print "Empty sentences"
        return "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0," + str(label) + "\n"
    
    function_set = [
                    first_person_pronouns, 
                    second_person_pronouns, 
                    third_person_pronouns,
                    coordinating_conjunctions,
                    past_tense_verbs,
                    future_tense_verbs,
                    commas,
                    colons,
                    dashes,
                    parantheses,
                    ellipses,
                    common_nouns,
                    proper_nouns,
                    adverbs,
                    wh_words,
                    slang_acronyms,
                    upper_case_words,
                    sentence_length,
                    token_length,
                    number_sentences
                   ]
    
    sentence_split = split_sentences(sentences)
    for function in function_set:
        feature_string += str(function(sentences, sentence_split)) + ','
        
    feature_string += str(label)
    
    return feature_string + "\n"


def buildarff(input_file, output_file, max_per_class=float("inf")):

    prep_arff(output_file)
    
    sentence_container = []

    # We keep a counter of how many samples of each class we've seen
    # [Class 0 samples, Class 4 samples]
    #
    # We start class 0 at -1 because the first iteration computes an empty
    # feature vector, writes "" to the output file, and then starts counting from 0
    class_counters = [-1, 0]

    class_label = 0 # Holds the most recently seen class label
    for line in input_file: 

        if line.startswith('<A='):
            try:
                feature_vector = compute_feature_vector(sentence_container, class_label)
            except Exception as e:
                print "Error: {} on ".format(e), sentence_container
            else:
                if class_counters[class_label / 4] < max_per_class:
                    output_file.write(feature_vector)
                    class_counters[class_label / 4] += 1
            
            class_label = int(line[3])
            sentence_container = []
        else:
            sentence_container.append(line)

    feature_vector = compute_feature_vector(sentence_container, class_label)
    if class_counters[class_label / 4] < max_per_class:
        output_file.write(feature_vector)


if __name__ == "__main__":
    if len(sys.argv) not in [3, 4]:
        print "Expecting the input file name, output file name and an optional max number of tweets"
        sys.exit()

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]  

    with open(input_filename, "r") as _input:
        with open(output_filename, "w") as _output:
            if len(sys.argv) == 4:
                buildarff(_input, _output, int(sys.argv[3]))
            else:
                buildarff(_input, _output)
