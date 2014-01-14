CHTCUTILS := chtc-utils
export CHTCUTILS

SITE := NULL
METHOD := NULL

ifeq ($(SITE), hika)
DATA := ../data/MaxRowsTurb/HK2013.2.MaxRowsTurb.csv
endif

ifeq ($(SITE), kreher)
DATA := ../data/MaxRowsTurb/KR2013.2.MaxRowsTurb.csv
endif

ifeq ($(SITE), maslowski)
DATA := ../data/MaxRowsTurb/MS2013.2.MaxRowsTurb.csv
endif

ifeq ($(SITE), neshotah)
DATA := ../data/MaxRowsTurb/NS2013.2.MaxRowsTurb.csv
endif

ifeq ($(SITE), point)
DATA := ../data/MaxRowsTurb/PointAll.csv
endif

ifeq ($(SITE), redarrow)
DATA := ../data/MaxRowsTurb/RA2013.2.MaxRowsTurb.csv
endif

ifeq ($(SITE), thompson)
DATA := ../data/MaxRowsTurb/TH2013.2.MaxRowsTurb.csv
endif


@echo $(value DATA)

njobs := ((`wc -l < $(value DATA)` - 1))

@echo $(value njobs)

submit-atomic:
	./submit-atomic.sh $(SITE) $(METHOD)


jobdirs-atomic:
	find 'beautydata-$(SITE)-$(METHOD)' -wholename 'beautydata-$(SITE)-$(METHOD)/shared' -prune -o -not -name 'beautydata-$(SITE)-$(METHOD)' | xargs rm -rf 
	rm -rf beautyoutput-$(SITE)-$(METHOD)
	rm -rf beautydata-$(SITE)-$(METHOD)
	mkdir beautydata-$(SITE)-$(METHOD)
	mkdir beautydata-$(SITE)-$(METHOD)/shared
	cp -rf ../R-libs beautydata-$(SITE)-$(METHOD)/shared/R-libs
	cp -rf ../data beautydata-$(SITE)-$(METHOD)/shared/data
	cp -rf ../R/* beautydata-$(SITE)-$(METHOD)/shared/
	cp -rf ../seeds.txt beautydata-$(SITE)-$(METHOD)/shared
	./make-job-dirs-atomic.sh $(njobs) beautyrun $(SITE) $(METHOD)
	./mkdag \
	  --cmdtorun=beauty-atomic.r \
	  --data=beautydata-$(SITE)-$(METHOD) \
	  --dagdir=beautyoutput-$(SITE)-$(METHOD) \
	  --pattern=result.txt \
	  --type=R \
	  --version=sl5-R-2.15.3


submit:
	./submit.sh


jobdirs:
	find 'beautydata' -wholename 'beautydata/shared' -prune -o -not -name 'beautydata' | xargs rm -rf 
	rm -rf beautyoutput
	rm -rf beautydata
	mkdir beautydata)
	mkdir beautydata/shared
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

r-libs:
	rm -f *.tar.gz
	cp -rf ../R-src/* ./
	chtc_buildRlibs --rversion=sl5-R-2.15.3 --rlibs=lars_1.2.tar.gz,pls_2.4-3.tar.gz,spls_2.2-1.tar.gz,gbm_2.1.tar.gz,glmnet_1.9-5.tar.gz,adalars.tar.gz,adalasso.tar.gz,galm.tar.gz,galogistic.tar.gz,spls.wrap.tar.gz
