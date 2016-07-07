global XFile

property _target_xfile : missing value
property _target_bundle : missing value
property _info_dict : missing value

property _book_folder_name : missing value
property _bundle_id_is_checked : false
property _need_setup : false
property _is_setuped : false
property _book_folder : missing value
property NSString : class "NSString"
property NSMutableDictionary : class "NSMutableDictionary"

on check_target(x_file)
    set my _bundle_id_is_checked to false
	set my _book_folder to missing value
	set my _is_setuped to false
	set my _need_setup to false
	set my _target_xfile to x_file
    set my _info_dict to NSMutableDictionary's dictionaryWithContentsOfFile_(_target_xfile's child("Contents/Info.plist")'s posix_file())
    
    set my _book_folder_name to _info_dict's valueForKey_("CFBundleHelpBookFolder")
    if my _book_folder_name is missing value then
        set my _need_setup to true
    else
        set resource_folder to my _target_xfile's bundle_resources_folder()
        set my _book_folder to resource_folder's make_folder(_book_folder_name)
    end if
    
	return true
end check_target

on value_for(a_key)
    return my _info_dict's objectForKey_(a_key)
end value_for

on product_name()
    set a_result to missing value
    try
        set a_result to my _info_dict's objectForKey_("CFBundleName")
    end try
    if a_result is not missing value then
        return a_result
    end if
    return _target_xfile's basename()
end product_name

on set_bookname(book_name)
    --log "start set_bookname"
    my _info_dict's setObject_forKey_(book_name, "CFBundleHelpBookName")
    set my _need_setup to true
end set_bookname

on bookname()
	return my _info_dict's objectForKey_("CFBundleHelpBookName")
end bookname

on setup_book_folder()
	if _book_folder_name is missing value then
		set my _book_folder_name to (my _target_xfile's basename()) & "Help"
        my _info_dict's setObject_forKey_(my _book_folder_name, "CFBundleHelpBookFolder")
        set my _need_setup to true
	end if
	set resource_folder to my _target_xfile's bundle_resources_folder()
	set my _book_folder to resource_folder's make_folder(_book_folder_name)
end setup_book_folder

on get_book_folder()
	if my _book_folder is missing value then
		setup_book_folder()
	end if
	return _book_folder
end get_book_folder

on bundle_identifier()
    set bundle_id to my _info_dict's objectForKey_("CFBundleIndentifier")
    if bundle_id is missing value then
        set bundle_id to (system attribute "USER") & "." & (my _target_xfile's basename())
        my _info_dict's setObject_forKey_(bundle_id, "CFBundleIndentifier")
        set my _need_setup to true
    end if
    set my _bundle_id_is_checked to true
    return bundle_id
end bundle_identifier

on setup_info_plist()
    --log "start setup_info_plist"
	set _is_setuped to true
    if not _bundle_id_is_checked then
        bundle_identifier()
    end if
	if not _need_setup then return
    set target_infoPlist to my _target_xfile's child("Contents/Info.plist")
    my _info_dict's writeToFile_atomically_(target_infoPlist's posix_path(), 1)
    
    set recover_plist to my _target_xfile's bundle_resources_folder()'s child("recover-Info.plist")
    if recover_plist's item_exists() then
        target_infoPlist's copy_to(recover_plist)
    end if
end setup_info_plist
