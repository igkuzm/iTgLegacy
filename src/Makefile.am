AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = iTgLegacy
iTgLegacy_SOURCES = \
		AppDelegate.m \
		main.m

iTgLegacy_CXXFLAGS = \
		-std=gnu++11

iTgLegacy_OBJCFLAGS = \
	-Iogg -Iogg/ogg -I../opus/include -I../opus/include/opus -fobjc-arc -I../libtg2/essential

iTgLegacy_CFLAGS = \
			-framework UIKit -framework CoreData -framework Foundation -framework QuickLook -framework SystemConfiguration -framework CoreGraphics -framework QuartzCore -framework MediaPlayer -framework AVFoundation -framework AudioToolbox -framework CoreMedia -framework AddressBook -framework AddressBookUI -framework MobileCoreServices -framework CoreLocation -framework MapKit -Iogg -Iogg/ogg -I../opus/include -I../opus/include/opus -I../libopusenc/include -I../libopusenc/src

iTgLegacy_LDFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -framework SystemConfiguration -framework CoreGraphics -framework QuartzCore -framework MediaPlayer -framework AVFoundation -framework AudioToolbox -framework CoreMedia -framework AddressBook -framework AddressBookUI -framework MobileCoreServices -framework CoreLocation -framework MapKit -framework CoreData -L../opus/lib -lopus

iTgLegacy_LDADD = \
			-lssl -lcurl -L../libs -ltg -L../libtg2/tg/.libs -L../opus/lib -lopus ../libtg2objc/*.o

bin_SCRIPTS = iTgLegacy.ipa
CLEANiFILES = $(bin_SCRIPTS)
EXTRA_DIST  = iTgLegacy.ipa

_dir:
	mkdir -p iTgLegacy.app

_plist:
	sed -e 's/PACKAGE_VERSION/${PACKAGE_VERSION}/g' Info.plist | \
	sed -e 's/PRODUCT_NAME/${PACKAGE_NAME}/g' - | \
	sed -e 's/EXECUTABLE_NAME/${PACKAGE_NAME}/g' - | \
	sed -e 's/TELEGRAPH_BUNDLE_ID/kuzm.ig.iTgLegacy/g' - > iTgLegacy.app/Info.plist

_images:
	cp -f ../images/*.png iTgLegacy.app/.
	cp -f ../images/*.jpg iTgLegacy.app/.
	cp -f ../sounds/*.m4a iTgLegacy.app/.
#cp -f BubbleView/images/*.png iTgLegacy.app/.
	cp -f LaunchScreen.nib iTgLegacy.app/.

iTgLegacy.app: iTgLegacy _dir _plist _images
	cp -f ../provision_profiles/iTgLegacydevelopment.mobileprovision telegram.mobileprovision 
	cp -f ../provision_profiles/iTgLegacydevelopment.mobileprovision iTgLegacy.app/telegram.mobileprovision 
	cp -f .libs/iTgLegacy iTgLegacy.app/. 
	cp -f ../libtg2/.libs/tgtest iTgLegacy.app/. 
	cp -f ../libtg2/pub.pkcs iTgLegacy.app/. 
	cp -r ../libs iTgLegacy.app/.
	cp -f ../libtg2/tg/.libs/*.dylib iTgLegacy.app/libs/.
	cd iTgLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib tgtest; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib tgtest; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib tgtest; \
		$(INSTALL_NAME_TOOL) -change /usr/local/lib/libtg.0.dylib @executable_path/libs/libtg.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/local/lib/libtg.0.dylib @executable_path/libs/libtg.dylib tgtest; \
	cd libs; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libtg.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib libtg.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libcrypto.dylib;

iTgLegacy.ipa: iTgLegacy.app
	rm -fr app
	mkdir -p app/Payload
	cp -r iTgLegacy.app app/Payload/.
	zsign -m telegram.mobileprovision -k ../certificates/app.key -p "ig.kuzm@gmail.com" -e iTgLegacy.xcent app -o iTgLegacy.ipa
	rm -fr app
	rm -fr iTgLegacy.app
#${ZIP} -r iTgLegacy.ipa Payload iTunesArtwork iTunesMetadata.plist
#rm -rf Payload

clean-local:
	rm -r iTgLegacy.app
	rm -r iTgLegacy.ipa

install:
#do nothing
