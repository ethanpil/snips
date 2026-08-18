# Snips
A simple tool to store text snippets and to paste them into any Windows program.
https://github.com/ethanpil/snips

[Download Binary](https://github.com/ethanpil/snips/releases)

![snips](https://cloud.githubusercontent.com/assets/254784/21910990/78f0bc36-d8ec-11e6-84c8-88a801bd4d20.gif)

## Instructions

* Press the hotkey to open Snips. The default hotkey is CTRL+\` (CTRL+Backtick). Press the hotkey again to close the window. You can change the hotkey in snips.ini.
* The search box has the focus when Snips opens. Type to search the snippet names. Type more than one word to make the search smaller. For example, `html form` finds the snippet `form` in the folder `html`.
* Press the down arrow to move to the tree or to the search results. Use the arrow keys to navigate.
* Press Enter or double-click a snippet to paste it into your previous window.
* Press CTRL+Enter to copy a snippet to the clipboard and not paste it. Use this for a program that does not accept a paste, such as a program that runs as administrator.
* Press Escape to close Snips and go back to your previous window.
* Use the tray icon to open Snips, to refresh the list, to open the snippet folder, or to stop the program.

All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet.

To run snips.ahk you need [AutoHotkey](https://www.autohotkey.com/) v2.0 or later. The compiled snips.exe does not need AutoHotkey.

## Keys

| Key | Function |
| --- | --- |
| Enter | Paste the snippet into your previous window |
| CTRL+Enter | Copy the snippet to the clipboard |
| CTRL+N | Make a new snippet in the selected folder |
| CTRL+E | Open the selected snippet in your text editor |
| CTRL+R | Read the snippet list from disk again |
| Down arrow | Move from the search box to the tree or to the results |
| Escape | Clear the search, or close the window |

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
| folder | The folder that contains the snippet files. A path that starts at the program folder, or a full path such as `D:\Dropbox\snips`. | snips |
| key | The [hotkey](https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols) that opens Snips. | ^\` (CTRL+Backtick) |
| foldernamesearch | Set to Y to also search the folder names. A match on a folder name shows all snippets of that folder. | Y |
| position | Where the window opens: `center`, `caret` (at the text cursor), or `mouse`. | center |
| autorefresh | Set to Y to read changed snippet files when the window opens. Set to N if you have many snippets and the window opens slowly. | Y |

Write comments in snips.ini on their own lines. Start each comment line with a semicolon.

Press CTRL+R after you change snips.ini. Snips then reads the file again. The `key` option is an exception: it needs a restart.

To keep your snippets on more than one computer, put the snippet folder in Dropbox, OneDrive, or a git repository, and set `folder` to that full path.

## Snippet Files

All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet. Edit the files in the \snips folder to change your collection. The tree view shows your folder structure. The file names are the snippet titles in the search and in the tree.

Snips reads a snippet file as UTF-8.

## Position the Cursor

Write the marker `{|}` in the snippet at the position for the cursor. Snips removes the marker and puts the cursor there.

Example snippet file:

    #include <{|}>

After the paste, the cursor is between the brackets.

A snippet cannot contain the three characters of the marker as text. If a snippet contains the marker more than one time, Snips uses the first one and removes the others.

Snips also accepts the older command `<<-X` alone on the last line of the file. Replace X with the number of steps between the cursor position and the end of the snippet. Your older snippet files continue to operate.

## Default Snippets

I have included some basics to get you started. Please feel free to share any useful default snippets you think other users will appreciate. I prefer a PR on GitHub for your submissions.

## To Do

* Improve UI [Auto height, better layout & colors, theming?]
* Add more default snippets

## Warranty and Support

None provided. Good luck. Source code is available on GitHub.

## Thanks

[AutoHotkey](https://autohotkey.com/) developers and forums.

## License and Copyright
Copyright (C) Ethan Piliavin
Released under the [GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.en.html), included as license.txt
