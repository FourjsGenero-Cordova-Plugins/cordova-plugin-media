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
DEVICE              = simulator
MODE                = debug
BUILD_FGL           = no
IDENTITY='(59W7RY75ZU)'
PROVISIONING_PROFILE=/Users/leo/Library/MobileDevice/Provisioning\ Profiles/4js_wildcard
FORMS   = $(patsubst %.per, %.42f, $(wildcard *.per))

MEDIA=cordova-plugin-media
# in case you build the demo when having the plugin checked out of github 
# then we use the fglcvdMedia.42m in the fgl dir of the plugin
ifneq ($(wildcard ../../fgldemo),)
  MEDIA=$(CURDIR)/../..
  FGLLDPATH=../../fgl
endif

MODULES  = $(patsubst %.4gl, %.42m, $(wildcard *.4gl))
FORMS    = $(patsubst %.per, %.42f, $(wildcard *.per))

%.42m: %.4gl
	FGLLDPATH=$(FGLLDPATH) fglcomp -M --resolve-calls $*

%.42f: %.per
	fglform -M $*

all:: $(MODULES) $(FORMS)

main.42m: main.42f 

run: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main

runfile: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main animals115.mp3

runhttp: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main https://cordova.apache.org/downloads/BlueZedEx.mp3

runstream: main.42m
	FGLLDPATH=$(FGLLDPATH) fglrun main http://c22033-l.i.core.cdn.streamfarm.net/22033mdr/live/3087mdr_figaro/ch_classic_128.mp3

gmi.install: all
	gmibuildtool --app-name=$(APPNAME) --bundle-id=$(BUNDLE_IDENTIFIER) --provisioning=$(PROVISIONING_PROFILE) --certificate=$(IDENTITY) --device=$(DEVICE) --mode=$(MODE) --install=yes --build-cordova=$(MEDIA),GeneroTestPlugin

clean::
	rm -f *.sch *.dbs *.42*
	rm -rf build bin distbin
	rm -f cordovamap.txt gmi/*.a gmi/link_flags.sh *.4pwvs *.4pwdb
