AUTOMAKE_OPTIONS = subdir-objects
lib_LTLIBRARIES = libtg2objc.la

libtg2objc_la_SOURCES = \
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
				   
libtg2objc_la_OBJCFLAGS = \
	-fobjc-arc -I../libtg2/essential

libtg2objc_la_LDFLAGS = \
			-framework CoreData -framework Foundation
