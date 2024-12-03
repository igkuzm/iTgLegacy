AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = iTgLegacy
iTgLegacy_SOURCES = \
		AppDelegate.m \
		RootViewController.m \
		ChatsViewController.m \
		ConfigViewController.m \
		TextEditViewController.m \
		Reachability.m \
		TGDialog.m \
		BubbleView/NSBubbleData.m \
		BubbleView/UIBubbleHeaderTableViewCell.m \
		BubbleView/UIBubbleTableView.m \
		BubbleView/UIBubbleTableViewCell.m \
		BubbleView/UIBubbleTypingTableViewCell.m \
		APLSlideMenu/APLSlideMenuSegue.m \
		APLSlideMenu/APLSlideMenuViewController.m \
		SVProgressHUD/SVProgressHUD.m \
		TRMalleableFrameView/TRMalleableFrameView.m \
		Base64/Base64.m \
		UIImage+Utils/UIImage+Utils.m \
		RequestFactory/CaRequestFactory.m \
		ChatViewController.m \
		main.m

iTgLegacy_CFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -framework SystemConfiguration -framework CoreGraphics -framework QuartzCore -fobjc-arc

iTgLegacy_LDFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -framework SystemConfiguration -framework CoreGraphics -framework QuartzCore -fobjc-arc

iTgLegacy_LDADD = \
			-lssl -lcurl -L../libs -ltg -L../libtg/tg/.libs 

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
	cp -f ../images/Icon*.png iTgLegacy.app/.
	cp -f BubbleView/images/*.png iTgLegacy.app/.

iTgLegacy.app: iTgLegacy _dir _plist _images
	cp -f .libs/iTgLegacy iTgLegacy.app/. 
	cp -f ../libtg/.libs/tgtest iTgLegacy.app/. 
	cp -f ../libtg/pub.pkcs iTgLegacy.app/. 
	cp -r ../libs iTgLegacy.app/.
	cp -f ../libtg/tg/.libs/*.dylib iTgLegacy.app/libs/.
	cd iTgLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/local/lib/libtg.0.dylib @executable_path/libs/libtg.dylib iTgLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/local/lib/libtg.0.dylib @executable_path/libs/libtg.dylib tgtest; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib tgtest; \
	cd libs; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libtg.dylib; \
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
