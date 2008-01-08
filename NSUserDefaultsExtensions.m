#import "NSUserDefaultsExtensions.h"


@implementation NSUserDefaults (NSUserDefaultsExtensions)

- (void)addToHistory:(id)value forKey:(NSString *)key
{
	if (!value) return;
	
	NSMutableArray *a_history = [self objectForKey:key];
	if (a_history == nil) {
		a_history = [NSMutableArray arrayWithObject:@""];
	}
	else {
		if ([a_history containsObject:value]) {
			return;
		}
		a_history = [a_history mutableCopy];
	}

	[a_history insertObject:value atIndex:1];
	unsigned int history_max = [self integerForKey:@"HistoryMax"];

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
@end
