//
//  NSDataExntension.m
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/08/30.
//
//

#import "NSDataExtensions.h"

@implementation NSData (NSDataExtensions)

- (NSURL *)fileURL
{
    if (! self.length) return nil;
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:self
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
    if (error) NSLog(@"Error in path of NSDataExtensions with %@", error);
    return an_url;
}

- (NSString *)path
{
    NSURL *an_url = [self fileURL];
    if (! an_url) return nil;
    return [an_url path];
}

@end
