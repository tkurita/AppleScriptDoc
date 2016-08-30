#import <Carbon/Carbon.h>
#import "PathSettingWindowController.h"
#import "PathExtra.h"
#import "NSUserDefaultsExtensions.h"
#import "AppController.h"
#import "NSDataExtensions.h"

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
	NSURL *root_url;
	if (!(root_url = [user_defaults fileURLForKey:@"HelpBookRootURL"])) {
		[okButton setEnabled:NO];return;
	}
    NSString *root_path = root_url.path;
	if (![root_path fileExists]) {
		[okButton setEnabled:NO];return;
	}
	
	NSURL *export_url;
	if (! _exportFileURL) {
		[okButton setEnabled:NO];return;
	}
	
	if (![_exportFileURL.path hasPrefix:root_path]) {
		[exportPathWarning setHidden:NO];
		[okButton setEnabled:NO];
	} else {
		[exportPathWarning setHidden:YES];
        [okButton setEnabled:YES];
	}	
}

- (void)addToRecents:(NSData *)bmd forKey:(NSString *)key
{
	[[NSUserDefaults standardUserDefaults] addToHistory:bmd forKey:key];
	[self checkOKCondition];
}

- (void)setHelpBookRoot:(NSURL *)anURL
{
    NSError *error = nil;
    NSData *bmd = [anURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                  includingResourceValuesForKeys:nil
                                   relativeToURL:nil error:&error];
    [[NSUserDefaults standardUserDefaults] setObject:bmd forKey:@"HelpBookRootURL"];
	[self addToRecents:bmd forKey:@"RecentHelpBookRootURLs"];
}


- (void)saveExportFileURL
{
    NSError *error = nil;
    NSData *bmd = [_exportFileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil error:&error];
    [[NSUserDefaults standardUserDefaults] setObject:bmd forKey:@"ExportFileURL"];
	[self addToRecents:bmd forKey:@"RecentExportFileURLs"];
}

- (IBAction)chooseExportPath:(id)sender
{
	NSSavePanel *save_panel = [NSSavePanel savePanel];
	[save_panel setAllowedFileTypes:@[@"public.html"]];
	[save_panel setCanSelectHiddenExtension:YES];
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSURL *an_url = [user_defaults fileURLForKey:@"ExportFileURL"];
	NSString *a_name;
	NSURL *dir = nil;
	if (an_url) {
		a_name = [an_url lastPathComponent];
		dir = [an_url URLByDeletingLastPathComponent];
		if (![dir.path fileExists]) dir = nil;
	} else {
		a_name = [user_defaults stringForKey:@"ExportFileName"];
	}
    
    if (dir) {
        [save_panel setDirectoryURL:dir];
    }
    [save_panel setNameFieldStringValue:a_name];
    [save_panel beginSheetModalForWindow:self.window
                       completionHandler:^(NSInteger result) {
        if (result == NSCancelButton) return;
        self.exportFileURL = [save_panel URL];
        [self checkOKCondition];
    }];
}

- (IBAction)chooseHBRoot:(id)sender
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSURL *an_url = [user_defaults fileURLForKey:@"HelpBookRootURL"];
	
	NSOpenPanel *open_panel = [NSOpenPanel openPanel];
	[open_panel setCanChooseFiles:NO];
	[open_panel setCanChooseDirectories:YES];
	[open_panel setCanCreateDirectories:YES];
    if (an_url) {
        [open_panel setDirectoryURL:an_url];
    }
    [open_panel beginSheetModalForWindow:self.window
                       completionHandler:^(NSInteger result) {
                           if (result == NSCancelButton) return;
                           [self setHelpBookRoot:[open_panel URL]];
                       }];
}

- (IBAction)okAction:(id)sender
{
    AppController *app_controller = [AppController sharedAppController];
    NSDictionary *err_info = [[AppController sharedAppController] exportHelpBook:self];
    [self saveExportFileURL];
    
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSArray *array = [pathRecordsController selectedObjects];
	if (array && array.count) {
		[pathRecordsController removeObjects:array];
	}
    
	[pathRecordsController addObject:
		@{@"ExportFileURL": [user_defaults dataForKey:@"ExportFileURL"],
			@"HelpBookRootURL": [user_defaults dataForKey:@"HelpBookRootURL"],
			@"ScriptURL": [user_defaults dataForKey:@"TargetScript"]}];
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
    NSData *bmd = [[RecentExportFileURLsController selectedObjects] lastObject];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if (!is_optkey) {
		[[NSUserDefaults standardUserDefaults] setObject:bmd forKey:@"ExportFileURL"];
		[self checkOKCondition];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:bmd
														  forKey:@"RecentExportFileURLs"];
	}
}

- (IBAction)setHelpBookRootFromRecents:(id)sender
{
    NSData *bmd = [[RecentHelpBookRootURLsController selectedObjects] lastObject];
	UInt32 is_optkey = GetCurrentEventKeyModifiers() & optionKey;
	if ((!is_optkey) && [[bmd path] fileExists]) {
		[[NSUserDefaults standardUserDefaults] setObject:bmd forKey:@"HelpBookRootURL"];
		[self checkOKCondition];
	} else {
		[[NSUserDefaults standardUserDefaults] removeFromHistory:bmd
														  forKey:@"RecentHelpBookRootURLs"];
	}
}

- (void)updatePathesForTarget
{
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	NSString *target_path = [[user_defaults fileURLForKey:@"TargetScript"] path];
	NSPredicate *predicate = [NSPredicate
								predicateWithFormat:@"ScriptURL.path like[c] %@", target_path];
	[pathRecordsController setFilterPredicate:predicate];
	NSArray *array = [pathRecordsController arrangedObjects];
	
	if (array && [array count]) {
		NSDictionary *path_dict = [array lastObject];
		NSEnumerator *enumerator = [@[@"HelpBookRootURL", @"ExportFileURL"]
										objectEnumerator];
		NSString *a_key;
		while (a_key = [enumerator nextObject]) {
			NSData *bmd = path_dict[a_key];
			if (bmd) {
                //NSLog(@"%@", bmd.path);
				[user_defaults setObject:bmd forKey:a_key];
			}
		}
        self.exportFileURL = [path_dict[@"ExportFileURL"] fileURL];
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

    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
             forKeyPath:@"values.TargetScript"
                 options:(NSKeyValueObservingOptionNew)
                    context:NULL];
    self.exportFileURL = [[NSUserDefaults standardUserDefaults] fileURLForKey:@"ExportFileURL"];
    [self updatePathesForTarget];
    [self checkOKCondition];
}

- (BOOL)dropBox:(NSView *)dbv acceptDrop:(id <NSDraggingInfo>)info item:(id)item
{
	item = [item infoResolvingAliasFile][@"ResolvedPath"];
	if (dbv == exportDestBox) {
		if ([item isFolder]) {
			NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
			NSURL *current_url = [user_defaults fileURLForKey:@"ExportFileURL"];
			NSString *a_name;
			if (current_url) {
				a_name = [current_url lastPathComponent];
			} else {
				a_name = [user_defaults stringForKey:@"ExportFileName"];
			}
			item = [item stringByAppendingPathComponent:a_name];
		}
		[self setExportFileURL:[item fileURL]];
	} else if (dbv == helpBookRootBox) {
		[self setHelpBookRoot:[item fileURL]];
	}
	[self checkOKCondition];
	return YES;
}

@end
