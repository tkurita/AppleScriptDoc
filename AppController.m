#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "IsBundleTransformer.h"
#import "URLToPathTransformer.h"
#import "BookmarkToPathTransformer.h"
#import "NSUserDefaultsExtensions.h"
#import "NSDataExtensions.h"
#import <Carbon/Carbon.h>

#define useLog 0

@interface AppleScriptDocController : NSObject
- (void)outputFrom:(NSString *)src toPath:(NSString *)dst;
- (void)setupHelpBook:(NSString *)path;
- (void)cancelExport;
- (void)setup;
- (NSDictionary *)exportHelpBook:(NSString *)path toPath:(NSString *)destination;
@end

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[IsBundleTransformer alloc] init];
	[NSValueTransformer setValueTransformer:transformer forName:@"IsBundleTransformer"];

    [NSValueTransformer setValueTransformer:[[URLToPathTransformer alloc] init]
                                    forName:@"URLToPathTransformer"];

    [NSValueTransformer setValueTransformer:[[BookmarkToPathTransformer alloc] init]
                                    forName:@"BookmarkToPathTransformer"];

    // clear UserDefaults cache
    //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark singleton
static id sharedInstance = nil;

+ (AppController *)sharedAppController
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        (void)[[AppController alloc] init];
    });
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	
	__block id ret = nil;
	
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		sharedInstance = [super allocWithZone:zone];
		ret = sharedInstance;
	});
	
	return  ret;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


#pragma mark services for scripts
- (NSString *)sourceOfScript:(NSString *)path
{
	NSDictionary *error_info;
	NSAppleScript *a_script = [[NSAppleScript alloc] initWithContentsOfURL:
									[NSURL fileURLWithPath:path] error:&error_info];
									
	return [a_script source];

}

- (OSStatus)showHelpBook:(NSString *)path
{
	NSBundle *bundle_ref = [NSBundle bundleWithPath:path];
    if (! bundle_ref) {
        NSLog(@"Failed to obtain bundle : %@", path);
        return fnfErr;
    }
    if (![[NSHelpManager sharedHelpManager] registerBooksInBundle:bundle_ref]) {
        NSLog(@"Failed to registerBooksInBundle : %@", path);
        return fnfErr;
    }
    
	NSString *bookname = [bundle_ref infoDictionary][@"CFBundleHelpBookName"];
    if (! bookname) {
        NSLog(@"Failed to obtain CFBundleHelpBookName : %@", path);
        return fnfErr;
    }
		
    return AHGotoPage((__bridge CFStringRef)bookname, NULL, NULL);
}


- (OSStatus)showHelpBook:(NSString *)path bookname:(NSString *)name
{
    NSBundle *bundle_ref = [NSBundle bundleWithPath:path];
    if (! bundle_ref) {
        NSLog(@"Failed to obtain bundle : %@", path);
        return fnfErr;
    }
    if (![[NSHelpManager sharedHelpManager] registerBooksInBundle:bundle_ref]) {
        NSLog(@"Failed to registerBooksInBundle : %@", path);
        return fnfErr;
    }
    
    return AHGotoPage((__bridge CFStringRef)name, NULL, NULL);
}

#pragma mark private methods
- (BOOL)setTargetScript:(NSURL *)an_url
{
    NSError *error = nil;
    NSData *bmd = [an_url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                        includingResourceValuesForKeys:nil
                                    relativeToURL:nil error:&error];
    [[NSUserDefaultsController sharedUserDefaultsController]
					setValue:bmd forKeyPath:@"values.TargetScript"];
	[[NSUserDefaults standardUserDefaults] addToHistory:bmd forKey:@"RecentScripts"];
	[recentScriptsButton setTitle:@""];
	return YES;
}

#pragma mark initilize
- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif
    
    NSArray *recent_scripts = [RecentScriptsController arrangedObjects];
    NSMutableArray* invalid_items = [NSMutableArray arrayWithCapacity:[recent_scripts count]];
    for (NSData *an_item in recent_scripts) {
        if (![an_item fileURL]) {
            [invalid_items addObject:an_item];
        }
    }
    if ([invalid_items count]) {
        [RecentScriptsController removeObjects:invalid_items];
    }
    
	[recentScriptsButton setTitle:@""];
	NSPopUpButtonCell *a_cell = [recentScriptsButton cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];
    
	[targetScriptBox setAcceptFileInfo:@[
        @{@"FileType": NSFileTypeDirectory, @"PathExtension": @"scptd"},
        @{@"FileType": NSFileTypeRegular, @"PathExtension": @"scpt"},
        @{@"FileType": NSFileTypeRegular, @"PathExtension": @"applescript"}]];
	[_mainWindow center];
	[_mainWindow setFrameAutosaveName:@"Main"];
}

#pragma mark delegate methods for somethings
- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [item infoResolvingAliasFile][@"ResolvedPath"];
	[self setTargetScript:[item fileURL]];
	return YES;
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
}


#pragma mark delegate methods for NSApplication
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
#if useLog
	NSLog(filename);
#endif
	return [self setTargetScript:[filename fileURL]];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
	NSString *defaults_plist = [[NSBundle mainBundle] 
						pathForResource:@"FactorySettings" ofType:@"plist"];
	NSDictionary *factory_defaults = [NSDictionary dictionaryWithContentsOfFile:defaults_plist];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults registerDefaults:factory_defaults];
    
	[appleScriptDocController setup];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[DonationReminder remindDonation];
	NSData *bmd = [[NSUserDefaults standardUserDefaults] dataForKey:@"TargetScript"];
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:bmd
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
    if (an_url) {
		if (![[an_url path] fileExists]) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TargetScript"];
		}
	}
	[_mainWindow orderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[_mainWindow saveFrameUsingName:@"Main"];
}

#pragma mark actions
- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (IBAction)selectTarget:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setResolvesAliases:NO];
    [panel setAllowedFileTypes:@[@"scpt", @"scptd", @"applescript"]];
    [panel beginSheetModalForWindow:_mainWindow
                    completionHandler:^(NSInteger result) {
                        if (result != NSOKButton) return;
                        NSURL *an_url = [panel URL];
                        NSDictionary *alias_info = [an_url infoResolvingAliasFile];
                        if (alias_info) {
                            [self setTargetScript:alias_info[@"ResolvedURL"] ];
                        } else {
                            [panel orderOut:self];
                            NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
                                                                defaultButton:@"OK" alternateButton:nil otherButton:nil
                                                    informativeTextWithFormat:@"No original item of '%@'",an_url.path ];
                            [an_alert beginSheetModalForWindow:self->_mainWindow modalDelegate:self
                                                didEndSelector:nil contextInfo:nil];
                        }
                    }];
}

- (IBAction)popUpRecents:(id)sender
{
    NSData *bmd = [[RecentScriptsController selectedObjects] lastObject];
    BOOL is_stale;
    NSError *error = nil;
    NSURL *an_url = [NSURL URLByResolvingBookmarkData:bmd
                                              options:NSURLBookmarkResolutionWithSecurityScope
                                        relativeToURL:nil
                                  bookmarkDataIsStale:&is_stale
                                                error:&error];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if ((!is_optkey) && [[an_url path] fileExists]) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:bmd forKeyPath:@"values.TargetScript"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:bmd
												forKey:@"RecentScripts"];
	}
	[recentScriptsButton setTitle:@""];
}

- (IBAction)exportAction:(id)sender
{
    NSError *error;
    if (! [self existTargetScriptReturnError:&error]) {
        return;
    }
	if (!_pathSettingWindowController) {
		self.pathSettingWindowController =
			[[PathSettingWindowController alloc] initWithWindowNibName:@"PathSettingWindow"];
	}

	[[NSApplication sharedApplication] beginSheet:[_pathSettingWindowController window]
							   modalForWindow:_mainWindow
								modalDelegate:self 
							   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
								  contextInfo:nil];
}

- (void)startIndicator
{
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];	
}

- (void)stopIndicator
{
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
}

void showOSAError(NSDictionary *err_info)
{
	[NSApp activateIgnoringOtherApps:YES];
	NSNumber *err_no = err_info[OSAScriptErrorNumber];
	if ([err_no intValue] != -128) {
		[[NSAlert alertWithMessageText:@"AppleScript Error"
						 defaultButton:@"OK" alternateButton:nil otherButton:nil
			 informativeTextWithFormat:@"%@\nNumber: %@", 
				err_info[OSAScriptErrorMessage],
				 err_no]
			runModal];
#if useLog
		NSLog(@"%@", [error_info description]);
#endif			
	}
}

- (BOOL) existTargetScriptReturnError:(NSError **)errptr
{
    NSURL *an_url = [[NSUserDefaults standardUserDefaults] fileURLForKey:@"TargetScript" error:errptr];
    if (an_url && [an_url checkResourceIsReachableAndReturnError:errptr])
        return YES;
    if (! *errptr) {
        NSString *errmsg = NSLocalizedString(@"fileNotExists", @"");
        *errptr = [NSError errorWithDomain:@"AppleScriptDocErrorDomain"
                                     code:1465
                            userInfo:@{NSLocalizedDescriptionKey: errmsg}];
    }
    [[NSAlert alertWithError:*errptr]
        beginSheetModalForWindow:_mainWindow modalDelegate:self
                                               didEndSelector:nil contextInfo:nil];
    return NO;
}

- (NSDictionary *)exportHelpBook:(id)sender
{
	NSURL *an_url = [[NSUserDefaults standardUserDefaults] fileURLForKey:@"TargetScript"];
	[sender startIndicator];
    NSDictionary *err_info = [appleScriptDocController exportHelpBook:[an_url path]
                                toPath:[[(PathSettingWindowController*)sender exportFileURL] path]];
	[sender stopIndicator];
    return err_info;
}

- (void)cancelExport:(id)sender
{
	[appleScriptDocController cancelExport];
}

- (IBAction)setupHelpBookAction:(id)sender
{
    NSError *error;
    if (! [self existTargetScriptReturnError:&error]) {
        return;
    }
    NSUserDefaults *userdefaults = [NSUserDefaults standardUserDefaults];
    [userdefaults synchronize];
    NSURL *an_url = [userdefaults fileURLForKey:@"TargetScript"];
	[self startIndicator];
	[appleScriptDocController setupHelpBook:[an_url path]];
	[self stopIndicator];
}

- (void)outputToPath:(NSString *)dst
{
    NSString *a_path = [[[NSUserDefaults standardUserDefaults] fileURLForKey:@"TargetScript"] path];
    [self startIndicator];
	[appleScriptDocController outputFrom:a_path toPath:dst];
	[self stopIndicator];
}

- (IBAction)saveToFileAction:(id)sender
{
    NSError *error;
    if (! [self existTargetScriptReturnError:&error]) {
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setAllowedFileTypes:@[@"public.html"]];
    [panel setCanSelectHiddenExtension:YES];
    [panel setNameFieldStringValue:@"index.html"];
    [panel beginSheetModalForWindow:_mainWindow
                  completionHandler:^(NSInteger result) {
                      if (result != NSOKButton) return;
                      [self outputToPath:panel.URL.path];
                  }];
}


@end
