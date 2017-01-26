#import <Cocoa/Cocoa.h>


@interface NSUserDefaults (NSUserDefaultsExtensions) 

- (void)addToHistory:(id)value forKey:(NSString *)key;
- (void)removeFromHistory:(id)value forKey:(NSString *)key;
- (void)setFileURL:(NSURL *)anURL forKey:(NSString *)key;
- (NSURL *)fileURLForKey:(NSString *)key;
- (NSURL *)fileURLForKey:(NSString *)key error:(NSError **)errptr;
@end
