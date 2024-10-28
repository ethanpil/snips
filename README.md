# Snips v1.1
A simple way to store and use text snippets in any windows program.
https://github.com/ethanpil/snips

[Download Binary](https://github.com/ethanpil/snips/releases)

![snips](https://cloud.githubusercontent.com/assets/254784/21910990/78f0bc36-d8ec-11e6-84c8-88a801bd4d20.gif)

## Instructions

* Activate Snips using the hotkey - Default is CTRL+` (CTRL+Backtick) [Can be changed in snips.ini]
* On activation the search box is focused, so you can imeediately type to search snippets 
* Hit the down arrow to activate the tree or search resuls box. Use the arrow keys to navigate 
* Press enter or double click to copy a snippet to clipboard
* Escape key will close Snips and return to your previous window
* CTRL+R will refresh your list of snippets from disk
* A tray icon is displayed, which you can use to manage Snips or terminate the program.

All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. 

### History

````
    v1.2    Apr 18, 2020
            New: Minor changes to about screen text
            New: Add some new simple PHP snips
            Fix #3 : ESC sometimes still sends data
            Fix: Recent AHK versions require extra left for cursor move [Internal]
            Fix: Slow down paste keys to improve compatibility with some apps
            Fix: Codespacing and indents [Internal]

    v1.1    Jan 15, 2017
            New: Added support for cmd.exe
            New: Added some additional default snippets
            New: Added category name to search. (Example: type 'html' to see all \html snippets)
            Fix: Improved paste speed
            Fix: Improved cursor movement speed  

    v1.0    Jan 12, 2017
            Initial Release

````

## Why

I made this because:

 * I want to use the same snippet list across all my editors and IDE software
 * I want an easy and intuitive way to manage my snippets
 * I dont want my snippets in a proprietary format
 * Other third party snippet tools were too bulky and resource intensive
 * It was fun

## Options

Snips.ini the the program folder sets a few options:

    folder=snips        ; The subfolder under snips.exe which contains all the snippets.
    key=^`              ; An autohotkey code that activates the snippets window.
    foldernamesearch    ; Enabling to search both category/folder name and file names

## Snippet Files

All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. Edit the contents of the \snips folder in the program root to modify your collection. The tree view will mirror your folder structure. Filenames are the Snippet titles displayed in search and tree.

## Position the Cursor

You can tell Snips to position the cursor after inserting the snippet with an optional command code which is placed on the last line of a snippet file: `<<-X`   
Replace X with the number of spaces FROM THE END OF THE FILE to reverse the cursor. 

For example if your snippet file contained the following code:

    #include <>
    <<-2

The <<-2 on the last line of the file tells snips to position the cursor 2 characters from the end of the previous line. Therefore, after the snippet is inserted, the cursor will be positioned between the brackets. `<|>`.

## Default Snippets

I have included some basics to get you started. Please feel free to share any useful default snippets you think other users will appreciate. I prefer a PR on GitHub for your submissions.

## To Do

* Add CTRL+N hotlink to easily create a new snippet under a category (undecided)
* Improve UI [Auto height, better layout & colors, theming?]
* Add more default snippets
* Rewrite for AHK v2
* Request: Option to show window at cursor location instead of center screen [Tenavin@Reddit](https://www.reddit.com/r/AutoHotkey/comments/5nmzdt/show_off_i_made_a_cool_snippets_manager_with_ahk/j52ogtf/)

## Warranty and Support

None provided. Good luck. Source code is available on GitHub.

## Thanks

[AutoHotKey](https://autohotkey.com/) developers and forums.

## License and Copyright
Copyright (C) Ethan Piliavin
Released under the [GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.en.html), included as license.txt
