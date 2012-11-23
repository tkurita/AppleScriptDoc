# following variables must be given as command line arguments
#target_lang = Japanese
#target_nib = Japanese.lproj/MainMenu.nib

$(target_nib): $(target_lang).lproj/%.nib: English.lproj/%.nib $(target_lang).lproj/%.strings
	./localize_ib.sh $< $@
