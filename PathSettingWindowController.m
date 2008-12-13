#import <Carbon/Carbon.h>
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "NSUserDefaultsExtensions.h"

@implementation PathSettingWindowController

@class ASKScriptCache;
@class ASKScript;

#define uselog 0

- (IBAction)cancelAction:(id)sender
{
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];

	id a_script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptDoc"];		
	NSDictionary *error_info = nil;
	[a_script executeHandlerWithName:@"cancel_export" arguments:nil error:&error_info];
	if (error_info) {
		[[NSAlert alertWithMessageText:@"AppleScript Error"
			defaultButton:@"OK" alternateButton:nil otherButton:nil
			informativeTextWithFormat:@"%@\nNumber: %@", 
				[error_info objectForKey:@"OSAScriptErrorMessage"],
				[error_info objectForKey:@"OSAScriptErrorNumber"]] runModal];
		NSLog([error_info description]);
	}
		
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

- (void)addToRecents:(NSString *)path forKey:(NSString *)key
{
	[[NSUserDefaults standardUserDefaults] addToHistory:path forKey:key];
	[self checkOKCondition];
}

- (void)setHelpBookRoot:(NSString *)path
{
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"HelpBookRootPath"];
	[self addToRecents:path forKey:@"RecentHelpBookRoots"];
}

- (void)setExportPath:(NSString *)path
{
	[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"ExportFilePath"];
	[self addToRecents:path forKey:@"RecentExportPathes"];
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
	[open_panel setCanCreateDirectories:YES];
	[open_panel beginSheetForDirectory:nil file:nil types:nil 
		modalForWindow:[self window] modalDelegate:self 
		didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)okAction:(id)sender
{
	NSDictionary *error_info = nil;
	id a_script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptDoc"];
	
	[progressIndicator setHidden:NO];
	[progressIndicator startAnimation:self];
	[a_script executeHandlerWithName:@"export_helpbook" arguments:nil error:&error_info];
	if (error_info) {
		NSNumber *err_no = [error_info objectForKey:@"OSAScriptErrorNumber"];
		if ([err_no intValue] != -128) {
			[[NSAlert alertWithMessageText:@"AppleScript Error"
				defaultButton:@"OK" alternateButton:nil otherButton:nil
				informativeTextWithFormat:@"%@\nNumber: %@", 
					[error_info objectForKey:@"OSAScriptErrorMessage"],
					err_no] runModal];
			NSLog([error_info description]);
		}
	}
	
	[progressIndicator stopAnimation:self];
	[progressIndicator setHidden:YES];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSArray *array = [pathRecordsController selectedObjects];
	if (array) {
		[pathRecordsController removeSelectedObjects:array];
	} else {
	
	}

	[pathRecordsController addObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			[user_defaults stringForKey:@"ExportFilePath"], @"ExportFilePath", 
			[user_defaults stringForKey:@"HelpBookRootPath"], @"HelpBookRootPath", 
			[user_defaults stringForKey:@"TargetScript"], @"ScriptPath", nil]];	
	[[NSApplication sharedApplication] endSheet: [sender window] returnCode:128];
}

- (IBAction)setExportPathFromRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if (!is_optkey) {
		[[NSUserDefaults standardUserDefaults] setObject:a_path forKey:@"ExportFilePath"];
		[self checkOKCondition];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:a_path
														  forKey:@"RecentExportPathes"];
	}
}

- (IBAction)setHelpBookRootFromRecents:(id)sender
{
	NSString *a_path = [[sender selectedItem] title];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if ((!is_optkey) && [a_path fileExists]) {
		[[NSUserDefaults standardUserDefaults] setObject:a_path forKey:@"HelpBookRootPath"];
		[self checkOKCondition];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:a_path
														  forKey:@"RecentHelpBookRoots"];
	}
}

- (void)updatePathesForTarget
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *target_path = [user_defaults objectForKey:@"TargetScript"];
	NSPredicate *predicate = [NSPredicate
								predicateWithFormat:@"ScriptPath like[c] %@", target_path];
	[pathRecordsController setFilterPredicate:predicate];
	NSArray *array = [pathRecordsController arrangedObjects];
	
	if (array && [array count]) {
		NSDictionary *path_dict = [array lastObject];
		NSEnumerator *enumerator = [[NSArray arrayWithObjects:@"HelpBookRootPath", @"ExportFilePath", nil]
										objectEnumerator];
		NSString *a_key;
		while (a_key = [enumerator nextObject]) {
			NSString *a_path = [path_dict objectForKey:a_key];
			if (a_path) {
				[user_defaults setObject:a_path forKey:a_key];
			}
		}
		[pathRecordsController setSelectedObjects:array];
	} else {
#if uselog	
		NSLog(@"No content");
#endif		
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
#if uselog
	NSLog(@"observeValueForKeyPath");
#endif	
	if ([keyPath isEqualToString:@"values.TargetScript"]) {
		[self updatePathesForTarget];
	}
}

- (void)windowDidLoad
{
#if uselog
	NSLog(@"windowDidLoad");
#endif
	[helpBookRootBox setAcceptFileInfo:[NSArray arrayWithObject:
		[NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:@"FileType"]]];
	
	[exportDestBox setAcceptFileInfo:[NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObject:NSFileTypeDirectory forKey:@"FileType"],
		[NSDictionary dictionaryWithObjectsAndKeys:NSFileTypeRegular, @"FileType",
													@"html", @"PathExtension", nil], nil]];
	
	NSPopUpButtonCell *a_cell = [helpBookRootPopup cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];

	a_cell = [exportPathPopup cell];
	[a_cell setBezelStyle:NSSmallSquareBezelStyle];
	[a_cell setArrowPosition:NSPopUpArrowAtCenter];

	[self updatePathesForTarget];
	[self checkOKCondition];
	 [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
             forKeyPath:@"values.TargetScript"
                 options:(NSKeyValueObservingOptionNew)
                    context:NULL];
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
