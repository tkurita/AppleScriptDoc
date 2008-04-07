global _line_end

global ASDocParser

global ASFormattingStyle
global ASHTML
global HTMLElement
global PathConverter
global SimpleRD
global TemplateProcessor
global XFile
global XList
global OneShotScriptEditor
global _app_controller

property _bookName : missing value
property _appleTitle : ""
property _use_appletitle : false
property _defaultPageName : "reference.html"
property _template_folder : "HelpBookTemplate"
property _stop_processing : false

on stop_processing()
	set my _stop_processing to true
end stop_processing

on initialize()
	set _bookName to missing value
	set _appleTitle to ""
	set _use_appletitle to false
	set _template_folder to "HelpBookTemplate"
	set _stop_processing to false
end initialize

on set_template_folder(a_name)
	set my _template_folder to a_name
end set_template_folder

on appletitle()
	return _appleTitle
end appletitle

on bookname()
	return _bookName
end bookname

on set_bookname(a_name)
	set my _bookName to a_name
end set_bookname

on set_appletitle(a_name)
	set my _appleTitle to a_name
end set_appletitle

on set_use_appletitle(a_flag)
	set _use_appletitle to a_flag
end set_use_appletitle

--global doc_container
on output_to_folder(root_ref, index_page, a_text, script_name)
	if class of index_page is not script then
		set index_page to XFile's make_with(index_page)
	end if
	
	set book_folder to index_page's parent_folder()
	
	book_folder's make_path()
	set temp_asset_folder to XFile's make_with(path to resource "assets" in directory _template_folder)
	set assets_folder to temp_asset_folder's copy_to(book_folder)
	
	set pages_folder to book_folder's make_folder("pages")
	set doc_title to ""
	set index_contents to make XList
	set style_formatter to make_from_plist() of ASFormattingStyle
	if my _stop_processing then error number -128
	set doc_container to ASDocParser's parse_list(every paragraph of a_text)
	set a_link_manager to doc_container's link_manager()
	set template_folder to XFile's make_with(path to resource _template_folder)
	set handler_template to template_folder's child("pages:handler.html")
	set rel_index_path to "../" & index_page's item_name()
	
	if my _stop_processing then error number -128
	set oneshot_doc to OneShotScriptEditor's make_with_name(ASHTML's temporary_doctitle())
	oneshot_doc's check_status()
	
	script HandlerIDManager
		property _handler_id : {}
		on handler_id_for(handler_name)
			if handler_name is not in _handler_id then
				set end of _handler_id to handler_name
				return handler_name
			else
				set n to 1
				repeat
					set new_handler_id to handler_name & "_" & n
					if new_handler_id is not in _handler_id then
						set end of _handler_id to new_handler_id
						return new_handler_id
					end if
					set n to n + 1
				end repeat
			end if
		end handler_id_for
		
	end script
	
	repeat with doc_element in elementList of doc_container
		if my _stop_processing then error number -128
		set a_kind to doc_element's get_kind()
		--log a_kind
		if a_kind is "title" then
			--log "start process title element"
			index_contents's push(as_xhtml() of doc_element)
			set doc_title to doc_element's get_contents()'s as_unicode()
			if my _bookName is missing value then
				--set my _bookName to doc_title
				set my _bookName to script_name & " Help"
			end if
			
			if _use_appletitle then
				set my _appleTitle to HTMLElement's make_with("meta", {{"name", "AppleTitle"}, {"content", _bookName}})
				set my _appleTitle to my _appleTitle's as_html()
			end if
			--log "end process title element"
			
		else if a_kind is "handler" then
			--log "start process handler element"
			set handler_name to get_handler_name() of doc_element
			set handler_id to HandlerIDManager's handler_id_for(handler_name)
			
			set handler_heading to HTMLElement's make_with("h3", {})
			set a_link to handler_heading's push_element_with("a", {{"href", "pages/" & handler_id & ".html"}})
			a_link's push(handler_name)
			index_contents's push(handler_heading's as_html())
			
			a_link_manager's set_prefix("pages/")
			set an_abstruct to doc_element's copy_abstruct()
			an_abstruct's each(a_link_manager)
			--log an_abstruct's dump()
			set srd to SimpleRD's make_with_iterator(an_abstruct)
			index_contents's push(srd's as_xhtml())
			
			set handler_page to pages_folder's child(handler_id & ".html")
			set pathconv to PathConverter's make_with(handler_page's posix_path())
			set rel_root to relative_path of pathconv for (POSIX path of root_ref)
			
			set template to TemplateProcessor's make_with_file(handler_template's as_alias())
			tell template
				insert_text("$DOC_TITLE", doc_title)
				insert_text("$HANDLERNAME", handler_name)
				insert_text("$BODY", doc_element's as_xhtml())
				insert_text("$HELPBOOK_ROOT", HTMLElement's make_with("a", {{"href", rel_root}, {"id", "HelpBookRoot"}})'s as_html())
				insert_text("$INDEX_PAGE", rel_index_path)
				write_to(handler_page)
			end tell
			--log "end process handler element"
			
		else if a_kind is "paragraph" then
			a_link_manager's set_prefix("pages/")
			doc_element's each(a_link_manager)
			index_contents's push(doc_element's as_xhtml())
		else
			--log "start process other element"
			index_contents's push(doc_element's as_xhtml())
			--log "end process other element"
		end if
	end repeat
	oneshot_doc's catch_doc()
	oneshot_doc's release()
	set index_body to index_contents's as_unicode_with(_line_end)
	set pathconv to PathConverter's make_with(index_page's posix_path())
	set rel_root to relative_path of pathconv for (POSIX path of root_ref)
	set template to TemplateProcessor's make_with_file(path to resource "index.html" in directory _template_folder)
	if my _stop_processing then error number -128
	tell template
		insert_text("$BODY", index_body)
		insert_text("$APPLETITLE", my _appleTitle)
		insert_text("$SCRIPTNAME", script_name)
		--insert_text("$BOOKNAME", my _bookName)
		insert_text("$BOOKNAME", doc_title)
		insert_text("$HELPBOOK_ROOT", HTMLElement's make_with("a", {{"href", rel_root}, {"id", "HelpBookRoot"}})'s as_html())
		--insert_text("$EDIT_SCRIPT", edit_scpt_path)
		set index_page to write_to(index_page)
	end tell
	
	if my _stop_processing then error number -128
	set css_text to style_formatter's build_css()
	set as_css_file to assets_folder's child("applescript.css")
	as_css_file's write_as_utf8(css_text)
	
	return index_page
end output_to_folder

on process_file(a_file)
	initialize()
	set a_text to call method "script_source:" of _app_controller with parameter (a_file's posix_path())
	set script_name to a_file's basename()
	
	set a_root to (POSIX file (contents of default entry "HelpBookRootPath" of user defaults)) as alias
	set a_destination to POSIX file (contents of default entry "ExportFilePath" of user defaults)
	set index_page to output_to_folder(a_root, a_destination, a_text, script_name)
	
	index_page's set_types(missing value, missing value)
	tell application "Finder"
		open index_page's as_alias()
	end tell
end process_file
