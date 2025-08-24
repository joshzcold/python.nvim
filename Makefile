SHELL := /bin/bash
.ONESHELL:
.SILENT:

# Run all test files
test: deps test_requirements
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps test_requirements
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Install all test dependencies
deps: deps/mini.nvim \
			deps/nvim-dap \
			deps/nvim-dap-python \
			deps/nvim-lspconfig \
			deps/nui.nvim \
			deps/LuaSnip \
			deps/neotest \
			deps/neotest-python \
			deps/nvim-treesitter

test_requirements:
	for req in "python3" "uv"; do \
		command -v "$$req" > /dev/null || { echo "system cmd '$$req' required for tests"; exit 1; } ;\
	done
	for req in "venv"; do \
		python3 -c "import $$req" || { echo "python dependency '$$req' required for tests"; exit 1; } ;\
	done

deps/nvim-treesitter:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-treesitter/nvim-treesitter $@

deps/mini.nvim:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/echasnovski/mini.nvim $@

deps/nvim-dap:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/mfussenegger/nvim-dap $@

deps/nvim-dap-python:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/mfussenegger/nvim-dap-python $@

deps/nvim-lspconfig:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/neovim/nvim-lspconfig $@

deps/nui.nvim:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/MunifTanjim/nui.nvim $@

deps/LuaSnip:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/L3MON4D3/LuaSnip $@

deps/neotest:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-neotest/neotest $@

deps/neotest-python:
	set -x
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-neotest/neotest-python $@
