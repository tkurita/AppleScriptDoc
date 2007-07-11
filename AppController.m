#import "AppController.h"
#import <DonationReminder/DonationReminder.h>

#define useLog 1

@class ASKScriptCache;
@class ASKScript;

@implementation AppController

- (IBAction)makeDonation:(id)sender
{
	[DonationReminder goToDonation];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start applicationWillFinishLaunching");
#endif
	NSString *defaults_plist = [[NSBundle mainBundle] pathForResource:@"FactorySettings" ofType:@"plist"];
	NSDictionary *factory_defaults = [NSDictionary dictionaryWithContentsOfFile:defaults_plist];
	
	NSUserDefaults *user_defaults = [NSUserDefaults standardUserDefaults];
	[user_defaults registerDefaults:factory_defaults];
}

- (IBAction)popUpRecents:(id)sender
{
	NSDictionary *errorInfo = nil;
	ASKScript *a_script = [[ASKScriptCache sharedScriptCache] scriptWithName:@"AppleScriptDoc"];
	[a_script 
		executeHandlerWithName:@"set_target_from_recent" arguments:[NSArray arrayWithObject:[[sender selectedItem] title]]
			error:&errorInfo];
}

- (void)awakeFromNib {
	[recentScriptsButton setTitle:@""];
}

@end
