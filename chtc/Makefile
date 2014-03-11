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

njobs := $(shell echo $$((`wc -l < $(value DATA)` - 1)))


atomic:
	find 'beautydata-$(SITE)-$(METHOD)' -wholename 'beautydata-$(SITE)-$(METHOD)/shared' \
	  -prune -o -not -name 'beautydata-$(SITE)-$(METHOD)' | xargs rm -rf 
	rm -rf beautyoutput-$(SITE)-$(METHOD)
	rm -rf beautydata-$(SITE)-$(METHOD)
	mkdir beautydata-$(SITE)-$(METHOD)
	mkdir beautydata-$(SITE)-$(METHOD)/shared
	cp -rf ../R-libs beautydata-$(SITE)-$(METHOD)/shared/R-libs
	cp -rf ../data beautydata-$(SITE)-$(METHOD)/shared/data
	cp -rf ../R beautydata-$(SITE)-$(METHOD)/shared/R
	cp -rf ../seeds.txt beautydata-$(SITE)-$(METHOD)/shared
	./make-job-dirs-atomic.sh $(value njobs) beautyrun $(SITE) $(METHOD)
	./mkdag \
	  --cmdtorun=R/beauty-atomic.r \
	  --data=beautydata-$(SITE)-$(METHOD) \
	  --dagdir=beautyoutput-$(SITE)-$(METHOD) \
	  --pattern=result \
	  --type=R \
	  --version=sl5-R-2.15.3
	./submit-atomic.sh $(SITE) $(METHOD)
