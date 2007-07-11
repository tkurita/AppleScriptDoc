global XFileBase

on make
	script XFileExtend
		property parent : XFileBase
		
		on resolve_alias()
			set info_rec to resolve_info_record()
			if alias of info_rec then
				set a_url to call method "fileURLWithPath:" of class "NSURL" with parameter my _itemRef
				set a_url to call method "resolveAliasFile" of a_url
				try
					set a_path to call method "path" of a_url
					set original_item to (POSIX file a_path) as alias
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