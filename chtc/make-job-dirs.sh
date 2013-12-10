#! /bin/sh

for ((i=1; i<=$1; i++))
do
  mkdir -p beautydata/$i
  echo "$2\n$i" > beautydata/$i/jobid.txt
done
