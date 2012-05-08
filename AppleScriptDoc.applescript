(*== Modules *)
property DefaultsManager : missing value
property ASDocParser : missing value
property ExportHelpBook : missing value
property SetupHelpBook : missing value
property SaveToFile : missing value
property InfoPlistArranger : missing value

property ASFormattingStyle : missing value
property ASHTML : missing value
property DocElements : missing value
property XFile : missing value
property OneShotScriptEditor : missing value

-- modules loaded at compile time
property HTMLElement : module
property SimpleRD : module
property XDict : module
property XList : module
property XText : module
property TemplateProcessor : module
property XFileBase : module "XFile"
property PathConverter : module
property XCharacterSet : module
property CSSBuilder : module
property RGBColor : module


(*== GUI elements *)
property _recent_popup : missing value
property _indicator : missing value

property _app_controller : missing value

(*== variables *)
property _target_script : missing value

(*== constants *)
property _line_end : missing value

on boot
	boot (module loader of application (get "AppleScriptDocLib")) for me
	set my _line_end to HTMLElement's line_end()
end boot

property _ : boot

on export_helpbook()
	--log "start export_helpbook"
	set a_path to contents of default entry "TargetScript" of user defaults
	ExportHelpBook's process_file(XFile's make_with(a_path))
end export_helpbook

on cancel_export()
	ExportHelpBook's stop_processing()
end cancel_export

on setup_helpbook(a_path)
	SetupHelpBook's process_file(XFile's make_with(POSIX file a_path))
end setup_helpbook

on save_to_file(a_path)
	SaveToFile's process_file(XFile's make_with(POSIX file a_path))
end save_to_file

on import_script(script_name)
	tell main bundle
		set a_path to path for script script_name extension "scpt"
	end tell
	return load script POSIX file a_path
end import_script

on will finish launching theObject
	--boot
	set ASFormattingStyle to import_script("ASFormattingStyle")
	set ASHTML to import_script("ASHTML")'s initialize()
	set XFile to make (import_script("XFileExtend"))
	
	set DefaultsManager to import_script("DefaultsManager")
	set ASDocParser to import_script("ASDocParser")
	ASDocParser's set_wrap_with_block(false)
	set DocElements to import_script("DocElements")
	set ExportHelpBook to import_script("ExportHelpBook")
	set SetupHelpBook to import_script("SetupHelpBook")
	set SaveToFile to import_script("SaveToFile")
	set InfoPlistArranger to import_script("InfoPlistArranger")
	set _app_controller to call method "delegate"
end will finish launching

on clicked theObject
	set a_name to name of theObject
	if a_name is "CancelExport" then
		--log "CancelExport"
	end if
end clicked

on awake from nib theObject
	set a_name to name of theObject
	if a_name is "RecentPopup" then
		set _recent_popup to theObject
	end if
end awake from nib

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
		set app_controller to call method "delegate"
		call method "setTargetScript:" of app_controller with parameter a_file's posix_path()
	end if
	return true
end open

