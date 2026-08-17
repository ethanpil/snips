# Snips
A simple tool to store text snippets and to paste them into any Windows program.
https://github.com/ethanpil/snips

[Download Binary](https://github.com/ethanpil/snips/releases)

![snips](https://cloud.githubusercontent.com/assets/254784/21910990/78f0bc36-d8ec-11e6-84c8-88a801bd4d20.gif)

## Instructions

* Press the hotkey to open Snips. The default hotkey is CTRL+\` (CTRL+Backtick). You can change the hotkey in snips.ini.
* The search box has the focus when Snips opens. Type to search the snippet names.
* Press the down arrow to move to the tree or to the search results. Use the arrow keys to navigate.
* Press Enter or double-click a snippet to paste it into your previous window.
* Press Escape to close Snips and go back to your previous window.
* Press CTRL+R to load the snippet list from disk again.
* Use the tray icon to open, refresh, or stop Snips.

All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet.

To run snips.ahk you need [AutoHotkey](https://www.autohotkey.com/) v1.1. The compiled snips.exe does not need AutoHotkey.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## Why

I made this because:

 * I want to use the same snippet list across all my editors and IDE software
 * I want an easy and intuitive way to manage my snippets
 * I dont want my snippets in a proprietary format
 * Other third party snippet tools were too bulky and resource intensive
 * It was fun

## Options

The file snips.ini in the program folder sets these options:

| Option | Function | Default |
| --- | --- | --- |
| folder | The folder that contains the snippet files. | snips |
| key | The [hotkey](https://www.autohotkey.com/docs/v1/Hotkeys.htm#Symbols) that opens Snips. | ^\` (CTRL+Backtick) |
| foldernamesearch | Set to Y to also search the folder names. A match on a folder name shows all snippets of that folder. | Y |

Write comments in snips.ini on their own lines. Start each comment line with a semicolon.

## Snippet Files

All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet. Edit the files in the \snips folder to change your collection. The tree view shows your folder structure. The file names are the snippet titles in the search and in the tree.

Save snippet files as UTF-8 with BOM when they contain special characters.

## Position the Cursor

Snips can position the cursor after it pastes a snippet. Write the command code `<<-X` alone on the last line of the snippet file. Replace X with the number of characters between the cursor position and the end of the snippet.

Example snippet file:

    #include <>
    <<-2

The code `<<-2` tells Snips to move the cursor 2 characters back from the end of the pasted text. After the paste, the cursor is between the brackets: `<|>`.

## Default Snippets

I have included some basics to get you started. Please feel free to share any useful default snippets you think other users will appreciate. I prefer a PR on GitHub for your submissions.

## To Do

* Add CTRL+N hotkey to easily create a new snippet under a category (undecided)
* Improve UI [Auto height, better layout & colors, theming?]
* Add more default snippets
* Rewrite for AHK v2
* Request: Option to show window at cursor location instead of center screen [Tenavin@Reddit](https://www.reddit.com/r/AutoHotkey/comments/5nmzdt/show_off_i_made_a_cool_snippets_manager_with_ahk/j52ogtf/)

## Warranty and Support

None provided. Good luck. Source code is available on GitHub.

## Thanks

[AutoHotkey](https://autohotkey.com/) developers and forums.

## License and Copyright
Copyright (C) Ethan Piliavin
Released under the [GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.en.html), included as license.txt
