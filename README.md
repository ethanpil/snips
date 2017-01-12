# Snips v1.0
A simple way to store and use text snippets in any windows program.
https://github.com/ethanpil/snips

[Download Binary](https://github.com/ethanpil/snips/releases)

![snips](https://cloud.githubusercontent.com/assets/254784/21910990/78f0bc36-d8ec-11e6-84c8-88a801bd4d20.gif)

## Instructions

* Activate Snips using the hotkey - Default is CTRL+` (CTRL+Backtick)
* By default the search box is activated, so you can tyoe to search snippet titles. (File names) 
* Hit the down arrow to activate the tree or search resuls box. Use the arrow keys to navigate 
* Press enter or double click to copy a snippet to clipboard
* Escape key will close Snips and return you to your previous window
* CTRL+R will refresh your list of snippets from disk
* A tray icon is displayed, which you can use to manage Snips or terminate the program.

All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. 

### History

````

    v1.0 - Initial Release

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

    folder=snips   ; The subfolder under snips.exe which contains all the snippets.
    key=^`         ; An autohotkey code that activates the snippets window.

## Snippet Files

All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. Edit the contents of the \snips folder in the program root to modify your collection. The tree view will mirror your folder structure. Filenames are the Snippet titles displayed in search and tree.

## Position the Cursor

You can tell Snips to position the cursor with anoptional command code exclusively on the last line of a snippet file: <<-X   
Replace X with the number of spaces FROM THE END OF THE FILE to reverse the cursor. 

For example if your snippet file contained the following code:

    #include <>
    <<-2

The <<-2 on the last line of the file tells snips to position the cursor 2 characters from the end of the previous line. Therefore, after the snippet is inserted, the cursor will be positioned between the brackets. <|>.

## Default Snippets

I have included some basics to get you started. Please feel free to share any useful default snippets you think other users will appreciate. I prefer a PR on GitHub for your submissions.

## Warranty and Support

None provided. Good luck. Source code is available on GitHub.

## Thanks

[AutoHotKey](https://autohotkey.com/) developers and forums.

## License and Copyright
Copyright (C) Ethan Piliavin
Released under the [GPLv3 license](https://www.gnu.org/licenses/gpl-3.0.en.html), included as license.txt
