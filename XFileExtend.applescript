global XFileBase

on make
	script XFileExtend
		property parent : XFileBase
		
		on resolve_alias()
			set info_rec to info()
			if alias of info_rec then
				tell current application's class "NSURL"
					set a_url to its fileURLWithPath_(my _itemRef)
				end tell
				set a_url to a_url's resolveAliasFile()
				--set a_url to call method "fileURLWithPath:" of class "NSURL" with parameter my _itemRef
				--set a_url to call method "resolveAliasFile" of a_url
				try
					--set a_path to call method "path" of a_url
					set a_path to a_url's |path|() as text
					set original_item to (a_path as POSIX file) as alias
				on error
					return missing value
				end try
				return make_with(original_item)
			else
				return a reference to me
			end if
		end resolve_alias
		
	end script
	return XFileExtend
end make