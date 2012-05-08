/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	IBOutlet id progressIndicator;
	NSWindowController *pathSettingWindowController;
}
+ (id)sharedAppController;
- (void)processTargetScriptWithHandler:(NSString *)handlerName;

- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)setupHelpBookAction:(id)sender;
- (IBAction)saveToFileAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
@end
