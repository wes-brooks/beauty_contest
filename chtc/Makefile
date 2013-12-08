CHTCUTILS:=chtc-utils
export CHTCUTILS

submit: #beautyoutput/mydag.dag
	./submit.sh

jobdirs:
	rm -rf beautyoutput
	cp -rf ../R-libs beautydata/shared
	cp -rf ../data/MaxRowsTurb beautydata/shared/data
	cp -rf ../R beautydata/shared
	cp -rf ../seeds.txt beautydata/shared
	./make-job-dirs.sh 12 test
	./mkdag \
	  --cmdtorun=R/beauty.r \
	  --data=beautydata \
	  --dagdir=beautyoutput \
	  --pattern=annual.out \
	  --type=R \
	  --version=sl5-R-2.15.3

#r-libs:
#	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=../R-libs/pls_2.4-3.tar.gz,../R-libs/gbm_2.1.tar.gz
#	cp -r sl5-RLIBS.tar.gz beautydata/shared/
#	cp -r sl6-RLIBS.tar.gz beautydata/shared/
	
