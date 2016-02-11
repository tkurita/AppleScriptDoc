#import "AppController.h"
#import "DonationReminder/DonationReminder.h"
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "IsBundleTransformer.h"
#import "NSUserDefaultsExtensions.h"
#import <Carbon/Carbon.h>

#define useLog 0

@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end

@interface AppleScriptDocController : NSObject
- (void)saveToFile:(NSString *)path;
- (void)setupHelpBook:(NSString *)path;
- (void)cancelExport;
- (void)setup;
@end

static id sharedObj;

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[[IsBundleTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"IsBundleTransformer"];
}

+ (id)sharedAppController
{
	if (sharedObj == nil) {
		sharedObj = [[self alloc] init];
	}
	return sharedObj;
}

- (id)init
{
	if (self = [super init]) {
		if (sharedObj == nil) {
			sharedObj = self;
		}
	}
	
	return self;
}

#pragma mark services for scripts
- (NSString *)sourceOfScript:(NSString *)path
{
	NSDictionary *error_info;
	NSAppleScript *a_script = [[[NSAppleScript alloc] initWithContentsOfURL:
									[NSURL fileURLWithPath:path] error:&error_info] autorelease];
									
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
		
    return AHGotoPage((CFStringRef)bookname, NULL, NULL);
}

#pragma mark private methods
- (BOOL)setTargetScript:(NSString *)a_path
{
	[[NSUserDefaultsController sharedUserDefaultsController]
					setValue:a_path forKeyPath:@"values.TargetScript"];
	[[NSUserDefaults standardUserDefaults] addToHistory:a_path forKey:@"RecentScripts"];
	[recentScriptsButton setTitle:@""];
	return YES;
}

#pragma mark initilize
- (void)awakeFromNib
{
#if useLog
	NSLog(@"awakeFromNib");
#endif
	[recentScriptsButton setTitle:@""];
	NSPopUpButtonCell *a_cell = [recentScriptsButton cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];

	[targetScriptBox setAcceptFileInfo:@[@{@"FileType": NSFileTypeDirectory,
													@"PathExtension": @"scptd"}, 
		@{@"FileType": NSFileTypeRegular,
													@"PathExtension": @"scpt"}]];
	[mainWindow center];
	[mainWindow setFrameAutosaveName:@"Main"];
}

#pragma mark delegate methods for somethings
- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [item infoResolvingAliasFile][@"ResolvedPath"];
	[self setTargetScript:item];
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
	return [self setTargetScript:filename];
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
	NSString *a_path = [[NSUserDefaults standardUserDefaults] stringForKey:@"TargetScript"];
	if (a_path) {
		if (![a_path fileExists]) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TargetScript"];
		}
	}
	[mainWindow orderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[mainWindow saveFrameUsingName:@"Main"];
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
    [panel setAllowedFileTypes:@[@"scpt", @"scptd"]];
    [panel beginSheetModalForWindow:mainWindow
                    completionHandler:^(NSInteger result) {
                        if (result != NSOKButton) return;
                        NSURL *an_url = [panel URL];
                        NSDictionary *alias_info = [an_url infoResolvingAliasFile];
                        if (alias_info) {
                            [self setTargetScript:alias_info[@"ResolvedPath"] ];
                        } else {
                            [panel orderOut:self];
                            NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
                                                                defaultButton:@"OK" alternateButton:nil otherButton:nil
                                                    informativeTextWithFormat:@"No original item of '%@'",an_url.path ];
                            [an_alert beginSheetModalForWindow:mainWindow modalDelegate:self
                                                didEndSelector:nil contextInfo:nil];
                        }
                    }];
}

- (IBAction)popUpRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if ((!is_optkey) && [a_path fileExists]) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:a_path forKeyPath:@"values.TargetScript"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:a_path
												forKey:@"RecentScripts"];
	}
	[recentScriptsButton setTitle:@""];
}

- (IBAction)exportAction:(id)sender
{
	if (!_pathSettingWindowController) {
		self.pathSettingWindowController =
			[[PathSettingWindowController alloc] initWithWindowNibName:@"PathSettingWindow"];
	}

	[[NSApplication sharedApplication] beginSheet:[_pathSettingWindowController window]
							   modalForWindow:mainWindow 
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
/*
- (OSAScript *)script
{
	if (script) return script;
	NSDictionary *err_info = nil;	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"AppleScriptDoc"
										ofType:@"scpt" inDirectory:@"Scripts"];
	
	OSAScript *scpt = [[OSAScript alloc] initWithContentsOfURL:
					   [NSURL fileURLWithPath:path] error:&err_info];
	
	if (err_info) {
		showOSAError(err_info);
		if (scpt) [scpt release];
		return nil;
	}
	
	[scpt executeHandlerWithName:@"setup_modules"
					   arguments:nil error:&err_info];
	if (err_info) {
		showOSAError(err_info);
		if (scpt) [scpt release];
	}
	script = scpt;
	return script;
}
*/

- (void)exportHelpBook:(id)sender
{
	NSString *a_path = [[NSUserDefaults standardUserDefaults] stringForKey:@"TargetScript"];
	[sender startIndicator];
	[appleScriptDocController exportHelpBook:a_path];
	[sender stopIndicator];	
}

- (void)cancelExport:(id)sender
{
	[appleScriptDocController cancelExport];
}

- (IBAction)setupHelpBookAction:(id)sender
{
	NSString *a_path = [[NSUserDefaults standardUserDefaults] stringForKey:@"TargetScript"];
	[self startIndicator];
	[appleScriptDocController setupHelpBook:a_path];
	[self stopIndicator];
}

- (IBAction)saveToFileAction:(id)sender
{
	NSString *a_path = [[NSUserDefaults standardUserDefaults] stringForKey:@"TargetScript"];
	[self startIndicator];
	[appleScriptDocController saveToFile:a_path];
	[self stopIndicator];	
}


@end
