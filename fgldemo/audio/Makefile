# Property of Four Js*
# (c) Copyright Four Js 2017, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these
# samples are accurate and suitable for your purposes. Their inclusion is
# purely for information purposes only.

#calling make without parameters simply creates an GMI executable for the simulator
#use "make gmi.install" to install on the simulator or device depending on the TARGET

BUNDLE_IDENTIFIER   = com.4js.audio
APPNAME             = Audio
TARGET              = simulator
MODE                = debug
BUILD_FGL           = yes
FGLLDPATH           = ../../lib
IDENTITY='(59W7RY75ZU)'
PROVISIONING_PROFILE=/Users/leo/Library/MobileDevice/Provisioning\ Profiles/4js_wildcard
FORMS   = $(patsubst %.per, %.42f, $(wildcard *.per))


#include the generic Makefile-gmi with a lot of targets
ifndef GMIDIR
GMIDIR=$(FGLDIR)
endif
MAKEFILE_GMI=$(shell GMIDIR="$(GMIDIR)";echo $${GMIDIR// /\\ })/lib/Makefile-gmi
-include $(MAKEFILE_GMI)

%.42m: %.4gl 
	FGLLDPATH=$(FGLLDPATH) fglcomp -M -W all $<

USER_EXTENSION_LIBS = $(GMIDIR)/lib/cordova/CDVMedia.a $(GMIDIR)/lib/cordova/CDVFile.a $(GMIDIR)/lib/cordova/GeneroTestPlugin.a


main.42m: $(USER_EXTENSION_LIBS) main.42f 

run: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main

runfile: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main animals115.mp3

runhttp: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main https://cordova.apache.org/downloads/BlueZedEx.mp3

runstream: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main http://c22033-l.i.core.cdn.streamfarm.net/22033mdr/live/3087mdr_figaro/ch_classic_128.mp3


clean::
	rm -f *.sch *.dbs *.42*

distclean::
