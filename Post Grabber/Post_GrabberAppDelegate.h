//
//  Post_GrabberAppDelegate.h
//  Post Grabber
//
//  Created by Michael Tyson on 21/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Post_GrabberAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
