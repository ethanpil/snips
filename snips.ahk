#SingleInstance force

SnipsVersion := 1.1

; Setup the GUI window, don't show it until data is loaded
Gui, 1:Add, Edit, w220 hwndSearchHWND vSearchTerm gSearch
Gui, 1:Add, TreeView, x10 y35 w220 r21 hwndTreeHWND vST gSnipsTree
Gui, 1:Add, ListView, x10 y35 w220 r19 -Multi +grid -hdr hwndListHWND vSR gSearchResults, Folder|Match|ID
Gui, Add, Button, Hidden Default, OK
LV_ModifyCol(1, 60),
LV_ModifyCol(2, 140),
LV_ModifyCol(3, 0), ; Hide array key
GuiControl, 1:Hide, SR

; Refresh the list of snippets prior to GUI display
gosub, RefreshSnips

; Activate user configured hotkey
IniRead, SnipsActivate, %A_ScriptDir%\snips.ini, snips, key
Hotkey, %SnipsActivate%, view

;Load other ini settings into memory
IniRead, SnipsFolderSearch, %A_ScriptDir%\snips.ini, snips, foldernamesearch

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


#IfWinActive Snips 
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


#IfWinActive

RefreshSnips:
{
    global SnipsArray
    SnipsArray := Object()
    IniRead, SnipsPath, %A_ScriptDir%\snips.ini, snips, folder
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
            
            
            if (InStr(OutNameNoExt, SearchTerm))  || ((InStr(DirGroup, SearchTerm)) and (SnipsFolderSearch == "Y"))
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
    
    ; Clear the windows status
    ControlSetText, Search, ""
    guicontrol, , SearchTerm,
    guicontrol, 1:hide, SR
    guicontrol, 1:show, ST
    GuiControl, Focus, SearchTerm
     
    if (!SRvisible) {
        LV_Delete()
        gui, 1:hide
<<<<<<< HEAD
        return
=======
        
>>>>>>> parent of 16b65db... Fix: ESC sometimes still sends data
    }
 
}
return

SearchResults:
{    

    if (A_GuiControlEvent == "DoubleClick")  
        LV_GetText(RetrievedText, A_EventInfo, 3) 
                
    else {     
        RowNumber := FocusedRowNumber := LV_GetNext(0, "F") 
        
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
    WinGet, active_id, ID, A ;Save the currently active window
    gui, 1:show, w240 h350 Center, Snips
    WinSet, AlwaysOnTop, on, Snips
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
A simple way to store and use text snippets in any windows program.
https://github.com/ethanpil/snips

---Instructions---
* Activate Snips using the hotkey (Default is CTRL+Backtick)
* By default the search box is activated, so you can tyoe to search snippet titles. (File names) 
* Hit the down arrow to activate the tree or search resuls box. Use the arrow keys to navigate 
* Press enter or double click to copy a snippet to clipboard
* Escape key will close Snips and return you to your previous window
* CTRL+R will refresh your list of snippets from disk
* A tray icon is displayed, which you can use to manage Snips or terminate the program.

All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. 

---Options---
Snips.ini the the program folder sets a few options:

    folder=snips   ; The subfolder under snips.exe which contains all the snippets.
    key=^`         ; An autohotkey code that activates the snippets window.

---Snippet Files---
All snippets are plain text files stored in the \snips folder under the program binary. One snippet per file. Edit the contents of the \snips folder in the program root to modify your collection. The tree view will mirror your folder structure. Filenames are the Snippet titles displayed in search and tree.

---Position the Cursor---
You can tell Snips to position the cursor with anoptional command code exclusively on the last line of a snippet file: <<-X   
Replace X with the number of spaces FROM THE END OF THE FILE to reverse the cursor. 

For example if your snippet file contained the following code:

    #include <>
    <<-2

The <<-2 on the last line of the file tells snips to position the cursor 2 characters from the end of the previous line. Therefore, after the snippet is inserted, the cursor will be positioned between the brackets. <|>.

---Thanks---
Autohotkey developers and forums.

---License and Copyright---
Copyright (C) Ethan Piliavin
Released under the GPLv3 license, included as license.txt
)

      gui, 5:add, button, default x450 y375 w60 h20 g5guiclose, OK
      gui, 5:add, edit, +readonly vscroll x10 y10 w500 h360, %about_txt%
      gui, 5:show, center w520 h400, About Snips
      about_gui = "1"
    }
}
return

5guiclose:
 {
   gui, 5:destroy
   about_gui := "0"
 }

SnipsTree:
 {
    if (A_GuiEvent == "DoubleClick")    
       SnipSend(TV_GetSelection())
 }
return

SnipSend(snipid) {
    
    ;Hide the GUI
    gui, 1:hide
    ControlSetText, Search, ""
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
        
    global SnipsArray
    FileRead, Snip, % SnipsArray[snipid]
    
    ;Position cursor if data is there
    SnipLen := StrLen(Snip)
    FoundPos := RegExMatch(Snip, "\n<<\-(\d*)\Z", ReversePos)
 
    if (FoundPos > 0)
        StringTrimRight, Snip, Snip, (SnipLen - FoundPos)
 
    ; Backup Clipboard
    ClipSaved := ClipboardAll
    
    ; Send the Snip to clipboard and paste
    Clipboard := Snip
    ClipWait
    WinActivate, ahk_id %active_id%
    Sleep, 300
    
    ;Exception for command prompt which does not accept CTRL-V
    IfWinActive, ahk_class ConsoleWindowClass
    {
        Send !{Space}ep
        Sleep 50
    }
    Else
        Send, {Control down}
        Sleep, 50
        Send, v
        Sleep, 50
        Send, {Control up}
        
    ;Move the cursor if possible
    if (ReversePos1)
        SendInput {Left %ReversePos1%}
        SendInput {Left 1} ;one extra left (recent AHK versions hotfix)  
    
    ; Restore Clipboard
    Clipboard := ClipSaved

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