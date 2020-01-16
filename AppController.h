#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAScript.h>

void showOSAError(NSDictionary *err_info);

@interface AppleScriptDocController : NSObject
- (void)outputFrom:(NSString *)src toPath:(NSString *)dst;
- (NSNumber *)setupHelpBook:(NSString *)path;
- (void)cancelExport;
- (void)setup;
- (NSDictionary *)exportHelpBook:(NSString *)path toPath:(NSString *)destination;
@end

@interface AppController : NSObject
{
    __weak IBOutlet id recentScriptsButton;
	__weak IBOutlet id targetScriptBox;
	__weak IBOutlet id progressIndicator;
    __weak IBOutlet NSArrayController *RecentScriptsController;
}

@property (nonatomic, strong) NSWindowController *pathSettingWindowController;
@property (nonatomic, weak) IBOutlet NSWindow *mainWindow;
@property (nonatomic, weak) IBOutlet AppleScriptDocController *appleScriptDocController;

+ (id)sharedAppController;
- (IBAction)makeDonation:(id)sender;
- (IBAction)popUpRecents:(id)sender;
- (IBAction)exportAction:(id)sender;
- (IBAction)setupHelpBookAction:(id)sender;
- (IBAction)saveToFileAction:(id)sender;
- (IBAction)selectTarget:(id)sender;
- (NSDictionary *)exportHelpBook:(id)sender;;
- (void)cancelExport:(id)sender;
- (void)startIndicator;
- (void)stopIndicator;
@end

