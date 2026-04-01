# Release Notes: Custom GDM Theme Workflow

Date: 2026-04-01
Commit: `ac42e4d`

## Summary

This release adds a project-managed GDM login screen workflow for Ubuntu 24.04 GNOME, including:

- a bundled custom `prussiangreen` GDM resource
- install, repair, and rollback scripts
- automatic integration into `install.sh`
- automatic integration into `reapply.sh`
- automatic rollback integration into `reset.sh` and `uninstall.sh`
- project documentation and shell-level verification

The goal is to make the login screen look closer to the lock screen and current theme style, while keeping the workflow reversible.

## Highlights

### 1. Bundled custom GDM resource

The project now ships a compiled custom GDM resource:

- `assets/gdm/codex-gdm-prussiangreen/gnome-shell-theme.gresource`

This avoids depending on ad-hoc files outside the repository and makes the workflow reproducible.

### 2. New GDM maintenance scripts

Added:

- `scripts/install-custom-gdm-prussiangreen.sh`
- `scripts/repair-gdm-theme-alternative.sh`
- `scripts/rollback-custom-gdm-prussiangreen.sh`

These scripts support:

- initial activation of the custom GDM theme
- repairing a broken `update-alternatives` chain
- rolling back to the system default `Yaru` GDM theme

### 3. Automatic GDM integration in GNOME flows

`install.sh --desktop=gnome`

- now automatically attempts to apply the project custom GDM theme
- can opt out with `--skip-gdm`

`reapply.sh --desktop=gnome`

- now automatically attempts to reapply the project custom GDM theme
- can opt out with `--skip-gdm`

### 4. Automatic GDM rollback in reset and uninstall

`reset.sh --desktop=gnome`

- now automatically rolls back the project custom GDM theme to system default `Yaru`
- can opt out with `--keep-gdm`

`uninstall.sh --desktop=gnome`

- now automatically rolls back the project custom GDM theme to system default `Yaru`
- can opt out with `--keep-gdm`

## User-Facing Behavior Changes

### Install or reapply with GDM

```bash
bash ./install.sh --desktop=gnome
bash ./reapply.sh --desktop=gnome
```

### Skip GDM changes

```bash
bash ./install.sh --desktop=gnome --skip-gdm
bash ./reapply.sh --desktop=gnome --skip-gdm
```

### Roll back GDM to default Yaru

```bash
bash ./reset.sh --desktop=gnome
bash ./uninstall.sh --desktop=gnome
```

### Keep current GDM while resetting or uninstalling

```bash
bash ./reset.sh --desktop=gnome --keep-gdm
bash ./uninstall.sh --desktop=gnome --keep-gdm
```

### Manual repair and rollback

```bash
sudo bash ./scripts/repair-gdm-theme-alternative.sh
sudo bash ./scripts/rollback-custom-gdm-prussiangreen.sh
```

## Notes

- This workflow targets Ubuntu 24.04 with `gdm3`.
- The project custom rollback covers the project-managed GDM theme only.
- It does not guarantee a full rollback of any upstream WhiteSur GDM tweaks that may have been applied earlier.
- After applying or rolling back GDM changes, log out or reboot to check the login screen result.

## Verification

The project changes were verified with:

```bash
bash ./check.sh
bash tests/gdm_theme_scripts_test.sh
```

## Related Docs

- `docs/gdm-login-beautify.md`
- `docs/superpowers/specs/2026-04-01-gdm-login-beautify-design.md`
- `docs/superpowers/plans/2026-04-01-gdm-login-beautify-sync.md`
- `docs/superpowers/plans/2026-04-01-install-sh-gdm-integration.md`
- `docs/superpowers/plans/2026-04-01-reapply-sh-gdm-integration.md`
- `docs/superpowers/plans/2026-04-01-reset-uninstall-gdm-rollback.md`
