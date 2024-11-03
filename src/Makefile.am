AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = iTgLegacy
iTgLegacy_SOURCES = \
		AppDelegate.m \
		RootViewController.m \
		main.m

iTgLegacy_CFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -fobjc-arc

iTgLegacy_LDFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook

iTgLegacy_LDADD = \
			-lssl -lcurl -L../libs -ltg -L../libtg/tg/.libs

bin_SCRIPTS = iTgLegacy.ipa
CLEANiFILES = $(bin_SCRIPTS)
EXTRA_DIST  = iTgLegacy.ipa

_dir:
	mkdir -p iTgLegacy.app

_plist:
	sed -e 's/VERSION/${PACKAGE_VERSION}/g' Info.plist > iTgLegacy.app/Info.plist

_images:
	cp -f ../images/Icon*.png iTgLegacy.app/.
#cp -f ../images/Directory*.png iTgLegacy.app/.

iTgLegacy.app: iTgLegacy _dir _plist _images
	cp -f iTgLegacy iTgLegacy.app/. 
	cp -r ../libs iTgLegacy.app/.
	cp -f libs/tg/.libs/*.dylib iTgLegacy/libs/.
	cd iTgLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iTgLegacy; \
	cd libs; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libcrypto.dylib;

iTgLegacy.ipa: iTgLegacy.app
	mkdir Payload
	cp -r iTgLegacy.app Payload/.
	${ZIP} -r iTgLegacy.ipa Payload iTunesArtwork iTunesMetadata.plist
	rm -rf Payload

clean-local:
	rm -r iTgLegacy.app
	rm -r iTgLegacy.ipa

install:
#do nothing
