#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (NSUserDefaultsExtensions) 

- (void)addToHistory:(id)value forKey:(NSString *)key;
- (void)removeFromHistory:(id)value forKey:(NSString *)key;

@end
