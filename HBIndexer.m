//
//  HBIndexer.m
//  AppleScriptDoc
//
//  Created by 栗田 哲郎 on 2016/02/12.
//
//

#import "HBIndexer.h"

@implementation HBIndexer
+ (id)hbIndexerWithTarget:(NSString *)aPath
{
    HBIndexer *obj = [self new];
    obj.targetPath = aPath;
    obj.indexFileName = nil;
    return obj;
}

- (BOOL)makeIndex
{
    NSTask *a_task = [NSTask new];
    [a_task setLaunchPath:@"/usr/bin/hiutil"];
    if (! self.indexFileName) {
        self.indexFileName = [_targetPath.lastPathComponent stringByAppendingPathExtension:@"helpindex"];
    }
    NSString *idx_path = [_targetPath stringByAppendingPathComponent:_indexFileName];
    [a_task setArguments:
        @[@"-vaCf", idx_path, @"-m", @"1", @"-s", @"en", @"-e", @"assets/.*", @"-e", @".*/assets/.*", self.targetPath]];
    [a_task setStandardOutput:[NSPipe pipe]];
    [a_task setStandardError:[NSPipe pipe]];
    
    [a_task launch];
    [a_task waitUntilExit];
    
    if (0 == [a_task terminationStatus]) return YES;
    
    NSString *err = [[NSString alloc] initWithData:
                      [[[a_task standardError] fileHandleForReading] availableData]
                                        encoding:NSUTF8StringEncoding];
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Failed to index HelpBook"
                                        defaultButton:@"OK" alternateButton:nil otherButton:nil
                informativeTextWithFormat:@"Target : %@ \n\n Message :\n %@", self.targetPath, err ];
    [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:self
                        didEndSelector:nil contextInfo:nil];
    
    return NO;
}

@end
