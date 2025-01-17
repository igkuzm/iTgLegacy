

// Create vcd file all contacts
- (void)CreateVCardfile {
NSMutableArray *contactsArray=[[NSMutableArray alloc] init];
CNContactStore *store = [[CNContactStore alloc] init];
[store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error)
{

    if (!granted)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
        return;
    }
    NSMutableArray *contacts = [NSMutableArray array];
    NSError *fetchError;
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[[CNContactVCardSerialization descriptorForRequiredKeys], [CNContactFor

    BOOL success = [store enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact *contact, BOOL *stop) {
        [contacts addObject:contact];
    }];

    if (!success)
    {

        NSLog(@"error = %@", fetchError);
    }



    CNContactFormatter *formatter = [[CNContactFormatter alloc] init];

    for (CNContact *contact in contacts)
    {
        [contactsArray addObject:contact];
    }

    NSData *vcardString =[CNContactVCardSerialization dataWithContacts:contactsArray error:&error];
    NSString* vcardStr = [[NSString alloc] initWithData:vcardString encoding:NSUTF8StringEncoding];
    NSLog(@"vcardStr = %@",vcardStr);

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *folderPath = [paths objectAtIndex:0];

    NSString *filePath = [folderPath stringByAppendingPathComponent:@"Contacts.vcf"];
    [vcardStr writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];



    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSArray *objectsToShare = @[fileUrl];

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    [self presentViewController:controller animated:YES completion:nil];

}];

}

