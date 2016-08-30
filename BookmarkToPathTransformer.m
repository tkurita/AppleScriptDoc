//
//  BookmarkToPathTransformer.m
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/08/30.
//
//

#import "BookmarkToPathTransformer.h"

@implementation BookmarkToPathTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(NSData *)value
{
    if (!value) return nil;
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:value
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
    if (error) NSLog(@"error in BookmarkToPathTransformer with %@", error);
    return [an_url path];
}

@end
