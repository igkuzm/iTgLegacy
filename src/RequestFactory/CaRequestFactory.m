//
//  CaRequestFactory.m
//  Calcium
//
//  Created by bag.xml on 06/04/24.
//  Copyright (c) 2024 Mali 357. All rights reserved.
//

//Apiary communicator class which interacts with a koboldcpp instance.

#import "CaRequestFactory.h"

@implementation CaRequestFactory

//holy mother
- (void)startTextRequest:(NSString *)messagePayload {
    NSLog(@"ChatCommunicator active, will prepare request now.");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //Init-Configuration
    //Only triggered if returned to requesta
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didGenerateImage"];
    
    NSString *baseURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverURL"];
    BOOL authorization = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasAuth"];
    //if auth
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    //Codeblocks
    if(VERSION_MIN(@"5.0")) {
        NSLog(@"Initializing Chat Completion request, iOS 5.0-6.1.6");
        
        //URL Building
        NSString *finalURL = [NSString stringWithFormat:@"%@/amber/v1/home/bag.php", baseURL];
        NSLog(@"final built URL: %@", finalURL);
        NSURL *apiaryRequestURL = [NSURL URLWithString:finalURL];

        NSMutableURLRequest *apiaryCommunicationRequest = [NSMutableURLRequest requestWithURL:apiaryRequestURL];
        NSMutableDictionary *completionRequestBody = [NSMutableDictionary dictionaryWithDictionary:@{@"max_context_length": @2048, @"max_length": @100, @"prompt": messagePayload, @"quiet": @false, @"rep_pen": @1.1, @"rep_pen_range": @256, @"rep_pen_slope": @1, @"temperature": @0.5, @"tfs": @1, @"top_a": @0, @"top_k": @100, @"top_p": @0.9, @"typical": @1}];

        NSData *completionRBData = [NSJSONSerialization dataWithJSONObject:completionRequestBody options:0 error:nil];

        [apiaryCommunicationRequest setHTTPMethod:@"POST"];
        [apiaryCommunicationRequest setHTTPBody:completionRBData];
        [apiaryCommunicationRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if(authorization == YES)
            [apiaryCommunicationRequest setValue:[NSString stringWithFormat:@"Bearer %@", password] forHTTPHeaderField:@"Authorization"];
        
        //typing indication
        [self.delegate setTyping:2];
        
        NSURLConnection *communicatorCall = [[NSURLConnection alloc] initWithRequest:apiaryCommunicationRequest delegate:self];
        [communicatorCall start];
    } else if(VERSION_MIN(@"7.0")) {
    }
}

- (void)startTextRequest:(NSString *)messagePayload withBase64Image:(NSString *)base64Image {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSLog(@"ChatCommunicator active, will prepare request now.");
    //Init-Configuration
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"didGenerateImage"];
    
    //Server related
    NSString *baseURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverURL"];
    BOOL authorization = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasAuth"];
    //if auth
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    
    //Codeblock
    if(VERSION_MIN(@"5.0")) {
        NSLog(@"User does not want to use a middleman, this is okay.");
        
        //URL Building
        NSString *finalURL = [NSString stringWithFormat:@"%@/api/v1/generate", baseURL];
        NSLog(@"final built URL: %@", finalURL);
        NSURL *apiaryRequestURL = [NSURL URLWithString:finalURL];
        
        NSMutableURLRequest *apiaryCommunicationRequest = [NSMutableURLRequest requestWithURL:apiaryRequestURL];
        NSMutableDictionary *completionRequestBody = [@{
                                                        @"n": @1,
                                                        @"max_content_length": @1600,
                                                        @"max_length": @120,
                                                        @"rep_pen": @1.1,
                                                        @"temperature": @0.7,
                                                        @"top_p": @0.92,
                                                        @"top_k": @100,
                                                        @"top_a": @0,
                                                        @"typical": @1,
                                                        @"tfs": @1,
                                                        @"rep_pen_range": @320,
                                                        @"rep_pen_slope": @0.7,
                                                        @"sampler_order": @[@6, @0, @1, @3, @4, @2, @5],
                                                        @"memory": @"",
                                                        @"genkey": @"KCPP3044",
                                                        @"min_p": @0,
                                                        @"dynatemp_range": @0,
                                                        @"dynatemp_exponent": @1,
                                                        @"smoothing_factor": @0,
                                                        @"banned_tokens": @[],
                                                        @"presence_penalty": @0,
                                                        @"logit_bias": @{},
                                                        @"prompt": [NSString stringWithFormat:@"### Instruction:\n%@\n### Response:\n", messagePayload],
                                                        @"quiet": @true,
                                                        @"stop_sequence": @[@"### Instruction:", @"### Response:"],
                                                        @"use_default_badwordsids": @false,
                                                        @"images": @[],
                                                        } mutableCopy];
        if (base64Image != nil) {
            [completionRequestBody addEntriesFromDictionary:@{@"images": @[base64Image]}];
        }
        NSData *completionRBData = [NSJSONSerialization dataWithJSONObject:completionRequestBody options:0 error:nil];
        
        //Headers for the apiary URL Request
        [apiaryCommunicationRequest setHTTPMethod:@"POST"];
        [apiaryCommunicationRequest setHTTPBody:completionRBData];
        [apiaryCommunicationRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        if(authorization == YES)
            [apiaryCommunicationRequest setValue:[NSString stringWithFormat:@"Bearer %@", password] forHTTPHeaderField:@"Authorization"];
        
        //Typing indicator
        [self.delegate setTyping:2];
        
        //Starting the request
        NSURLConnection *communicatorCall = [[NSURLConnection alloc] initWithRequest:apiaryCommunicationRequest delegate:self];
        [communicatorCall start];
        
    } else if(VERSION_MIN(@"7.0")) {
    }
}

- (void)startImageGenerationRequest:(NSString *)messageContent {
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Check the client's OS for if-blocks 
        NSLog(@"API has responded");
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        BOOL didImageGeneration = [[NSUserDefaults standardUserDefaults] boolForKey:@"didGenerateImage"];
        if(self.apiaryResponseData == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self displayAlertView:@"Apiary Error" message:@"Check your endpoint, it's not normal that the response is nothing."];
                [self.delegate setTyping:0];
            });
        } else {
            NSDictionary *apiaryResponseJournal = [NSJSONSerialization JSONObjectWithData:self.apiaryResponseData options:0 error:nil];
            NSLog(@"Apiary Response: %@", apiaryResponseJournal);
            NSLog(@"Executing code block dependent on request config now");
            
            //In case of any error
            
            //Null response:
            if(apiaryResponseJournal == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self displayAlertView:@"Apiary Error" message:@"Check your endpoint, it's not normal that the response is nothing."];
                });
                
            }
            
            //JSON Error
            NSDictionary *apiaryError = [apiaryResponseJournal objectForKey:@"detail"];
            if(apiaryError) {
                NSLog(@"error");
                NSString *error = [apiaryError objectForKey:@"error"];
                NSString *errorBody = [apiaryError objectForKey:@"msg"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self displayAlertView:error message:errorBody];
                });
            }
            
            //Codeblocks, each executed dependent on what the user requested
            
            if(didImageGeneration == YES) {
                NSLog(@"Image Generation = YES");
                
            } else if(didImageGeneration == NO) {
                NSLog(@"Image Generation = NO");
                //prepare for next call
                [self sendReset];
                //processing
                NSString *response = [[[apiaryResponseJournal objectForKey:@"results"] objectAtIndex:0] valueForKey:@"text"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(!apiaryResponseJournal == nil) {
                        //remove typing indication
                        [self.delegate setTyping:0];
                        [self.delegate didReceiveResponseData:response];
                        self.apiaryResponseData = nil;
                    }
                });
                
            }
        }
    });
}

//MISC FUNCTION
- (void)displayAlertView:(NSString *)title message:(NSString *)message {
    UIAlertView *connectDisplay = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [connectDisplay show];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!self.apiaryResponseData) {
        self.apiaryResponseData = [NSMutableData data];
    }
    [self.apiaryResponseData appendData:data];
}

- (void)sendReset {
    NSLog(@"Resetting previous request parameters");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"didGenerateImage"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Done");
}

/* - - -
 
 dispatch_async(dispatch_get_main_queue(), ^{
 //[self.delegate didReceiveResponseData:[NSString stringWithFormat:@"a" ]];
 });
 
 sudo /Applications/Install\ OS\ X\ Mavericks.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume --applicationpath /Applications/Install\ OS\ X\ Mavericks.app
 - - - */
@end
