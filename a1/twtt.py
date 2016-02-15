import numpy as np
import NLPlib as nlp

import csv
import itertools

import re
import HTMLParser

import StringIO
import string

import sys


#####
##### Helper functions
#####

##### 1. All html tags and attributes (i.e., /<[^>]+>/) are removed.
def strip_html_tags(tweet):
    return re.sub(r'<[^>]+>', '', tweet)


##### 2. Html character codes (i.e., &...;) are replaced with an ASCII equivalent.
#        - Remove the ascii encoding to support extended in unicode
def replace_html_codes(tweet):
    parser = HTMLParser.HTMLParser()
    tweet = filter(lambda x: x in string.printable, tweet)
    return parser.unescape(tweet).encode('ascii', 'ignore')


##### 3. All URLs (i.e., tokens beginning with http or www) are removed.
def remove_urls(tweet):
    # Note that this will modify the whitespace when words are separated by
    # more than one space, but that shouldn't matter as we are tokenizing
    # the tweets anyways
    
    return ' '.join(filter(lambda x : not x.lower().startswith(('www', 'http')), tweet.split(' ')))


##### 4. The first character in Twitter user names (@) and hash tags (#) are removed.
def remove_hashtags(tweet):
    return ' '.join([ x[1:] if  x.startswith(('@', '#')) else x for x in tweet.split(' ')])


##### 5. Each sentence within a tweet is on its own line.
def create_abbrev_set(file_path='Wordlists/abbrev.english'):
    abbrev_set = set()
    
    with open(file_path, 'rb') as abbrevs:
        for line in abbrevs:
            abbrev_set.add(line.strip())
            #print line.strip()
    
    return abbrev_set

def split_by_sentence(tweet):
    '''
        # 1. Anything ending in .?! declared a sentence
        # 2. Sentence boundary moved after quotation mark, if any ex. He said, "I am coming."
        # 3. Period boundary is disqualified if it preceded by an element in abbrev_set
        #    <We could look for capitals after an EOS, but nobody uses capitals on twitter>
        #    <Both sides of :;- could also be thought of as sentence>
    '''
    
    tweet = re.sub(r' +', ' ', tweet).strip()
    if 0 == len(tweet): return [tweet]
    
    abbrev_set = create_abbrev_set()
    split_by_space = tweet.split(' ')

    quote_eos = lambda x: len(x) > 1 and (x[-2:] in {'."', '?"', '!"'} or x[-2:] in {".'", "?'", "!'"})
    eos = lambda x: (x[-1] in {'.', '?', '!'} and x not in abbrev_set) or (quote_eos(x) and x[:-1] not in abbrev_set)
    eos_indices = [i + 1 for i, x in enumerate(split_by_space) if eos(x)]
    
    if 0 == len(eos_indices):
        return [tweet]
    
    sents = [' '.join(x) for x in [split_by_space[i:j] for i, j in zip([0] + eos_indices[:-1], eos_indices)]]

    if eos_indices[-1] < len(split_by_space):
        sents = sents + [' '.join(split_by_space[eos_indices[-1]:])]

    return sents


##### 6/7. Each token, including punctuation and clitics, is separated by spaces.
# - Clitics: contracted forms of words, such as n't
# - 's on possessive (ie. Brad's) different from 's on clitics (ie. What's), but both separated
# - Must also separate possessive on plurals (ie. dogs ')
# - Ellipsis (i.e., '...''), and other kinds of multiple punctuation (e.g., '!!!') are not split.
# - Don't split e.g. into tokens

def split_tokens(sentence):
    # 1. Split on all punctuation symbols, where a given symbol is repeated once or more
    sentence_1 = re.sub(r"((["+ string.punctuation + "])\\2*)", r" \1 ", sentence).strip()
    sentence_1 = ' '.join(sentence_1.split('  '))
    
    # 2. Join clitics and contractions where ' occurs mid-word
    sentence_2 = re.sub(r"(') ([A-Za-z] )", r"\1\2", sentence_1)
    
    # 3. Join e.g.
    sentence_3 = re.sub(r" e . g . ", r" e.g. ", sentence_2)
    
    return sentence_3


##### 8. Each token is tagged with its part-of-speech.
def tag_sentence(sentence, pos_tagger):
    '''
    Assume sentence is already separated into tokens
    '''
    split = sentence.split(' ')
    return ' '.join([x[0] + "/" + x[1] for x in zip(split, pos_tagger.tag(split))])


##### 9. Before each tweet is demarcation A=# in <> which occurs on its own line, where # is the numeric class of the tweet (0, 2, or 4).
def add_class(sentences, class_):
    prepend = "<A={}>".format(class_)
    return [prepend] + sentences


##### Perform steps 1 through 9 on a tweet
def preprocess(tweet, t_class, tagger):
    tweet = re.sub(r' +', ' ', tweet).strip()
    tweet = strip_html_tags(tweet)
    tweet = replace_html_codes(tweet)
    tweet = remove_urls(tweet)
    tweet = remove_hashtags(tweet)
    
    sentences = split_by_sentence(tweet)
    
    if len(tweet) > 0:
        sentences = [split_tokens(sentence) for sentence in sentences]
        sentences = [tag_sentence(sentence, tagger) for sentence in sentences]
        
    sentences = add_class(sentences, t_class)
    
    return sentences


##### Take in an input file name, and an output file, and a group ID.
# Negative group IDs use all samples available
def twtt(output_file, input_file_name='training.1600000.processed.noemoticon.csv', GID=-1):
    
    class_slices = []
    if (GID > 0):
        class_slices.append([GID * 5500,          (GID + 1) * 5500])
        class_slices.append([GID * 5500 + 800000, (GID + 1) * 5500 + 800000])
    else:
        class_slices.append([0, None])
    
    with open(input_file_name, 'r') as train_file:
        reader = csv.reader(train_file)
        tagger = nlp.NLPlib()
        
        for class_slice in class_slices:
            
            for row in itertools.islice(reader, *class_slice):
                
                tweet = row[5]
                t_class = int(row[0])
                
                try:
                    sentences = preprocess(tweet, t_class, tagger)
                except Exception as e:
                    print "Couldn't pre-process <<<" + tweet + ">>>, error is {}, skipping...".format(e)
                else:
                    for sentence in sentences:
                        output_file.write(sentence + '\n')


#python twtt.py /u/cs401/A1/tweets/training.1600000.processed.noemoticon.csv 42 train.twt

if __name__ == "__main__":

    if len(sys.argv) != 4:
        print "Enter 3 arguments: input file, group id, output file"
        sys.exit()

    input_file_name = sys.argv[1]
    group_id = int(sys.argv[2])
    output_file_name = sys.argv[3]

    with open(output_file_name, "w") as output_file:
        twtt(output_file, input_file_name, group_id)

