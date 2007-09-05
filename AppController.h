/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id recentScriptsButton;
	IBOutlet id mainWindow;
	NSWindowController *pathSettingWindowController;
}
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
@end
