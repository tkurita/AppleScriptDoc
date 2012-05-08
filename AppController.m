#import "AppController.h"
#import <DonationReminder/DonationReminder.h>
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "IsBundleTransformer.h"
#import "NSUserDefaultsExtensions.h"
#import <Carbon/Carbon.h>
#import <OSAKit/OSAScript.h>

#define useLog 0

@interface ASKScriptCache : NSObject
{
}
+ (ASKScriptCache *)sharedScriptCache;
- (OSAScript *)scriptWithName:(NSString *)name;
@end

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[[IsBundleTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"IsBundleTransformer"];
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
    OSStatus err = noErr;
	
	FSRef ref;
	err = FSPathMakeRef((UInt8 *)[path fileSystemRepresentation], &ref, NULL);
	if (err != noErr) goto bail;
	err = AHRegisterHelpBook(&ref);
	if (err != noErr) goto bail;
	
	NSBundle *bundle_ref = [NSBundle bundleWithPath:path];
    if (bundle_ref == nil) {err = fnfErr; goto bail;}
	
	NSString *bookname = [[bundle_ref infoDictionary] objectForKey:@"CFBundleHelpBookName"];
    if (bookname == nil) {err = fnfErr; goto bail;}
		
    if (err == noErr) err = AHGotoPage((CFStringRef)bookname, NULL, NULL);
bail:
    return err;
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

	[targetScriptBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeDirectory, @"FileType",
													@"scptd", @"PathExtension", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"scpt", @"PathExtension", nil], nil]];
	[mainWindow center];
	[mainWindow setFrameAutosaveName:@"Main"];
}

#pragma mark delegate methods for somethings
- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [[item infoResolvingAliasFile] objectForKey:@"ResolvedPath"];
	[self setTargetScript:item];
	return YES;
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode 
												contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *a_path = [panel filename];
		NSDictionary *alias_info = [a_path infoResolvingAliasFile];
		if (alias_info) {
			[self setTargetScript:[alias_info objectForKey:@"ResolvedPath"] ];
		} else {
			[panel orderOut:self];
			NSAlert *an_alert = [NSAlert alertWithMessageText:@"Can't resolving alias"
							defaultButton:@"OK" alternateButton:nil otherButton:nil
							informativeTextWithFormat:@"No original item of '%@'",a_path ];
			[an_alert beginSheetModalForWindow:mainWindow modalDelegate:self
														didEndSelector:nil contextInfo:nil];
		}
	}
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
	NSOpenPanel *a_panel = [NSOpenPanel openPanel];
	[a_panel setResolvesAliases:NO];
	[a_panel beginSheetForDirectory:nil file:nil 
			types:[NSArray arrayWithObjects:@"scpt", @"scptd", nil]
			modalForWindow:mainWindow modalDelegate:self
			didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
			contextInfo:nil];
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
	if (!pathSettingWindowController) {
		pathSettingWindowController = 
			[[PathSettingWindowController alloc] initWithWindowNibName:@"PathSettingWindow"];
	}

	[[NSApplication sharedApplication] beginSheet:[pathSettingWindowController window] 
							   modalForWindow:mainWindow 
								modalDelegate:self 
							   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
								  contextInfo:nil];
}

- (IBAction)setupHelpBookAction:(id)sender
{
	NSDictionary *error_info = nil;
	id a_script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptDoc"];
	
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	[a_script executeHandlerWithName:@"setup_helpbook" arguments:nil error:&error_info];
	if (error_info) {
		NSNumber *err_no = [error_info objectForKey:@"OSAScriptErrorNumber"];
		if ([err_no intValue] != -128) {
			[[NSAlert alertWithMessageText:@"AppleScript Error"
							 defaultButton:@"OK" alternateButton:nil otherButton:nil
				 informativeTextWithFormat:@"%@\nNumber: %@", 
			  [error_info objectForKey:@"OSAScriptErrorMessage"],
			  err_no] runModal];
			NSLog(@"%@", [error_info description]);
		}
	}
	
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];	
}

@end
