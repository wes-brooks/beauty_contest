#! /bin/sh

for ((i=1; i<=$1; i++))
do
  mkdir -p beautydata2/$i
  echo "$2\n$i" > beautydata2/$i/jobid.txt
done
