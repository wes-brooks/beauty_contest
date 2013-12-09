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
	cp -rf ../R-libs beautydata/shared/R-libs
	cp -rf ../data/MaxRowsTurb beautydata/shared/data
	cp -rf ../R/* beautydata/shared/
	cp -rf ../seeds.txt beautydata/shared
	./make-job-dirs.sh 112 dryrun
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
	
