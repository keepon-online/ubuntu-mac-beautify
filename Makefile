SHELL := /usr/bin/env bash
DESKTOP ?= auto

.PHONY: help install install-light install-kde install-kde-light reapply reapply-light reapply-kde reapply-kde-light reset reset-kde uninstall uninstall-kde check

help:
	@echo "Targets:"
	@echo "  make install            Full install with dark theme (DESKTOP=auto by default)"
	@echo "  make install-light      Full install with light theme"
	@echo "  make install-kde        Full install for KDE with dark theme"
	@echo "  make install-kde-light  Full install for KDE with light theme"
	@echo "  make reapply            Reapply dark theme settings"
	@echo "  make reapply-light      Reapply light theme settings"
	@echo "  make reapply-kde        Reapply KDE settings"
	@echo "  make reapply-kde-light  Reapply KDE light settings"
	@echo "  make reset              Reset current desktop appearance settings"
	@echo "  make reset-kde          Reset KDE appearance settings"
	@echo "  make uninstall          Remove project-installed user files"
	@echo "  make uninstall-kde      Remove KDE-specific user files"
	@echo "  make check              Run syntax checks"

install:
	bash ./install.sh --desktop=$(DESKTOP)

install-light:
	bash ./install.sh --desktop=$(DESKTOP) --light

install-kde:
	bash ./install.sh --desktop=kde

install-kde-light:
	bash ./install.sh --desktop=kde --light

reapply:
	bash ./reapply.sh --desktop=$(DESKTOP)

reapply-light:
	bash ./reapply.sh --desktop=$(DESKTOP) --light

reapply-kde:
	bash ./reapply.sh --desktop=kde

reapply-kde-light:
	bash ./reapply.sh --desktop=kde --light

reset:
	bash ./reset.sh --desktop=$(DESKTOP)

reset-kde:
	bash ./reset.sh --desktop=kde

uninstall:
	bash ./uninstall.sh --desktop=$(DESKTOP)

uninstall-kde:
	bash ./uninstall.sh --desktop=kde

check:
	bash ./check.sh
