#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; === Global variables ===
global isMacroRunning := false
global isPaused := false
global macroStatus := "Inactive ❌"
global guiVisible := true
global configFile := "config.ini"

; Default values
global diggingTime := 700
global walkTime := 1000
global backwardDelay := 2000
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

LoadConfig() {
    global configFile, diggingTime, walkTime, backwardDelay, barLX, barLY, barRX, barRY
    global inventoryKey, autoSellEnabled, autoSellX, autoSellY, autoSellInterval
    
    if !FileExist(configFile) {
        MsgBox "File config.ini tidak ditemukan. Menggunakan nilai default."
        return
    }

    try {
        diggingTime := IniRead(configFile, "Settings", "diggingTime", diggingTime)
        walkTime := IniRead(configFile, "Settings", "walkTime", walkTime)
        backwardDelay := IniRead(configFile, "Settings", "backwardDelay", backwardDelay)
        
        barLX := IniRead(configFile, "Bar", "barLX", barLX)
        barLY := IniRead(configFile, "Bar", "barLY", barLY)
        barRX := IniRead(configFile, "Bar", "barRX", barRX)
        barRY := IniRead(configFile, "Bar", "barRY", barRY)
        
        inventoryKey := IniRead(configFile, "AutoSell", "inventoryKey", inventoryKey)
        autoSellEnabled := IniRead(configFile, "AutoSell", "enabled", autoSellEnabled)
        autoSellX := IniRead(configFile, "AutoSell", "autoSellX", autoSellX)
        autoSellY := IniRead(configFile, "AutoSell", "autoSellY", autoSellY)
        autoSellInterval := IniRead(configFile, "AutoSell", "interval", autoSellInterval)
    }
    catch as e {
        MsgBox "Error loading config: " e.Message
    }
}

SaveConfig(*) {
    global diggingTime := diggingTimeEdit.Value
    global walkTime := walkTimeEdit.Value
    global backwardDelay := backwardDelayEdit.Value
    global autoSellEnabled := autoSellCheck.Value
    global autoSellInterval := autoSellIntervalEdit.Value * 60000
    
    try {
        IniWrite(diggingTime, configFile, "Settings", "diggingTime")
        IniWrite(walkTime, configFile, "Settings", "walkTime")
        IniWrite(backwardDelay, configFile, "Settings", "backwardDelay")
        IniWrite(barLX, configFile, "Bar", "barLX")
        IniWrite(barLY, configFile, "Bar", "barLY")
        IniWrite(barRX, configFile, "Bar", "barRX")
        IniWrite(barRY, configFile, "Bar", "barRY")
        IniWrite(inventoryKey, configFile, "AutoSell", "inventoryKey")
        IniWrite(autoSellEnabled, configFile, "AutoSell", "enabled")
        IniWrite(autoSellX, configFile, "AutoSell", "autoSellX")
        IniWrite(autoSellY, configFile, "AutoSell", "autoSellY")
        IniWrite(autoSellInterval, configFile, "AutoSell", "interval")
        
        ShowTempToolTip("Configuration saved successfully!")
        return true
    }
    catch as e {
        ShowTempToolTip("Failed to save configuration!")
        return false
    }
}

ResetDefaults(*) {
    global diggingTimeEdit, walkTimeEdit, backwardDelayEdit, autoSellCheck, autoSellIntervalEdit
    global diggingTime := 700
    global walkTime := 1000
    global backwardDelay := 2000
    global autoSellEnabled := false
    global autoSellInterval := 600000
    
    diggingTimeEdit.Value := diggingTime
    walkTimeEdit.Value := walkTime
    backwardDelayEdit.Value := backwardDelay
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
    global isMacroRunning, isPaused, macroStatus, statusText, diggingTime, lastSellTime
    
    if !isMacroRunning {
        if diggingTime <= 0 {
            ShowTempToolTip("Please set digging time first!")
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
    
    wasPaused := isPaused
    isPaused := true
    Send("{w up}{s up}{a up}{d up}{LButton up}")
    Sleep(100)
    
    MouseMove(fixedMouseX, fixedMouseY, 0)
    Send("{" inventoryKey "}")
    Sleep(500)
    MouseClick("left", autoSellX, autoSellY)
    Sleep(500)
    Send("{" inventoryKey "}")
    Sleep(300)
    
    lastSellTime := A_TickCount
    isPaused := wasPaused
    if (!isPaused) {
        ShowTempToolTip("Auto-Sell completed! Resuming macro...")
    }
}

RunMacro() {
    global isMacroRunning, isPaused, diggingTime, walkTime, backwardDelay
    global autoSellEnabled, lastSellTime, autoSellInterval, fixedMouseX, fixedMouseY
    
    while isMacroRunning {
        if isPaused {
            Sleep(200)
            continue
        }
        
        ; Digging phase
        while (isMacroRunning && !isPaused && !IsBarFill()) {
            MouseMove(fixedMouseX, fixedMouseY, 0)
            Dig()
            if (ShouldAutoSell()) {
                PerformAutoSell()
            }
            Sleep(100)
        }
        
        if !isMacroRunning or isPaused
            continue
        
        Sleep(300)
        Send("{w down}")
        Sleep(walkTime)
        Send("{w up}")
        
        ; Cleaning pan phase
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
        Sleep(backwardDelay)
        Send("{s down}")
        Sleep(walkTime)
        Send("{s up}")
        Sleep(300)
    }
}

Dig() {
    global diggingTime
    Click("down")
    Sleep(diggingTime)
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
myGui.Add("Text", "xs y+5", "Digging Time (ms):")
diggingTimeEdit := myGui.Add("Edit", "xs y+5 w60 Number", diggingTime)
myGui.Add("Text", "xs y+5", "Walk Time (ms):")
walkTimeEdit := myGui.Add("Edit", "xs y+5 w60 Number", walkTime)
myGui.Add("Text", "xs y+5", "Backward Delay (ms):")
backwardDelayEdit := myGui.Add("Edit", "xs y+5 w60 Number", backwardDelay)

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
btnSave := myGui.Add("Button", "xm y+5 w200", "Save Configuration")
btnSave.OnEvent("Click", SaveConfig)
btnReset := myGui.Add("Button", "xm y+5 w200", "Reset Defaults")
btnReset.OnEvent("Click", ResetDefaults)

; === Hotkeys ===
F6::ToggleMacro()
F7::ToggleGUI()

; === Start script ===
LoadConfig()  ; Load config before showing GUI

; Update GUI controls with loaded values
diggingTimeEdit.Value := diggingTime
walkTimeEdit.Value := walkTime
backwardDelayEdit.Value := backwardDelay
autoSellCheck.Value := autoSellEnabled
autoSellIntervalEdit.Value := autoSellInterval//60000

myGui.Show()
