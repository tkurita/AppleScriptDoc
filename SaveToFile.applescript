global ExportHelpBook
global XFile
global appController
global HandlerElement

on process_file(a_file, index_page)
	set index_page to index_page's change_path_extension("html")
	set a_text to appController's sourceOfScript_(a_file's posix_path()) as text
	set script_name to a_file's basename()
	
    tell (make ExportHelpBook)
        set_template_folder("HTMLTemplate")
        set_assets_srcfolders({"HelpBookTemplate/assets", "HTMLTemplate/assets-non-helpbook"})
        set exporter to it
    end tell
    HandlerElement's set_script_support(false)
    set dest_folder to index_page's parent_folder()
	set index_page to exporter's output_to_folder(¬
        dest_folder's as_alias(), index_page, a_text, script_name)
	index_page's set_types(missing value, missing value)
    
    
	tell application "Finder"
		open index_page's as_alias()
	end tell
	-- log "end process_file in SaveToFile"
end process_file
