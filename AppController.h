/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	IBOutlet id targetScriptBox;
	NSWindowController *pathSettingWindowController;
}
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
@end
