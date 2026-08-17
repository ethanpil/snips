#Requires AutoHotkey v1.1
#NoEnv
#SingleInstance force
SetBatchLines, -1

SnipsVersion := "1.21"

; Setup the GUI window, don't show it until data is loaded
Gui, 1:+HwndSnipsHwnd
Gui, 1:Add, Edit, w220 hwndSearchHWND vSearchTerm gSearch
Gui, 1:Add, TreeView, x10 y35 w220 r21 hwndTreeHWND vST gSnipsTree
Gui, 1:Add, ListView, x10 y35 w220 r19 -Multi +grid -hdr hwndListHWND vSR gSearchResults, Folder|Match|ID
LV_ModifyCol(1, 60)
LV_ModifyCol(2, 140)
LV_ModifyCol(3, 0) ; Hide array key
GuiControl, 1:Hide, SR

; Refresh the list of snippets prior to GUI display
gosub, RefreshSnips

; Activate the hotkey from snips.ini. Use the default when the value is not valid.
IniRead, SnipsActivate, %A_ScriptDir%\snips.ini, snips, key, ^``
Hotkey, %SnipsActivate%, view, UseErrorLevel
if (ErrorLevel)
{
    Hotkey, ^``, view
    TrayTip, Snips, The hotkey in snips.ini is not valid. Snips uses CTRL+Backtick.
    SetTimer, RemoveTrayTip, 4000
}

;Load other ini settings into memory
IniRead, SnipsFolderSearch, %A_ScriptDir%\snips.ini, snips, foldernamesearch, Y

; Add the tray icon and menu
;menu, tray, Icon, %A_ScriptDir%\snips.ico, , 1 ;Not needed when compiled with AHK2EXE
menu, tray, nostandard
menu, tray, tip, Snips v%SnipsVersion%
menu, tray, add, Snips v%SnipsVersion%, about
menu, tray, add
menu, tray, add, Open, view
menu, tray, add, Refresh, RefreshSnips
menu, tray, add, About/Help, about
menu, tray, add
menu, tray, add, Exit, exit

return


#If WinActive("ahk_id " SnipsHwnd)
Down:: ; Use down arrow to move focus to tree or search results
    GuiControlGet, FocusedControl, focusV
    GuiControlGet, SRvisible, Visible, SR
    
    if (FocusedControl == "SearchTerm") 
    {
        
        if (SRvisible) 
        {
            GuiControl, Focus, SR 
            LV_Modify(1, "+Select +Focus")
        }
        else 
        {
            GuiControl, Focus, ST
            TV_Modify(1, "+Select +Focus")
        }

    }
    else
    {
        Send {Down}
    }
return

Enter:: ; Enterkey to search or send results

    GuiControlGet, FocusedControl, FocusV
    GuiControlGet, SRvisible, Visible, SR
    
    if (FocusedControl == "SearchTerm") 
    {
        
        if (SRvisible) 
        {
            GuiControl, Focus, SR 
            LV_Modify(0, "-Select")
            LV_Modify(1, "+Select +Focus")
        }
    }
    else if (FocusedControl = "SR")
        gosub, SearchResults
        
    else if (FocusedControl = "ST")
        SnipSend(TV_GetSelection())
return

^R::gosub, RefreshSnips


#If

RefreshSnips:
{
    global SnipsArray
    SnipsArray := Object()
    IniRead, SnipsPath, %A_ScriptDir%\snips.ini, snips, folder, snips
    SetWorkingDir, %A_ScriptDir%\%SnipsPath%
    TV_Delete()
    AddSubFolderToTree(A_WorkingDir)
    TrayTip, Snips, Snips list has been reloaded.
    SetTimer, RemoveTrayTip, 4000
}
return

RemoveTrayTip:
{
    SetTimer, RemoveTrayTip, Off
    TrayTip
}
return

Search:
{
    GuiControl, 1:Hide, ST
    
    LV_Delete() 
    guicontrol, 1:show, SR
    
    GuiControl, 1:-Redraw, SR
    GuiControlGet, SearchTerm
    
    global SnipsArray
    global SnipsFolderSearch
    
    
    if (SearchTerm != "")
    {
        GuiControl, -Redraw, SR
        for k, Snip in SnipsArray
        {
            SplitPath, Snip, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
            
            ; Extract category (folder) name
            Stringgetpos,pos,OutDir,\,R 
            pos+=1 
            Stringtrimleft,DirGroup,OutDir,%pos%
            
            
            if (InStr(OutNameNoExt, SearchTerm))  || ((InStr(DirGroup, SearchTerm)) and (SnipsFolderSearch = "Y"))
            {   
                
                ; Add to listview search results
                LV_Add("",DirGroup, OutNameNoExt , k)
            }
        }
        
        Items := LV_GetCount()
        
        if (Items == 0)
          LV_Add("","No Results.")  
          
        ; refresh the control 
        LV_ModifyCol()        
        LV_ModifyCol(3, 0)

        GuiControl, +Redraw, SR

    }
    else
    {
        guicontrol, 1:hide, SR
        guicontrol, 1:show, ST    
    }

}
return

GUIEscape:
{

    ; If a search was performed clear the search instead of closing the window
    GuiControlGet, SRvisible, Visible, SR
    
    guicontrol, , SearchTerm,
    guicontrol, 1:hide, SR
    guicontrol, 1:show, ST
    GuiControl, Focus, SearchTerm
     
    if (!SRvisible) {
        LV_Delete()
        gui, 1:hide
        return
    }
 
}
return

SearchResults:
{
    RetrievedText := ""

    if (A_GuiControlEvent == "DoubleClick")
        LV_GetText(RetrievedText, A_EventInfo, 3)

    ; An empty event means the call comes from the Enter hotkey
    else if (A_GuiControlEvent == "")
    {
        RowNumber := LV_GetNext(0, "F")

        if RowNumber
            LV_GetText(RetrievedText, RowNumber, 3)
    }

    if RetrievedText
        SnipSend(RetrievedText)
}
return

view:
{
    global active_id
    if (!WinActive("ahk_id " SnipsHwnd))
        WinGet, active_id, ID, A ;Save the currently active window
    gui, 1:show, w240 h350 Center, Snips
    WinSet, AlwaysOnTop, on, ahk_id %SnipsHwnd%
    GuiControl, Focus, SearchTerm
}
return

about:
{
   if (about_gui != "1")
    {

      about_txt =
(
---Snips %SnipsVersion%---
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
    key                The hotkey that opens Snips. Default: ^`` (CTRL+Backtick)
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
Released under the GPLv3 license, included as license.txt
)

      gui, 5:add, button, default x450 y375 w60 h20 g5guiclose, OK
      gui, 5:add, edit, +readonly vscroll x10 y10 w500 h360, %about_txt%
      gui, 5:show, center w520 h400, About Snips
      about_gui := "1"
    }
}
return

5GuiClose:
5GuiEscape:
 {
   gui, 5:destroy
   about_gui := "0"
 }
return

SnipsTree:
 {
    if (A_GuiEvent == "DoubleClick")    
       SnipSend(TV_GetSelection())
 }
return

SnipSend(snipid) {

    global SnipsArray
    global active_id

    ; Ignore folders and tree items that have no file
    if (!SnipsArray.HasKey(snipid))
        return

    ; Read the snippet file. Stop if the file is empty.
    FileRead, Snip, % SnipsArray[snipid]
    if (Snip = "")
        return

    ;Hide the GUI
    gui, 1:hide
    guicontrol, , SearchTerm,
    guicontrol, 1:hide, SR
    guicontrol, 1:show, ST

    ;Reset the tree
    GuiControl, -Redraw, ST
    ItemID = 0  ; Causes the loop's first iteration to start the search at the top of the tree.
    Loop
    {
        ItemID := TV_GetNext(ItemID, "Full") 
        if not ItemID  ; No more items in tree.
            break
        TV_Modify(ItemID, "-Expand")
    }
    GuiControl, +Redraw, ST        
        
    ;Position cursor if data is there
    SnipLen := StrLen(Snip)
    FoundPos := RegExMatch(Snip, "\n<<\-(\d*)\s*\Z", ReversePos)
 
    if (FoundPos > 0)
        StringTrimRight, Snip, Snip, (SnipLen - FoundPos)
 
    ; Backup Clipboard
    ClipSaved := ClipboardAll
    
    ; Send the Snip to clipboard and paste
    Clipboard := Snip
    ClipWait, 1
    if (ErrorLevel)
    {
        ; The clipboard did not get the data. Restore the clipboard and stop.
        Clipboard := ClipSaved
        ClipSaved := ""
        return
    }
    WinActivate, ahk_id %active_id%
    Sleep, 300
    
    ;Exception for command prompt which does not accept CTRL-V
    IfWinActive, ahk_class ConsoleWindowClass
    {
        Send !{Space}ep
        Sleep 50
    }
    Else
    {
        Send, {Control down}
        Sleep, 50
        Send, v
        Sleep, 50
        Send, {Control up}
    }
        
    ;Move the cursor if possible
    if (ReversePos1)
    {
        SendInput {Left %ReversePos1%}
        SendInput {Left 1} ;one extra left (recent AHK versions hotfix)
    }
    
    ; Wait for the target program to complete the paste. Then restore the clipboard.
    Sleep, 300
    Clipboard := ClipSaved
    ClipSaved := ""

}

exit:
{
   exitapp
}
return

AddSubFolderToTree(Folder, ParentItemID = 0)
{  
  global SnipsArray

  Loop %Folder%\*.*, 2
  {
    ID := TV_Add(A_LoopFileName, ParentItemID)
    AddSubFolderToTree(A_LoopFileFullPath, ID)   
  }
  Loop %Folder%\*.*
  {
    SplitPath, A_LoopFileFullPath, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
    ID := TV_Add(OutNameNoExt, ParentItemID)
    SnipsArray[ID] := A_LoopFileFullPath
  }
}