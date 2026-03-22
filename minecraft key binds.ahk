#Requires AutoHotkey v2.0
#SingleInstance Force

FontFile := A_ScriptDir "\media\Minecraftia-Regular.ttf"
if FileExist(FontFile)
    DllCall("gdi32\AddFontResourceEx", "Str", FontFile, "UInt", 0x10, "UInt", 0)

MediaDir    := A_ScriptDir "\media"
SettingsDir := A_ScriptDir "\settings"
SaveFile    := SettingsDir "\binds.ini"

MCGui := Gui("-Resize", "Minecraft Key Binds")
MCGui.BackColor := "1C1C1C"

winW := 650
winH := 880

MCGui.Add("Picture", "x0 y0 w" winW " h" winH " +Disabled", MediaDir "\image_78e6e4.png")

AddShadowText(MCGui, 0, 15, winW, "Minecraft lce Keyboard Binds Made By 8vy2", "s16", "Center", 2)
AddShadowText(MCGui, 0, 45, winW, "Settings Keybinds", "s10", "Center", 2)

Data := [
    ["Walk Forward",            "W",            "w"],
    ["Walk Backward",           "S",            "s"],
    ["Strafe Left",             "A",            "a"],
    ["Strafe Right",            "D",            "d"],
    ["Jump / Fly (Up)",         "Space",        "Space"],
    ["Sneak / Fly (Down)",      "Shift (Hold)", "Shift"],
    ["Sprint",                  "Ctrl",         "Ctrl"],
    ["Inventory",               "E",            "e"],
    ["Chat",                    "T",            "t"],
    ["Drop Item",               "Q",            "q"],
    ["Crafting",                "C",            "c"],
    ["Toggle View (FPS/TPS)",   "F5",           "F5"],
    ["Fullscreen",              "F11",          "F11"],
    ["Pause Menu",              "Esc",          "Escape"],
    ["Attack / Destroy",        "Left Click",   "LButton"],
    ["Use / Place",             "Right Click",  "RButton"],
    ["Hotbar Slot 1",           "1",            "1"],
    ["Hotbar Slot 2",           "2",            "2"],
    ["Hotbar Slot 3",           "3",            "3"],
    ["Hotbar Slot 4",           "4",            "4"],
    ["Hotbar Slot 5",           "5",            "5"],
    ["Hotbar Slot 6",           "6",            "6"],
    ["Hotbar Slot 7",           "7",            "7"],
    ["Hotbar Slot 8",           "8",            "8"],
    ["Hotbar Slot 9",           "9",            "9"],
    ["Select Item",             "Scroll Up",    "WheelUp"],
    ["Accept Tutorial",         "Enter",        "Enter"],
    ["Decline Tutorial",        "B",            "b"],
    ["Game Info (Player List)", "TAB",          "Tab"],
    ["Toggle HUD",              "F1",           "F1"],
    ["Toggle Debug Info",       "F3",           "F3"],
    ["Open Debug Overlay",      "F4",           "F4"],
    ["Toggle Debug Console",    "F6",           "F6"]
]

KeyTextObjects     := []
BtnObjects         := []
CurrentBindings    := []
ActiveRow          := 0
ActiveRemaps       := Map()
RemapSendMap       := Map()
ScrollableControls := []
WheelBindPending   := false

for i, item in Data {
    saved := IniRead(SaveFile, "Bindings", "Key" i, "")
    CurrentBindings.Push(saved != "" ? saved : item[3])
}

ListStartY  := 85
RowHeight   := 30
FooterRowH  := 55
TotalListH  := (Data.Length * RowHeight) + FooterRowH + 20
VisibleH    := winH - ListStartY
ScrollOffset := 0
MinScroll    := 0
MaxScroll    := -(TotalListH - VisibleH)
if (MaxScroll > 0)
    MaxScroll := 0
ScrollSpeed := 30

yPos := ListStartY

for index, item in Data {
    displayLabel := (CurrentBindings[index] != item[3]) ? KeyToLabel(CurrentBindings[index]) : item[2]

    txtLabel := AddShadowText(MCGui, 50, yPos, 220, item[1], "s9", "Right", 6)
    btnMain  := MCGui.Add("Picture", "x280 y" yPos " w180 h26", MediaDir "\btn bind.png")
    txtKey   := AddShadowText(MCGui, 280, yPos, 180, displayLabel, "s9", "Center", 6)
    btnReset := MCGui.Add("Picture", "x470 y" yPos " w80 h26", MediaDir "\btn bind.png")
    txtReset := AddShadowText(MCGui, 470, yPos, 80, "Reset", "s9", "Center", 6)

    ScrollableControls.Push(txtLabel.shadow, txtLabel.main)
    ScrollableControls.Push(btnMain)
    ScrollableControls.Push(txtKey.shadow, txtKey.main)
    ScrollableControls.Push(btnReset)
    ScrollableControls.Push(txtReset.shadow, txtReset.main)

    KeyTextObjects.Push({main: txtKey.main, shadow: txtKey.shadow})
    BtnObjects.Push(btnMain)

    btnMain.OnEvent("Click", BindRow.Bind(index))
    txtKey.main.OnEvent("Click", BindRow.Bind(index))
    btnReset.OnEvent("Click", ResetSingle.Bind(index))
    txtReset.main.OnEvent("Click", ResetSingle.Bind(index))

    yPos += RowHeight
}

yPos += 15
btnResetAll := MCGui.Add("Picture", "x130 y" yPos " w180 h40", MediaDir "\btn bind.png")
txtResetAll := AddShadowText(MCGui, 130, yPos, 180, "Reset Keys", "s10", "Center", 12)
btnDone     := MCGui.Add("Picture", "x340 y" yPos " w180 h40", MediaDir "\btn bind.png")
txtDone     := AddShadowText(MCGui, 340, yPos, 180, "Done", "s10", "Center", 12)

ScrollableControls.Push(btnResetAll, txtResetAll.shadow, txtResetAll.main)
ScrollableControls.Push(btnDone, txtDone.shadow, txtDone.main)

btnResetAll.OnEvent("Click", ResetAll)
txtResetAll.main.OnEvent("Click", ResetAll)
btnDone.OnEvent("Click", (*) => ExitApp())
txtDone.main.OnEvent("Click", (*) => ExitApp())

MCGui.Show("w" winW " h" winH)

for i, item in Data {
    if (CurrentBindings[i] != item[3])
        SetRemap(i, CurrentBindings[i], item[3])
}

#HotIf WinActive("Minecraft Key Binds") && ActiveRow = 0
WheelUp::ScrollGUI(1)
WheelDown::ScrollGUI(-1)
#HotIf

#HotIf WinActive("Minecraft Key Binds") && ActiveRow != 0
WheelUp:: {
    global WheelBindPending
    if WheelBindPending {
        WheelBindPending := false
        ApplyBind(ActiveRow, "WheelUp")
    }
}
WheelDown:: {
    global WheelBindPending
    if WheelBindPending {
        WheelBindPending := false
        ApplyBind(ActiveRow, "WheelDown")
    }
}
#HotIf

BindRow(idx, *) {
    global ActiveRow
    if (ActiveRow != 0 && ActiveRow != idx)
        CancelBind(ActiveRow)
    ActiveRow := idx
    SetKeyText(idx, "> Press Key <")
    SetTimer(StartListening, -200)
}

StartListening(*) {
    global WheelBindPending
    WheelBindPending := true
    SetTimer(ListenForKey, 30)
}

ListenForKey() {
    global ActiveRow
    if (ActiveRow = 0) {
        SetTimer(ListenForKey, 0)
        return
    }
    static AllKeys := [
        "LButton","RButton","MButton","XButton1","XButton2",
        "a","b","c","d","e","f","g","h","i","j","k","l","m",
        "n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9",
        "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
        "Space","Enter","Escape","Tab","Backspace","Delete","Insert",
        "Home","End","PgUp","PgDn","Up","Down","Left","Right",
        "Numpad0","Numpad1","Numpad2","Numpad3","Numpad4",
        "Numpad5","Numpad6","Numpad7","Numpad8","Numpad9",
        "NumpadEnter","NumpadDot","NumpadDiv","NumpadMult","NumpadSub","NumpadAdd",
        "Shift","LShift","RShift","Ctrl","LCtrl","RCtrl","Alt","LAlt","RAlt",
        "LWin","RWin","CapsLock","ScrollLock","NumLock","PrintScreen","Pause"
    ]
    for key in AllKeys {
        if GetKeyState(key, "P") {
            if (key = "Escape") {
                CancelBind(ActiveRow)
                return
            }
            ApplyBind(ActiveRow, key)
            return
        }
    }
}

ApplyBind(idx, newKey) {
    global ActiveRow, CurrentBindings, Data, WheelBindPending
    SetTimer(ListenForKey, 0)
    WheelBindPending := false
    defaultKey := Data[idx][3]
    RemoveRemap(idx)
    CurrentBindings[idx] := newKey
    SetKeyText(idx, KeyToLabel(newKey))
    if (newKey != defaultKey)
        SetRemap(idx, newKey, defaultKey)
    SaveBindings()
    ActiveRow := 0
}

CancelBind(idx) {
    global ActiveRow, CurrentBindings, WheelBindPending
    SetTimer(ListenForKey, 0)
    SetTimer(StartListening, 0)
    WheelBindPending := false
    SetKeyText(idx, KeyToLabel(CurrentBindings[idx]))
    ActiveRow := 0
}

SetKeyText(idx, txt) {
    global KeyTextObjects
    KeyTextObjects[idx].main.Value   := txt
    KeyTextObjects[idx].shadow.Value := txt
}

SaveBindings() {
    global CurrentBindings, SaveFile, SettingsDir
    if !DirExist(SettingsDir)
        DirCreate(SettingsDir)
    for i, key in CurrentBindings
        IniWrite(key, SaveFile, "Bindings", "Key" i)
}

SendRemapped(thisHotkey) {
    global RemapSendMap
    if RemapSendMap.Has(thisHotkey) {
        target := RemapSendMap[thisHotkey]
        Send("{Blind}{" target " down}")
        KeyWait(thisHotkey)
        Send("{Blind}{" target " up}")
    }
}

SetRemap(idx, newKey, oldKey) {
    global ActiveRemaps, RemapSendMap
    HotIfWinActive("ahk_exe Minecraft.Client.exe")
    try {
        Hotkey(oldKey, BlockKey, "On")
    } catch {
    }
    RemapSendMap[newKey] := oldKey
    try {
        Hotkey(newKey, SendRemapped, "On")
    } catch {
    }
    HotIfWinActive()
    ActiveRemaps[idx] := {newKey: newKey, oldKey: oldKey}
}

RemoveRemap(idx) {
    global ActiveRemaps, RemapSendMap
    if !ActiveRemaps.Has(idx)
        return
    r := ActiveRemaps[idx]
    HotIfWinActive("ahk_exe Minecraft.Client.exe")
    try {
        Hotkey(r.oldKey, "Off")
    } catch {
    }
    try {
        Hotkey(r.newKey, "Off")
    } catch {
    }
    HotIfWinActive()
    RemapSendMap.Delete(r.newKey)
    ActiveRemaps.Delete(idx)
}

BlockKey(*) {
}

ResetSingle(idx, *) {
    global Data, CurrentBindings, ActiveRow, WheelBindPending
    if (ActiveRow = idx) {
        SetTimer(ListenForKey, 0)
        SetTimer(StartListening, 0)
        WheelBindPending := false
        ActiveRow := 0
    }
    RemoveRemap(idx)
    CurrentBindings[idx] := Data[idx][3]
    SetKeyText(idx, Data[idx][2])
    SaveBindings()
}

ResetAll(*) {
    global Data, CurrentBindings, ActiveRow, WheelBindPending
    SetTimer(ListenForKey, 0)
    SetTimer(StartListening, 0)
    WheelBindPending := false
    ActiveRow := 0
    for idx, item in Data {
        RemoveRemap(idx)
        CurrentBindings[idx] := item[3]
        SetKeyText(idx, item[2])
    }
    SaveBindings()
}

KeyToLabel(key) {
    labels := Map(
        "LButton","Left Click",  "RButton","Right Click", "MButton","Middle Click",
        "XButton1","Mouse 4",    "XButton2","Mouse 5",
        "WheelUp","Scroll Up",   "WheelDown","Scroll Down",
        "Space","Space",         "Enter","Enter",          "Escape","Esc",
        "Tab","TAB",             "Backspace","Backspace",   "Delete","Delete",
        "Shift","Shift",         "LShift","L Shift",        "RShift","R Shift",
        "Ctrl","Ctrl",           "LCtrl","L Ctrl",          "RCtrl","R Ctrl",
        "Alt","Alt",             "LAlt","L Alt",            "RAlt","R Alt",
        "Up","Up",               "Down","Down",             "Left","Left",  "Right","Right",
        "CapsLock","CapsLock",   "PrintScreen","PrtSc",     "Pause","Pause",
        "Home","Home",           "End","End",               "PgUp","PgUp",  "PgDn","PgDn",
        "Insert","Insert",       "LWin","Win",              "RWin","Win"
    )
    if labels.Has(key)
        return labels[key]
    return StrUpper(key)
}

ScrollGUI(direction) {
    global ScrollOffset, ScrollSpeed, MinScroll, MaxScroll, ScrollableControls, MCGui
    newOffset := ScrollOffset + (direction > 0 ? ScrollSpeed : -ScrollSpeed)
    if (newOffset > MinScroll)
        newOffset := MinScroll
    if (newOffset < MaxScroll)
        newOffset := MaxScroll
    if (newOffset = ScrollOffset)
        return
    move := newOffset - ScrollOffset
    ScrollOffset := newOffset
    DllCall("SendMessage", "Ptr", MCGui.Hwnd, "UInt", 0x000B, "Ptr", 0, "Ptr", 0)
    for ctrl in ScrollableControls {
        ctrl.GetPos(&x, &y, &w, &h)
        ctrl.Move(x, y + move)
    }
    DllCall("SendMessage", "Ptr", MCGui.Hwnd, "UInt", 0x000B, "Ptr", 1, "Ptr", 0)
    DllCall("RedrawWindow", "Ptr", MCGui.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x0081)
}

AddShadowText(GuiObj, x, y, w, txt, sizeStr, align, downOffset := 0) {
    actualY := y + downOffset
    GuiObj.SetFont(sizeStr " c3F3F3F", "Minecraftia")
    shadow := GuiObj.Add("Text", "x" (x+2) " y" (actualY+2) " w" w " +BackgroundTrans " align, txt)
    GuiObj.SetFont(sizeStr " cWhite", "Minecraftia")
    main := GuiObj.Add("Text", "x" x " y" actualY " w" w " +BackgroundTrans " align, txt)
    return {shadow: shadow, main: main}
}

OnExit((*) => DllCall("gdi32\RemoveFontResourceEx", "Str", FontFile, "UInt", 0x10, "UInt", 0))
