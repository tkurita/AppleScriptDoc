#import "AppController.h"
#import <DonationReminder/DonationReminder.h>
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "IsBundleTransformer.h"
#import "NSUserDefaultsExtensions.h"

#define useLog 0

@class ASKScriptCache;
@class ASKScript;

@implementation AppController

+ (void)initialize
{	
	NSValueTransformer *transformer = [[[IsBundleTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"IsBundleTransformer"];
}

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
	NSString *defaults_plist = [[NSBundle mainBundle] pathForResource:@"FactorySettings" ofType:@"plist"];
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
}

- (void)setTargetScript:(NSString *)a_path
{
	[[NSUserDefaultsController sharedUserDefaultsController]
					setValue:a_path forKeyPath:@"values.TargetScript"];
	[[NSUserDefaults standardUserDefaults] addToHistory:a_path forKey:@"RecentScripts"];
	[recentScriptsButton setTitle:@""];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode 
												contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		[self setTargetScript:[panel filename]];
	}
}

- (IBAction)selectTarget:(id)sender
{
	[[NSOpenPanel openPanel] beginSheetForDirectory:nil file:nil 
		types:[NSArray arrayWithObjects:@"scpt", @"scptd", nil]
		modalForWindow:mainWindow modalDelegate:self
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
		contextInfo:nil];
}

- (IBAction)popUpRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	if ([a_path fileExists]) {
		[[NSUserDefaultsController sharedUserDefaultsController] 
						setValue:a_path forKeyPath:@"values.TargetScript"];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:a_path
												forKey:@"RecentScripts"];
	}
}

- (void)awakeFromNib {
	[recentScriptsButton setTitle:@""];
	[targetScriptBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeDirectory, @"FileType",
													@"scptd", @"PathExtension", nil], 
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"scpt", @"PathExtension", nil], nil]];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:self];
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

- (NSString *)script_source:(NSString *)path
{
	NSDictionary *error_info;
	NSAppleScript *a_script = [[[NSAppleScript alloc] initWithContentsOfURL:
									[NSURL fileURLWithPath:path] error:&error_info] autorelease];
									
	return [a_script source];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [[item infoResolvingAliasFile] objectForKey:@"ResolvedPath"];
	[self setTargetScript:item];
	return YES;
}

@end
