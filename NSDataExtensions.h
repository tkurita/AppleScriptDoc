//
//  NSDataExntension.h
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/08/30.
//
//

#import <Foundation/Foundation.h>

@interface NSData (NSDataExtensions)
- (NSURL *)fileURL;
- (NSString *)path;
@end
