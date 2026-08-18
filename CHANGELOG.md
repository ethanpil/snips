# Changelog

All notable changes to Snips are recorded in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2.0] - 2026-08-18

### Added

- Add the cursor marker `{|}` for the snippet text (23b72df).
- Add CTRL+Enter to copy a snippet to the clipboard (23b72df).
- Add CTRL+N to make a new snippet in the selected folder (23b72df).
- Add CTRL+E to open the selected snippet in your text editor (23b72df).
- Add "Open Snippets Folder" to the tray menu (23b72df).
- Add a search with more than one word. All words must agree (23b72df).
- Add a full path for the `folder` option, such as `D:\Dropbox\snips` (23b72df).
- Add the `position` option: center, caret, or mouse (23b72df).
- Add the `autorefresh` option (23b72df).

### Changed

- Rewrite the program for AutoHotkey v2.0 (a1e9a19). To run the program from
  source you now need AutoHotkey v2.0 or later. The compiled program does not
  need AutoHotkey.
- The hotkey also closes the window when the window is in front (23b72df).
- Snips registers the hotkey and the tray menu before it reads the snippet
  folder (a1e9a19).
- Snips reads snips.ini again on each refresh (a1e9a19).
- Snips shows the number of snippets after a refresh (a1e9a19).
- Snips gives a message when it cannot paste (a1e9a19).
- Snips reads a snippet file as UTF-8, and falls back to the code page of
  Windows for an older file (23b72df).
- Snips pastes into the command prompt with CTRL+V. The menu commands operated
  only on an English Windows. Snips uses them only for the legacy console
  (23b72df).
- All included snippets now use the `{|}` marker. The cursor goes to the same
  position as before (23b72df).
- Correct the cursor position in the f3-devoid and f3-exists snippets (23b72df).

### Fixed

- Fix a stop of the program when a snippet ends with `<<-` and no number.
- Fix the window position for the `caret` and `mouse` options. Snips used the
  position in the other window in place of the position on the screen, and it
  did not obey the screen DPI.
- Fix the window position on a screen with a different size or a taskbar.
- Fix a loop when a junction is in the snippet folder and Snips looks for
  changed files.
- Fix auto-refresh. One error no longer stops it for the rest of the session.
- Fix loss of the clipboard contents when a snippet contains only a cursor
  command.
- Fix CTRL+E and CTRL+N during a search. They now use the selected result.
- Fix CTRL+Enter in the search box. It now copies the first result.
- Fix a snippet that contains the marker `{|}` and also the older command.
  Snips no longer pastes the older command as text.
- Fix a snippet that contains the marker `{|}` more than one time.
- Fix a new snippet with a name that Windows keeps for a device.
- Fix a `folder` value that starts from the root of the drive.
- Fix loss of the clipboard contents. Snips now always gives the clipboard back
  to you, also after an error.
- Fix a paste into the Snips window. A second hotkey press during a paste can
  no longer interrupt the paste.
- Fix wrong key operation in the target program. Snips no longer holds the
  CTRL key down while it waits.
- Fix a paste into the wrong window. Snips now waits for the target window to
  take the focus.
- Fix a paste of the wrong snippet after a refresh. Snips now clears the search
  results, which point to the old list.
- Fix a stop of the program. A cursor position command with a very large number
  can no longer make Snips send millions of keys.
- Fix an unwanted line break in the pasted text. The cursor position command
  now removes the line break in front of it.
- Fix keys that go into the target program. Snips waits for you to release the
  Enter key before it pastes.
- Fix a paste into the About window or into the taskbar. Snips now pastes only
  into a window of a different program.
- Fix a loop when the snippet folder contains a junction or a symbolic link.
- Fix an empty or a bad folder value in snips.ini. Snips uses the default value.
- Fix slow keys in other programs. The Snips hotkeys no longer make Windows
  wait for the program.
- Fix the keyboard in the search results. The "No Results." line no longer
  takes the focus.
- Fix a start error when the snippet folder does not exist. Snips shows a
  message and continues.
- Fix an error when Snips cannot read a snippet file. Snips shows a message and
  continues.
- Fix the Enter key in the About window. The key closes the window again.
- Fix the position of the Snips window. The window shows in front of other
  windows that are always on top.

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

[unreleased]: https://github.com/ethanpil/snips/compare/2.0...HEAD
[2.0]: https://github.com/ethanpil/snips/compare/1.21...2.0
[1.21]: https://github.com/ethanpil/snips/compare/1.2...1.21
[1.2]: https://github.com/ethanpil/snips/compare/1.1...1.2
[1.1]: https://github.com/ethanpil/snips/compare/1.0...1.1
[1.0]: https://github.com/ethanpil/snips/releases/tag/1.0
