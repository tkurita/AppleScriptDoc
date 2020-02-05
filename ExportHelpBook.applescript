global _line_end

global ASDocParser
global HandlerElement
global ASFormattingStyle
global ASHTML
global HTMLElement
global PathConverter
global SimpleRD
global TemplateProcessor
global XFile
global XList
global appController

property _bookName : missing value
property _appleTitle : ""
property _use_appletitle : false
property _defaultPageName : "reference.html"
property _template_folder : "HelpBookTemplate"
property _assets_srcfolders : {"HelpBookTemplate/assets", "HelpBookTemplate/assets-helpbook"}
property _stop_processing : false

property _current_exporter : missing value

on make
    set a_class to me
    script ExportHelpBookInstance
        property _bookName : my _bookName
        property _appleTitle : my _appleTitle
        property _use_appletitle : my _use_appletitle
        property _defaultPageName : my _defaultPageName
        property _template_folder : my _template_folder
        property _assets_srcfolders : my _assets_srcfolders
        property _stop_processing : false
        property _current_exporter : me
    end script
    set my _current_exporter to ExportHelpBookInstance
    return ExportHelpBookInstance
end make

on set_assets_srcfolders(a_list)
    set my _assets_srcfolders to a_list
end set_assets_srcfolders

on stop_processing()
	set my _current_exporter's _stop_processing to true
end stop_processing

on set_template_folder(a_name)
	set my _template_folder to a_name
end set_template_folder

on appletitle()
	return my _appleTitle
end appletitle

on bookname()
	return my _bookName
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

on jump_list(index_contents)
	--log "start jump_list in ExportHelpBook"
	set jp_list to HTMLElement's make_with("select", {{"onchange", "navibarJump(this)"}})
	jp_list's push_element_with("option", {{"value", ""}})'s push("§")
	script walker
		on push_headding(he, marker)
			--log "start push_headding"
			try
				he's attribute_value -- check handler existance
				set attv to he's attribute_value("id")
			on error msg number errno
				if errno is not in {-1700, -1728, 900} then
					error msg number errno
				end if
				return true
			end try
			set jp_label to he's plain_contents()
			if class of attv is script then
				set attv to attv's as_unicode()
			end if
			jp_list's push_element_with("option", {{"value", "#" & attv}})'s push(marker & jp_label)
			--log "end push_headding"
		end push_headding
		
		on do(he)
			--log "start do in walker in jump_list"
			try
				he's element_name
				set ename to he's element_name()
			on error msg number errno
				if errno is not in {-1700, -1728} then
					error msg number errno
				end if
				return true
			end try
			if ename is "h2" then
				push_headding(he, "")
			else if ename is "h3" then
				push_headding(he, "- ")
			end if
			--log "end do in walker in jump_list"
			return true
		end do
	end script
	index_contents's walk(walker)
	--log "end jump_list in ExportHelpBook"
	return jp_list
end jump_list

--global doc_container
on output_to_folder(root_ref, index_page, a_text, script_name)
	--log "start output_to_folder in ExportHelpBook"
	if class of index_page is not script then
		set index_page to XFile's make_with(index_page)
	end if
	set book_folder to index_page's parent_folder()
	book_folder's make_path(missing value)
    script CopyAssetsFolders
        on do(src)
            -- log "start do in CopyAssetsFolders : "&src
            set x_src to XFile's make_with(path to resource src)
            return x_src's copy_with_replacing(book_folder)
        end do
    end script
    set assets_folders to XList's make_with(my _assets_srcfolders)'s map(CopyAssetsFolders)

    set pages_folder to book_folder's make_folder("pages")

	set index_contents to make HTMLElement
	set style_formatter to ASFormattingStyle's make_from_setting()
	if my _stop_processing then error number -128
	set doc_container to ASDocParser's parse_list(every paragraph of a_text)
    
	set a_link_manager to doc_container's link_manager()
	set root_page_path to index_page's posix_path()
	a_link_manager's set_root_page(root_page_path)
	a_link_manager's set_current_page(root_page_path)
	set a_path to path to resource my _template_folder
	set template_folder to XFile's make_with(a_path)
	set handler_template to template_folder's child("pages/handler.html")
	set rel_index_path to "../" & index_page's item_name()
	if my _stop_processing then error number -128
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

    set doc_title to missing value
	--log "will arrange doc elements in output_to_folder of ExportHelpBook"
	repeat with doc_element in elementList of doc_container
		if my _stop_processing then error number -128
		set a_kind to doc_element's get_kind()
		--log a_kind
		if a_kind is "title" then
			--log "start process title element"
			index_contents's push(doc_element's html_element())
			set doc_title to doc_element's get_contents()'s as_unicode()
			--log "end process title element"
			
		else if a_kind is "handler" then
			--log "start process handler element"
			set handler_name to doc_element's get_handler_name()
			-- log handler_name
			set handler_id to HandlerIDManager's handler_id_for(handler_name)
			set handler_heading to HTMLElement's make_with("h3", {{"id", handler_id}})
			set a_link to handler_heading's push_element_with("a", {{"href", "pages/" & handler_id & ".html"}})
			a_link's push(handler_name)
			index_contents's push(handler_heading)
			a_link_manager's set_prefix("pages/")
			set an_abstruct to doc_element's copy_abstruct()
			an_abstruct's enumerate(a_link_manager)
			set srd to SimpleRD's make_with_iterator(an_abstruct)
			index_contents's push(srd's html_tree())
			set handler_page to pages_folder's child(handler_id & ".html")
			set hanlder_page_path to handler_page's posix_path()
			a_link_manager's set_current_page(hanlder_page_path)
			set pathconv to PathConverter's make_with(hanlder_page_path)
			set rel_root to relative_path of pathconv for (POSIX path of root_ref)
			set template to TemplateProcessor's make_with_file(handler_template's as_alias())
			tell template
				insert_text("$DOC_TITLE", doc_title)
				insert_text("$HANDLER_NAME", handler_name)
				insert_text("$SCRIPT_NAME", script_name)
				insert_text("$BODY", doc_element's as_xhtml())
				insert_text("$HELPBOOK_ROOT", rel_root)
				insert_text("$INDEX_PAGE", rel_index_path)
				write_to(handler_page)
			end tell
			a_link_manager's set_current_page(root_page_path)
			-- log "end process handler element"
			
		else if a_kind is "paragraph" then
			-- log "kind is paragraph"
			a_link_manager's set_prefix("pages/")
			doc_element's enumerate(a_link_manager)
			index_contents's push(doc_element's html_element())
			--log "end kind is paragraph"
		else
			--log "start process other element"
			index_contents's push(doc_element's html_element())
			-- log "end process other element"
		end if
	end repeat

    if doc_title is missing value then
        set doc_title to script_name & " Reference"
    end if

    if my _bookName is missing value then
        set my _bookName to doc_title
    end if

    if _use_appletitle then
        set my _appleTitle to HTMLElement's make_with("meta", {{"name", "AppleTitle"}, {"content", my _bookName}})
        set my _appleTitle to my _appleTitle's as_html()
    end if

	-- log "index_contents's as_html"
	set index_body to index_contents's as_html()
	set jump_list_text to jump_list(index_contents)'s as_html()
	set pathconv to PathConverter's make_with(index_page's posix_path())
	set rel_root to relative_path of pathconv for (POSIX path of root_ref)
	set a_path to path to resource "index.html" in directory my _template_folder
	set template to TemplateProcessor's make_with_file(a_path)
	if my _stop_processing then error number -128
	tell template
		insert_text("$JUMP_LIST", jump_list_text)
		insert_text("$BODY", index_body)
		insert_text("$APPLE_TITLE", my _appleTitle)
		insert_text("$SCRIPT_NAME", script_name)
		insert_text("$BOOK_NAME", doc_title)
		insert_text("$HELPBOOK_ROOT", rel_root)
		set index_page to write_to(index_page)
	end tell
	if my _stop_processing then error number -128
	-- log "before build css in output_to_folder"
	set css_text to style_formatter's build_css()
	set as_css_file to assets_folders's item_at(1)'s child("applescript.css")
	as_css_file's write_as_utf8(css_text)

	-- log "end of output_to_folder"
	return index_page
end output_to_folder

on process({source:x_file, destination:a_destination})
	HandlerElement's set_script_support(true)
    if x_file's path_extension() is "applescript" then
        set a_text to read (x_file's posix_path())
    else
        set a_text to appController's sourceOfScript_(x_file's posix_path()) as text
    end if
	set script_name to x_file's basename()
	tell current application's class "NSUserDefaults"'s standardUserDefaults()
        set a_root to ((its fileURLForKey_("HelpBookRootURL")'s |path|() as text) as POSIX file) as alias
		--set a_root to ((its stringForKey_("HelpBookRootPath") as text) as POSIX file) as alias
		--set a_destination to (its stringForKey_("ExportFilePath") as text) as POSIX file
	end tell
	set index_page to output_to_folder(a_root, a_destination, a_text, script_name)
	
	-- index_page's set_types(missing value, missing value)
    set aURL to current application's |NSURL|'s fileURLWithPath:(index_page's posix_path())
    tell current application's |NSWorkspace|'s sharedWorkspace()
        its openURL:aURL
    end tell
end process

