.DEFAULT_GOAL: poll

.PHONY: poll

.polling:
	@touch $@
	@echo "Doing one poll..."

spip.json: .polling
	@poll
	@rm -f .polling
	@echo "Done."

poll: .polling spip.json
