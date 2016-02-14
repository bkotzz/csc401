#!/bin/bash

prefix=""
output_file=${prefix}3.4output.txt

start=0
end=10

for ((i=$start; i<$end; i++))
do
    echo "

Partition $i:" >> $output_file
    tail -n 5 $prefix$i.txt >> $output_file
    output=`tail -n 3 $prefix$i.txt`
    output_arr=($output)
    aa=${output_arr[0]}
    ab=${output_arr[1]}
    ba=${output_arr[6]}
    bb=${output_arr[7]}

    acc=$(awk -v aa=$aa -v bb=$bb -v ab=$ab -v ba=$ba 'BEGIN { print (aa + bb) / (aa + bb + ab + ba) }')
    prec_a=$(awk -v aa=$aa -v ba=$ba 'BEGIN { print aa / (aa + ba) }')
    prec_b=$(awk -v bb=$bb -v ab=$ab 'BEGIN { print bb / (bb + ab) }')
    rec_a=$(awk -v aa=$aa -v ab=$ab 'BEGIN { print aa / (aa + ab) }')
    rec_b=$(awk -v bb=$bb -v ba=$ba 'BEGIN { print bb / (bb + ba) }')

    echo Accuracy - $acc % >> $output_file
    echo "Precision - A: $prec_a %
            B: $prec_b %" >> $output_file
    echo "Recall - A: $rec_a %
         B: $rec_b %" >> $output_file
    echo $acc,
done
