OFFLINE_TESTS := test/test_parse.lua test/test_session.lua

.PHONY: test
test:
	@for t in $(OFFLINE_TESTS); do \
		echo "== $$t"; \
		nvim --headless -u NONE --cmd "set rtp+=." -c "luafile $$t" -c "cquit 1" || exit 1; \
		echo; \
	done

.PHONY: demo
demo:
	vhs assets/demo.tape
