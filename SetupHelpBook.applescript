global ExportHelpBook
global XFile
global _app_controller
global InfoPlistArranger

property _template_folder : "HelpBookTemplate"

on write_handler(handler_elem)
	set template to TemplateProcessor's make_with_file(path to resource "reference.html" in directory _template_folder)
end write_handler

on process given bundle:a_bundle, text:a_text
	--log "start process in SetupHelpBook"
	if a_bundle is missing value then return
	if not InfoPlistArranger's check_target(a_bundle) then return
	ExportHelpBook's initialize()
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
	tell application "Help Indexer"
		open (book_folder's as_alias())
	end tell
	
	show helpbook (a_bundle's as_alias())
end process

on process_file(a_bundle)
	set a_text to call method "script_source:" of _app_controller with parameter (a_bundle's posix_path())
	process given bundle:a_bundle, text:a_text
end process_file
