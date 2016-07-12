global TemplateProcessor

property NSString : class "NSString"

on href_with_text(a_text, an_action)
	log "start href_with_text"
    log a_text
	tell NSString's stringWithString_(a_text)
		set escaped_text to stringByAddingPercentEscapesUsingEncoding_leavings_additionals_(134217984, "", "&'+") as text
        --set escaped_text to stringByAddingPercentEncodingWithAllowedCharacters_(missing value)
	end tell
    log escaped_text
	set href_text to "applescript://com.apple.scripteditor?action=" & an_action & "&amp;script=" & escaped_text
	--log "end href_with_text"
	return href_text
end href_with_text

on button_with_template(a_text, link_text, an_action, template_name)
	set href_text to href_with_text(a_text, an_action)
	set template_file to path to resource template_name
	set a_template to TemplateProcessor's make_with_file(template_file)
	a_template's insert_text("$LINKTEXT", link_text)
	a_template's insert_text("$HREF", href_text)
	return a_template
end button_with_template