global ExportHelpBook
global XFile
global appController
global InfoPlistArranger
global DocElements

property _template_folder : "HelpBookTemplate"

on process given bundle:a_bundle, text:a_text
	-- log "start process in SetupHelpBook"
	if a_bundle is missing value then return
	if not InfoPlistArranger's check_target(a_bundle) then return
	ExportHelpBook's initialize()
	DocElements's set_script_support(true)
	set book_name to get_book_name() of InfoPlistArranger
	if book_name is not missing value then
		ExportHelpBook's set_bookname(book_name)
	end if
	set book_folder to InfoPlistArranger's get_book_folder()
	set index_page to book_folder's child("index.html")
	ExportHelpBook's set_use_appletitle(true)
	ExportHelpBook's output_to_folder(book_folder's as_alias(), index_page, a_text, a_bundle's basename())
	if book_name is missing value then
		InfoPlistArranger's set_book_name(ExportHelpBook's bookname())
	end if
	InfoPlistArranger's setup_info_pllist()
    (*
	tell application "Help Indexer"
		open (book_folder's as_alias())
	end tell
     *)
    tell current application's class "HBIndexer"'s hbIndexerWithTarget_(book_folder's posix_path())
        if not (its makeIndex() as boolean) then
            return
        end if
    end tell
    
	set a_result to appController's showHelpBook_(a_bundle's posix_path()) as boolean
	if a_result then
		display alert "Error : " & a_result
	end if
	-- log "end process in SetupHelpBook"
end process

on process_file(a_bundle)
	-- log "start process_file in SetupHelpBook"
	set a_text to appController's sourceOfScript_(a_bundle's posix_path()) as text
	process given bundle:a_bundle, text:a_text
end process_file
