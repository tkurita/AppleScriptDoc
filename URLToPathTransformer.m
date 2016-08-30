//
//  URLToPathTransformer.m
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/08/29.
//
//

#import "URLToPathTransformer.h"

@implementation URLToPathTransformer

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
    return [an_url path];
}

@end
