use framework "Foundation"
use scripting additions

on setup_modules(a_script)
    application (get "AppleScriptDocLib")'s loader()'s setup(a_script)
	set a_script's _line_end to a_script's HTMLElement's line_end()
	return
end setup_modules

script AppleScriptDocController
	-- modules loaded at compile time
	property HTMLElement : "@module"
	property SimpleRD : "@module"
	property XDict : "@module"
	property XList : "@module"
	property XText : "@module"
	property TemplateProcessor : "@module"
	property XFileBase : "@module XFile"
	property PathConverter : "@module"
	property XCharacterSet : "@module"
	property CSSBuilder : "@module"
	property RGBColor : "@module"
    property XRegex : "@module"
	--property _collecting_modules : true
	property _only_local : true
	
	(*== constants *)
	property _line_end : missing value
	property _ : setup_modules(me)
    property _ignoring_comment_pattern : missing value

	(*== Modules *)
	property ASDocParser : missing value
	property ExportHelpBook : missing value
	property SetupHelpBook : missing value
	property SaveToFile : missing value
	property InfoPlistArranger : missing value
	
	property ASFormattingStyle : missing value
	property ASHTML : missing value
	property DocElements : missing value
	property XFile : missing value
	property appController : missing value
    property ScriptLinkMaker : missing value
    property HandlerElement : missing value
    
	on exportHelpBook_toPath_(src, dest)
		--log "start export_helpbook"
        try
            tell (make ExportHelpBook)
                process({source:XFile's make_with(src as text), ¬
                                          destination:((dest as text) as POSIX file)})
            end tell
        on error msg number errno
            return {|message|:msg, |number|:errno}
        end try
        return missing value
	end exportHelpBook_
	
	on cancelExport()
		ExportHelpBook's stop_processing()
	end cancelExport
	
	on setupHelpBook_(a_path)
        try
            SetupHelpBook's process_file(XFile's make_with((a_path as text) as POSIX file))
        on error msg number errno from offending_obj
            if errno is 1503 then
                tell offending_obj
                    set details to error_message() & return & target_text()
                end tell
            else
                set details to ""
            end if
            display alert msg message details
            return false
        end try
        return true
	end setupHelpBook_
	
    on outputFrom_toPath_(src, dst)
        try
            SaveToFile's process_file(XFile's make_with((src as text) as POSIX file),¬
                        XFile's make_with((dst as text) as POSIX file))
        on error msg number errno from offending_obj
            if errno is 1503 then
                tell offending_obj
                    set details to error_message() & return & target_text()
                end tell
            else
                set details to ""
            end if
            display alert msg message details
        end try
    end outputFrom_toPath_
    
	on import_script(a_name)
		--log "start import_script"
		return load script (path to resource a_name & ".scpt")
	end import_script
	
	on setup()
        -- setup_modules(me) -- debug
		--log "start setup in AppleScriptDocController"
		set ASFormattingStyle to import_script("ASFormattingStyle")
		set ASHTML to import_script("ASHTML")'s initialize()
		set XFile to make (import_script("XFileExtend"))
		set ASDocParser to import_script("ASDocParser")
		ASDocParser's set_wrap_with_block(false)
		set DocElements to import_script("DocElements")
		set ExportHelpBook to import_script("ExportHelpBook")
		set SetupHelpBook to import_script("SetupHelpBook")
		set SaveToFile to import_script("SaveToFile")
		set InfoPlistArranger to import_script("InfoPlistArranger")
        set ScriptLinkMaker to import_script("ScriptLinkMaker")
        set HandlerElement to import_script("HandlerElement")
        set my _ignoring_comment_pattern to XRegex's make_with("\\S+\\s*\\(\\*.+\\*\\)")
	end setup
	
end script
