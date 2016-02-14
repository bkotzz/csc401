#!/bin/bash

start=500
end=5500

for (( i=$start; i<=$end; i+=500 ))
do
    java -cp WEKA/weka.jar weka.classifiers.bayes.NaiveBayes -t datafiles/train_group_$i.arff -T datafiles/test.arff -o > outputs/part3_2/$i.txt  
done

mv outputs/part3_2/500.txt outputs/part3_2/0500.txt 

grep Correctly ./outputs/part3_2/* | sed -n 'g;n;p' | sed 's/.txt:Correctly Classified Instances//' | sed 's/.\/outputs\/part3_2\///' > outputs/part3_2/3.2output.txt

rm outputs/part3_2/*00.txt
