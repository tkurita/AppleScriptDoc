property factorySettingDict : missing value

on registerFactorySetting(fileName)
	loadFactorySettings(fileName)
	call method "registerDefaults:" of user defaults with parameter factorySettingDict
end registerFactorySetting

on loadFactorySettings(fileName)
	tell main bundle
		set factorySettingFile to path for resource fileName extension "plist"
	end tell
	set factorySettingDict to call method "dictionaryWithContentsOfFile:" of class "NSDictionary" with parameter factorySettingFile
end loadFactorySettings

on getFactorySetting for entryName
	return call method "objectForKey:" of factorySettingDict with parameter entryName
end getFactorySetting

on initializeDefaultValue(entryName, defaultValue)
	tell user defaults
		if not (exists default entry entryName) then
			make new default entry at end of default entries with properties {name:entryName, contents:defaultValue}
		end if
	end tell
end initializeDefaultValue

on readDefaultValue(entryName)
	--log entryName
	tell user defaults
		return contents of default entry entryName
	end tell
end readDefaultValue

on default_with_initialize(entry_name, default_value)
	tell user defaults
		if exists default entry entry_name then
			return contents of default entry entry_name
		else
			make new default entry at end of default entries with properties {name:entry_name, contents:default_value}
			return default_value
		end if
	end tell
end default_with_initialize
