.PHONY: poll-only archive print compile save

archive: .polled
	@archive spip.json php.json
	@rm -f .polled

poll-only: .polled
	@rm -f .polled

print:
	@print spip.json

compile:
	@compile

save:
	@save

.polled:
	@poll spip.json
	@print spip.json
