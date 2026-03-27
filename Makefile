.DEFAULT_GOAL := bootstrap

SHELL := /bin/zsh

CLI_APPS := zplug rust go ripgrep fzf zoxide neovim lazygit yazi tmux
GUI_APPS := ghostty hammerspoon

HAMMERSPOON_SOURCE := $(HOME)/.config/hammerspoon
HAMMERSPOON_LINK := $(HOME)/.hammerspoon
TMUX_SOURCE := $(HOME)/.config/tmux/tmux.conf
TMUX_LINK := $(HOME)/.tmux.conf
TMUX_TPM_DIR := $(HOME)/.config/tmux/plugins/tpm

.PHONY: bootstrap install check_brew install-packages install_upgrade_cli_apps install_upgrade_gui_apps link-configs link-hammerspoon link-tmux update-submodules install-tmux-plugins check-configs notes

define ensure_symlink
	@src="$(1)"; dst="$(2)"; \
	if [ ! -e "$$src" ]; then \
		echo "Missing source: $$src"; \
		exit 1; \
	fi; \
	if [ -L "$$dst" ] && [ "$$(readlink "$$dst")" = "$$src" ]; then \
		echo "$$dst already linked to $$src"; \
	else \
		if [ -e "$$dst" ] || [ -L "$$dst" ]; then \
			backup="$$dst.bak.$$(date +%Y%m%d-%H%M%S)"; \
			echo "Backing up $$dst to $$backup"; \
			mv "$$dst" "$$backup"; \
		fi; \
		ln -s "$$src" "$$dst"; \
		echo "Linked $$dst -> $$src"; \
	fi
endef

bootstrap: install-packages link-configs update-submodules install-tmux-plugins check-configs notes

install: bootstrap

check_brew:
	@which brew >/dev/null || (echo "Homebrew is not installed. Installing..."; /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")

install-packages: install_upgrade_cli_apps install_upgrade_gui_apps

install_upgrade_cli_apps: check_brew
	brew tap daipeihust/tap
	@for app in $(CLI_APPS); do \
		if brew list $$app >/dev/null 2>&1; then \
			echo "$$app is installed. Upgrading..."; \
			brew upgrade $$app; \
		else \
			echo "Installing $$app..."; \
			brew install $$app; \
		fi; \
	done

install_upgrade_gui_apps: check_brew
	@for app in $(GUI_APPS); do \
		if brew list --cask $$app >/dev/null 2>&1; then \
			echo "$$app is installed. Upgrading..."; \
			brew upgrade --cask $$app; \
		else \
			echo "Installing $$app..."; \
			brew install --cask $$app; \
		fi; \
	done

link-configs: link-hammerspoon link-tmux

link-hammerspoon:
	$(call ensure_symlink,$(HAMMERSPOON_SOURCE),$(HAMMERSPOON_LINK))

link-tmux:
	$(call ensure_symlink,$(TMUX_SOURCE),$(TMUX_LINK))

update-submodules:
	git submodule update --init --recursive

install-tmux-plugins:
	@if [ ! -x "$(TMUX_TPM_DIR)/bin/install_plugins" ]; then \
		echo "Missing TPM installer: $(TMUX_TPM_DIR)/bin/install_plugins"; \
		echo "Run 'make update-submodules' first."; \
		exit 1; \
	fi
	@env -u TMUX "$(TMUX_TPM_DIR)/bin/install_plugins"

check-configs:
	@echo "== Brew =="; \
	if command -v brew >/dev/null 2>&1; then \
		echo "brew: $$(command -v brew)"; \
	else \
		echo "brew: missing"; \
	fi
	@echo ""; \
	echo "== Versions =="; \
	if command -v tmux >/dev/null 2>&1; then \
		echo "$$(env -u TMUX tmux -V)"; \
	else \
		echo "tmux: missing"; \
	fi; \
	if command -v ghostty >/dev/null 2>&1; then \
		echo "$$(ghostty +version | sed -n '1p')"; \
	else \
		echo "ghostty: missing"; \
	fi; \
	if [ -d "/Applications/Hammerspoon.app" ]; then \
		echo "hammerspoon: installed"; \
	else \
		echo "hammerspoon: missing"; \
	fi
	@echo ""; \
	echo "== Symlinks =="; \
	if [ -L "$(HAMMERSPOON_LINK)" ]; then \
		echo "$(HAMMERSPOON_LINK) -> $$(readlink "$(HAMMERSPOON_LINK)")"; \
	else \
		echo "$(HAMMERSPOON_LINK): missing or not a symlink"; \
	fi; \
	if [ -L "$(TMUX_LINK)" ]; then \
		echo "$(TMUX_LINK) -> $$(readlink "$(TMUX_LINK)")"; \
	else \
		echo "$(TMUX_LINK): missing or not a symlink"; \
	fi

notes:
	@echo ""; \
	echo "== Manual Follow-up =="; \
	echo "- Hammerspoon may still need macOS Accessibility permission."; \
	echo "- Ghostty and tmux configs are managed from ~/.config."
