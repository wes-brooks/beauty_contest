CHTCUTILS:=chtc-utils
export CHTCUTILS

jobdirs:
	cp -r ../R-libs beautydata/shared
	./make-job-dirs.sh 12 test
	./make-dag.sh

#r-libs:
#	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=../R-libs/pls_2.4-3.tar.gz,../R-libs/gbm_2.1.tar.gz
#	cp -r sl5-RLIBS.tar.gz beautydata/shared/
#	cp -r sl6-RLIBS.tar.gz beautydata/shared/
	
