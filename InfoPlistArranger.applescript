global XFile

property _target_bundle : missing value
property _book_name : missing value
property _book_folder_name : missing value
property _target_plist : missing value
property _need_setup : false
property _plist_file : missing value
property _is_setuped : false
property _book_folder : missing value

on check_target(a_target_bundle)
	set _book_folder to missing value
	set _is_setuped to false
	set _need_setup to false
	set _target_bundle to a_target_bundle
	
	set contents_folder to a_target_bundle's child("Contents:")
	set _plist_file to contents_folder's child("Info.plist")
	if not (_plist_file's item_exists()) then
		--log (_plist_file's unicode_value())
		--display alert "The document " & quote & (a_target_bundle's item_name()) & quote & " does't have Info.plist."
		--return false
		set myself to XFile's make_with(path to me)
		set empty_plist to myself's bundle_resource("empty-Info.plist")
		set _plist_file to empty_plist's copy_to(_plist_file)
	end if
	
	tell application "System Events"
		set _target_plist to value of contents of property list file (_plist_file's hfs_path())
	end tell
	
	try
		set _book_name to |CFBundleHelpBookName| of _target_plist
	on error
		set _book_name to missing value
		set _need_setup to true
		--set book_name to (targetBundle's basename()) & " Reference"
	end try
	
	try
		set _book_folder_name to |CFBundleHelpBookFolder| of _target_plist
	on error
		set _book_folder_name to missing value
		set _need_setup to true
	end try
	
	if _book_folder_name is not missing value then
		set resource_folder to my _target_bundle's bundle_resources_folder()
		set _book_folder to resource_folder's make_folder(_book_folder_name)
	end if
	
	return true
end check_target

on set_book_name(book_name)
	set _book_name to book_name
end set_book_name

on get_book_name()
	return my _book_name
end get_book_name

on setup_book_folder()
	if _book_folder_name is missing value then
		set _book_folder_name to (_target_bundle's basename()) & "Help"
	end if
	set resource_folder to my _target_bundle's bundle_resources_folder()
	set _book_folder to resource_folder's make_folder(_book_folder_name)
end setup_book_folder

on get_book_folder()
	--set resources_folder to my _target_bundle's bundle_resources_folder()
	--return resources_folder's child(my _book_folder_name)
	if my _book_folder is missing value then
		setup_book_folder()
	end if
	
	return _book_folder
end get_book_folder

on setup_info_pllist()
	set _is_setuped to true
	if not _need_setup then return
	
	if my _book_name is missing value then
		set my _book_name to (_target_bundle's basename()) & " Reference"
	end if
	
	set helpbook_rec to {|CFBundleHelpBookName|:my _book_name, |CFBundleHelpBookFolder|:_book_folder_name}
	set new_rec to _target_plist & helpbook_rec
	tell application "System Events"
		set value of contents of property list file (_plist_file's hfs_path()) to new_rec
	end tell
	
	set resource_folder to my _target_bundle's bundle_resources_folder()
	
	(** setup recover-Info.plist **)
	set recover_plist to resource_folder's child("recover-Info.plist")
	if recover_plist's item_exists() then
		tell application "System Events"
			set a_plist_ref to property list file (_plist_file's hfs_path())
			set reccover_plist_rec to value of contents of a_plist_ref
			set value of contents of a_plist_ref to (reccover_plist_rec & helpbook_rec)
		end tell
	else
		_plist_file's copy_to(resource_folder's child("recover-Info.plist"))
	end if
end setup_info_pllist
