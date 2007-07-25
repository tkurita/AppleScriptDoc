#import "PathSettingWindowController.h"
#import "PathExtra.h"

@implementation PathSettingWindowController

@class ASKScriptCache;
@class ASKScript;

- (IBAction)cancelAction:(id)sender
{
	[[NSApplication sharedApplication] endSheet:[sender window] returnCode:128];
}

- (void)checkOKCondition
{
	BOOL is_ok = YES;
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *root_path;
	if (!(root_path = [user_defaults stringForKey:@"HelpBookRootPath"])) {
		is_ok = NO;
		goto bail;
	}
	
	if (![root_path fileExists]) {
		is_ok = NO;
		goto bail;
	}
	
	NSString *export_path;
	if (!(export_path = [user_defaults stringForKey:@"ExportFilePath"])) {
		is_ok = NO;
		goto bail;
	}
	
	if (![export_path hasPrefix:root_path]) {
		[exportPathWarning setHidden:NO];
		is_ok = NO;
		goto bail;
	} else {
		[exportPathWarning setHidden:YES];
	}
	
bail:
	[okButton setEnabled:is_ok];
}

- (void)addToHistory:(NSString *)path forKey:(NSString *)key
{
	if (!path) return;
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *a_history = [user_defaults objectForKey:key];
	if (a_history == nil) {
		a_history = [NSMutableArray arrayWithObject:@""];
	}
	else {
		if ([a_history containsObject:path]) return;
		a_history = [a_history mutableCopy];
	}

	[a_history insertObject:path atIndex:1];
	unsigned int history_max = [user_defaults integerForKey:@"RecentsMax"];

	if ([a_history count] > history_max) {
		[a_history removeLastObject];
	}
	[user_defaults setObject:a_history forKey:key];
	[self checkOKCondition];
}

- (void)setHelpBookRoot:(NSString *)path
{
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"HelpBookRootPath"];
	[self addToHistory:path forKey:@"RecentHelpBookRoots"];
}

- (void)setExportPath:(NSString *)path
{
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"ExportFilePath"];
	[self addToHistory:path forKey:@"RecentExportPathes"];
}

- (void)savePanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if (returnCode == NSCancelButton) return;
	[self setExportPath:[panel filename]];
}

- (IBAction)chooseExportPath:(id)sender
{
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setRequiredFileType:@"html"];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *a_path = [user_defaults stringForKey:@"ExportFilePath"];
	NSString *a_name;
	if (a_path) {
		a_name = [a_path lastPathComponent];
	} else {
		a_name = [user_defaults stringForKey:@"ExportFileName"];
	}
	
	[save_panel beginSheetForDirectory:nil file:a_name
		modalForWindow:[self window] modalDelegate:self
		didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSCancelButton) return;
	[self setHelpBookRoot:[panel filename]];
}

- (IBAction)chooseHBRoot:(id)sender
{
	NSOpenPanel *open_panel = [NSOpenPanel openPanel];
	[open_panel setCanChooseFiles:NO];
	[open_panel setCanChooseDirectories:YES];
	[open_panel beginSheetForDirectory:nil file:nil types:nil 
		modalForWindow:[self window] modalDelegate:self 
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)okAction:(id)sender
{
	NSDictionary *errorInfo = nil;
	id a_script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptDoc"];
	
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	[a_script executeHandlerWithName:@"export_helpbook" arguments:nil error:&errorInfo];
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
	[[NSApplication sharedApplication] endSheet: [sender window] returnCode:128];
}

- (IBAction)setExportPathFromRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	[[NSUserDefaults standardUserDefaults] setObject:a_path forKey:@"ExportFilePath"];
	[self checkOKCondition];
}

- (IBAction)setHelpBookRootFromRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	if ([a_path fileExists]) {
		[[NSUserDefaults standardUserDefaults] setObject:a_path forKey:@"HelpBookRootPath"];
		[self checkOKCondition];
	}
}

- (void)windowDidLoad
{
	[helpBookRootBox setAcceptFileInfo:[NSArray arrayWithObject:
		[NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:@"FileType"]]];
	[exportDestBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:@"FileType"],
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"html", @"PathExtension", nil], nil]];
	[self checkOKCondition];
}

- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [[item infoResolvingAliasFile] objectForKey:@"ResolvedPath"];
	if (dbv == exportDestBox) {
		if ([item isFolder]) {
			NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
			NSString *current_path = [user_defaults objectForKey:@"ExportFilePath"];
			NSString *a_name;
			if (current_path) {
				a_name = [current_path lastPathComponent];
			} else {
				a_name = [user_defaults stringForKey:@"ExportFileName"];
			}
			item = [item stringByAppendingPathComponent:a_name];
		}
		[self setExportPath:item];
	} else if (dbv == helpBookRootBox) {
		[self setHelpBookRoot:item];
	}
	[self checkOKCondition];
	return YES;
}

@end
