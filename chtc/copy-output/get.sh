#! /bin/sh

SITE=$1
METHOD=$2

if [ "$SITE" == "hika" ]; then
  DATA="data/HK2013.2.MaxRowsTurb.csv"
elif [ "$SITE" == "kreher" ]; then
  DATA="data/KR2013.2.MaxRowsTurb.csv"
elif [ "$SITE" == "maslowski" ]; then
  DATA="data/MS2013.2.MaxRowsTurb.csv"
elif [ "$SITE" == "neshotah" ]; then
  DATA="data/NS2013.2.MaxRowsTurb.csv"
elif [ "$SITE" == "point" ]; then
  DATA="data/PointAll.csv"
elif [ "$SITE" == "redarrow" ]; then
  DATA="data/RA2013.2.MaxRowsTurb.csv"
elif [ "$SITE" == "thompson" ]; then
  DATA="data/TH2013.2.MaxRowsTurb.csv"
fi

echo $SITE
echo $METHOD
echo $DATA

((njobs = `wc -l < $DATA` - 1))

echo $njobs

for ((i=1; i<=$njobs; i++))
do
  echo $i
  ./copy-output.sh $i $SITE $METHOD
done


