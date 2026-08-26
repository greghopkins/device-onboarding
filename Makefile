SHELL := /bin/bash
.DEFAULT_GOAL := help

REPO_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BREW      := /opt/homebrew/bin/brew
SCRIPTS   := $(REPO_ROOT)/scripts

.PHONY: help all brew brew-optional mise fonts prezto link unlink relink iterm iterm-integration cursor shell doctor

help: ## Show this help
	@echo "device-onboarding"
	@echo
	@echo "Usage: make <target>"
	@echo
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "'make all' is idempotent and safe to re-run."
	@echo "'make shell' is separate because it needs sudo."

# Order matters: link must precede mise (which reads the stowed global
# ~/.config/mise/config.toml), and mise must precede fonts (whose ligature build
# needs node).
all: brew link prezto mise fonts iterm iterm-integration cursor ## Everything except the sudo step
	@echo
	@echo "Done. Run 'make shell' to set zsh as the login shell, then 'make doctor'."

brew: ## Install the core Brewfile
	$(BREW) bundle --file="$(REPO_ROOT)/Brewfile"

brew-optional: ## Install the opt-in Brewfile (containers, cloud)
	$(BREW) bundle --file="$(REPO_ROOT)/Brewfile.optional"

mise: ## Install the pinned language runtimes
	@command -v mise >/dev/null || { echo "mise not found; run 'make brew' first" >&2; exit 1; }
	@test -f "$(HOME)/.config/mise/config.toml" \
		|| { echo "~/.config/mise/config.toml missing; run 'make link' first" >&2; exit 1; }
	mise install

fonts: ## Build and install Operator Mono Lig + verify FiraCode Nerd Font
	$(SCRIPTS)/install-fonts.sh

prezto: ## Clone Prezto to ~/.zprezto
	$(SCRIPTS)/install-prezto.sh

link: ## Symlink home/ into your home directory via stow
	$(SCRIPTS)/link.sh

unlink: ## Remove the stow symlinks
	stow --dir="$(REPO_ROOT)" --target="$(HOME)" --no-folding -D home

relink: ## Re-stow (use after adding or renaming files in home/)
	stow --dir="$(REPO_ROOT)" --target="$(HOME)" --no-folding -R home

iterm: ## Point iTerm2 at this repo's preferences
	$(SCRIPTS)/configure-iterm2.sh

iterm-integration: ## Fetch iTerm2 shell integration + it2* utilities from upstream
	$(SCRIPTS)/install-iterm-integration.sh

cursor: ## Install the One Dark Operator theme and set Cursor fonts
	$(SCRIPTS)/configure-cursor.sh

shell: ## Make Homebrew zsh the login shell (needs sudo)
	$(SCRIPTS)/set-login-shell.sh

doctor: ## Verify every piece of the install landed
	$(SCRIPTS)/doctor.sh
