global ExportHelpBook
global XFile
global _app_controller
global DocElements

on process_file(a_file)
	try
		set a_result to choose file name default name "index.html"
	on error
		return
	end try
	set index_page to XFile's make_with(a_result)
	set index_page to index_page's change_path_extension("html")
	set a_text to call method "sourceOfScript:" of _app_controller with parameter (a_file's posix_path())
	set script_name to a_file's basename()
	
	ExportHelpBook's initialize()
	ExportHelpBook's set_template_folder("HTMLTemplate")
	DocElements's set_script_support(false)
	set index_page to ExportHelpBook's output_to_folder(a_result, index_page, a_text, script_name)
	index_page's set_types(missing value, missing value)
	tell application "Finder"
		open index_page's as_alias()
	end tell
end process_file
