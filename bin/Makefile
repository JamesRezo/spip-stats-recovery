.DEFAULT_GOAL: poll archive print

.PHONY: poll

.polling:
	@touch $@
	@echo "Doing one poll..."

spip.json: .polling
	@poll $@
	@rm -f .polling
	@echo "Done."
	@print $@

poll: .polling spip.json

archive:
	@archive spip.json php.json

print:
	@print spip.json
