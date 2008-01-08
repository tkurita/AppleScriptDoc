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

on awake from nib theObject
	set a_name to name of theObject
	if a_name is "ExportHelpBook" then
		set _export_helpbook_button to theObject
	else if a_name is "SetupHelpBook" then
		set _setup_helpbook_button to theObject
	else if a_name is "SaveToFile" then
		set _save_button to theObject
	else if a_name is "RecentPopup" then
		set _recent_popup to theObject
	else if a_name is "ProgressIndicator" then
		set _indicator to theObject
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
		if a_suffix is in {".scpt", ".scptd"} then
			DefaultsManager's set_value("TargetScript", a_file's posix_path())
		end if
	end if
end open

