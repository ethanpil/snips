#Requires AutoHotkey v2.0
#SingleInstance Force

; Snips - A simple tool to store text snippets and to paste them into any
; Windows program.
; https://github.com/ethanpil/snips
; Copyright (C) Ethan Piliavin. The GPLv3 license applies to this program.

SnipsVersion := "2.0"

; Limits that keep a bad folder setting from stopping the program
MaxFolderDepth := 12
MaxSnippets := 5000

SnipsIni := A_ScriptDir "\snips.ini"

; The Map holds one record for each snippet in the tree. The key is the
; TreeView item id.
SnipsArray := Map()

; The settings. RefreshSnips reads them again on each refresh.
SnipsFolder := ""
SnipsFolderSearch := "Y"

; The window that Snips pastes into
ActiveWindowId := 0

; The About window, or an empty string when it is not open
AboutWin := ""

; True when the results list holds snippets and not the "No Results." row
HasMatches := false

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
Hotkey("Enter", NavigateEnter)
Hotkey("^r", (*) => RefreshSnips())
HotIfWinActive()

; Activate the hotkey from snips.ini. Use the default when the value is not valid.
SnipsActivate := ReadSetting("key", "^``")

try
    Hotkey(SnipsActivate, ShowSnips)
catch
{
    Hotkey("^``", ShowSnips)
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

; ---------------------------------------------------------------------------
; Snippet list
; ---------------------------------------------------------------------------

RefreshSnips(ShowMessage := true)
{
    global SnipsArray, SnipsFolder, SnipsFolderSearch
    static Busy := false

    ; Two refreshes at the same time can put the tree and the Map out of step
    if (Busy)
        return

    Busy := true

    try
    {
        ; Read the settings again, so that an edit of snips.ini takes effect
        SnipsFolder := A_ScriptDir "\" ReadSetting("folder", "snips")
        SnipsFolderSearch := ReadSetting("foldernamesearch", "Y")

        if (!DirExist(SnipsFolder))
        {
            Notify("Snips cannot find the snippet folder: " SnipsFolder)
            return
        }

        ; Old search results point to items of the old tree. Remove them.
        ClearSearch()

        NewList := Map()
        Tree.Opt("-Redraw")
        Tree.Delete()

        try
            AddSubFolderToTree(NewList, SnipsFolder)
        catch Error as Problem
        {
            Tree.Delete()
            NewList := Map()
            Notify("Snips cannot read the snippet folder. " Problem.Message)
        }

        Tree.Opt("+Redraw")
        SnipsArray := NewList

        if (NewList.Count >= MaxSnippets)
            Notify("Snips loaded the first " MaxSnippets " snippets only.")
        else if (ShowMessage)
            Notify("Snips loaded " NewList.Count " snippets.")
    }
    finally
        Busy := false
}

AddSubFolderToTree(List, Folder, ParentItemId := 0, Depth := 1)
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
        AddSubFolderToTree(List, A_LoopFileFullPath, Id, Depth + 1)
    }

    Loop Files, Folder "\*.*"
    {
        if (List.Count >= MaxSnippets)
            return

        SplitPath(A_LoopFileFullPath, , , , &NameNoExt)
        Id := Tree.Add(NameNoExt, ParentItemId)
        List[Id] := { Path: A_LoopFileFullPath, Name: NameNoExt, Category: Category }
    }
}

; ---------------------------------------------------------------------------
; Search
; ---------------------------------------------------------------------------

DoSearch(*)
{
    global HasMatches

    ; One keystroke must not interrupt the search of the keystroke before it
    Critical

    Term := SearchBox.Value

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

    SearchFolders := (SnipsFolderSearch = "Y")

    for Key, Snip in SnipsArray
    {
        if (InStr(Snip.Name, Term) || (SearchFolders && InStr(Snip.Category, Term)))
            Results.Add("", Snip.Category, Snip.Name, Key)
    }

    HasMatches := (Results.GetCount() > 0)

    if (!HasMatches)
        Results.Add("", "No Results.")

    Results.ModifyCol()
    Results.ModifyCol(3, 0) ; Hide the Map key
    Results.Opt("+Redraw")
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

; The Enter key moves to the results list, or it pastes the selected snippet.
NavigateEnter(*)
{
    Focused := FocusedControl()

    if (Focused = SearchBox)
    {
        if (Results.Visible)
            FocusResults()
    }
    else if (Focused = Results)
        SendResult(Results.GetNext(0, "F"))
    else if (Focused = Tree)
        SnipSend(Tree.GetSelection())
}

SendResult(Row)
{
    if (Row)
        SnipSend(Results.GetText(Row, 3))
}

; ---------------------------------------------------------------------------
; Window control
; ---------------------------------------------------------------------------

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

    SnipsGui.Show("w240 h350 Center")

    ; Show the window in front of other windows that are always on top
    SnipsGui.Opt("+AlwaysOnTop")
    SearchBox.Focus()
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
; Paste a snippet
; ---------------------------------------------------------------------------

SnipSend(SnipId)
{
    ; A second paste must not start while the first paste holds the clipboard
    static Busy := false

    if (Busy)
        return

    ; Ignore folders and tree items that have no file
    if (!IsInteger(SnipId))
        return

    SnipId := Integer(SnipId)

    if (!SnipsArray.Has(SnipId))
        return

    Snip := ReadSnippet(SnipsArray[SnipId].Path)

    if (Snip = "")
        return

    Busy := true

    ; No other thread must interrupt the paste
    Critical

    try
    {
        HideSnips()
        CollapseTree()
        PasteSnippet(Snip)
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
        return FileRead(Path)
    catch
    {
        Notify("Snips cannot read the file: " Path)
        return ""
    }
}

PasteSnippet(Snip)
{
    ; Read the cursor position command and remove it, and remove the line break
    ; in front of it.
    ReverseCount := 0

    if (FoundPos := RegExMatch(Snip, "\R<<\-(\d*)\s*\Z", &Found))
    {
        ReverseCount := Found[1]
        Snip := SubStr(Snip, 1, FoundPos - 1)
    }

    ; The count comes from the snippet file. Keep it inside the snippet.
    if (ReverseCount)
        ReverseCount := Min(ReverseCount + 0, StrLen(Snip))

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
        try
            A_Clipboard := Snip
        catch
        {
            Notify("Another program holds the clipboard. Try again.")
            return
        }

        if (!ClipWait(1))
        {
            Notify("Snips cannot put the snippet on the clipboard.")
            return
        }

        if (!ActivateTarget())
            return

        ; Wait for the user to release the keys of the last command. If Snips
        ; does not wait, the key repeat goes into the target program.
        KeyWait("Enter", "T1")
        KeyWait("Control", "T1")

        ; The command prompt of older Windows versions does not accept CTRL+V.
        ; SendEvent puts a delay between the keys, which the menu needs.
        if (WinActive("ahk_class ConsoleWindowClass"))
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
    OkButton := AboutWin.AddButton("Default x450 y375 w60 h20", "OK")
    OkButton.OnEvent("Click", CloseAbout)

    AboutWin.AddEdit("ReadOnly VScroll x10 y10 w500 h360", AboutText())
    AboutWin.Show("Center w520 h400")
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
* Press the hotkey to open Snips. The default hotkey is CTRL+Backtick.
* Type in the search box to search the snippet names.
* Press the down arrow to move to the tree or to the search results. Use the arrow keys to navigate.
* Press Enter or double-click a snippet to paste it into your previous window.
* Press Escape to close Snips and go back to your previous window.
* Press CTRL+R to load the snippet list from disk again.
* Use the tray icon to open, refresh, or stop Snips.

All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet.

---Options---
The file snips.ini in the program folder sets these options:

    folder             The folder that contains the snippet files. Default: snips
    key                The hotkey that opens Snips. See snips.ini for the format. Default: CTRL+Backtick
    foldernamesearch   Set to Y to also search the folder names. Default: Y

---Snippet Files---
All snippets are plain text files in the \snips folder in the program folder. Each file contains one snippet. Edit the files in the \snips folder to change your collection. The tree shows your folder structure. The file names are the snippet titles in the search and in the tree. Save files as UTF-8 with BOM when they contain special characters.

---Position the Cursor---
Snips can position the cursor after it pastes a snippet. Write the command code <<-X alone on the last line of the snippet file.
Replace X with the number of characters between the cursor position and the end of the snippet.

Example snippet file:

    #include <>
    <<-2

The code <<-2 tells Snips to move the cursor 2 characters back from the end of the pasted text. After the paste, the cursor is between the brackets: <|>.

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
