#! /bin/sh

sites=( hika maslowski kreher thompson point neshotah redarrow )
methods=( pls gbm gbmcv galogistic-unweighted galogistic-weighted adalasso-unweighted adalasso-unweighted-select adalasso-weighted adalasso-weighted-select galm adapt adapt-select spls spls-select )

for site in ${sites[@]}
do
  for method in ${methods[@]}
  do
    make atomic SITE=$site METHOD=$method
  done
done