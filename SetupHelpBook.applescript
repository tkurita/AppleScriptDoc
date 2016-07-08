global ExportHelpBook
global XFile
global appController
global InfoPlistArranger
global DocElements
global TemplateProcessor

property NSDictionary : class "NSDictionary"
property _template_folder : "HelpBookTemplate"

on prepare_HBBundle(product_bundle, product_infoplist)
    --log "start prepare_HBBundle"
    set hb_bundle_folder to product_infoplist's get_book_folder()
    set info_in_HBBundle to hb_bundle_folder's child("Contents/Info.plist")
    
    if info_in_HBBundle's item_exists() then
        set hbbundle_infoPlist to NSDictionary's dictionaryWithContentsOfFile_(info_in_HBBundle's posix_path())
        set hbbundle_id to hbbundle_infoPlist's objectForKey_("CFBundleIdentifier")
        if (product_infoplist's value_for("CFBundleHelpBookName") is not hbbundle_id) then
            product_infoplist's set_bookname(hbbundle_id)
        end if
    else
        set myself to XFile's make_with(path to current application)
        set info_in_HBBundle to myself's bundle_resource("HBBundleTemplate")'s ¬
            child("Contents")'s copy_to(hb_bundle_folder)'s child("Info.plist")
        set product_id to product_infoplist's bundle_identifier()
        tell TemplateProcessor's make_with_xfile(info_in_HBBundle)
             insert_text("${HBBundleName}", hb_bundle_folder's basename())
             insert_text("${ProductName}", product_infoplist's product_name())
             insert_text("${ProductIdentifier}", product_id)
             write_to(info_in_HBBundle)
        end tell
        product_infoplist's set_bookname(product_id&".help")
    end if
    return {output:hb_bundle_folder's child("Contents/Resources/"), infoPlist:info_in_HBBundle}
end

on process given bundle:a_bundle, text:a_text
	--log "start process in SetupHelpBook"
	if a_bundle is missing value then return
	set product_infoplist to InfoPlistArranger's make_with(a_bundle)
	ExportHelpBook's initialize()
	DocElements's set_script_support(true)
    set {output:book_folder, infoPlist:hb_infoPlist} to prepare_HBBundle(a_bundle, product_infoplist)
    tell NSDictionary's dictionaryWithContentsOfFile_(hb_infoPlist's posix_path())
        set doc_title to its objectForKey_("HPDBookTitle")
    end tell
    ExportHelpBook's set_bookname(doc_title)
	set index_page to book_folder's child("index.html")
	ExportHelpBook's set_use_appletitle(true)
	ExportHelpBook's output_to_folder(book_folder's as_alias(), index_page, a_text, a_bundle's basename())

	product_infoplist's setup_info_plist()
    
    tell current application's class "HBIndexer"'s hbIndexerWithTarget_(book_folder's posix_path())
        its setIndexFileName_("search.helpindex")
        if not (its makeIndex() as boolean) then
            return
        end if
    end tell
    
	set a_result to appController's showHelpBook_bookname_(a_bundle's posix_path(), product_infoplist's bookname()) as boolean
	if a_result then
		display alert "Error : " & a_result
	end if
	-- log "end process in SetupHelpBook"
end process

on process_file(a_bundle)
	-- log "start process_file in SetupHelpBook"
	set a_text to appController's sourceOfScript_(a_bundle's posix_path()) as text
	process given bundle:a_bundle, text:a_text
end process_file
