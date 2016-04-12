#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

void showOSAError(NSDictionary *err_info);

@class AppleScriptDocController;

@interface AppController : NSObject
{
    __weak IBOutlet id recentScriptsButton;
	__weak IBOutlet id targetScriptBox;
	__weak IBOutlet id progressIndicator;
	__weak IBOutlet AppleScriptDocController *appleScriptDocController;
}

@property (nonatomic, strong) NSWindowController *pathSettingWindowController;
@property (nonatomic, weak) IBOutlet NSWindow *mainWindow;

+ (id)sharedAppController;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)setupHelpBookAction:(id)sender;
- (IBAction)saveToFileAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
- (NSDictionary *)exportHelpBook:(id)sender;;
- (void)cancelExport:(id)sender;
@end
