AUTOMAKE_OPTIONS = subdir-objects
lib_LTLIBRARIES = libtlg2objc.la

libtlg2objc_la_SOURCES = \
					 CoreDataTools.m \
				   NSData+libtg2.m \
				   NSString+libtg2.m \
				   TGChatPhoto.m \
				   TGDialog.m \
				   TGFolder.m \
				   TGManagedObjectContext.m \
				   TGManagedObjectModel.m \
				   TGMessage.m \
				   TGPeer.m \
				   TGPersistentStoreCoordinator.m
				   
libtlg2objc_la_OBJCFLAGS = \
	-fobjc-arc

libtlg2objc_la_LDFLAGS = \
			-framework CoreData -framework Foundation
