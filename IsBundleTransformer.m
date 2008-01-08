#import "IsBundleTransformer.h"

@implementation IsBundleTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

- (id)transformedValue:(id)value
{
	
	return [NSNumber numberWithBool:
				(value && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:value])];
}

@end
