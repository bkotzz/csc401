# ibmTest.py
# 
# This file tests all 11 classifiers using the NLClassifier IBM Service
# previously created using ibmTrain.py
# 
# TODO: You must fill out all of the functions in this file following 
# 		the specifications exactly. DO NOT modify the headers of any
#		functions. Doing so will cause your program to fail the autotester.
#
#		You may use whatever libraries you like (as long as they are available
#		on CDF). You may find json, request, or pycurl helpful.
#		You may also find it helpful to reuse some of your functions from ibmTrain.py.
#

import requests

import json
import urllib

import csv
import itertools

def get_classifier_ids(username,password):
	# Retrieves a list of classifier ids from a NLClassifier service 
	# an outputfile named ibmTrain#.csv (where # is n_lines_to_extract).
	#
	# Inputs: 
	# 	username - username for the NLClassifier to be used, as a string
	#
	# 	password - password for the NLClassifier to be used, as a string
	#
	#		
	# Returns:
	#	a list of classifier ids as strings
	#
	# Error Handling:
	#	This function should throw an exception if the classifiers call fails for any reason
	#
	
    url = "https://gateway.watsonplatform.net/natural-language-classifier/api/v1/classifiers"

    response = requests.get(url, data={}, auth=(username, password))
    
    if not response.ok:
        raise Exception("Classifier call failed.")
        
    id_list = []
    for classifier in response.json()['classifiers']:
        id_list.append(classifier['classifier_id'])
        
    return id_list
	

def assert_all_classifiers_are_available(username, password, classifier_id_list):
	# Asserts all classifiers in the classifier_id_list are 'Available' 
	#
	# Inputs: 
	# 	username - username for the NLClassifier to be used, as a string
	#
	# 	password - password for the NLClassifier to be used, as a string
	#
	#	classifier_id_list - a list of classifier ids as strings
	#		
	# Returns:
	#	None
	#
	# Error Handling:
	#	This function should throw an exception if the classifiers call fails for any reason AND 
	#	It should throw an error if any classifier is NOT 'Available'
	#
	
    url = "https://gateway.watsonplatform.net/natural-language-classifier/api/v1/classifiers/"

    for c_id in classifier_id_list:
        response = requests.get(url + c_id, data={}, auth=(username, password))
        if not response.ok:
            raise Exception("Classifier call failed.")
        if response.json()['status'] != "Available":
            # The term "throwing an error" is undefined in python,
            # so we will interpret that as raising an exception
            raise Exception("Classifier {} is {}, not Available".format(c_id, response.json()['status']))

    return

def classify_single_text(username,password,classifier_id,text):
	# Classifies a given text using a single classifier from an NLClassifier 
	# service
	#
	# Inputs: 
	# 	username - username for the NLClassifier to be used, as a string
	#
	# 	password - password for the NLClassifier to be used, as a string
	#
	#	classifier_id - a classifier id, as a string
	#		
	#	text - a string of text to be classified, not UTF-8 encoded
	#		ex. "Oh, look a tweet!"
	#
	# Returns:
	#	A "classification". Aka: 
	#	a dictionary containing the top_class and the confidences of all the possible classes 
	#	Format example:
	#		{'top_class': 'class_name',
	#		 'classes': [
	#					  {'class_name': 'myclass', 'confidence': 0.999} ,
	#					  {'class_name': 'myclass2', 'confidence': 0.001}
	#					]
	#		}
	#
	# Error Handling:
	#	This function should throw an exception if the classify call fails for any reason 
	#
	
    url = "https://gateway.watsonplatform.net/natural-language-classifier/api/v1/classifiers/"
    text = urllib.quote(text.encode('utf8'))
    url = url + classifier_id + "/classify?text=" + text
    
    response = requests.get(url, data={}, auth=(username, password))
    if not response.ok:
        raise Exception("Classifier call failed.")

    return response.json()


def classify_all_texts(username,password,input_csv_name):
        # Classifies all texts in an input csv file using all classifiers for a given NLClassifier
        # service.
        #
        # Inputs:
        #       username - username for the NLClassifier to be used, as a string
        #
        #       password - password for the NLClassifier to be used, as a string
        #      
        #       input_csv_name - full path and name of an input csv file in the 
        #              6 column format of the input test/training files
        #
        # Returns:
        #       A dictionary of lists of "classifications".
        #       Each dictionary key is the name of a classifier.
        #       Each dictionary value is a list of "classifications" where a
        #       "classification" is in the same format as returned by
        #       classify_single_text.
        #       Each element in the main dictionary is:
        #       A list of dictionaries, one for each text, in order of lines in the
        #       input file. Each element is a dictionary containing the top_class
        #       and the confidences of all the possible classes (ie the same
        #       format as returned by classify_single_text)
        #       Format example:
        #              {‘classifiername’:
        #                      [
        #                              {'top_class': 'class_name',
        #                              'classes': [
        #                                        {'class_name': 'myclass', 'confidence': 0.999} ,
        #                                         {'class_name': 'myclass2', 'confidence': 0.001}
        #                                          ]
        #                              },
        #                              {'top_class': 'class_name',
        #                              ...
        #                              }
        #                      ]
        #              , ‘classifiername2’:
        #                      [
        #                      …      
        #                      ]
        #              …
        #              }
        #
        # Error Handling:
        #       This function should throw an exception if the classify call fails for any reason
        #       or if the input csv file is of an improper format.
        #

        return_dict = {}
        
        id_list = get_classifier_ids(username, password)
        for c_id in id_list:
            return_dict[c_id] = []
        
        with open(input_csv_name, "r") as _input:
                reader = csv.reader(_input)
                for row in itertools.islice(reader, 0, None):
					# This statement will throw an IndexError or
					# an AttributeError if the CSV is of improper format,
					# and so doesn't require any manual exception raising
                    tweet = row[5].strip()
                    
                    for c_id in id_list:
						# Any exceptions from classify_single_text will
						# propagate, and so doesn't require manual raising
                        return_dict[c_id].append(classify_single_text(username, password, c_id, tweet))
        
        return return_dict


def compute_accuracy_of_single_classifier(classifier_dict, input_csv_file_name):
	# Given a list of "classifications" for a given classifier, compute the accuracy of this
	# classifier according to the input csv file
	#
	# Inputs:
	# 	classifier_dict - A list of "classifications". Aka:
	#		A list of dictionaries, one for each text, in order of lines in the 
	#		input file. Each element is a dictionary containing the top_class
	#		and the confidences of all the possible classes (ie the same
	#		format as returned by classify_single_text) 	
	# 		Format example:
	#			[
	#				{'top_class': 'class_name',
	#			 	 'classes': [
	#						  	{'class_name': 'myclass', 'confidence': 0.999} ,
	#						  	{'class_name': 'myclass2', 'confidence': 0.001}
	#							]
	#				},
	#				{'top_class': 'class_name',
	#				...
	#				}
	#			]
	#
	#	input_csv_name - full path and name of an input csv file in the  
	#		6 column format of the input test/training files
	#
	# Returns:
	#	The accuracy of the classifier, as a fraction between [0.0-1.0] (ie percentage/100). \
	#	See the handout for more info.
	#
	# Error Handling:
	# 	This function should throw an error if there is an issue with the 
	#	inputs.
	#
	
    num_correct = 0
    
    with open(input_csv_file_name, "r") as _input:
            reader = csv.reader(_input)
            for i, row in enumerate(itertools.islice(reader, 0, None)):
                tweet_class = int(row[0])

				# An exception will be thrown here by python if the
				# dictionary is not in proper form
                top_class = int(classifier_dict[i]['top_class'])
                num_correct += (tweet_class == top_class)
                
    return num_correct / float(len(classifier_dict))

def compute_average_confidence_of_single_classifier(classifier_dict, input_csv_file_name):
	# Given a list of "classifications" for a given classifier, compute the average 
	# confidence of this classifier wrt the selected class, according to the input
	# csv file. 
	#
	# Inputs:
	# 	classifier_dict - A list of "classifications". Aka:
	#		A list of dictionaries, one for each text, in order of lines in the 
	#		input file. Each element is a dictionary containing the top_class
	#		and the confidences of all the possible classes (ie the same
	#		format as returned by classify_single_text) 	
	# 		Format example:
	#			[
	#				{'top_class': 'class_name',
	#			 	 'classes': [
	#						  	{'class_name': 'myclass', 'confidence': 0.999} ,
	#						  	{'class_name': 'myclass2', 'confidence': 0.001}
	#							]
	#				},
	#				{'top_class': 'class_name',
	#				...
	#				}
	#			]
	#
	#	input_csv_name - full path and name of an input csv file in the  
	#		6 column format of the input test/training files
	#
	# Returns:
	#	The average confidence of the classifier, as a number between [0.0-1.0]
	#	See the handout for more info.
	#
	# Error Handling:
	# 	This function should throw an error if there is an issue with the 
	#	inputs.
	#
	
    # Sums for [incorrect, correct] guesses
    confidence_sums = [0, 0]
    # Number of [incorrect, correct] guesses
    total_number_seen = [0, 0]
    
    with open(input_csv_file_name, "r") as _input:
            reader = csv.reader(_input)
            for i, row in enumerate(itertools.islice(reader, 0, None)):
                tweet_class = int(row[0])
                
				# An exception will be thrown here by python if the
				# dictionary is not in proper form
				#
				# The 0th class listed is the most confident class
                most_conf_class = classifier_dict[i]["classes"][0]
                is_classification_correct = int(most_conf_class["class_name"]) == tweet_class
                
				# If the prediction is incorrect, we sum the confidence rating with the
				# other incorrect guesses, and if the prediction is correct, we sum the
				# confidence rating with the other correct guesses
				#
				# We keep track of how many confidence ratings are in each sum, so we can 
				# take an average later on
                confidence_sums[is_classification_correct] += most_conf_class["confidence"]
                total_number_seen[is_classification_correct] += 1
    
    confidence_sums[0] /= float(total_number_seen[0])
    confidence_sums[1] /= float(total_number_seen[1])
    
    return confidence_sums


if __name__ == "__main__":

	input_test_data = '/u/cs401/A1/tweets/testdata.manualSUBSET.2009.06.14.csv'
	
	#STEP 1: Ensure all 11 classifiers are ready for testing
	try:
	    assert_all_classifiers_are_available(username, password, get_classifier_ids(username, password))
	except Exception as e:
	    print "Error({0}): {1}".format(e.errno, e.strerror)

	#STEP 2: Test the test data on all classifiers
	classd_dict = classify_all_texts(username, password, input_test_data)
	
	#STEP 3: Compute the accuracy for each classifier
	#STEP 4: Compute the confidence of each class for each classifier
	
	per_classifier_acc = []
	per_classifier_confidence = [] # pairs per classifier (one for each class)
	for c_id in get_classifier_ids(username, password):
	    per_classifier_list = classd_dict[c_id]
	    
		print "Classifier: ", c_id
		
	    acc = compute_accuracy_of_single_classifier(per_classifier_list, input_test_data)
	    per_classifier_acc.append(acc)
	    
		print "Accuracy: ", acc
		
	    conf = compute_average_confidence_of_single_classifier(per_classifier_list, input_test_data)
	    per_classifier_confidence.append(conf)

		print "Confidence: ", conf
	
	
