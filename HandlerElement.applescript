global DocElements
global HTMLElement
global ASHTML
global SimpleRD
global _line_end

property _useAppleSegment : false
property _useScriptSupport : true

on set_use_Apple_segment(a_flag)
    set my _useAppleSegment to a_flag
end set_use_Apple_segment

on set_script_support(a_flag)
    set my _useScriptSupport to a_flag
end set_script_support

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
    
    --log "syntax"
    script process_syntax
        on do(syntax_text, sender)
            --log "do in process_syntax"
            set syntax_p to output's push_element_with("p", {{"class", "sourceCode"}})
            syntax_p's push(ASHTML's process_text(syntax_text's as_text(), true))
            if my _useScriptSupport then
                set a_link to syntax_p's push_element_with("a", {{"href", "../assets-helpbook/setClipboard.scpt"},¬
                                                    {"onclick", "return runHelpScriptWithInnerText(this)"}})
                a_link's push_element_with("img", {{"src", "../assets-helpbook/Clipboard24.png"}, {"alt", "copy to clipboard"}, {"align", "right"}})
            end if
            return true
        end do
    end script
    my _syntax's enumerate(process_syntax)
    
    my _link_manager's set_prefix("")

    --log "abstruct"
    my _abstruct's enumerate(my _link_manager)
    set srd to SimpleRD's make_with_iterator(my _abstruct)
    
    output's push(srd's html_tree())
    
    if (my _description's count_items()) > 0 then
        my _description's enumerate(my _link_manager)
        set srd to SimpleRD's make_with_iterator(my _description)
        output's push(_line_end)
        output's push(srd's html_tree())
    end if
    
    --log "will process parameter descriptions"
    if (my _parameters's count_items()) > 0 then
        set a_div to output's push_element_with("div", {{"class", "subHeading"}})
        a_div's push("Parameters")
        set a_ul to output's push_element_with("ul", {})
        set a_link_maganer to my _link_manager
        
        script ProcessParamDescription
            on do(param_descs, sender)
                --log "start do in ProcessParamDescription"
                param_descs's enumerate(a_link_maganer)
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
        my _result's enumerate(my _link_manager)
        set srd to SimpleRD's make_with_iterator(my _result)
        output's push(srd's html_tree())
    end if


    if my _example is not missing value then
        output's push_element_with("div", {{"class", "subHeading"}})'s push("Example")
        output's push(my _example's html_element())
    end if

    if my _useAppleSegment then
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