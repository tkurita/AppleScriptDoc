#import "ScriptCommands.h"
#import "AppController.h"

@implementation SetupHelpBookCommand
- (id)performDefaultImplementation
{
    NSURL *an_url = self.directParameter;
    AppController *app_controller = [AppController sharedAppController];
    [app_controller startIndicator];
    NSNumber *result = [app_controller.appleScriptDocController setupHelpBook:an_url.path];
    [app_controller stopIndicator];
    
    return result;
}
@end
