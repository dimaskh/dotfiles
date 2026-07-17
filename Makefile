# ~/.dotfiles/Makefile — GNU stow management
# Each top-level dir (except docs/) is a stow "package" whose contents mirror $HOME.

DOTFILES := $(HOME)/.dotfiles
PACKAGES := zsh git ghostty cursor lazygit atuin tmux scripts
STOW     := stow --dir=$(DOTFILES) --target=$(HOME)

.PHONY: help link unlink restow status add tools

help:
	@echo "Dotfiles (GNU stow) — targets:"
	@echo "  make link                       symlink all packages into \$$HOME"
	@echo "  make unlink                     remove all symlinks (stow -D)"
	@echo "  make restow                     re-link all packages (after adding files)"
	@echo "  make status                     dry-run: show what stow would change"
	@echo "  make add pkg=<p> path=<file>    move a live file into package <p> and re-link"
	@echo "  make tools                      install the CLI tools from packages.txt (sudo)"

link:
	$(STOW) $(PACKAGES)
	@echo "Linked: $(PACKAGES)"

unlink:
	$(STOW) -D $(PACKAGES)
	@echo "Unlinked: $(PACKAGES)"

restow:
	$(STOW) -R $(PACKAGES)
	@echo "Restowed: $(PACKAGES)"

status:
	@$(STOW) -n -v 2 $(PACKAGES) 2>&1 | sed 's/^/  /' || true
	@echo "(no LINK/UNLINK lines above = already in sync)"

# Move a live file under stow management:
#   make add pkg=ghostty path=~/.config/ghostty/config
add:
	@test -n "$(pkg)" -a -n "$(path)" || { echo "usage: make add pkg=<package> path=~/.config/foo/bar"; exit 1; }
	@abs=$$(readlink -f "$(path)"); \
	test ! -L "$(path)" || { echo "error: $(path) is already a symlink (already managed?)"; exit 1; }; \
	rel=$${abs#$(HOME)/}; \
	dest="$(DOTFILES)/$(pkg)/$$rel"; \
	mkdir -p "$$(dirname "$$dest")"; \
	mv "$$abs" "$$dest"; \
	echo "moved $$abs -> $$dest"; \
	$(STOW) -R "$(pkg)"; \
	echo "re-linked package: $(pkg)"

# Install the modern CLI tool set (idempotent; --needed skips installed packages).
# Run interactively — sudo prompts for a password.
tools:
	sudo pacman -S --needed - < $(DOTFILES)/packages.txt
