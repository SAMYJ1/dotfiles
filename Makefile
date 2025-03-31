
# Define applications
CLI_APPS = zplug rust go ripgrep fzf zoxide neovim lazygit yazi
GUI_APPS = karabiner-Elements kitty

# Check if Homebrew is installed
check_brew:
	@which brew > /dev/null || (echo "Homebrew is not installed. Installing..."; /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")

# Install or upgrade command-line applications
install_upgrade_cli_apps: check_brew
	brew tap daipeihust/tap
	@for app in $(CLI_APPS); do \
		if brew list $$app &>/dev/null; then \
			echo "$$app is installed. Upgrading..."; \
			brew upgrade $$app; \
		else \
			echo "Installing $$app..."; \
			brew install $$app; \
		fi \
	done

# Install or upgrade GUI applications
install_upgrade_gui_apps: check_brew
	@for app in $(GUI_APPS); do \
		if brew list --cask $$app &>/dev/null; then \
			echo "$$app is installed. Upgrading..."; \
			brew upgrade --cask $$app; \
		else \
			echo "Installing $$app..."; \
			brew install --cask $$app; \
		fi \
	done

# Install or upgrade all applications
install: install_upgrade_cli_apps install_upgrade_gui_apps
