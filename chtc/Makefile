CHTCUTILS := chtc-utils
export CHTCUTILS

SITE := NULL
METHOD := NULL

ifeq ($(SITE), hika)
nobs := 167
endif

ifeq ($(SITE), kreher)
nobs := 132
endif

ifeq ($(SITE), maslowski)
nobs := 134
endif

ifeq ($(SITE), neshotah)
nobs := 163
endif

ifeq ($(SITE), point)
nobs := 191
endif

ifeq ($(SITE), redarrow)
nobs := 174
endif

ifeq ($(SITE), thompson)
nobs := 143
endif


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
	./make-job-dirs-atomic.sh $(value nobs) beautyrun $(SITE) $(METHOD)
	./mkdag \
	  --cmdtorun=R/beauty-atomic.r \
	  --data=beautydata-$(SITE)-$(METHOD) \
	  --dagdir=beautyoutput-$(SITE)-$(METHOD) \
	  --pattern=result \
	  --type=R \
	  --version=sl5-R-2.15.3
	./submit-atomic.sh $(SITE) $(METHOD)
