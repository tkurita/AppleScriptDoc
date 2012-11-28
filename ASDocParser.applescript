global ASHTML
global DocElements
global HTMLElement
global XDict
global XList
global XText
global PathConverter

global _line_end

on set_wrap_with_block(a_flag)
	ASHTML's set_wrap_with_block(a_flag)
end set_wrap_with_block

on extract_doc_region(line_list)
	set doc_block_list to {}
	
	script DocExtractor
		property _isInDoc : false
		property _docIsEnded : false
		property _textList : {}
		property _indent : ""
		property _n_indent : 0
		
		on close_region()
			if _textList is not {} then
				set a_rec to {lineEnum:XList's make_with(_textList), nextLine:""}
				set end of doc_block_list to a_rec
			end if
		end close_region
		
		on strip_indent(a_line)
			if (_n_indent > 0) and (a_line's starts_with(_indent)) then
				if a_line's is_equal(_indent) then
					set a_line to XText's make_with("")
				else
					set a_line to a_line's text_in_range(_n_indent + 1, -1)
				end if
			end if
			return a_line
		end strip_indent
		
		on do(a_line, enumerator)
			--log a_line
			if _docIsEnded then
				repeat while (a_line's equal_to(""))
					set a_line to next() of enumerator
					set a_line to XText's make_with(a_line)
				end repeat
				set a_rec to {lineEnum:XList's make_with(_textList), nextLine:a_line}
				set end of doc_block_list to a_rec
				set _textList to {}
				set _docIsEnded to false
				if a_line's equal_to(missing value) then
					return
				end if
			end if
			
			if _isInDoc or (not a_line's equal_to("")) then
				set {indent_text, beg_deblank_line} to a_line's strip_beginning()
				set {end_text, end_deblank_line} to a_line's strip_endding()
				if _isInDoc then
					set _isInDoc to not end_deblank_line's ends_with("*)")
					if _isInDoc then
						set end of _textList to strip_indent(a_line)
					else
						try
							set deblank_line to end_deblank_line's text_in_range(1, -3)
							set deblank_line to strip_indent(deblank_line)
						on error
							set deblank_line to XText's make_with("")
						end try
						
						if not deblank_line's equal_to("") then
							set end of _textList to deblank_line
						end if
						set _isInDoc to false
						set _docIsEnded to true
					end if
				else
					set _isInDoc to beg_deblank_line's starts_with("(*!")
					if _isInDoc then
						set _indent to indent_text
						set _n_indent to length of indent_text
						if length of beg_deblank_line > 3 then
							set deblank_line to beg_deblank_line's text_in_range(4, -1)
							if end_deblank_line's ends_with("*)") then
								set {end_text, deblank_line} to deblank_line's strip_endding()
								try
									set deblank_line to deblank_line's text_in_range(1, -3)
								on error
									set deblank_line to XText's make_with("")
								end try
								set _isInDoc to false
								set _docIsEnded to true
								set {end_text, deblank_line} to deblank_line's strip_endding()
							end if
							set end of _textList to deblank_line
						end if
					end if
				end if
			end if
		end do
	end script
	
	set enumerator to make_with(line_list) of XList
	repeat while enumerator's has_next()
		set a_line to enumerator's next()
		set a_line to XText's make_with(a_line)
		do(a_line, enumerator) of DocExtractor
	end repeat
	DocExtractor's close_region()
	return doc_block_list
end extract_doc_region

on is_handler(a_line)
	--log "start is_handler"
	return (a_line starts with "on ") or (a_line starts with "to ")
end is_handler

on is_heading_tag(a_line)
	set a_tag to first word of a_line
	return a_tag is in {"group", "title"}
end is_heading_tag

on is_handler_tag(a_line)
	set a_tag to first word of a_line
	return a_tag is in {"abstruct", "description", "param", "result", "syntax"}
end is_handler_tag

on is_references_tag(a_line)
	set a_tag to first word of a_line
	return a_tag is in {"references", "glossary"} -- "glossary is deprecated"
end is_references_tag

on parse_heading_region(a_region, doc_container)
	--log "start parse_heading_region"
	local paragraph_list
	set paragraph_list to {}
	set enumerator to a_region's lineEnum
	
	repeat while enumerator's has_next()
		set a_line to enumerator's next()
		--log a_line
		if (not a_line's equal_to("")) then
			if (a_line's starts_with("@")) then
				if paragraph_list is not {} then
					doc_container's push(DocElements's make_paragraph_element(paragraph_list))
					set paragraph_list to {}
				end if
				
				if is_heading_tag(a_line) then
					doc_container's push(DocElements's make_heading_element(a_line))
				else if is_handler_tag(a_line) then
					enumerator's decrement_index()
					parse_handler_region(a_region, doc_container)
					exit repeat
				else if is_references_tag(a_line) then
					parse_references(a_region, doc_container)
					exit repeat
				else
					error (quoted form of a_line) & " have an unknown tag." number 1450
				end if
			else
				set end of paragraph_list to a_line
			end if
		else
			if paragraph_list is not {} then
				set end of paragraph_list to a_line
			end if
		end if
	end repeat
	
	if paragraph_list is not {} then
		doc_container's push(DocElements's make_paragraph_element(paragraph_list))
	end if
end parse_heading_region

on parse_references(a_region, doc_container)
	--log "start parse_references"
	set enumerator to lineEnum of a_region
	set is_continued to false
	repeat while enumerator's has_next()
		set a_line to next() of enumerator
		if a_line's starts_with("@") then
			if not is_references_tag(a_line) then
				set is_continued to true
				enumerator's decrement_index()
				exit repeat
			end if
		else if length of a_line < 4 then
			set is_continued to true
			exit repeat
		else
			set a_list to a_line's as_list_with("||")
			set a_word to XText's make_with(item 1 of a_list)'s strip()'s as_unicode()
			set a_link to XText's make_with(item 2 of a_list)'s strip()'s as_unicode()
			if (count a_list) > 2 then
				set a_target to XText's make_with(item 3 of a_list)'s strip()'s as_unicode()
			else
				set a_target to missing value
			end if
			doc_container's push_external_link(a_word, a_link, a_target)
		end if
	end repeat
	
	if is_continued then
		parse_heading_region(a_region, doc_container)
	end if
end parse_references

on tag_contents(enumerator)
	--log "start tag_contents"
	set content_list to {}
	set a_line to enumerator's current_item()
	set a_text to DocElements's strip_tag(a_line)
	if not a_text's equal_to("") then
		set end of content_list to a_text
	end if
	
	repeat while enumerator's has_next()
		set a_line to enumerator's next()
		if a_line's starts_with("@") then
			enumerator's decrement_index()
			exit repeat
		else
			set end of content_list to a_line
		end if
	end repeat
	--log "count tag contents : " & (count content_list)
	return content_list
end tag_contents

on parse_handler_region(a_region, doc_container)
	--log "start parse_handler_region"
	set description_list to {}
	set param_list to {}
	set result_list to {}
	set abstruct_list to {}
	set syntax_list to {}
	
	set is_continued to false
	set enumerator to lineEnum of a_region
	repeat while enumerator's has_next()
		set a_line to enumerator's next()
		
		if a_line's starts_with("@") then
			set the_tag to first word of a_line
			if the_tag is "abstruct" then
				set abstruct_list to tag_contents(enumerator)
			else if the_tag is "description" then
				set description_list to tag_contents(enumerator)
			else if the_tag is "param" then
				set end of param_list to XList's make_with(tag_contents(enumerator))
			else if the_tag is "result" then
				set result_list to tag_contents(enumerator)
			else if the_tag is "syntax" then
				set syntax_list to tag_contents(enumerator)
			else
				set is_continued to true
				enumerator's decrement_index()
				exit repeat
			end if
			
		else
			if ((a_line is not "") or (description_list is not {})) then
				set end of description_list to a_line
			end if
		end if
	end repeat
	if syntax_list is {} then
		set syntax_text to DocElements's strip_tag(nextLine of a_region)
		set comment_offset to syntax_text's offset_of("--")
		if comment_offset > 0 then
			--set syntax_text to text 1 thru (comment_offset - 1) of syntax_text
			set syntax_text to syntax_text's text_in_range(1, (comment_offset - 1))
		end if
	else
		set syntax_text to item 1 of syntax_list
	end if
	script HandlerProperties
		property _abstruct : XList's make_with(abstruct_list)
		property _description : XList's make_with(description_list)
		property _result : XList's make_with(result_list)
		property _parameters : XList's make_with(param_list)
		property _syntax : syntax_text
		property _handler_name : first word of syntax_text
	end script
	
	doc_container's push(DocElements's make_handler_element(HandlerProperties))
	--log "end parse_handler_region"
	if is_continued then
		parse_heading_region(a_region, doc_container)
	end if
end parse_handler_region

on make_doc_container()
	script LinkManager
		property _anchor_words : make XList
		property _prefix : ""
		property _external_links : make XDict
		property _root_page : missing value
		property _current_page : missing value
		
		on push_external(a_word, a_url, a_target)
			set a_record to {original:a_url, link:missing value, has_scheme:false, link_target:a_target}
			if has_scheme(XText's make_with(a_url)) then
				set link of a_record to a_url
				set has_scheme of a_record to true
			end if
			my _external_links's set_value(a_word, a_record)
		end push_external
		
		on push_anchor(a_word)
			my _anchor_words's push(a_word)
		end push_anchor
		
		on push(a_word)
			my _anchor_words's push(a_word)
		end push
		
		on link_tag(a_word)
			set a_link to HTMLElement's make_with("a", {{"href", my _prefix & a_word & ".html"}})
			a_link's push(a_word)
			return a_link's as_html()
		end link_tag
		
		on set_root_page(a_path)
			set my _root_page to a_path
		end set_root_page
		
		on set_current_page(a_path)
			set my _current_page to a_path
			set an_iterator to my _external_links's iterator()
			set pathconv_root to PathConverter's make_with(my _root_page)
			set pathconv_current to PathConverter's make_with(a_path)
			repeat while an_iterator's has_next()
				set {a_word, a_record} to an_iterator's next()
				if not has_scheme of a_record then
					set abs_path to absolute_path of pathconv_root for a_record's original
					set link of a_record to relative_path of pathconv_current for abs_path
				end if
			end repeat
		end set_current_page
		
		on set_prefix(a_text)
			set my _prefix to a_text
		end set_prefix
		
		on has_scheme(a_word)
			--log "start has_scheme"
			set schemes to {"http:", "mailto:", "ftp:", "file:", "help:"}
			repeat with a_scheme in schemes
				if a_word's starts_with(contents of a_scheme) then
					return true
				end if
			end repeat
			return false
		end has_scheme
		
		on process_autolink(a_text)
			--log "start process_autolink"
			set start_pos to a_text's offset_of("((<")
			if start_pos > 0 then
				set end_pos to a_text's offset_of(">))")
				if end_pos is 0 then
					error "Link bracket is not closed in " & quoted form of (a_text's as_unicode()) number 1455
				end if
				set linked_word to a_text's text_in_range(start_pos + 3, end_pos - 1)
				set linked_word_text to linked_word's as_unicode()
				if has_scheme(linked_word) then
					set a_link to HTMLElement's make_with("a", {{"href", linked_word_text}})
					a_link's push(linked_word_text)
				else if linked_word's include("@") then
					set a_link to HTMLElement's make_with("a", {{"href", linked_word's prepend("mailto:")'s as_unicode()}})
					a_link's push(linked_word_text)
				else
					error "The link location for " & quoted form of (linked_word_text) & " is not specified." number 1460
				end if
				set a_text to a_text's replace_in_range(start_pos, end_pos + 2, a_link's as_html())
				-- log "before process_autolink in process_autolink"
				return process_autolink(a_text)
			end if
			return a_text
		end process_autolink
		
		on do(a_text, sender)
			--log "start do in LinkManager"
			my _anchor_words's reset()
			repeat while my _anchor_words's has_next()
				set a_word to my _anchor_words's next()
				--log "anchor word : " & a_word
				set link_word to "((<" & a_word & ">))"
				if a_text's include(link_word) then
					set link_text to link_tag(a_word)
					set a_text to a_text's replace(link_word, link_text)
				end if
			end repeat
			--log "insert external links"
			set an_iterator to my _external_links's iterator()
			repeat while an_iterator's has_next()
				set {a_word, a_record} to an_iterator's next()
				set link_word to "((<" & a_word & ">))"
				if (a_text's include(link_word)) and (not my _anchor_words's has_item(a_word)) then
					set a_tag to HTMLElement's make_with("a", {{"href", a_record's link}})
					if a_record's link_target is not missing value then
						a_tag's set_attribute("target", a_record's link_target)
					end if
					a_tag's push(a_word)
					set a_text to a_text's replace(link_word, a_tag's as_xhtml())
				end if
			end repeat
			--log "befor process_autolink in do of LinkManager"
			set a_result to process_autolink(a_text)
			sender's set_item_at(a_result, sender's current_index())
			--log "end do in LinkManager"
			return true
		end do
	end script
	
	script DocObjectsContainer
		property elementList : {}
		property _link_manager : LinkManager
		
		on push(an_element)
			set end of elementList to an_element
			if (an_element's get_kind() is "handler") then
				set a_name to an_element's get_handler_name()
				my _link_manager's push_anchor(a_name)
			end if
		end push
		
		on push_external_link(a_word, a_url, a_target)
			--log "push_external_link"
			my _link_manager's push_external(a_word, a_url, a_target)
		end push_external_link
		
		on link_manager()
			return _link_manager
		end link_manager
	end script
	
	return DocObjectsContainer
end make_doc_container

--global docObjContainer

script SinglePageLayout
	on layout(doc_container)
		--log "start layout"
		set output to make XList
		repeat with an_elem in elementList of doc_container
			--log "start output"
			output's push(an_elem's as_xhtml())
		end repeat
		
		return output's as_unicode_with(_line_end)
	end layout
end script

property _layoutProcessor : SinglePageLayout

on set_layout_processor(a_processor)
	set _layoutProcessor to a_processor
end set_layout_processor

--global doc_regions
on parse_list(a_list)
	-- log "start parse_list"
	set doc_regions to extract_doc_region(a_list)
	set doc_container to make_doc_container()
	repeat with a_region in doc_regions
		parse_heading_region(a_region, doc_container)
	end repeat
	DocElements's set_link_manager(doc_container's link_manager())
	--log "end parse_list"
	return doc_container
end parse_list

--global doc_container
on process_for_list(a_list)
	set doc_container to parse_list(a_list)
	return _layoutProcessor's layout(doc_container)
end process_for_list

on process_for_editor()
	tell application id "com.apple.ScriptEditor2"
		set theText to contents of document 1
	end tell
	
	return process_for_list(every paragraph of theText)
end process_for_editor
