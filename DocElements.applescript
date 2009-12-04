--property SimpleRD : missing value
global SimpleRD
--property ASHTML : missing value
global ASHTML
--property XList : missing value
global XList
--property HTMLElement : missing value
global HTMLElement
-- property _line_end : missing value
global _line_end
(*
on __load__(loader)
	tell loader
		--set SimpleRD to load("SimpleRD")
		--set HTMLElement to SimpleRD's HTMLElement
		--set XList to SimpleRD's XList
		--set ASHTML to load("ASHTML")
		ASHTML's set_wrap_with_block(false)
		set my _line_end to SimpleRD's _line_end
	end tell
	return missing value
end __load__
*)
--property _ : __load__(proxy() of application (get "AppleScriptDocLib"))

property _useAppleSegment : false
--property _useAppleSegment : true
property _useScriptSupport : true
property _link_manager : missing value

on set_link_manager(an_link_manager)
	set my _link_manager to an_link_manager
end set_link_manager

on set_use_Apple_segment(a_flag)
	set _useAppleSegment to a_flag
end set_use_Apple_segment

on set_script_support(a_flag)
	set _useScriptSupport to a_flag
end set_script_support

on strip_tag(a_text)
	--set a_list to XList's make_with_text(a_text, space)
	set a_list to a_text's as_xlist_with(space)
	a_list's delete_at(1)
	return a_list's as_xtext_with(space)
end strip_tag

(*!
@abstruct
@description
@param a_line (script object) : An instance of XText
@result script object : HeadingElement
*)
on make_heading_element(a_line)
	--log "start make_heading_element"
	set a_tag to first word of a_line
	script HeadingElement
		--property parent : AppleScript
		property tag : a_tag
		property _data : strip_tag(a_line)
		
		on get_kind()
			return my tag
		end get_kind
		
		on as_html(a_tag)
			set an_elem to HTMLElement's make_with(a_tag, {})
			set anc_name to my _data's replace(space, "_")
			set an_anchor to an_elem's push_anchor_with(anc_name's as_unicode())
			an_elem's push_content(my _data)
			return an_elem's as_html()
		end as_html
		
		on get_contents()
			return my _data
		end get_contents
		
		on as_xhtml()
			return as_html()
		end as_xhtml
	end script
	
	--log "will end make_heading_element"
	
	if a_tag is "group" then
		return make_group_element(HeadingElement)
	else if a_tag is "title" then
		return make_title_element(HeadingElement)
	else
		error a_line & " is unknown tag." number 1450
	end if
	
	return HeadingElement
end make_heading_element

on make_group_element(parentElement)
	script GroupElement
		property parent : parentElement
		
		on as_html()
			return continue as_html("h2")
		end as_html
		
	end script
	return GroupElement
end make_group_element

on make_title_element(parentElement)
	--log "start make_title_element"
	script TitleElement
		property parent : parentElement
		
		on as_html()
			set an_elem to HTMLElement's make_with("h1", {})
			an_elem's push_content(my _data)
			return an_elem's as_html()
		end as_html
		
	end script
	return TitleElement
end make_title_element

on make_paragraph_element(a_list)
	--log "start make_handler_element"
	script ParagraphElement
		property parent : XList's make_with(a_list)
		
		on get_kind()
			return "paragraph"
		end get_kind
		
		on convert()
			if (count me) > 0 then
				set srd to SimpleRD's make_with_iterator(me)
				return srd's perform_convert()
			else
				return ""
			end if
		end convert
		
		on as_html()
			SimpleRD's use_html()
			return convert()
		end as_html
		
		on as_xhtml()
			SimpleRD's use_xhtml()
			return convert()
		end as_xhtml
	end script
end make_paragraph_element

on make_handler_element(property_script)
	--log "start make_handler_element"
	script HandlerElement
		property parent : property_script
		
		on get_kind()
			return "handler"
		end get_kind
		
		on handler_name()
			return my _handler_name
		end handler_name
		
		on get_handler_name()
			return my _handler_name
		end get_handler_name
		
		on copy_abstruct()
			copy my _abstruct to an_item
			return an_item
		end copy_abstruct
		
		on get_abstruct()
			return my _abstruct
		end get_abstruct
		
		on convert()
			--log "start convert"
			--set output_list to {}
			set output to make HTMLElement
			if _useAppleSegment then
				output's push_comment_with("", {{"AppleSegStart", my _handler_name}})
				output's push_comment_with("", {{"AppleKeywords", my _handler_name}})
			end if
			--log "elementTitle"
			set title_div to output's push_element_with("div", {{"class", "elementTitle"}})
			set an_anchor to title_div's push_anchor_with(my _handler_name)
			an_anchor's push(my _handler_name)
			
			--log "sourceCode"
			set syntax_p to output's push_element_with("p", {{"class", "sourceCode"}})
			syntax_p's push(ASHTML's process_text(my _syntax's as_unicode(), true))
			
			--log "scriptSupport"
			if _useScriptSupport then
				set a_link to syntax_p's push_element_with("a", {{"href", "../assets/setClipboard.scpt"}, {"onclick", "return runHelpScriptWithInnerText(this)"}})
				a_link's push_element_with("img", {{"src", "../assets/Clipboard24.png"}, {"alt", "copy to clipboard"}, {"align", "right"}})
			end if
			
			_link_manager's set_prefix("")
			--log "abstruct"
			my _abstruct's each(_link_manager)
			set srd to make_with_iterator(my _abstruct) of SimpleRD
			
			output's push(srd's perform_convert())
			--set end of output_list to srd's perform_convert()
			--log "description"
			--log my _description
			if (my _description's count_items()) > 0 then
				my _description's each(_link_manager)
				set srd to make_with_iterator(my _description) of SimpleRD
				output's push(_line_end)
				output's push(srd's perform_convert())
			end if
			
			--log "after convertToHTML"
			if (my _parameters's count_items()) > 0 then
				set a_div to output's push_element_with("div", {{"class", "subHeading"}})
				a_div's push("Parameters")
				set a_ul to output's push_element_with("ul", {})
				script ProcessParamDescription
					on do(param_descs)
						param_descs's each(_link_manager)
						set a_li to a_ul's push_element_with("li", {})
						script RowText
							on do(a_text)
								return a_text's as_unicode()
							end do
						end script
						a_li's push(param_descs's map(RowText)'s as_unicode_with(_line_end))
						return true
					end do
				end script
				my _parameters's each(ProcessParamDescription)
			end if
			
			--log "process result field"
			if (my _result's count_items()) > 0 then
				output's push_element_with("div", {{"class", "subHeading"}})'s push("Result")
				my _result's each(_link_manager)
				set srd to make_with_iterator(my _result) of SimpleRD
				output's push(srd's perform_convert())
			end if
			
			if _useAppleSegment then
				ouput's push_comment_with("AppleSegEnd", {})
			end if
			
			--log "will end outputText"
			return output's as_html()
		end convert
		
		on as_html()
			SimpleRD's use_html()
			return convert()
		end as_html
		
		on as_xhtml()
			SimpleRD's use_xhtml()
			return convert()
		end as_xhtml
		
	end script
end make_handler_element
