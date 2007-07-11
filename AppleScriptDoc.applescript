(*== Modules *)
property DefaultsManager : missing value
property ASDocParser : missing value
property ExportHelpBook : missing value
property SetupHelpBook : missing value
property SaveToFile : missing value

property ASFormattingStyle : missing value
property ASHTML : missing value
property DocElements : missing value
property HTMLElement : missing value
property SimpleRD : missing value
property XDict : missing value
property XList : missing value
property XText : missing value
property PathAnalyzer : missing value
property TemplateProcessor : missing value
property XFileBase : missing value
property PathConverter : missing value
property XFile : missing value

on __load__(loader)
	tell loader
		set DocElements to load("DocElements")
		set TemplateProcessor to load("TemplateProcessor")
		set PathConverter to load("PathConverter")
	end tell
	set SimpleRD to DocElements's SimpleRD
	set HTMLElement to SimpleRD's HTMLElement
	set XList to SimpleRD's XList
	set XText to XList's XText
	
	set ASHTML to DocElements's ASHTML
	set XText to ASHTML's XText
	set ASFormattingStyle to ASHTML's ASFormattingStyle
	set XDict to ASFormattingStyle's XDict
	set XFileBase to TemplateProcessor's XFile
	set PathAnalyzer to XFileBase's PathAnalyzer
	
	return missing value
end __load__

property _ : __load__(proxy() of application (get "AppleScriptDocLib"))
--property _ : __load__(application (get "AppleScriptDocLib"))

(*== GUI elements *)
property _target_script_field : missing value
property _export_helpbook_button : missing value
property _setup_helpbook_button : missing value
property _save_button : missing value
property _recent_popup : missing value

(*== variables *)
property _target_script : missing value

(*== constants *)
property _line_end : HTMLElement's line_end()

on display_hello(msg)
	log msg
	display dialog msg
end display_hello

on import_script(script_name)
	tell main bundle
		set a_path to path for script script_name extension "scpt"
	end tell
	return load script POSIX file a_path
end import_script

on will finish launching theObject
	set XFile to make (import_script("XFileExtend"))
	
	set DefaultsManager to import_script("DefaultsManager")
	set ASDocParser to import_script("ASDocParser")
	set ExportHelpBook to import_script("ExportHelpBook")
	set SetupHelpBook to import_script("SetupHelpBook")
	set SaveToFile to import_script("SaveToFile")
end will finish launching

on launched theObject
	set_target_script(DefaultsManager's default_with_initialize("TargetScript", ""))
	show window "Main"
	call method "remindDonation" of class "DonationReminder"
end launched

on is_script_file(a_path)
	set a_path to a_path as Unicode text
	return ((a_path ends with ".scpt") or (a_path ends with ".scptd"))
end is_script_file

on setup_for_no_target()
	set a_path to ""
	set enabled of _export_helpbook_button to false
	set enabled of _setup_helpbook_button to false
	set enabled of _save_button to false
	set content of _target_script_field to a_path
	set contents of default entry "TargetScript" of user defaults to a_path
	set _target_script to missing value
end setup_for_no_target

on set_target_from_recent(a_path)
	set a_file to XFile's make_with(POSIX file a_path)
	if not a_file's item_exists() then
		setup_for_no_target()
		return
	end if
	set content of _target_script_field to a_path
	set contents of default entry "TargetScript" of user defaults to a_path
	set enabled of _setup_helpbook_button to a_file's is_package()
	set enabled of _export_helpbook_button to true
	set enabled of _save_button to true
	set _target_script to a_file
end set_target_from_recent

on set_target_script(a_path)
	--log "start set_target_script"
	if a_path is "" then
		setup_for_no_target()
		return
	end if
	
	if class of a_path is script then
		set a_file to a_path
		set a_path to a_file's posix_path()
	else
		set a_file to XFile's make_with(POSIX file a_path)
	end if
	
	if not a_file's item_exists() then
		setup_for_no_target()
		return
	end if
	--log "before resolve_alias"
	set a_file to a_file's resolve_alias()
	--log "after resolve_alias"
	if a_file is missing value then
		display dialog "No original item of " & (quoted form of a_path)
		setup_for_no_target()
		return
	end if
	
	set a_path to a_file's posix_path()
	set content of _target_script_field to a_path
	set contents of default entry "TargetScript" of user defaults to a_path
	set recent_list to DefaultsManager's default_with_initialize("RecentScripts", {})
	if recent_list does not contain a_path then
		set beginning of recent_list to a_path
		set a_max to contents of default entry "RecentsMax" of user defaults
		if (length of recent_list) > a_max then
			set recent_list to items 1 thru a_max of recent_list
		end if
		--log "before set RecentScripts"
		set contents of default entry "RecentScripts" of user defaults to recent_list
		set title of _recent_popup to ""
		--log "after set RecentScripts"
	end if
	
	set enabled of _setup_helpbook_button to a_file's is_package()
	set enabled of _export_helpbook_button to true
	set enabled of _save_button to true
	set _target_script to a_file
end set_target_script

on make_slave_doc(an_xfile)
	script SlaveDoc
		property parent : an_xfile
		property _is_doc_opened : false
		property _is_app_launched : false
		property _doc_ref : missing value
		
		on check_status()
			tell application "System Events"
				set a_list to application processes whose name is "Script Editor"
			end tell
			set _is_app_launched to (length of a_list) > 0
			set my _doc_ref to missing value
			set _is_doc_opened to false
			if _is_app_launched then
				set a_path to posix_path()
				tell application "Script Editor"
					set a_list to documents whose path is a_path
				end tell
				if (length of a_list) > 0 then
					set my _doc_ref to item 1 of a_list
					set _is_doc_opened to true
				end if
			end if
			
			return my _doc_ref
		end check_status
		
		on get_contents()
			check_status()
			if my _doc_ref is missing value then
				tell application "Script Editor"
					open my as_alias()
					set _doc_ref to document 1
				end tell
			end if
			tell application "Script Editor"
				set a_text to contents of contents of my _doc_ref
			end tell
			return a_text
		end get_contents
		
		on release()
			if not _is_doc_opened then
				tell application "Script Editor" to close contents of _doc_ref
			end if
		end release
		
	end script
end make_slave_doc

on clicked theObject
	set a_name to name of theObject
	if a_name is "SelectTarget" then
		display open panel attached to window "main" for file types {"scpt", "scptd"}
	else if a_name is "ExportHelpBook" then
		ExportHelpBook's process_file(make_slave_doc(my _target_script))
	else if a_name is "SetupHelpBook" then
		SetupHelpBook's process_file(make_slave_doc(my _target_script))
	else if a_name is "SaveToFile" then
		SaveToFile's process_file(make_slave_doc(my _target_script))
	end if
end clicked

on drop theObject drag info dragInfo
	set data_types to types of pasteboard of dragInfo
	if "file names" is in data_types then
		set preferred type of pasteboard of dragInfo to "file names"
		set pathes to contents of pasteboard of dragInfo
		set_target_script(item 1 of pathes)
		set preferred type of pasteboard of dragInfo to ""
	end if
	return true
end drop

on prepare drop theObject drag info dragInfo
	set data_types to types of pasteboard of dragInfo
	set is_acceptable to false
	if "file names" is in data_types then
		set preferred type of pasteboard of dragInfo to "file names"
		set pathes to contents of pasteboard of dragInfo
		set a_path to item 1 of pathes
		set is_acceptable to is_script_file(a_path)
		set preferred type of pasteboard of dragInfo to ""
	end if
	return is_acceptable
end prepare drop

on awake from nib theObject
	set a_name to name of theObject
	if a_name is "TargetScriptField" then
		set _target_script_field to theObject
	else if a_name is "TargetScriptBox" then
		tell theObject to register drag types {"string", "rich text", "file names"}
	else if a_name is "SelectTarget" then
		tell theObject to register drag types {"string", "rich text", "file names"}
	else if a_name is "ExportHelpBook" then
		set _export_helpbook_button to theObject
	else if a_name is "SetupHelpBook" then
		set _setup_helpbook_button to theObject
	else if a_name is "SaveToFile" then
		set _save_button to theObject
	else if a_name is "Main" then
		center theObject
		call method "setFrameUsingName:" of theObject with parameter a_name
	else if a_name is "RecentPopup" then
		set _recent_popup to theObject
	end if
end awake from nib

on panel ended theObject with result withResult
	if withResult is not 1 then
		return
	end if
	
	set a_list to path names of theObject
	set a_path to item 1 of a_list
	set_target_script(a_path)
end panel ended

on will close theObject
	call method "saveFrameUsingName:" of theObject with parameter (name of theObject)
	quit
end will close

on open theObject
	activate
	set a_class to class of theObject
	if a_class is list then
		set theObject to item 1 of theObject
		set a_class to class of theObject
	end if
	if a_class is script then
		do of theObject for "" at me
	else
		set a_file to XFile's make_with(theObject)
		set a_suffix to a_file's path_extension()
		if a_suffix is in {".scpt", ".scptd"} then
			set_target_script(a_file)
		end if
	end if
end open