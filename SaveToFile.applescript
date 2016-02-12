global ExportHelpBook
global XFile
global appController
global DocElements

on process_file(a_file, index_page)
	set index_page to index_page's change_path_extension("html")
	set a_text to appController's sourceOfScript_(a_file's posix_path()) as text
	set script_name to a_file's basename()
	
	ExportHelpBook's initialize()
	ExportHelpBook's set_template_folder("HTMLTemplate")
	DocElements's set_script_support(false)
	set index_page to ExportHelpBook's output_to_folder(¬
        index_page's parent_folder()'s as_alias(), index_page, a_text, script_name)
	index_page's set_types(missing value, missing value)
	tell application "Finder"
		open index_page's as_alias()
	end tell
	-- log "end process_file in SaveToFile"
end process_file
