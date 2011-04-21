//
//  PGMainWindowController.m
//  Post Grabber
//
//  Created by Michael Tyson on 21/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PGMainWindowController.h"
#import <WebKit/WebKit.h>

@interface PGReloadStopTitleValueTransformer : NSValueTransformer {
}
@end

@interface PGStringToAttributedStringValueTransformer : NSValueTransformer {
}
@end

@implementation PGMainWindowController
@synthesize webView;
@synthesize urlField;
@dynamic script;
@synthesize includeCookies, useCookieJar, includeReferrer;

+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ( [key isEqualToString:@"script"] ) {
        return [[super keyPathsForValuesAffectingValueForKey:key] setByAddingObjectsFromArray:[NSArray arrayWithObjects:@"includeCookies", @"useCookieJar", @"includeReferrer", nil]];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

+(void)initialize {
    [NSValueTransformer setValueTransformer:[[[PGReloadStopTitleValueTransformer alloc] init] autorelease] forName:@"PGReloadStopTitleValueTransformer"];
    [NSValueTransformer setValueTransformer:[[[PGStringToAttributedStringValueTransformer alloc] init] autorelease] forName:@"PGStringToAttributedStringValueTransformer"];
}

- (id)init {
    if ( !(self = [super init]) ) return nil;
    requests = [[NSMutableArray alloc] init];
    return self;
}

-(void)awakeFromNib {
    [urlField.window makeFirstResponder:urlField];
}

- (void)dealloc {
    [requests release];
    self.webView = nil;
    [super dealloc];
}

- (IBAction)stopOrReload:(id)sender {
    if ( webView.isLoading ) {
        [webView stopLoading:sender];
    } else {
        [webView reload:sender];
    }
}

- (IBAction)copyScript:(id)sender {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:self.script forType:NSStringPboardType];
}

- (IBAction)openURL:(NSTextField*)sender {
    if ( ![[sender stringValue] hasPrefix:@"http"] ) {
        [sender setStringValue:[@"http://" stringByAppendingString:[sender stringValue]]];
    }
    [webView takeStringURLFrom:sender];
    [[webView window] makeFirstResponder:webView];
}

- (NSString*)script {
    NSMutableString *string = [NSMutableString string];
    for ( NSURLRequest *request in requests ) {
        [string appendString:@"curl"];
        if ( includeCookies && [[request allHTTPHeaderFields] objectForKey:@"Cookie"] ) {
            NSArray *cookies = [[[request allHTTPHeaderFields] objectForKey:@"Cookie"] componentsSeparatedByString:@";"];
            for ( NSString *cookie in cookies ) {
                [string appendFormat:@" -b \"%@=%@\"", [[cookie stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
            }
        }
        if ( useCookieJar ) {
            [string appendString:@" -c /tmp/cookies.txt"];
            if ( !includeCookies || ![[request allHTTPHeaderFields] objectForKey:@"Cookie"] ) {
                [string appendString:@" -b /tmp/cookies.txt"];
            }
        }
        
        if ( includeReferrer && [[request allHTTPHeaderFields] objectForKey:@"Referer"] ) {
            [string appendFormat:@" -e %@", [[request allHTTPHeaderFields] objectForKey:@"Referer"]];
        }
        
        NSMutableDictionary *formFields = nil;
        if ( [[[request allHTTPHeaderFields] objectForKey:@"Content-Type"] rangeOfString:@"application/x-www-form-urlencoded"].location != NSNotFound ) {
            // Extract form fields from URL-Encoded form
            NSString *bodyString = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
            
            formFields = [NSMutableDictionary dictionary];
            for ( NSString *pair in [[bodyString stringByReplacingOccurrencesOfString:@"+" withString:@" "] componentsSeparatedByString:@"&"] ) {
                NSArray *pairArray = [pair componentsSeparatedByString:@"="];
                if ( [pairArray count] == 2 ) {
                    [formFields setObject:[[pairArray objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                forKey:[pairArray objectAtIndex:0]];
                } else {
                    [formFields setObject:@"" forKey:[pairArray objectAtIndex:0]];
                }
            }
            
        } else if ( [[[request allHTTPHeaderFields] objectForKey:@"Content-Type"] rangeOfString:@"multipart/form-data"].location != NSNotFound ) {
            // Extract form fields from multipart
            [string appendFormat:@" \"%@\"\n", [[request URL] absoluteString]];
            [string appendString:@"# Note: The last request had multipart/form-data type, which isn't supported yet.\n"];
            continue;
        }
        
        if ( formFields ) {
            for ( NSString *key in [formFields allKeys] ) {
                [string appendFormat:@" -F \"%@=%@\"", key, [[formFields objectForKey:key] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
            }
        }
        
        [string appendFormat:@" \"%@\"\n", [[request URL] absoluteString]];
    }
    
    return string;
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    NSURLRequest *request = [[frame provisionalDataSource] request];
    
    if ( [[request HTTPMethod] isEqualToString:@"POST"] ) {
        [self willChangeValueForKey:@"script"];
        [requests addObject:[[request copy] autorelease]];
        [self didChangeValueForKey:@"script"];
    }
}

@end


@implementation PGReloadStopTitleValueTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    return ([value boolValue] ? @"╳" : @"↻");
}
@end



@implementation PGStringToAttributedStringValueTransformer
+ (Class)transformedValueClass { return [NSAttributedString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)value {
    return [[[NSAttributedString alloc] initWithString:value 
                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSFont fontWithName:@"Monaco" size:14.0], NSFontAttributeName, nil]] autorelease];
}
@end