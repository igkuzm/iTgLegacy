#import "TGFolder.h"
#import "NSString+libtg2.h"

@implementation TGFolder
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		if (tl->_id == id_folder){
			tl_folder_t *f = (tl_folder_t *)tl;

			self.autofill_new_broadcasts = f->autofill_new_broadcasts_;
			self.autofill_public_groups = f->autofill_public_groups_;
			self.autofill_new_correspondents = f->autofill_new_correspondents_;
			self.id = f->id_;
			self.title = [NSString sringWithTLString:f->title_]; 
			self.photo = [[TGChatPhoto alloc]initWithTL:f->photo_];

		}
	}
	return self;
}
@end
// vim:ft=objc
