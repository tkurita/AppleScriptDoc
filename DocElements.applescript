global SimpleRD
global ASHTML
global XList
global HTMLElement
global ScriptLinkMaker
global _line_end

--property _useAppleSegment : true

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
			set anc_name to my _data's strip()'s replace(space, "_")
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
            -- log "start html_element in GroupElement"
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
			--tell applescript to log "start convert in ParagraphElement"
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

script ExampleElement
    property parent : AppleScript
    
    on get_kind()
        return "example"
    end get_kind
    
    on html_element()
        --log "start html_element in ExampleElement"
        set a_code to my _contents's as_text_with(return)
        tell make ASHTML
            set_wrap_with_block(false)
            set a_html to process_text(a_code, false)
        end tell
        set script_link to ScriptLinkMaker's button_with_template(a_code, "Open this script", "new", "button_template.html")
        tell HTMLElement's make_with("div", {{"class", "sourceCode"}})
            push(script_link)
            push(a_html)
            --log "end html_element"
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

on make_example_element(a_list)
    script ExampleElementInstance
        property parent : ExampleElement
        property _contents :  XList's make_with(a_list)
    end script
    return ExampleElementInstance
end make_example_element
