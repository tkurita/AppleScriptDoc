/*
extern void ASKInitialize();
extern int NSApplicationMain(int argc, const char *argv[]);

int main(int argc, const char *argv[])
{
    ASKInitialize();

    return NSApplicationMain(argc, argv);
}
*/

#import <Cocoa/Cocoa.h>
#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
	[[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
	
	return NSApplicationMain(argc, (const char **) argv);
}

