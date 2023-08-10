include .make/Makefile

vignettes/progressr-intro.md: incl/OVERVIEW.md vignettes/incl/clean.css
	sed -E -i '/^(<!-- DO NOT EDIT THIS FILE|!\[|#+[[:space:]])/,$$d' $@
	echo "<!-- DO NOT EDIT THIS FILE! Edit 'OVERVIEW.md' instead and then rebuild this file with 'make vigs' -->" >> $@
	cat $< >> $@
	sed -i 's/vignettes\///g' $@

vigns: vignettes/progressr-intro.md

spelling:
	$(R_SCRIPT) -e "spelling::spell_check_package()"
	$(R_SCRIPT) -e "spelling::spell_check_files(dir('vignettes', pattern='[.](md|rsp)$$', full.names=TRUE), ignore=readLines('inst/WORDLIST', warn=FALSE))"
