on boot_for(a_script)
	boot (module loader of application (get "AppleScriptDocLib")) for a_script
	set a_script's _line_end to a_script's HTMLElement's line_end()
	return
end boot_for

script AppleScriptDocController
	-- modules loaded at compile time
	property HTMLElement : module
	property SimpleRD : module
	property XDict : module
	property XList : module
	property XText : module
	property TemplateProcessor : module
	property XFileBase : module "XFile"
	property PathConverter : module
	property XCharacterSet : module
	property CSSBuilder : module
	property RGBColor : module
	--property collecting modules : true
	property only local : true
	
	(*== constants *)
	property _line_end : missing value
	property _ : boot_for(me)
	
	(*== Modules *)
	property DefaultsManager : missing value
	property ASDocParser : missing value
	property ExportHelpBook : missing value
	property SetupHelpBook : missing value
	property SaveToFile : missing value
	property InfoPlistArranger : missing value
	
	property ASFormattingStyle : missing value
	property ASHTML : missing value
	property DocElements : missing value
	property XFile : missing value
	property OneShotScriptEditor : missing value
	property appController : missing value
    property ScriptLinkMaker : missing value
    property HandlerElement : missing value
    
	on exportHelpBook_(a_path)
		--log "start export_helpbook"
        try
            ExportHelpBook's process_file(XFile's make_with(a_path as text))
        on error msg number errno
            return {|message|:msg, |number|:errno}
        end try
        return missing value
	end exportHelpBook_
	
	on cancelExport()
		ExportHelpBook's stop_processing()
	end cancelExport
	
	on setupHelpBook_(a_path)
        --log "start setupHelpBook_"
		SetupHelpBook's process_file(XFile's make_with((a_path as text) as POSIX file))
	end setupHelpBook_
	
    on outputFrom_toPath_(src, dst)
        SaveToFile's process_file(XFile's make_with((src as text) as POSIX file),¬
                    XFile's make_with((dst as text) as POSIX file))
    end outputFrom_toPath_
    
	on import_script(a_name)
		--log "start import_script"
		return load script (path to resource a_name & ".scpt")
	end import_script
	
	on setup()
		--log "start setup in AppleScriptDocController"
		set ASFormattingStyle to import_script("ASFormattingStyle")
		set ASHTML to make (import_script("ASHTML"))
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
	end setup
	
end script