//
//  FileArrayController.m
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/12/22.
//
//

#import "FileArrayController.h"
#import "NSDataExtensions.h"

@implementation FileArrayController

- (NSArray *)arrangedPaths
{
    NSArray *arranged_objects = self.arrangedObjects;
    //NSArray *arranged_paths = [arranged_objects valueForKey:@"path"];
    for (NSData *an_obj in arranged_objects) {
        if (! [an_obj path]) {
            [self removeObject:an_obj];
        }
    }
    NSArray *result = [self.arrangedObjects valueForKey:@"path"];
    return result;
}

@end
