#import "NSUserDefaultsExtensions.h"


@implementation NSUserDefaults (NSUserDefaultsExtensions)

- (void)addToHistory:(id)value forKey:(NSString *)key
{
	if (!value) return;
	
	NSMutableArray *a_history = [self objectForKey:key];
	if (a_history == nil) {
        a_history = [NSMutableArray arrayWithObject:[NSData data]];
	}
	else {
		if ([a_history containsObject:value]) {
			return;
		}
		a_history = [a_history mutableCopy];
	}

	[a_history insertObject:value atIndex:1];
    //[a_history insertObject:value atIndex:0];
	NSInteger history_max = [self integerForKey:@"HistoryMax"];

	if ([a_history count] > history_max) {
		[a_history removeLastObject];
	}
	[self setObject:a_history forKey:key];
}

- (void)removeFromHistory:(id)value forKey:(NSString *)key
{
	if (!value) return;
	
	NSMutableArray *a_history = [self objectForKey:key];
	if (!a_history) return;
	if ([a_history containsObject:value]) {
		a_history = [a_history mutableCopy];
		[a_history removeObject:value];
		[self setObject:a_history forKey:key];
	}
	
}

- (void)setFileURL:(NSURL *)anURL forKey:(NSString *)key
{
    NSError *error = nil;
    NSData *bmd = [anURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                            includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
    if (error) NSLog(@"error in setFileURL with %@", error);
    [self setObject:bmd forKey:key];
}

- (NSURL *)fileURLForKey:(NSString *)key error:(NSError **)errptr
{
    NSData *bmd = [self dataForKey:key];
    if (!bmd) return nil;
    BOOL is_stale;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:bmd
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:errptr];
    return an_url;
}
    
- (NSURL *)fileURLForKey:(NSString *)key
{
    NSData *bmd = [self dataForKey:key];
    if (!bmd) return nil;
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:bmd
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
    if (error) NSLog(@"error in fileURLForKey with %@", error);
    return an_url;
}
@end
