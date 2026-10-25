.DEFAULT_GOAL := help
.PHONY: help prepare-dt refresh-phony chmod-scripts cli install create install-js create-project-js create-project-ts create-project-py install-py
DEVTOOLS_MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
DEVTOOLS_BIN := $(dir $(DEVTOOLS_MAKEFILE))bin

help: ## Show available commands
	@awk 'BEGIN { FS = ":.*## " } /^[a-zA-Z_-]+:.*## / { printf "[%-20s] %s\n", $$1, $$2 }' $(MAKEFILE_LIST)


#### DEVTOOLS SPECIFICS

prepare-dt: ## dt related. Update .PHONY, chmod... 
	@$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" refresh-phony
	@$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" chmod-scripts

refresh-phony: ## Recompute .PHONY
	@awk -F ':' '/^[a-zA-Z_-]+:/ && $$1 != ".PHONY" { targets = targets " " $$1 } END { print ".PHONY:" targets }' $(lastword $(MAKEFILE_LIST)) > /tmp/devtools-phony.tmp
	@sed -i '' '/^\.PHONY:/d' $(lastword $(MAKEFILE_LIST))
	@sed -i '' '1r /tmp/devtools-phony.tmp' $(lastword $(MAKEFILE_LIST))
	@rm /tmp/devtools-phony.tmp

chmod-scripts: ## Run chmod +x on all ./bin
	@find "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))bin" -type f -name '*.sh' -exec chmod +x {} +
	
cli: ## Open vscode in the cli folder
	@code ~/dev/devtools-cli/


#### GLOBAL TOOLS

install: ## Install a package using the appropriate tool (py or js)
	@if [ -f pyproject.toml ]; then \
		$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" install-py arg1="$(arg1)"; \
	elif [ -f package.json ]; then \
		$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" install-js arg1="$(arg1)"; \
	else \
		echo "Error: no pyproject.toml or package.json found in the current directory."; \
		exit 1; \
	fi

uninstall: ## Uninstall a package using the appropriate tool (py or js)
	@if [ -f pyproject.toml ]; then \
		$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" uninstall-py arg1="$(arg1)"; \
	elif [ -f package.json ]; then \
		$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" uninstall-js arg1="$(arg1)"; \
	else \
		echo "Error: no pyproject.toml or package.json found in the current directory."; \
		exit 1; \
	fi

create: ## Give choice to create something
	@"$(DEVTOOLS_BIN)/create.sh"

add: ## Acknowledge all changes in current dir
	@git add .

commit: ## Validate changes
	@git commit -m "$(arg1)"

push: ## Push to remote location
	@git push origin main

save:
	$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" add
	$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" commit $(arg1)
	$(MAKE) -f "$(DEVTOOLS_MAKEFILE)" push
	
	
#### JS TOOLS

install-js: ## Install a package in a js folder
	@npm install $(arg1)

uninstall-js: ## Uninstall a package in a js folder
	@npm uninstall $(arg1)

create-project-sveltekit: ## Create a Sveltekit project in the current directory
	@npx sv create .

#### PY TOOLS

create-project-py: ## Create a Python project in the current directory
	@"$(DEVTOOLS_BIN)/create-project-py.py"

install-py: ## Install a package in python
	@uv add $(arg1)

uninstall-py: ## Uninstall a package in python
	@uv remove $(arg1)

clear-pycaches: ## Remove all pycaches folder in all sub directories
	@"$(DEVTOOLS_BIN)/clean-py.sh"