//
//  PGMainWindowController.h
//  Post Grabber
//
//  Created by Michael Tyson on 21/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebView;
@interface PGMainWindowController : NSObject {
    BOOL includeCookies;
    BOOL useCookieJar;
    BOOL includeReferrer;
    WebView *webView;
    NSTextField *urlField;
    
    @private
    NSMutableArray *requests;
}
- (IBAction)stopOrReload:(id)sender;
- (IBAction)copyScript:(id)sender;
- (IBAction)openURL:(id)sender;

@property (nonatomic, readonly) NSString *script;
@property (nonatomic, assign) BOOL includeCookies;
@property (nonatomic, assign) BOOL useCookieJar;
@property (nonatomic, assign) BOOL includeReferrer;

@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSTextField *urlField;
@end
