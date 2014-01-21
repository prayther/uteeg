#!/bin/bash -x
 
 
###Read first line to get headings
#read first_line < sampleInput.csv
read first_line < $1
 
 
#################Start reading headings into array##############################
a=0
 
###Read number of headings in line by getting number of field separators(which here is ,)###
headings=`echo $first_line | awk -F, {'print NF'}`
 
###Read number of lines by wc -l###
#lines=`cat test.csv | wc -l`
lines=`cat $1 | wc -l`
 
while [ $a -lt $headings ]
do
#Read ($a + 1) value into x as awk prints columns in 1-n order
#Read each column element into headings array
head_array[$a]=$(echo $first_line | awk -v x=$(($a + 1)) -F"," '{print $x}')
a=$(($a+1))
done
####################End reading headings into array##############################
 
 
c=0
echo "{"
while [ $c -lt $lines ] #Loop on number of lines
do
read each_line
if [ $c -ne 0 ] #$c = 0 is the headings line.skip it
then
d=0
echo -n "{"
while [ $d -lt $headings ] #Loop on number of headings
do
 
#Same logic as reading each heading.Read each element to print it with its heading
each_element=$(echo $each_line | awk -v y=$(($d + 1)) -F"," '{print $y}')
 
if [ $d -ne $(($headings-1)) ] #print comma only if its not the last element
then
echo -n ${head_array[$d]}":"$each_element","
else
echo -n ${head_array[$d]}":"$each_element
fi
d=$(($d+1))
done
if [ $c -eq $(($lines-1)) ] #skip , for the last block
then
echo "}"
else
echo "},"
fi
fi
c=$(($c+1))
#done < test.csv
done < $1
echo "}"
