# Changelog

All notable changes to Snips are recorded in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.21] - 2026-08-16

### Added

- Add symbol snippets: star, heart, smiley (e730252, 333990c).
- Add default values for all snips.ini settings. A missing value no longer causes a start error (1090f6d).
- Add a fallback to CTRL+Backtick when the hotkey in snips.ini is not valid (1090f6d).
- Add `#Requires AutoHotkey v1.1` so AutoHotkey v2 shows a clear error (1090f6d).
- Add this changelog in Keep a Changelog format.

### Changed

- Change the check symbol (d63e7b1).
- Move the version history from README.md to CHANGELOG.md.
- Correct the text errors in README.md and in the About window.

### Fixed

- Fix paste into cmd.exe: Snips typed an extra "v" character (110c3eb).
- Fix the cursor position: the cursor moved one position left after each paste without a `<<-X` command (110c3eb).
- Fix the `<<-X` command: it now operates when the snippet file ends with a newline (110c3eb).
- Fix a lock: a double-click on a folder cleared the clipboard and stopped the send routine (964c887).
- Fix the clipboard wait: Snips now stops after 1 second when the clipboard gets no data (964c887).
- Fix a race: Snips now restores the clipboard after the target program completes the paste (964c887).
- Fix the hotkey scope: Down, Enter, and CTRL+R no longer operate in other windows with "Snips" in the title (6abf88e).
- Fix the paste target: Snips no longer saves its own window as the paste target (6abf88e).
- Fix the search results: a single click no longer pastes the snippet (92c00c5).
- Fix the About window: a second click no longer adds duplicate controls, and Escape now closes it (92c00c5).
- Fix the foldernamesearch option: it now accepts "y" and "Y" (92c00c5).
- Fix the symbol snippets check, heart, smiley, and star: they now paste the correct characters (b52f7a7).

### Removed

- Remove dead code: a hidden OK button and two ControlSetText calls (964c887, 92c00c5).

## [1.2] - 2020-04-18

### Added

- Add simple PHP snippets (839d4f0).

### Changed

- Change the About screen text (3d9b25b).
- Change code spacing and indents (853b817).

### Fixed

- Fix issue #3: ESC sometimes still sends data (80a2ccb).
- Fix the cursor move for recent AutoHotkey versions (3163a60).
- Fix slow paste keys for some programs (98980ab).

## [1.1] - 2017-01-15

### Added

- Add support for cmd.exe (86ba7dc).
- Add more default snippets (a1ddee4).
- Add the category name to the search (273c825).

### Fixed

- Fix the paste speed.
- Fix the cursor move speed.

## [1.0] - 2017-01-12

### Added

- First release (4e7afb5).

[unreleased]: https://github.com/ethanpil/snips/compare/1.21...HEAD
[1.21]: https://github.com/ethanpil/snips/compare/1.2...1.21
[1.2]: https://github.com/ethanpil/snips/compare/1.1...1.2
[1.1]: https://github.com/ethanpil/snips/compare/1.0...1.1
[1.0]: https://github.com/ethanpil/snips/releases/tag/1.0
