.PHONY: poll archive print

poll:
	@touch .polling
	@echo "Doing one poll..."
	@poll spip.json
	@echo "Done."
	@print spip.json
	@rm -f .polling
	@touch .polled

archive:
	@archive spip.json php.json

print:
	@print spip.json
