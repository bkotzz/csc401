#!/bin/bash

start=0
end=10

for (( i=$start; i<$end; i++ ))
do
#   cat datafiles/cv/train_header.arff datafiles/cv/train_[^$i].arff >> datafiles/cv/train_merged_$i.arff 
#   cat datafiles/cv/train_header.arff datafiles/cv/train_$i.arff >> datafiles/cv/train_$i_.arff
#   mv datafiles/cv/train_$i_.arff datafiles/cv/train_$i.arff
    java -cp WEKA/weka.jar weka.classifiers.bayes.NaiveBayes -t datafiles/cv/train_merged_$i.arff -T datafiles/cv/train_$i.arff -o > outputs/part3_4/$i.txt
done


