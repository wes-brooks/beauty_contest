CHTCUTILS:=chtc-utils
export CHTCUTILS

submit: #beautyoutput/mydag.dag
	./submit.sh

jobdirs:
	find 'beautydata' -wholename 'beautydata/shared' -prune -o -not -name 'beautydata' | xargs rm -rf 
	rm -rf beautyoutput
	rm -rf beautydata
	mkdir beautydata
	mkdir beautydata/shared
	rm -f *.tar.gz
	cp -rf ../R-src/* ./
	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=bitops_1.0-6.tar.gz,RCurl_1.95-4.1.tar.gz,stringr_0.6.2.tar.gz,digest_0.6.4.tar.gz,memoise_0.1.tar.gz,whisker_0.3-2.tar.gz,evaluate_0.5.1.tar.gz,httr_0.2.tar.gz,devtools_1.4.1.tar.gz
	cp -rf ../R-libs beautydata/shared/R-libs
	cp -rf ../data beautydata/shared/data
	cp -rf ../R/* beautydata/shared/
	cp -rf ../seeds.txt beautydata/shared
	./make-job-dirs.sh 98 beautyrun
	./mkdag \
	  --cmdtorun=beauty.r \
	  --data=beautydata \
	  --dagdir=beautyoutput \
	  --pattern=result.txt \
	  --type=R \
	  --version=sl5-R-2.15.3

#r-libs:
#	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=../R-libs/pls_2.4-3.tar.gz,../R-libs/gbm_2.1.tar.gz
#	cp -r sl5-RLIBS.tar.gz beautydata/shared/
#	cp -r sl6-RLIBS.tar.gz beautydata/shared/
	
