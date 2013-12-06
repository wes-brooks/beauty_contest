#! /bin/sh
for i in {1..10}
do
  mkdir -p ChtcRun/beautydata/$i
  echo "$i" > ChtcRun/beautydata/$i/jobid.txt
done
