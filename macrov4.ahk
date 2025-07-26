#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; === Global variables ===
global isMacroRunning := false
global isPaused := false
global macroStatus := "Inactive ❌"
global guiVisible := true
global settingsFile := "config.ini"

; Default values
global digHoldMs := 700
global walkMs := 2000
global backwardDelayMs := 1000
global barLX := 0
global barLY := 0
global barRX := 0
global barRY := 0
global colorEmpty := 0x8C8C8C
global colorFill := 0xF1DC6B
global inventoryKey := "g"
global autoSellEnabled := false
global autoSellX := 0
global autoSellY := 0
global autoSellInterval := 600000
global lastSellTime := 0
global fixedMouseX := 940
global fixedMouseY := 364

; === Function Definitions ===

ShowTempToolTip(message, duration := 1000) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -duration)
}

LoadSettings() {
    global settingsFile, digHoldMs, walkMs, backwardDelayMs, barLX, barLY, barRX, barRY
    global inventoryKey, autoSellEnabled, autoSellX, autoSellY, autoSellInterval, lastSellTime
    
    if FileExist(settingsFile) {
        digHoldMs := IniRead(settingsFile, "Settings", "digHoldMs", digHoldMs)
        walkMs := IniRead(settingsFile, "Settings", "walkMs", walkMs)
        backwardDelayMs := IniRead(settingsFile, "Settings", "backwardDelayMs", backwardDelayMs)
        barLX := IniRead(settingsFile, "Bar", "barLX", barLX)
        barLY := IniRead(settingsFile, "Bar", "barLY", barLY)
        barRX := IniRead(settingsFile, "Bar", "barRX", barRX)
        barRY := IniRead(settingsFile, "Bar", "barRY", barRY)
        inventoryKey := IniRead(settingsFile, "AutoSell", "inventoryKey", inventoryKey)
        autoSellEnabled := IniRead(settingsFile, "AutoSell", "enabled", autoSellEnabled)
        autoSellX := IniRead(settingsFile, "AutoSell", "autoSellX", autoSellX)
        autoSellY := IniRead(settingsFile, "AutoSell", "autoSellY", autoSellY)
        autoSellInterval := IniRead(settingsFile, "AutoSell", "interval", autoSellInterval)
    }
}

SaveSettings(*) {
    global digHoldMs := digHoldEdit.Value
    global walkMs := walkMsEdit.Value
    global backwardDelayMs := backwardDelayEdit.Value
    global autoSellEnabled := autoSellCheck.Value
    global autoSellInterval := autoSellIntervalEdit.Value * 60000
    
    if SaveConfig() {
        ShowTempToolTip("Settings saved successfully!")
    } else {
        ShowTempToolTip("Failed to save settings!")
    }
}

SaveConfig() {
    global settingsFile, digHoldMs, walkMs, backwardDelayMs, barLX, barLY, barRX, barRY
    global inventoryKey, autoSellEnabled, autoSellX, autoSellY, autoSellInterval
    
    try {
        IniWrite(digHoldMs, settingsFile, "Settings", "digHoldMs")
        IniWrite(walkMs, settingsFile, "Settings", "walkMs")
        IniWrite(backwardDelayMs, settingsFile, "Settings", "backwardDelayMs")
        IniWrite(barLX, settingsFile, "Bar", "barLX")
        IniWrite(barLY, settingsFile, "Bar", "barLY")
        IniWrite(barRX, settingsFile, "Bar", "barRX")
        IniWrite(barRY, settingsFile, "Bar", "barRY")
        IniWrite(inventoryKey, settingsFile, "AutoSell", "inventoryKey")
        IniWrite(autoSellEnabled, settingsFile, "AutoSell", "enabled")
        IniWrite(autoSellX, settingsFile, "AutoSell", "autoSellX")
        IniWrite(autoSellY, settingsFile, "AutoSell", "autoSellY")
        IniWrite(autoSellInterval, settingsFile, "AutoSell", "interval")
        return true
    }
    catch {
        return false
    }
}

ResetDefaults(*) {
    global digHoldEdit, walkMsEdit, backwardDelayEdit, autoSellCheck, autoSellIntervalEdit
    global digHoldMs := 700
    global walkMs := 2000
    global backwardDelayMs := 1000
    global autoSellEnabled := false
    global autoSellInterval := 600000
    
    digHoldEdit.Value := digHoldMs
    walkMsEdit.Value := walkMs
    backwardDelayEdit.Value := backwardDelayMs
    autoSellCheck.Value := autoSellEnabled
    autoSellIntervalEdit.Value := autoSellInterval//60000
    ShowTempToolTip("Reset to default values!")
}

GetClickPosition(callback) {
    ToolTip("Click the desired position...")
    KeyWait("LButton", "D")
    MouseGetPos(&x, &y)
    ToolTip()
    callback(x, y)
}

SetLeftBar(x, y) {
    global barLX, barLY
    barLX := x
    barLY := y
    ShowTempToolTip("Left bar position saved: " x ", " y)
}

SetRightBar(x, y) {
    global barRX, barRY
    barRX := x
    barRY := y
    ShowTempToolTip("Right bar position saved: " x ", " y)
}

SetAutoSellPos(x, y) {
    global autoSellX, autoSellY
    autoSellX := x
    autoSellY := y
    ShowTempToolTip("Auto Sell position saved: " x ", " y)
}

ToggleMacro(*) {
    global isMacroRunning, isPaused, macroStatus, statusText, digHoldMs, lastSellTime
    
    if !isMacroRunning {
        if digHoldMs <= 0 {
            ShowTempToolTip("Please set dig hold time first!")
            return
        }
        isMacroRunning := true
        isPaused := false
        macroStatus := "Active ✅"
        statusText.Text := "Status: " macroStatus
        lastSellTime := A_TickCount
        SetTimer(RunMacro, 100)
        ShowTempToolTip("Macro started!")
    }
    else {
        isPaused := !isPaused
        macroStatus := isPaused ? "Paused ⏸️" : "Active ✅"
        statusText.Text := "Status: " macroStatus
        Send("{w up}{s up}{a up}{d up}{LButton up}")
        ShowTempToolTip(isPaused ? "Macro paused!" : "Macro resumed!")
        
        if (!isPaused && isMacroRunning) {
            SetTimer(RunMacro, 100)
        }
    }
}

ToggleGUI(*) {
    global guiVisible, myGui
    guiVisible := !guiVisible
    if guiVisible
        myGui.Show()
    else
        myGui.Hide()
}

PerformAutoSell() {
    global isPaused, autoSellX, autoSellY, inventoryKey, lastSellTime, fixedMouseX, fixedMouseY
    
    ; Pause other macros
    wasPaused := isPaused
    isPaused := true
    Send("{w up}{s up}{a up}{d up}{LButton up}")
    Sleep(100)
    
    ; Perform sell actions
    MouseMove(fixedMouseX, fixedMouseY, 0)
    Send("{" inventoryKey "}")
    Sleep(500)
    MouseClick("left", autoSellX, autoSellY)
    Sleep(500)
    Send("{" inventoryKey "}")
    Sleep(300)
    
    ; Update last sell time
    lastSellTime := A_TickCount
    
    ; Restore previous state
    isPaused := wasPaused
    if (!isPaused) {
        ShowTempToolTip("Auto-Sell completed! Resuming macro...")
    }
}

RunMacro() {
    global isMacroRunning, isPaused, digHoldMs, walkMs, backwardDelayMs
    global autoSellEnabled, lastSellTime, autoSellInterval, fixedMouseX, fixedMouseY
    
    while isMacroRunning {
        if isPaused {
            Sleep(200)
            continue
        }
        
        ; Dig phase with fixed mouse position
        while (isMacroRunning && !isPaused && !IsBarFill()) {
            MouseMove(fixedMouseX, fixedMouseY, 0)
            DigPerfect()
            if (ShouldAutoSell()) {
                PerformAutoSell()
            }
            Sleep(100)
        }
        
        if !isMacroRunning or isPaused
            continue
        
        Sleep(300)
        Send("{w down}")
        Sleep(walkMs)
        Send("{w up}")
        
        ; Water phase with fixed mouse position
        while (isMacroRunning && !isPaused && !IsBarEmpty()) {
            MouseMove(fixedMouseX, fixedMouseY, 0)
            Click("down")
            if (ShouldAutoSell()) {
                PerformAutoSell()
            }
            Sleep(100)
        }
        Click("up")
        
        if !isMacroRunning or isPaused
            continue
        
        Sleep(2000)
        Sleep(backwardDelayMs)
        Send("{s down}")
        Sleep(walkMs)
        Send("{s up}")
        Sleep(300)
    }
}

DigPerfect() {
    global digHoldMs
    Click("down")
    Sleep(digHoldMs)
    Click("up")
}

ShouldAutoSell() {
    global autoSellEnabled, lastSellTime, autoSellInterval
    if !autoSellEnabled
        return false
    return (A_TickCount - lastSellTime) >= autoSellInterval
}

IsColorClose(color1, color2, tolerance := 20) {
    r1 := (color1 >> 16) & 0xFF
    g1 := (color1 >> 8) & 0xFF
    b1 := color1 & 0xFF
    r2 := (color2 >> 16) & 0xFF
    g2 := (color2 >> 8) & 0xFF
    b2 := color2 & 0xFF
    return (Abs(r1 - r2) <= tolerance)
        && (Abs(g1 - g2) <= tolerance)
        && (Abs(b1 - b2) <= tolerance)
}

IsBarFill() {
    global barRX, barRY, colorFill
    return IsColorClose(PixelGetColor(barRX, barRY, "RGB"), colorFill)
}

IsBarEmpty() {
    global barLX, barLY, colorEmpty
    return IsColorClose(PixelGetColor(barLX, barLY, "RGB"), colorEmpty)
}

; === Create GUI ===
myGui := Gui()
myGui.Title := "Prospect Macro By Vadeyourgh"
myGui.Opt("+AlwaysOnTop +Resize")

; Status display
statusText := myGui.Add("Text", "w200", "Status: " macroStatus)
myGui.Add("Text", "yp", "Hotkeys: F6=Start/Pause | F7=Hide/Show GUI")

; Main Settings
myGui.Add("Text", "xm y+10 Section", "Main Settings:")
myGui.Add("Text", "xs y+5", "Dig Hold (ms):")
digHoldEdit := myGui.Add("Edit", "xs y+5 w60 Number", digHoldMs)
myGui.Add("Text", "xs y+5", "Walk Time (ms):")
walkMsEdit := myGui.Add("Edit", "xs y+5 w60 Number", walkMs)
myGui.Add("Text", "xs y+5", "Backward Delay (ms):")
backwardDelayEdit := myGui.Add("Edit", "xs y+5 w60 Number", backwardDelayMs)

; Bar Scanner
myGui.Add("Text", "xm y+10 Section", "Bar Scanner:")
myGui.Add("Button", "xs y+5 w95", "Left Bar").OnEvent("Click", (*) => GetClickPosition(SetLeftBar))
myGui.Add("Button", "x+5 yp w95", "Right Bar").OnEvent("Click", (*) => GetClickPosition(SetRightBar))

; Auto-Sell
myGui.Add("Text", "xm y+10 Section", "Auto-Sell:")
autoSellCheck := myGui.Add("Checkbox", "xs y+5", "Enabled")
autoSellCheck.Value := autoSellEnabled
myGui.Add("Button", "xs y+5 w200", "Set Sell Button").OnEvent("Click", (*) => GetClickPosition(SetAutoSellPos))
myGui.Add("Text", "xs y+5", "Interval (min):")
autoSellIntervalEdit := myGui.Add("Edit", "xs y+5 w60 Number", autoSellInterval//60000)

; Control buttons
btnToggleMacro := myGui.Add("Button", "xm y+20 w200", "Start/Pause Macro")
btnToggleMacro.OnEvent("Click", ToggleMacro)
btnSave := myGui.Add("Button", "xm y+5 w200", "Save Settings")
btnSave.OnEvent("Click", SaveSettings)
btnReset := myGui.Add("Button", "xm y+5 w200", "Reset Defaults")
btnReset.OnEvent("Click", ResetDefaults)

; === Hotkeys ===
F6::ToggleMacro()
F7::ToggleGUI()

; === Start script ===
LoadSettings()
myGui.Show()