global XFile
property NSString : class "NSString"
property NSMutableDictionary : class "NSMutableDictionary"

on make_with(x_file)
    set a_class to me
    set a_dict to NSMutableDictionary's dictionaryWithContentsOfFile_(¬
                        x_file's child("Contents/Info.plist")'s posix_path())
    script InfoPlistArrangerInstance
        property parent : a_class
        property _target_xfile : x_file
        property _info_dict : a_dict
        property _book_folder_name : a_dict's objectForKey_("CFBundleHelpBookFolder")
        property _book_folder : missing value
        property _need_setup : false
        property _bundle_id_is_checked : false
    end script

    tell InfoPlistArrangerInstance
        if its _book_folder_name is missing value then
            set my _need_setup to true
        else
            set resource_folder to x_file's bundle_resources_folder()
            set its _book_folder to resource_folder's make_folder(its _book_folder_name)
        end if
    end tell

    return InfoPlistArrangerInstance
end make_with

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
    return my _target_xfile's basename()
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
	if my _book_folder_name is missing value then
		set my _book_folder_name to (my _target_xfile's basename()) & "Help"
        my _info_dict's setObject_forKey_(my _book_folder_name, "CFBundleHelpBookFolder")
        set my _need_setup to true
	end if
	set resource_folder to my _target_xfile's bundle_resources_folder()
	set my _book_folder to resource_folder's make_folder(my _book_folder_name)
end setup_book_folder

on get_book_folder()
	if my _book_folder is missing value then
		setup_book_folder()
	end if
	return my _book_folder
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
    if not my _bundle_id_is_checked then
        bundle_identifier()
    end if
    
	if not my _need_setup then return
    set target_infoPlist to my _target_xfile's child("Contents/Info.plist")
    my _info_dict's writeToFile_atomically_(target_infoPlist's posix_path(), 1)
    
    set recover_plist to my _target_xfile's bundle_resources_folder()'s child("recover-Info.plist")
    if recover_plist's item_exists() then
        target_infoPlist's copy_to(recover_plist)
    end if
    set my _need_setup to false
end setup_info_plist
