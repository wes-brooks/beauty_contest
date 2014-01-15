for method in pls gbm gbmcv galogistic-unweighted adalasso-unweighted-select adalasso-weighted adalasso-weighted-select galm adapt adapt-select spls spls-select
do
  for site in hika kreher maslowski neshotah point redarrow thompson
  do
    make atomic SITE=site METHOD=method
  done
done
