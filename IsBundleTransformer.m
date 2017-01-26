#import "IsBundleTransformer.h"

@implementation IsBundleTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
    if (!value) return nil;
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:value
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
    if (!an_url) {
        //[[NSAlert alertWithError:error] runModal];
        return nil;
    }
	return [NSNumber numberWithBool:
				(value && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:[an_url path]])];
}

@end
