#Requires AutoHotkey v2.0
#SingleInstance Force

; Snips - A simple tool to store text snippets and to paste them into any
; Windows program.
; https://github.com/ethanpil/snips
; Copyright (C) Ethan Piliavin. The GPLv3 license applies to this program.

SnipsVersion := "2.0"

; Read a snippet file as UTF-8 when the file has no byte order mark
A_FileEncoding := "UTF-8"

; The caret and the mouse must give screen positions, not window positions
CoordMode("Caret", "Screen")
CoordMode("Mouse", "Screen")

; Limits that keep a bad folder setting from stopping the program
MaxFolderDepth := 12
MaxSnippets := 5000

; The size of the window
WindowWidth := 240
WindowHeight := 350

SnipsIni := A_ScriptDir "\snips.ini"

; The Map holds one record for each snippet in the tree. The key is the
; TreeView item id.
SnipsArray := Map()

; The Map holds the folder path of each folder item in the tree
FolderArray := Map()

; The settings. RefreshSnips reads them again on each refresh.
SnipsFolder := ""
SnipsFolderSearch := "Y"
AutoRefresh := "Y"
WindowPlacement := "center"

; The window that Snips pastes into
ActiveWindowId := 0

; The About window, or an empty string when it is not open
AboutWin := ""

; True when the results list holds snippets and not the "No Results." row
HasMatches := false

; The times of the snippet folders at the last refresh
FolderState := ""

; The process id of this program. Snips must not paste into its own windows.
OwnProcessId := DllCall("GetCurrentProcessId")

; ---------------------------------------------------------------------------
; Main window
; ---------------------------------------------------------------------------

SnipsGui := Gui("+AlwaysOnTop", "Snips")
SnipsGui.OnEvent("Escape", GuiEscapePressed)
SnipsGui.OnEvent("Close", (*) => HideSnips())

SearchBox := SnipsGui.AddEdit("w220")
SearchBox.OnEvent("Change", DoSearch)

Tree := SnipsGui.AddTreeView("x10 y35 w220 r21")
Tree.OnEvent("DoubleClick", (Ctrl, Item) => SnipSend(Item))

Results := SnipsGui.AddListView("x10 y35 w220 r19 -Multi +Grid -Hdr", ["Folder", "Match", "ID"])
Results.OnEvent("DoubleClick", (Ctrl, Row) => SendResult(Row))
Results.Visible := false

; ---------------------------------------------------------------------------
; Hotkeys and tray menu
;
; Snips registers the hotkeys and the tray menu before it reads the snippet
; folder. A folder with many files can take time. The user can always stop the
; program from the tray.
; ---------------------------------------------------------------------------

; These hotkeys operate only in the Snips window. HotIfWinActive lets
; AutoHotkey test the condition without a call to the script.
HotIfWinActive("ahk_id " SnipsGui.Hwnd)
Hotkey("Down", NavigateDown)
Hotkey("Enter", (*) => NavigateEnter(false))
Hotkey("^Enter", (*) => NavigateEnter(true))
Hotkey("^r", (*) => RefreshSnips())
Hotkey("^n", NewSnippet)
Hotkey("^e", EditSnippet)
HotIfWinActive()

; Activate the hotkey from snips.ini. Use the default when the value is not valid.
SnipsActivate := ReadSetting("key", "^``")

try
    Hotkey(SnipsActivate, ToggleSnips)
catch
{
    Hotkey("^``", ToggleSnips)
    Notify("The hotkey in snips.ini is not valid. Snips uses CTRL+Backtick.")
}

; The compiled program contains the icon. A script must load the icon file.
if (!A_IsCompiled && FileExist(A_ScriptDir "\snips.ico"))
{
    try
        TraySetIcon(A_ScriptDir "\snips.ico")
    catch
        ; An icon that Snips cannot read is not a reason to stop.
        ignore := true
}

A_IconTip := "Snips v" SnipsVersion

TrayMenu := A_TrayMenu
TrayMenu.Delete()
TrayMenu.Add("Snips v" SnipsVersion, ShowAbout)
TrayMenu.Add()
TrayMenu.Add("Open", ShowSnips)
TrayMenu.Add("Refresh", (*) => RefreshSnips())
TrayMenu.Add("Open Snippets Folder", (*) => OpenFile(SnipsFolder))
TrayMenu.Add("About/Help", ShowAbout)
TrayMenu.Add()
TrayMenu.Add("Exit", (*) => ExitApp())
TrayMenu.Default := "Open"

; Read the snippet folder last, because it is the slow step
RefreshSnips(false)

return

; ---------------------------------------------------------------------------
; Settings
; ---------------------------------------------------------------------------

; Read one value from snips.ini. An empty value gives the default.
ReadSetting(Key, Default)
{
    Value := Trim(IniRead(SnipsIni, "snips", Key, Default))

    return (Value = "") ? Default : Value
}

; Make a full path from the folder setting. The setting accepts a path that
; starts at the program folder, and also a full path such as D:\Snippets.
ResolveFolder(Path)
{
    ; A path with a drive letter, a path from the root of the drive, or a
    ; network path
    if (RegExMatch(Path, "^[A-Za-z]:[\\/]") || SubStr(Path, 1, 1) = "\" || SubStr(Path, 1, 1) = "/")
        return Path

    return A_ScriptDir "\" Path
}

; ---------------------------------------------------------------------------
; Snippet list
; ---------------------------------------------------------------------------

RefreshSnips(ShowMessage := true)
{
    global SnipsArray, FolderArray, SnipsFolder, SnipsFolderSearch
    global AutoRefresh, WindowPlacement, FolderState
    static Busy := false

    ; Two refreshes at the same time can put the tree and the Map out of step
    if (Busy)
        return

    Busy := true

    try
    {
        ; Read the settings again, so that an edit of snips.ini takes effect
        SnipsFolder := ResolveFolder(ReadSetting("folder", "snips"))
        SnipsFolderSearch := ReadSetting("foldernamesearch", "Y")
        AutoRefresh := ReadSetting("autorefresh", "Y")
        WindowPlacement := ReadSetting("position", "center")

        if (!DirExist(SnipsFolder))
        {
            ; An empty state stops Snips from a refresh on each window open
            FolderState := ""
            Notify("Snips cannot find the snippet folder: " SnipsFolder)
            return
        }

        ; Old search results point to items of the old tree. Remove them.
        ClearSearch()

        NewSnips := Map()
        NewFolders := Map()
        Tree.Opt("-Redraw")
        Tree.Delete()

        try
            AddSubFolderToTree(NewSnips, NewFolders, SnipsFolder)
        catch Error as Problem
        {
            Tree.Delete()
            NewSnips := Map()
            NewFolders := Map()
            Notify("Snips cannot read the snippet folder. " Problem.Message)
        }

        Tree.Opt("+Redraw")
        SnipsArray := NewSnips
        FolderArray := NewFolders
        FolderState := ReadFolderState()

        if (NewSnips.Count >= MaxSnippets)
            Notify("Snips loaded the first " MaxSnippets " snippets only.")
        else if (ShowMessage)
            Notify("Snips loaded " NewSnips.Count " snippets.")
    }
    finally
        Busy := false
}

AddSubFolderToTree(Snips, Folders, Folder, ParentItemId := 0, Depth := 1)
{
    if (Depth > MaxFolderDepth)
        return

    ; The folder name is the category. Snips shows it in the search results.
    SplitPath(Folder, &Category)

    Loop Files, Folder "\*.*", "D"
    {
        ; Do not go into a junction or a symbolic link. It can make a loop.
        if (InStr(A_LoopFileAttrib, "L"))
            continue

        Id := Tree.Add(A_LoopFileName, ParentItemId)
        Folders[Id] := A_LoopFileFullPath
        AddSubFolderToTree(Snips, Folders, A_LoopFileFullPath, Id, Depth + 1)
    }

    Loop Files, Folder "\*.*"
    {
        if (Snips.Count >= MaxSnippets)
            return

        SplitPath(A_LoopFileFullPath, , , , &NameNoExt)
        Id := Tree.Add(NameNoExt, ParentItemId)
        Snips[Id] := { Path: A_LoopFileFullPath, Name: NameNoExt, Category: Category }
    }
}

; Make a text from the times of all snippet folders. The time of a folder
; changes when a file in it is added, removed, or renamed. That is what the
; snippet list shows. Snips reads the text of a file only when it sends it.
; An empty result means that Snips cannot read the folder now.
ReadFolderState()
{
    try
        return FolderTimes(SnipsFolder, 1)
    catch
        return ""
}

FolderTimes(Folder, Depth)
{
    if (Depth > MaxFolderDepth)
        return ""

    State := FileGetTime(Folder, "M")

    ; The recursion is manual, so that Snips can stop at a junction
    Loop Files, Folder "\*.*", "D"
    {
        if (InStr(A_LoopFileAttrib, "L"))
            continue

        State .= FolderTimes(A_LoopFileFullPath, Depth + 1)
    }

    return State
}

; Read the folder again when a snippet file changed since the last refresh
RefreshWhenChanged()
{
    if (AutoRefresh != "Y")
        return

    State := ReadFolderState()

    if (State = "" || State = FolderState)
        return

    RefreshSnips(false)
}

; ---------------------------------------------------------------------------
; Search
; ---------------------------------------------------------------------------

DoSearch(*)
{
    global HasMatches

    ; One keystroke must not interrupt the search of the keystroke before it
    Critical

    Term := Trim(SearchBox.Value)

    if (Term = "")
    {
        HasMatches := false
        Results.Visible := false
        Tree.Visible := true
        return
    }

    Tree.Visible := false
    Results.Visible := true
    Results.Opt("-Redraw")
    Results.Delete()

    ; Each word of the search must be in the name or in the folder name.
    ; "html form" finds the snippet "form" in the folder "html".
    Words := StrSplit(Term, " ")
    SearchFolders := (SnipsFolderSearch = "Y")

    for Key, Snip in SnipsArray
    {
        if (SnipMatches(Snip, Words, SearchFolders))
            Results.Add("", Snip.Category, Snip.Name, Key)
    }

    HasMatches := (Results.GetCount() > 0)

    if (!HasMatches)
        Results.Add("", "No Results.")

    Results.ModifyCol()
    Results.ModifyCol(3, 0) ; Hide the Map key
    Results.Opt("+Redraw")
}

SnipMatches(Snip, Words, SearchFolders)
{
    for Word in Words
    {
        if (Word = "")
            continue

        if (InStr(Snip.Name, Word))
            continue

        if (SearchFolders && InStr(Snip.Category, Word))
            continue

        return false
    }

    return true
}

; Return the control that has the focus, or an empty string
FocusedControl()
{
    try
        return SnipsGui.FocusedCtrl
    catch
        return ""
}

; Move the focus to the results list. Do not move to the "No Results." row.
FocusResults()
{
    if (!HasMatches)
        return

    Results.Focus()
    Results.Modify(0, "-Select")
    Results.Modify(1, "+Select +Focus")
}

FocusTree()
{
    Tree.Focus()

    if (FirstItem := Tree.GetNext())
        Tree.Modify(FirstItem, "+Select")
}

; ---------------------------------------------------------------------------
; Keyboard control
; ---------------------------------------------------------------------------

; The down arrow moves the focus from the search box to the tree or to the
; results list.
NavigateDown(*)
{
    if (FocusedControl() != SearchBox)
    {
        Send("{Down}")
        return
    }

    if (Results.Visible)
        FocusResults()
    else
        FocusTree()
}

; The Enter key moves to the results list, or it sends the selected snippet.
; CTRL+Enter copies the snippet to the clipboard in place of a paste.
NavigateEnter(CopyOnly)
{
    if (FocusedControl() = SearchBox)
    {
        if (!Results.Visible)
            return

        ; Move to the first result. CTRL+Enter also copies it immediately.
        FocusResults()

        if (!CopyOnly)
            return
    }

    SnipSend(SelectedSnipId(), CopyOnly)
}

SendResult(Row)
{
    if (Row)
        SnipSend(Results.GetText(Row, 3))
}

; Return the id of the snippet that the user selected. The results list is in
; front during a search, and the tree is in front at other times.
SelectedSnipId()
{
    if (Results.Visible)
    {
        if (HasMatches && (Row := Results.GetNext(0, "F")))
            return Results.GetText(Row, 3)

        return 0
    }

    return Tree.GetSelection()
}

; Return the file of a snippet id, or an empty string when the id is a folder
; or is not in the list
SnippetPath(SnipId)
{
    if (!IsInteger(SnipId))
        return ""

    SnipId := Integer(SnipId)

    return SnipsArray.Has(SnipId) ? SnipsArray[SnipId].Path : ""
}

; ---------------------------------------------------------------------------
; Make and change snippets
; ---------------------------------------------------------------------------

; Return the folder of the selected snippet, or of the selected folder
SelectedFolder()
{
    if (Path := SnippetPath(SelectedSnipId()))
    {
        SplitPath(Path, , &Dir)
        return Dir
    }

    Item := Tree.GetSelection()

    if (Item && FolderArray.Has(Item))
        return FolderArray[Item]

    return SnipsFolder
}

NewSnippet(*)
{
    Folder := SelectedFolder()
    HideSnips()

    Answer := InputBox("Type the name of the new snippet.`nSnips makes the file in:`n" Folder
        , "New Snippet", "w320 h150")

    if (Answer.Result != "OK")
        return

    Name := Trim(Answer.Value)

    if (Name = "")
        return

    if (RegExMatch(Name, "[\\/:*?`"<>|]"))
    {
        Notify("A file name cannot contain a quote mark or these characters: \ / : * ? < > |")
        return
    }

    ; Windows keeps some names for devices
    if (RegExMatch(Name, "i)^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])(\.|$)"))
    {
        Notify("Windows keeps the name " Name " for a device. Use a different name.")
        return
    }

    Path := Folder "\" Name ".txt"

    if (FileExist(Path))
    {
        Notify("This snippet is already there: " Path)
        return
    }

    try
        FileAppend("", Path, "UTF-8")
    catch
    {
        Notify("Snips cannot make the file: " Path)
        return
    }

    RefreshSnips(false)
    OpenFile(Path)
}

EditSnippet(*)
{
    Path := SnippetPath(SelectedSnipId())

    if (Path = "")
        return

    HideSnips()
    OpenFile(Path)
}

; Open a file or a folder with the program that Windows uses for it
OpenFile(Path)
{
    try
        Run('"' Path '"')
    catch
        Notify("Snips cannot open: " Path)
}

; ---------------------------------------------------------------------------
; Window control
; ---------------------------------------------------------------------------

; The hotkey opens the window. It hides the window when the window is in front.
ToggleSnips(*)
{
    if (WinActive("ahk_id " SnipsGui.Hwnd))
    {
        HideSnips()
        return
    }

    ShowSnips()
}

ShowSnips(*)
{
    global ActiveWindowId

    ; Keep the window that Snips pastes into
    if (!WinActive("ahk_id " SnipsGui.Hwnd))
    {
        try
        {
            Candidate := WinGetID("A")

            if (IsPasteTarget(Candidate))
                ActiveWindowId := Candidate
        }
        catch
            ; Keep the window from the last time
            ignore := true
    }

    RefreshWhenChanged()

    ; Make the window, but keep it hidden. Snips can then measure it and put it
    ; in position before the user sees it.
    SnipsGui.Show("Hide w" WindowWidth " h" WindowHeight)

    Spot := ""

    try
    {
        WinGetPos( , , &ActualWidth, &ActualHeight, "ahk_id " SnipsGui.Hwnd)
        Spot := WindowPosition(ActualWidth, ActualHeight)
    }
    catch
        Spot := ""

    if (Spot)
    {
        ; WinMove uses screen pixels. Gui.Show would change the numbers for the
        ; screen DPI.
        WinMove(Spot.X, Spot.Y, , , "ahk_id " SnipsGui.Hwnd)
        SnipsGui.Show()
    }
    else
        SnipsGui.Show("Center")

    ; Show the window in front of other windows that are always on top
    SnipsGui.Opt("+AlwaysOnTop")
    SearchBox.Focus()
}

; Find the position for the window. An empty result puts the window in the
; center of the screen.
WindowPosition(Width, Height)
{
    Mode := WindowPlacement

    if (Mode = "caret")
    {
        ; The text cursor position. Some programs do not give it.
        if (CaretGetPos(&CaretX, &CaretY))
            return KeepOnScreen(CaretX, CaretY + 20, Width, Height)

        ; Use the mouse when the program does not give a text cursor
        Mode := "mouse"
    }

    if (Mode = "mouse")
    {
        MouseGetPos(&MouseX, &MouseY)
        return KeepOnScreen(MouseX, MouseY, Width, Height)
    }

    return ""
}

; Move the position so that the full window stays on one screen
KeepOnScreen(X, Y, Width, Height)
{
    try
    {
        Found := false

        Loop MonitorGetCount()
        {
            ; The full size of the screen finds the correct screen, also when
            ; the point is on the taskbar
            MonitorGet(A_Index, &Left, &Top, &Right, &Bottom)

            if (X >= Left && X < Right && Y >= Top && Y < Bottom)
            {
                ; The work area keeps the window off the taskbar
                MonitorGetWorkArea(A_Index, &Left, &Top, &Right, &Bottom)
                Found := true
                break
            }
        }

        if (!Found)
            MonitorGetWorkArea( , &Left, &Top, &Right, &Bottom)
    }
    catch
        return ""

    ; Max comes last, so that a small screen keeps the window on the screen
    return { X: Max(Left, Min(X, Right - Width))
        , Y: Max(Top, Min(Y, Bottom - Height)) }
}

; A window of this program, or a window of the shell, cannot accept a paste.
IsPasteTarget(Hwnd)
{
    if (!Hwnd)
        return false

    try
    {
        if (WinGetPID("ahk_id " Hwnd) = OwnProcessId)
            return false

        Class := WinGetClass("ahk_id " Hwnd)
    }
    catch
        return false

    return !(Class = "Shell_TrayWnd" || Class = "Progman" || Class = "WorkerW"
        || Class = "NotifyIconOverflowWindow")
}

; The Escape key clears the search. When there is no search, it hides the window.
GuiEscapePressed(*)
{
    if (Results.Visible)
        ClearSearch()
    else
        HideSnips()
}

ClearSearch()
{
    global HasMatches

    HasMatches := false
    SearchBox.Value := ""
    Results.Delete()
    Results.Visible := false
    Tree.Visible := true
    SearchBox.Focus()
}

HideSnips()
{
    SnipsGui.Hide()
    ClearSearch()
}

; Close all folders in the tree
CollapseTree()
{
    Tree.Opt("-Redraw")

    ItemId := 0
    Loop
    {
        ItemId := Tree.GetNext(ItemId, "Full")

        if (!ItemId)
            break

        Tree.Modify(ItemId, "-Expand")
    }

    Tree.Opt("+Redraw")
}

; ---------------------------------------------------------------------------
; Send a snippet
; ---------------------------------------------------------------------------

SnipSend(SnipId, CopyOnly := false)
{
    ; A second send must not start while the first send holds the clipboard
    static Busy := false

    if (Busy)
        return

    ; Ignore folders and tree items that have no file
    Path := SnippetPath(SnipId)

    if (Path = "")
        return

    Snip := ReadSnippet(Path)

    if (Snip = "")
        return

    ReverseCount := CutCursorCommand(&Snip)

    ; The file can hold nothing more than a cursor command
    if (Snip = "")
    {
        Notify("This snippet has no text.")
        return
    }

    Busy := true

    ; No other thread must interrupt the send
    Critical

    try
    {
        HideSnips()
        CollapseTree()

        if (CopyOnly)
            CopySnippet(Snip)
        else
            PasteSnippet(Snip, ReverseCount)
    }
    finally
    {
        Critical("Off")
        Busy := false
    }
}

; Read the snippet file. Return an empty string when Snips cannot read it.
ReadSnippet(Path)
{
    try
    {
        Text := FileRead(Path)

        ; A replacement character shows that the file is not UTF-8. Read the
        ; file again with the code page of Windows.
        if (InStr(Text, Chr(0xFFFD)))
            Text := FileRead(Path, "CP0")

        return Text
    }
    catch
    {
        Notify("Snips cannot read the file: " Path)
        return ""
    }
}

; Find the cursor position command and remove it from the snippet.
; Snips accepts the marker {|} in the text, and also the older command <<-X on
; the last line. The result is the number of steps that the cursor must go back
; from the end of the snippet.
CutCursorCommand(&Snip)
{
    LegacyCount := 0

    ; The older command, and the line break in front of it
    if (FoundPos := RegExMatch(Snip, "\R<<\-(\d*)\s*\Z", &Found))
    {
        Snip := SubStr(Snip, 1, FoundPos - 1)

        ; The number comes from the snippet file. It can be absent or too large.
        if (Found[1] != "")
        {
            Count := Found[1] + 0
            LegacyCount := (Count > StrLen(Snip)) ? StrLen(Snip) : Integer(Count)
        }
    }

    ; The marker has priority. Snips removes all markers and puts the cursor at
    ; the first one.
    if (MarkerPos := InStr(Snip, "{|}"))
    {
        Snip := StrReplace(Snip, "{|}", "")

        return CursorSteps(SubStr(Snip, MarkerPos))
    }

    return LegacyCount
}

; Count the steps that the cursor makes through a text. A CR LF pair is one
; step, but two characters.
;
; The older command <<-X gives a number of steps and needs no calculation.
CursorSteps(Text)
{
    Steps := StrLen(Text)
    Position := 0

    while (Position := InStr(Text, "`r`n", , Position + 1))
        Steps--

    return Steps
}

; Put a text on the clipboard. Return false when it does not work.
PutOnClipboard(Text)
{
    try
        A_Clipboard := Text
    catch
    {
        Notify("Another program holds the clipboard. Try again.")
        return false
    }

    if (!ClipWait(1))
    {
        Notify("Snips cannot put the snippet on the clipboard.")
        return false
    }

    return true
}

CopySnippet(Snip)
{
    if (PutOnClipboard(Snip))
        Notify("Snips put the snippet on the clipboard.")
}

PasteSnippet(Snip, ReverseCount)
{
    ; Save the clipboard
    try
        ClipSaved := ClipboardAll()
    catch
    {
        Notify("Another program holds the clipboard. Try again.")
        return
    }

    try
    {
        if (!PutOnClipboard(Snip))
            return

        if (!ActivateTarget())
            return

        ; Wait for the user to release the keys of the last command. If Snips
        ; does not wait, the key repeat goes into the target program.
        KeyWait("Enter", "T1")
        KeyWait("Control", "T1")

        if (WinActive("ahk_class ConsoleWindowClass") && IsLegacyConsole())
            ; The legacy console has no CTRL+V. Use the Edit menu of the window.
            SendEvent("!{Space}ep")
        else
            Send("^v")

        if (ReverseCount)
            SendInput("{Left " ReverseCount "}")

        ; Wait for the target program to complete the paste. A large snippet
        ; needs more time.
        Sleep(300 + Min(StrLen(Snip) // 100, 1200))
    }
    finally
    {
        ; Always give the clipboard back to the user
        try
            A_Clipboard := ClipSaved
        catch
            Notify("Snips cannot restore the clipboard.")
    }
}

; The Windows setting ForceV2 turns the new console on. When the value is 0,
; the user selected the legacy console, which has no CTRL+V.
IsLegacyConsole()
{
    try
        return RegRead("HKEY_CURRENT_USER\Console", "ForceV2") = 0
    catch
        return false
}

; Put the focus on the window that Snips pastes into
ActivateTarget()
{
    if (!ActiveWindowId || !WinExist("ahk_id " ActiveWindowId))
    {
        Notify("Snips cannot find the window to paste into.")
        return false
    }

    try
        WinActivate("ahk_id " ActiveWindowId)
    catch
    {
        Notify("Snips cannot go to the window to paste into.")
        return false
    }

    ; Do not send keys before the target window has the focus
    if (!WinWaitActive("ahk_id " ActiveWindowId, , 2))
    {
        Notify("The window to paste into did not take the focus.")
        return false
    }

    return true
}

; ---------------------------------------------------------------------------
; About window
; ---------------------------------------------------------------------------

ShowAbout(*)
{
    global AboutWin

    if (AboutWin)
    {
        AboutWin.Show()
        return
    }

    AboutWin := Gui("+AlwaysOnTop", "About Snips")
    AboutWin.OnEvent("Escape", CloseAbout)
    AboutWin.OnEvent("Close", CloseAbout)

    ; Add the button first, so that it has the focus and the Enter key closes
    ; the window
    OkButton := AboutWin.AddButton("Default x450 y415 w60 h20", "OK")
    OkButton.OnEvent("Click", CloseAbout)

    AboutWin.AddEdit("ReadOnly VScroll x10 y10 w500 h400", AboutText())
    AboutWin.Show("Center w520 h440")
}

CloseAbout(*)
{
    global AboutWin

    AboutWin.Destroy()
    AboutWin := ""
}

AboutText()
{
    Text := "
(
---Snips %VERSION%---
A simple tool to store text snippets and to paste them into any Windows program.
https://github.com/ethanpil/snips

---Instructions---
* Press the hotkey to open Snips. The default hotkey is CTRL+Backtick. Press the hotkey again to close the window.
* Type in the search box to search the snippet names. Type more than one word to make the search smaller.
* Press the down arrow to move to the tree or to the search results. Use the arrow keys to navigate.
* Press Enter or double-click a snippet to paste it into your previous window.
* Press CTRL+Enter to copy a snippet to the clipboard and not paste it.
* Press Escape to close Snips and go back to your previous window.

---Keys---
    Enter        Paste the snippet into your previous window
    CTRL+Enter   Copy the snippet to the clipboard
    CTRL+N       Make a new snippet in the selected folder
    CTRL+E       Open the selected snippet in your text editor
    CTRL+R       Read the snippet list from disk again
    Escape       Clear the search, or close the window

---Options---
The file snips.ini in the program folder sets these options:

    folder             The folder that contains the snippet files. A full path such as D:\Snippets also operates. Default: snips
    key                The hotkey that opens Snips. See snips.ini for the format. Default: CTRL+Backtick
    foldernamesearch   Set to Y to also search the folder names. Default: Y
    position           Where the window opens: center, caret, or mouse. Default: center
    autorefresh        Set to Y to read changed snippet files when the window opens. Default: Y

Press CTRL+R after you change snips.ini. Snips then reads the file again.

---Snippet Files---
All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet. Edit the files in the \snips folder to change your collection. The tree shows your folder structure. The file names are the snippet titles in the search and in the tree. Snips reads a file as UTF-8.

---Position the Cursor---
Write the marker {|} in the snippet at the position for the cursor. Snips removes the marker and puts the cursor there.

Example snippet file:

    #include <{|}>

After the paste, the cursor is between the brackets.

A snippet cannot contain the three characters of the marker as text.

Snips also accepts the older command <<-X alone on the last line of the file. Replace X with the number of steps between the cursor position and the end of the snippet.

---Thanks---
AutoHotkey developers and forums.

---License and Copyright---
Copyright (C) Ethan Piliavin
The GPLv3 license applies to this program. Read license.txt.
)"

    return StrReplace(Text, "%VERSION%", SnipsVersion)
}

; ---------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------

Notify(Message)
{
    TrayTip(Message, "Snips")
    SetTimer(RemoveTrayTip, -4000)
}

RemoveTrayTip()
{
    TrayTip()
}
