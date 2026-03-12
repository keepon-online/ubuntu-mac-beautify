# GNOME Desktop Icon Repair Design

## Summary

Add a standalone repair entrypoint for GNOME users who see different applications rendered with the same dock icon after theme/application changes. The repair targets user-level desktop entries in `~/.local/share/applications` where hidden handler entries override the visible application entry but omit key metadata such as `Icon=` or `StartupWMClass=`.

## Problem

GNOME may prefer a user-local hidden desktop entry over the visible system desktop entry for a given application or scheme handler. When the hidden entry lacks `Icon=` or `StartupWMClass=`, shell/dock matching can fall back incorrectly and show the icon of another application. This can reappear after launching certain apps even if a reboot temporarily clears the state.

## Goals

- Provide a user-invoked repair command that fixes high-confidence metadata gaps in user-local hidden desktop entries.
- Keep the repair conservative: only patch entries when a single visible application entry can be matched confidently.
- Avoid changing system desktop files or icon theme assets.
- Make the repair easy to re-run after new applications are installed.

## Non-Goals

- No KDE-specific behavior.
- No changes to system files under `/usr/share/applications`.
- No aggressive renaming, deletion, or replacement of handler desktop entries.
- No changes to WhiteSur icon theme assets.

## User Experience

Users run a dedicated script, expected to be named `fix-desktop-icons.sh`. The script scans user-local desktop entries, reports what it changed, what it skipped, and why. It refreshes the local desktop database after applying changes.

## Repair Scope

The script only considers files under `~/.local/share/applications` that:

- are desktop entries,
- include `NoDisplay=true`,
- and are missing `Icon=` or `StartupWMClass=`.

Only the missing keys are repaired. Existing values are left untouched.

## Matching Strategy

For each repair candidate, find a corresponding visible application desktop entry using a conservative ranking:

1. Match by overlapping `MimeType` values.
2. Match by normalized executable name derived from `Exec=`.
3. Match by normalized `Name=` value.

Normalization rules:

- `Exec=` compares only the command token basename, stripping arguments and launch wrappers where practical.
- `Name=` comparison ignores case, spaces, underscores, and dashes.
- Matching excludes the candidate file itself and excludes `NoDisplay=true` entries when looking for the visible source entry.

Only a single high-confidence match is eligible for repair. Ambiguous or missing matches are skipped and reported.

## Repair Behavior

When a single visible source entry is found:

- copy `Icon=` from the source if the candidate lacks it,
- copy `StartupWMClass=` from the source if the candidate lacks it.

Before editing, create a timestamped backup alongside the target file. Then rewrite the desktop file in place, preserving unrelated keys and comments.

After processing all candidates:

- run `update-desktop-database ~/.local/share/applications` if available,
- print a summary with counts for `fixed`, `unchanged`, and `skipped`.

## Safety Rules

- Never edit files outside `~/.local/share/applications`.
- Never overwrite existing `Icon=` or `StartupWMClass=` values.
- Skip files with zero or multiple viable source matches.
- Skip files whose source entry also lacks the needed metadata.

## Implementation Layout

- `fix-desktop-icons.sh`: standalone user-facing entrypoint.
- `lib/common.sh`: desktop entry parsing, normalization, matching, backup, and safe rewrite helpers.
- `README.md`: add manual repair instructions.
- `check.sh`: include the new script in syntax/lint checks.
- `Makefile`: optional convenience target for the repair command.
- `tests/fix_desktop_icons_test.sh`: shell-level regression tests using temporary desktop entry fixtures.

## Testing Strategy

Use test-first coverage for the matching and rewrite behavior through a shell regression script that creates temporary fixture directories:

- hidden handler missing both fields, matched by `MimeType`,
- hidden handler missing both fields, matched by `Exec`,
- hidden handler with ambiguous matches, skipped,
- hidden handler already complete, unchanged.

Each test asserts resulting desktop file content and summary output.

## Risks

- Desktop entry matching can be ambiguous for some handlers; the script must prefer skipping over guessing.
- `Exec=` lines may contain launch wrappers. The normalization should stay minimal and conservative.
- Some applications may genuinely need a hidden handler distinct from the visible app entry. Copying metadata only avoids changing behavior while improving shell identification.
