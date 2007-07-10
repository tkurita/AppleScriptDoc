/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
    IBOutlet id recentScriptsButton;
}
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
@end
