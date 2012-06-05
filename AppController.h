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
	OSAScript *script;
}
+ (id)sharedAppController;
- (void)processTargetScriptWithHandler:(NSString *)handlerName sender:(id)sender;
- (OSAScript *)script;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)setupHelpBookAction:(id)sender;
- (IBAction)saveToFileAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
@end
