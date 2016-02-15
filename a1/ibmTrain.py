# ibmTrain.py
# 
# This file produces 11 classifiers using the NLClassifier IBM Service
# 
# TODO: You must fill out all of the functions in this file following 
# 		the specifications exactly. DO NOT modify the headers of any
#		functions. Doing so will cause your program to fail the autotester.
#
#		You may use whatever libraries you like (as long as they are available
#		on CDF). You may find json, request, or pycurl helpful.
#

###IMPORTS###################################
#TODO: add necessary imports
import csv
import itertools

import StringIO
import requests

import json

###HELPER FUNCTIONS##########################
def process_tweet(tweet):
	"""
	As per the documentation here, https://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/doc/nl-classifier/data_format.shtml
	We want to:
	1) Enclose tweets in double quotes if they contain a comma
	2) Enclose tweets in double quotes if they contain a quotation mark
	3) Escape quotation marks with double quotation marks (excluding the enclosing ones)
	"""
    if tweet.find('"') != -1:
        tweet = tweet.replace('"', '""') #Escape with double quotes
        tweet = '"' + tweet + '"' #Enclose tweet
    elif tweet.find(',') != -1:
        tweet = '"' + tweet + '"' #Enclose tweet
    
    return tweet
	
def convert_training_csv_to_watson_csv_format(input_csv_name, group_id, output_csv_name): 
	# Converts an existing training csv file. The output file should
	# contain only the 11,000 lines of your group's specific training set.
	#
	# Inputs:
	#	input_csv - a string containing the name of the original csv file
	#		ex. "my_file.csv"
	#
	#	output_csv - a string containing the name of the output csv file
	#		ex. "my_output_file.csv"
	#
	# Returns:
	#	None
	
    class_zero_data = [group_id * 5500, (group_id + 1) * 5500]
    class_four_data = [group_id * 5500 + 800000, (group_id + 1) * 5500 + 800000]

    with open(input_csv_name, 'r') as _input:
        reader = csv.reader(_input)
        
        with open(output_csv_name, 'w') as _output:
            for row in itertools.islice(reader, *class_zero_data):
                tweet = process_tweet(row[5].strip())
                _output.write(tweet + "," + row[0] + '\n')
            for row in itertools.islice(reader, *class_four_data):
                tweet = process_tweet(row[5].strip())
                _output.write(tweet + "," + row[0] + '\n')

	return
	
def extract_subset_from_csv_file(input_csv_file, n_lines_to_extract, output_file_prefix='ibmTrain'):
	# Extracts n_lines_to_extract lines from a given csv file and writes them to 
	# an outputfile named ibmTrain#.csv (where # is n_lines_to_extract).
	#
	# Inputs: 
	#	input_csv - a string containing the name of the original csv file from which
	#		a subset of lines will be extracted
	#		ex. "my_file.csv"
	#	
	#	n_lines_to_extract - the number of lines to extract from the csv_file, as an integer
	#		ex. 500
	#
	#	output_file_prefix - a prefix for the output csv file. If unspecified, output files 
	#		are named 'ibmTrain#.csv', where # is the input parameter n_lines_to_extract.
	#		The csv must be in the "watson" 2-column format.
	#		
	# Returns:
	#	None
	
	# We want n_lines_to_extract from each class, so we keep a counter for each
	# [Class 0 counter, Class 4 counter]
    counters = [0, 0]
    
    with open(input_csv_file, 'r') as _input:
        with open(output_file_prefix + str(n_lines_to_extract) + ".csv", 'w') as _output:
            for line in _input:
				
				# The last character in the line is '\n', so the second last is the class
                _class = int(line[-2])
				
				# This will index into the appropriate counter
				# Index 0  for class 0, Index 1 for class 4
                if counters[_class / 4] < n_lines_to_extract:
                    _output.write(line)
                    counters[_class / 4] += 1

	return
	
def create_classifier(username, password, n, input_file_prefix='ibmTrain'):
	# Creates a classifier using the NLClassifier service specified with username and password.
	# Training_data for the classifier provided using an existing csv file named
	# ibmTrain#.csv, where # is the input parameter n.
	#
	# Inputs:
	# 	username - username for the NLClassifier to be used, as a string
	#
	# 	password - password for the NLClassifier to be used, as a string
	#
	#	n - identification number for the input_file, as an integer
	#		ex. 500
	#
	#	input_file_prefix - a prefix for the input csv file, as a string.
	#		If unspecified data will be collected from an existing csv file 
	#		named 'ibmTrain#.csv', where # is the input parameter n.
	#		The csv must be in the "watson" 2-column format.
	#
	# Returns:
	# 	A dictionary containing the response code of the classifier call, will all the fields 
	#	specified at
	#	http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/natural-language-classifier/api/v1/?curl#create_classifier
	#   
	#
	# Error Handling:
	#	This function should throw an exception if the create classifier call fails for any reason
	#	or if the input csv file does not exist or cannot be read.
	#
	
    url = "https://gateway.watsonplatform.net/natural-language-classifier/api/v1/classifiers"
    training_metadata = {'language': 'en', 'name': 'Classifier {}'.format(n)}
    data = {'training_metadata': json.dumps(training_metadata)}
    
    # Open will throw an IOError Exception if the input file doesn't exist or can't be read,
	# so no need for manual exception throwing
    with open('{}{}.csv'.format(input_file_prefix, n), 'r') as input_file:
        files = [('training_data', input_file)]
        response = requests.post(url, auth=(username, password), data=data, files=files)
        
    if not response.ok:
        raise Exception("Error creating classifier")
    
    return response.json()
	
if __name__ == "__main__":
	
	### STEP 1: Convert csv file into two-field watson format
	input_csv_name = '/u/cs401/A1/tweets/training.1600000.processed.noemoticon.csv'
	
	#DO NOT CHANGE THE NAME OF THIS FILE
	output_csv_name 'training_11000_watson_style.csv'
	
	convert_training_csv_to_watson_csv_format(input_csv_name, output_csv_name)
	
	
	### STEP 2: Save 11 subsets in the new format into ibmTrain#.csv files
	
	#TODO: extract all 11 subsets and write the 11 new ibmTrain#.csv files
	#
	# you should make use of the following function call:
	#
	# n_lines_to_extract = 500
	# extract_subset_from_csv_file(input_csv,n_lines_to_extract)
	
	for n_lines_to_extract in [500, 2500, 5000]:
    	extract_subset_from_csv_file(output_csv_name, n_lines_to_extract)
	
	### STEP 3: Create the classifiers using Watson
	
	#TODO: Create all 11 classifiers using the csv files of the subsets produced in 
	# STEP 2
	# 
	#
	# you should make use of the following function call

	username = "2bd0e6c7-5784-4967-860c-a9778754fdee"
	password = "rFs4Solusscl"

	for n in [500, 2500, 5000]:
	    create_classifier(username, password, n)
		