CHTCUTILS:=chtc-utils
export CHTCUTILS

submit: #beautyoutput/mydag.dag
	./submit.sh

jobdirs:
	find 'beautydata2' -wholename 'beautydata2/shared' -prune -o -not -name 'beautydata2' | xargs rm -rf 
	rm -rf beautyoutput2
	rm -rf beautydata2
	mkdir beautydata2
	mkdir beautydata2/shared
	cp -rf ../R-libs beautydata2/shared/R-libs
	cp -rf ../data/MaxRowsTurb beautydata2/shared/data
	cp -rf ../R/* beautydata2/shared/
	cp -rf ../seeds.txt beautydata2/shared
	./make-job-dirs.sh 98 dryrun
	./mkdag \
	  --cmdtorun=beauty.r \
	  --data=beautydata2 \
	  --dagdir=beautyoutput2 \
	  --pattern=result.txt \
	  --type=R \
	  --version=sl5-R-2.15.3

#r-libs:
#	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=../R-libs/pls_2.4-3.tar.gz,../R-libs/gbm_2.1.tar.gz
#	cp -r sl5-RLIBS.tar.gz beautydata/shared/
#	cp -r sl6-RLIBS.tar.gz beautydata/shared/
	
