/* PathSettingWindowController */

#import <Cocoa/Cocoa.h>
#import "DropBox.h"

@interface PathSettingWindowController : NSWindowController <DropBoxDragAndDrop>
{
    IBOutlet id exportDestBox;
    IBOutlet id exportDestField;
    IBOutlet id exportPathPopup;
    IBOutlet id helpBookRootBox;
    IBOutlet id helpBookRootField;
    IBOutlet id helpBookRootPopup;
	IBOutlet id okButton;
	IBOutlet id exportPathWarning;
	IBOutlet id progressIndicator;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseExportPath:(id)sender;
- (IBAction)chooseHBRoot:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)setExportPathFromRecents:(id)sender;
- (IBAction)setHelpBookRootFromRecents:(id)sender;
@end
