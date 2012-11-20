#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

void showOSAError(NSDictionary *err_info);

@interface AppController : NSObject
{
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	IBOutlet id progressIndicator;
	NSWindowController *pathSettingWindowController;
	IBOutlet id appleScriptDocController;
}
+ (id)sharedAppController;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)setupHelpBookAction:(id)sender;
- (IBAction)saveToFileAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
- (void)exportHelpBook:(id)sender;;
- (void)cancelExport:(id)sender;
@end
