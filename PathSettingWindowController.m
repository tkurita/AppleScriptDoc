#import <Carbon/Carbon.h>
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "AppController.h"

@implementation PathSettingWindowController

#define uselog 0

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

- (IBAction)cancelAction:(id)sender
{
	[self stopIndicator];
	[[AppController sharedAppController] cancelExport:self];
	[[NSApplication sharedApplication] endSheet:[sender window] returnCode:128];
}

- (void)checkOKCondition
{	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *root_path;
	if (!(root_path = [user_defaults stringForKey:@"HelpBookRootPath"])) {
		[okButton setEnabled:NO];return;
	}
	
	if (![root_path fileExists]) {
		[okButton setEnabled:NO];return;
	}
	
	NSString *export_path;
	if (!(export_path = [user_defaults stringForKey:@"ExportFilePath"])) {
		[okButton setEnabled:NO];return;
	}
	
	if (![export_path hasPrefix:root_path]) {
		[exportPathWarning setHidden:NO];
		[okButton setEnabled:NO];
	} else {
		[exportPathWarning setHidden:YES];
        [okButton setEnabled:YES];
	}	
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

- (IBAction)chooseExportPath:(id)sender
{
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:@[@"public.html"]];
	[save_panel setCanSelectHiddenExtension:YES];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *a_path = [user_defaults stringForKey:@"ExportFilePath"];
	NSString *a_name;
	NSString *dir = nil;
	if (a_path) {
		a_name = [a_path lastPathComponent];
		dir = [a_path stringByDeletingLastPathComponent];
		if (![dir fileExists]) dir = nil;
	} else {
		a_name = [user_defaults stringForKey:@"ExportFileName"];
	}
    if (dir) {
        [save_panel setDirectoryURL:[NSURL fileURLWithPath:dir]];
    }
    [save_panel setNameFieldStringValue:a_name];
    [save_panel beginSheetModalForWindow:self.window
                       completionHandler:^(NSInteger result) {
        if (result == NSCancelButton) return;
        [self setExportPath:[[save_panel URL] path]];
    }];
}

- (IBAction)chooseHBRoot:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *a_path = [user_defaults stringForKey:@"HelpBookRootPath"];
	
	NSOpenPanel *open_panel = [NSOpenPanel openPanel];
	[open_panel setCanChooseFiles:NO];
	[open_panel setCanChooseDirectories:YES];
	[open_panel setCanCreateDirectories:YES];
    if (a_path) {
        [open_panel setDirectoryURL:[NSURL fileURLWithPath:a_path]];
    }
    [open_panel beginSheetModalForWindow:self.window
                       completionHandler:^(NSInteger result) {
                           if (result == NSCancelButton) return;
                           [self setHelpBookRoot:[[open_panel URL] path]];
                       }];
}

- (IBAction)okAction:(id)sender
{
    AppController *app_controller = [AppController sharedAppController];
    NSDictionary *err_info = [[AppController sharedAppController] exportHelpBook:self];

	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSArray *array = [pathRecordsController selectedObjects];
	if (array) {
		[pathRecordsController removeObjects:array];
	}

	[pathRecordsController addObject:
		@{@"ExportFilePath": [user_defaults stringForKey:@"ExportFilePath"], 
			@"HelpBookRootPath": [user_defaults stringForKey:@"HelpBookRootPath"], 
			@"ScriptPath": [user_defaults stringForKey:@"TargetScript"]}];	
	[[NSApplication sharedApplication] endSheet: [sender window] returnCode:128];
    
    if (err_info) {
        if (err_info ) {
            NSError *error = [NSError errorWithDomain:@"AppleScriptDocErrorDomain"
                                                 code:[err_info[@"number"] intValue]
                                             userInfo:@{NSLocalizedDescriptionKey: err_info[@"message"]}];
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert beginSheetModalForWindow:[app_controller mainWindow]
                              modalDelegate:self
                             didEndSelector:nil
                                contextInfo:nil];
        }
    }
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
		NSEnumerator *enumerator = [@[@"HelpBookRootPath", @"ExportFilePath"]
										objectEnumerator];
		NSString *a_key;
		while (a_key = [enumerator nextObject]) {
			NSString *a_path = path_dict[a_key];
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
	[helpBookRootBox setAcceptFileInfo:@[@{@"FileType": NSFileTypeDirectory}]];
	
	[exportDestBox setAcceptFileInfo:@[@{@"FileType": NSFileTypeDirectory},
		@{@"FileType": NSFileTypeRegular,
													@"PathExtension": @"html"}]];
	
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
	item = [item infoResolvingAliasFile][@"ResolvedPath"];
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
