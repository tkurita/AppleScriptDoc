install:
	xcodebuild -workspace AppleScriptDoc.xcworkspace -scheme AppleScriptDoc -configuration Release clean install DSTROOT=${HOME}

clean:
	xcodebuild -workspace AppleScriptDoc.xcworkspace -scheme AppleScriptDoc -configuration Release clean DSTROOT=${HOME}