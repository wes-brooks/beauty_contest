#! /bin/bash

for ((i=1; i<=$1; i++))
do
  mkdir -p beautydata-$3-$4/$i
  echo "loo\n$2\n$3\n$4\n$i" > beautydata-$3-$4/$i/params.txt
done


for ((i=1; i<=4; i++))
do
  ((k = $i + $1))
  echo $k
  mkdir -p beautydata-$3-$4/$k
  echo "annual\n$2\n$3\n$4\n$i" > beautydata-$3-$4/$k/params.txt
done
