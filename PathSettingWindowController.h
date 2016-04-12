/* PathSettingWindowController */

#import <Cocoa/Cocoa.h>
#import "DropBox.h"

@interface PathSettingWindowController : NSWindowController <DropBoxDragAndDrop>
{
    __weak IBOutlet id exportDestBox;
    __weak IBOutlet id exportDestField;
    __weak IBOutlet id exportPathPopup;
    __weak IBOutlet id helpBookRootBox;
    __weak IBOutlet id helpBookRootField;
    __weak IBOutlet id helpBookRootPopup;
	__weak IBOutlet id okButton;
	__weak IBOutlet id exportPathWarning;
	__weak IBOutlet id progressIndicator;
	__weak IBOutlet id pathRecordsController;
}
- (IBAction)cancelAction:(id)sender;
- (IBAction)chooseExportPath:(id)sender;
- (IBAction)chooseHBRoot:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)setExportPathFromRecents:(id)sender;
- (IBAction)setHelpBookRootFromRecents:(id)sender;
@end
