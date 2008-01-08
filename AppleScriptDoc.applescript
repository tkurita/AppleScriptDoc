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
--property PathConverter : load("PathConverter") of application (get "AppleScriptDocLib")
property XFile : missing value
property OneShotScriptEditor : missing value

on __load__(loader)
	tell loader
		set SimpleRD to load("SimpleRD")
		set ASHTML to load("ASHTML")
		--set DocElements to load("DocElements")
		set TemplateProcessor to load("TemplateProcessor")
		set PathConverter to load("PathConverter")
		set OneShotScriptEditor to load("OneShotScriptEditor")
	end tell
	--set SimpleRD to DocElements's SimpleRD
	set HTMLElement to SimpleRD's HTMLElement
	set XDict to HTMLElement's XDict
	set XList to SimpleRD's XList
	set XText to XList's XText
	--set ASHTML to DocElements's ASHTML
	set ASFormattingStyle to ASHTML's ASFormattingStyle
	set XFileBase to TemplateProcessor's XFile
	set PathAnalyzer to XFileBase's PathAnalyzer
	
	return missing value
end __load__

property _ : __load__(proxy() of application (get "AppleScriptDocLib"))

(*== GUI elements *)
property _export_helpbook_button : missing value
property _setup_helpbook_button : missing value
property _save_button : missing value
property _recent_popup : missing value
property _indicator : missing value

property _app_controller : missing value

(*== variables *)
property _target_script : missing value

(*== constants *)
property _line_end : HTMLElement's line_end()

on export_helpbook()
	--log "start export_helpbook"
	set a_path to contents of default entry "TargetScript" of user defaults
	ExportHelpBook's process_file(XFile's make_with(POSIX file a_path))
end export_helpbook

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
	ASDocParser's set_wrap_with_block(false)
	set DocElements to import_script("DocElements")
	set ExportHelpBook to import_script("ExportHelpBook")
	set SetupHelpBook to import_script("SetupHelpBook")
	set SaveToFile to import_script("SaveToFile")
	set _app_controller to call method "delegate"
end will finish launching
(*
on launched theObject
	--set_target_script(DefaultsManager's default_with_initialize("TargetScript", ""))
	--show window "Main"
	--call method "remindDonation" of class "DonationReminder"
end launched
*)

(*
on is_script_file(a_path)
	set a_path to a_path as Unicode text
	return ((a_path ends with ".scpt") or (a_path ends with ".scptd"))
end is_script_file

on setup_for_no_target()
	set a_path to ""
	set enabled of _export_helpbook_button to false
	set enabled of _setup_helpbook_button to false
	set enabled of _save_button to false
	set contents of default entry "TargetScript" of user defaults to a_path
	set _target_script to missing value
end setup_for_no_target

on set_target_from_recent(a_path)
	set a_file to XFile's make_with(POSIX file a_path)
	if not a_file's item_exists() then
		setup_for_no_target()
		return
	end if
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
*)

on start_indicator()
	set visible of _indicator to true
	start _indicator
end start_indicator

on stop_indicator()
	stop _indicator
	set visible of _indicator to false
end stop_indicator

on clicked theObject
	set a_name to name of theObject
	(*
	if a_name is "SelectTarget" then
		display open panel attached to window "main" for file types {"scpt", "scptd"}
	else 
	*)
	if a_name is "SetupHelpBook" then
		start_indicator()
		set a_path to contents of default entry "TargetScript" of user defaults
		SetupHelpBook's process_file(XFile's make_with(POSIX file a_path))
		stop_indicator()
	else if a_name is "SaveToFile" then
		start_indicator()
		set a_path to contents of default entry "TargetScript" of user defaults
		SaveToFile's process_file(XFile's make_with(POSIX file a_path))
		stop_indicator()
	end if
end clicked

(*
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
*)

on awake from nib theObject
	set a_name to name of theObject
	(* if a_name is "TargetScriptBox" then
		tell theObject to register drag types {"string", "rich text", "file names"}
	else if a_name is "SelectTarget" then
		tell theObject to register drag types {"string", "rich text", "file names"}
	else
	*)
	if a_name is "ExportHelpBook" then
		set _export_helpbook_button to theObject
	else if a_name is "SetupHelpBook" then
		set _setup_helpbook_button to theObject
	else if a_name is "SaveToFile" then
		set _save_button to theObject
		(*else if a_name is "Main" then
		center theObject
		call method "setFrameUsingName:" of theObject with parameter a_name*)
	else if a_name is "RecentPopup" then
		set _recent_popup to theObject
	else if a_name is "ProgressIndicator" then
		set _indicator to theObject
	end if
end awake from nib

(*
on panel ended theObject with result withResult
	if withResult is not 1 then
		return
	end if
	
	set a_list to path names of theObject
	set a_path to item 1 of a_list
	set_target_script(a_path)
end panel ended
*)

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
			DefaultsManager's set_value("TargetScript", a_file's posix_path())
			--set contents of default entry "TargetScript" of user defaults to a_file's posix_path()
		end if
	end if
end open

(*
on will quit theObject
	call method "saveFrameUsingName:" of window "Main" with parameter "Main"
end will quit
*)
