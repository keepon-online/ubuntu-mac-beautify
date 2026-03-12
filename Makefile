SHELL := /usr/bin/env bash

.PHONY: help install install-light reapply reapply-light reset uninstall check fix-desktop-icons test-fix-desktop-icons

help:
	@echo "Targets:"
	@echo "  make install        Full install with dark theme"
	@echo "  make install-light  Full install with light theme"
	@echo "  make reapply        Reapply dark theme settings"
	@echo "  make reapply-light  Reapply light theme settings"
	@echo "  make reset          Reset GNOME appearance settings"
	@echo "  make uninstall      Remove project-installed user files"
	@echo "  make fix-desktop-icons  Repair broken GNOME desktop icon metadata"
	@echo "  make test-fix-desktop-icons  Run desktop icon repair regression tests"
	@echo "  make check          Run syntax checks"

install:
	bash ./install.sh

install-light:
	bash ./install.sh --light

reapply:
	bash ./reapply.sh

reapply-light:
	bash ./reapply.sh --light

reset:
	bash ./reset.sh

uninstall:
	bash ./uninstall.sh

fix-desktop-icons:
	bash ./fix-desktop-icons.sh

test-fix-desktop-icons:
	bash tests/fix_desktop_icons_test.sh

check:
	bash ./check.sh
