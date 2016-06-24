global SimpleRD
global ASHTML
global XList
global HTMLElement
global _line_end

property _useAppleSegment : false
--property _useAppleSegment : true
property _useScriptSupport : true
property _link_manager : missing value

on set_link_manager(an_link_manager)
	set my _link_manager to an_link_manager
end set_link_manager

on set_use_Apple_segment(a_flag)
	set my _useAppleSegment to a_flag
end set_use_Apple_segment

on set_script_support(a_flag)
	set my _useScriptSupport to a_flag
end set_script_support

on strip_tag(a_text)
	--set a_list to XList's make_with_text(a_text, space)
	set a_list to a_text's as_xlist_with(space)
	a_list's delete_at(1)
	return a_list's as_xtext_with(space)
end strip_tag

on make_heading_element(a_line)
	--log "start make_heading_element"
	set a_tag to first word of (a_line's as_unicode())
	script HeadingElement
		--property parent : AppleScript
		property _tag : a_tag
		property _data : strip_tag(a_line)
		
		on get_kind()
			return my _tag
		end get_kind
		
		on html_element_with(a_tag)
			set anc_name to my _data's replace(space, "_")
			set an_elem to HTMLElement's make_with(a_tag, {{"id", anc_name's as_unicode()}})
			return an_elem's push(my _data)
		end html_element_with
		
		on as_html_with(a_tag)
			return html_element_with(a_tag)'s as_html()
		end as_html_with
		
		on get_contents()
			return my _data
		end get_contents
		
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
		
		on html_element()
			return html_element_with("h2")
		end html_element
		
		on as_html()
			return as_html_with("h2")
		end as_html
		
		on as_xhtml()
			return as_html()
		end as_xhtml
	end script
	return GroupElement
end make_group_element

on make_title_element(parentElement)
	--log "start make_title_element"
	script TitleElement
		property parent : parentElement
		
		on html_element()
			set an_elem to HTMLElement's make_with("h1", {})
			an_elem's push(my _data)
			return an_elem
		end html_element
		
		on as_html()
			set an_elem to html_element()
			return an_elem's as_html()
		end as_html
		
		on as_xhtml()
			return as_html()
		end as_xhtml
	end script
	return TitleElement
end make_title_element

on make_paragraph_element(a_list)
	--log "start make_paragraph_element"
	script ParagraphElement
		property parent : XList's make_with(a_list)
		
		on get_kind()
			return "paragraph"
		end get_kind
		
		on convert()
			--log "start convert in ParagraphElement"
			if (count me) > 0 then
				set srd to SimpleRD's make_with_iterator(me)
				return srd's html_tree()
			else
				return ""
			end if
		end convert
		
		on html_element()
			return convert()
		end html_element
		
		on as_html()
			return html_element()'s as_html()
		end as_html
		
		on as_xhtml()
			return as_html()
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
			--log "start convert in HandlerElement"
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
			my _abstruct's enumerate(_link_manager)
			set srd to make_with_iterator(my _abstruct) of SimpleRD
			
			output's push(srd's html_tree())
			
			if (my _description's count_items()) > 0 then
				my _description's enumerate(_link_manager)
				set srd to make_with_iterator(my _description) of SimpleRD
				output's push(_line_end)
				output's push(srd's html_tree())
			end if
			
			--log "will process parameter descriptions"
			if (my _parameters's count_items()) > 0 then
				set a_div to output's push_element_with("div", {{"class", "subHeading"}})
				a_div's push("Parameters")
				set a_ul to output's push_element_with("ul", {})
				
				script ProcessParamDescription
					on do(param_descs, sender)
						--log "start do in ProcessParamDescription"
						param_descs's enumerate(_link_manager)
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
				
				my _parameters's enumerate(ProcessParamDescription)
			end if
			
			--log "will process result field"
			if (my _result's count_items()) > 0 then
				output's push_element_with("div", {{"class", "subHeading"}})'s push("Result")
				my _result's enumerate(_link_manager)
				set srd to make_with_iterator(my _result) of SimpleRD
				output's push(srd's html_tree())
			end if
			
			if _useAppleSegment then
				ouput's push_comment_with("AppleSegEnd", {})
			end if
			
			--log "will end outputText"
			return output
		end convert
		
		on as_html()
			return convert()'s as_html()
		end as_html
		
		on as_xhtml()
			--log "as_ xthtml in handler_element"
			return as_html()
		end as_xhtml
		
	end script
end make_handler_element

on make_code_element(a_list)
    script CodeElement
        property parent : XList's make_with(a_list)
    
        on get_kind()
            return "code"
        end get_kind
    
        on html_element()
            tell make ASHTML
                set_wrap_with_block(true)
                set a_html to process_text(my as_text_with(return), false)
            end tell
                
            tell make HTMLElement
                push(a_html)
                return it
            end tell
        end html_element
        
        on as_html()
            return html_element()'s as_html()
        end as_html
    
        on as_xhtml()
            return as_html()
        end as_xhtml
    end script
end make_code_element
