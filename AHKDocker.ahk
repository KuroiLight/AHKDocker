;Author: KuroiLight - klomb - <kuroilight@openmailbox.org>
;Started On: 14/1/15
;Licensed under: Creative Commons Attribution 3.0 Unported (CC-BY) found at http://creativecommons.org/licenses/by/3.0/legalcode
SetBatchLines -1
ListLines Off
#KeyHistory 0
#MaxHotkeysPerInterval 1000
#MaxThreads 3
#MaxThreadsBuffer Off
#MaxThreadsPerHotkey, 2
#NoEnv
#SingleInstance force
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
DetectHiddenText, On
DetectHiddenWindows, On
SetMouseDelay, -1
SetTitleMatchMode, Fast
SetWorkingDir %A_ScriptDir%
StringCaseSense, Off

SCRIPTNAME := RegExReplace(A_Scriptname, "(?:(\w+).+)", "$1")
AskStartupShortcut()

SetTimer, PopoutPulse, 50
OnExit("ExitDocker", -1)
GenerateDockPoints()

Menu, Tray, NoStandard
Menu, Tray, Tip, %SCRIPTNAME%
Menu, Tray, Add, Enabled, ToggleScript
Menu, Tray, Check, Enabled
Menu, Tray, Add, Reload Settings, ReloadSettings
Menu, Tray, Add,
Menu, Tray, Add, Restart, _Reload
Menu, Tray, Add, Exit, _ExitApp

if(!%A_IsCompiled% and FileExist("./icon.ico")) {
    Menu, Tray, Icon, icon.ico
}

ReloadSettings:
    SysGet, FullScreenHeight, 17 ;79
    SysGet, FullScreenWidth, 16 ;78
    DISABLEMIDDLEMOUSECENTER := Setup("iDisableMiddleMouseCenter", 0, 0, 1)
    DOCKMODE := Setup("iDockHideMode", 1, 0, 1)
    DOCKTIMEOUT := Setup("iPopoutTimeout", 150, 0, 5000)
    DOCKDELAY := Setup("iPopoutDelay", 100, 0, 5000)
    DOCKANIMSPEEDMOD := Setup("fAnimSpeedMod", 1.0, 0.0, 2.0)
    LBLOCK := Setup("iMouse1PopoutLock", 1, 0, 1)
    GRIPSIZE := DllCall("GetSystemMetrics", Int, 5) ;get default border size
    GRIPSIZE += Setup("iBorderGripOverride", 1, 0, 50)
    TITLEGRIPSIZE := DllCall("GetSystemMetrics", Int, 4) ;system caption height
    ENABLETRANSPARENCY := Setup("iEnableTransparency", 0, 0, 1)
    TRANSLEVEL := Setup("iTransparency", 90, 10, 100)
    tLvl := Abs(255 * (TRANSLEVEL / 100))
    DISABLEASYNCMOVE := Setup("iDisableAsyncWinMove", 0, 0, 1)
    SetWinDelay, % Setup("iDelayWindowCommands", 2, -1, 500)
return
_ExitApp:
	ExitApp
_Reload:
	Reload

; F1::postDockPoints()
; postDockPoints() {
;    global DockPoints
;    for k, v in DockPoints {
;        res .= "Dock at " . k.wall.center.x . ":" . k.wall.center.y . " in monitor " . k.monitor . " contains " . (v ? v : "nothing") . "`n"
;    }
;    MsgBox, % res
; }

ExitDocker(Reason, Code) {
    Critical
    global DockPoints
    for k, v in DockPoints {
        if(v) {
            LockWindow(v, false)
            k.GetWindowToPosition(v, true, pt)
            AnimateMovement(v, pt)
        }
    }
}

ToggleScript() {
	static StopScript := "Off"
	StopScript := (StopScript = "On" ? "Off" : "On")
	Menu, Tray, % (StopScript = "Off" ? "Check" : "UnCheck"), Enabled
	Suspend, %StopScript%
    Pause, %StopScript%
}

;read/write ini setting with default, min and max values
Setup(setting, default_val, minimum, maximum, newvalue := "") {
    global SCRIPTNAME
    INIFILE := "./" . SCRIPTNAME . ".ini"
    
    IniRead, val, %INIFILE%, %SCRIPTNAME%, %setting%, %default_val%
    if(val > maximum and val < minimum) {
        Msgbox, 0x30, %SCRIPTNAME% Settings Loader, % (setting . " has a value of " val " which is incorrect, It must be a value between " minimum " and " maximum ".`nResetting it to the default of " default_val)
        val := default_val
    }

    if(newvalue)
        val := newvalue

    IniWrite, %val%, %INIFILE%, %SCRIPTNAME%, %setting%
    
    return val
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;dll calls
Sleep(ms) {
    DllCall("Sleep", UInt, ms)
}

SetWinPos(hWnd, pt, final := 0) {
    global DISABLEASYNCMOVE
    ;SWP_ASYNCWINDOWPOS is causing a timing issue, but without windows will move slow and sometimes holdup the script, looking for solution.
    ;0x0001:SWP_NOSIZE, 0x0004:SWP_NOZORDER, 0x0010:SWP_NOACTIVATE, 0x0400:SWP_NOSENDCHANGING, 0x4000:SWP_ASYNCWINDOWPOS
    ;@_@ added DISABLEASYNCMOVE so the user can optionally disable SWP_ASYNCWINDOWPOS
    flags := (final ? (0x0010 | 0x0004 | 0x0001) : (DISABLEASYNCMOVE ? 0x0 : 0x4000) | (0x0400 | 0x0010 | 0x0004 | 0x0001))
    DllCall("SetWindowPos", Ptr, hWnd, Ptr, 0, Int, pt.x, Int, pt.y, Int, 0, Int, 0, UInt, flags)
}

GetWinPos(hWnd, ByRef pt) {
    VarSetCapacity(lpRect, 16, 0)
    
    DllCall("GetWindowRect", Ptr, hWnd, Ptr, &lpRect)
    
    x := NumGet(lpRect, 0, "Int")
    y := NumGet(lpRect, 4, "Int")
    
    pt := new Point(x, y)
    VarSetCapacity(lpRect, 0)
}

GetClientRect(window, ByRef Width, ByRef Height) {
    VarSetCapacity(CR, 16)
    
    DllCall("GetClientRect", Ptr, window, Ptr, &CR)
    Width := NumGet(CR, 8), Height := Numget(CR, 12)
    
    VarSetCapacity(CR, 0)
}

GetTimerRes() {
    static NtQueryTimerResolution := DllCall("GetProcAddress", Ptr, DllCall("LoadLibrary", Str, "NTDLL", Ptr), AStr, "NtQueryTimerResolution", Ptr)
    VarSetCapacity(dumby , 64)
    VarSetCapacity(Cur , 64)

    DllCall(NtQueryTimerResolution, Ptr, &dumby, Int, &dumby, Ptr, &Cur)
    res := (NumGet(Cur, 0, "Int") / 10000)
    res := (res < 1 ? 1 : res)

    VarSetCapacity(Cur , 0)
    VarSetCapacity(dumby, 0)
    return res
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;generic functions
Contains(var, arr) {
    for t, v in arr
        if(v = var)
            return t
    return false
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;classes
class Point {
    __New(x,y) {
        this.x := ToInt(x)
        this.y := ToInt(y)
    }
}

class Line {
    __New(pt_start, pt_end) {
        this.start := pt_start
        this.end := pt_end
        
        c_x := (this.start.x + this.end.x) / 2
        c_y := (this.start.y + this.end.y) / 2
        this.center := new Point(c_x, c_y)
    }
    
    ;PointingTo(OtherLine) {
    ;    ;working on it
    ;}
}

ToInt(fl) {
    return (fl < 0 ? ceil(fl) : floor(fl))
}

class DockPoint {
    __New(line, offscreen, monitor) {
        this.wall := line
        this.outside := offscreen
        this.monitor := monitor
        this.name := "M: " . this.monitor . " S: " . this.outside . " X: " . this.wall.center.x . " Y: " . this.wall.center.y
        this.safename := "M" . this.monitor . "S" . this.outside
    }
    
    GetWindowToPosition(window, outside, ByRef pt) {
        global GRIPSIZE
        WinGetPos, winX, winY, winW, winH, ahk_id %window%
        
        ;first get center for window over point
        x := this.wall.center.x - (winW / 2)
        y := this.wall.center.y - (winH / 2)
        
        if(!outside) {
            if(this.outside = "right") {
                x := this.wall.center.x - GRIPSIZE
            } else if(this.outside = "left") {
                x := (this.wall.center.x - winW) + GRIPSIZE
            } else if(this.outside = "up") {
                y := (this.wall.center.y - winH) + GRIPSIZE
            } else if(this.outside = "down") {
                y := this.wall.center.y - GRIPSIZE
            }
        } else {
            if(this.outside = "right") {
                x := (this.wall.center.x - winW) + 1
            } else if(this.outside = "left") {
                x := this.wall.center.x - 1
            } else if(this.outside = "up") {
                y := this.wall.center.y - 1
            } else if(this.outside = "down") {
                y := (this.wall.center.y - winH) + 1
            }
        }
        
        pt := new Point(x, y)
    }
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
~MButton::DockWindow()

;ran on middle click
DockWindow() {
    Thread, NoTimers
    
    ;get mouse direction
    if(!GetMouseLine(line, window))
        return
    
    MoveWindow(window, MouseDirectionToDock(line))
}

GetMouseLine(ByRef line, ByRef win) {
    MouseGetPos, x, y, win
    
    ;;skip invalid windows
    if(!IsValidWindow(win))
        return
    
    ;;skip windows taking up the entire screen
    if(IsFullScreen(win))
        return
    
    ;;skip when mouse is in client area
    if(!IsInWindow(win, new Point(x, y), true))
        return
    
    ;;skip windows with minimized, maximized or child winstyles
    WinGet, wStyle, Style, ahk_id %win%
    if(wStyle & 0x1000000 or wStyle & 0x20000000 or wStyle & 0x40000000)
        return
    
    KeyWait, MButton, T3
    if(ErrorLevel)
        return false
    MouseGetPos, x2, y2

    line := new Line(new Point(x, y), new Point(x2, y2))
    return true
}

;moves the given window to a dock based on direction
MoveWindow(window, dockpoint := "") {
    global DockPoints, DISABLEMIDDLEMOUSECENTER
    
    LockWindow(window, false)
    for k, v in DockPoints {
        if(v = window)
            DockPoints[k] := ""
    }

    if(!dockpoint) {
    	if(DISABLEMIDDLEMOUSECENTER)
    		return
        MouseGetPos, mX, mY
        WinGetPos, wX, wY, wW, wH, ahk_id %window%
        mon := GetMonitorAtPoint(new Point(mX, mY))
        SysGet, m, Monitor, %mon%
        tPoint := new Point(mLeft + ((mRight - mLeft) / 2) - (wW / 2), mTop + ((mBottom - mTop) / 2) - (wH / 2))
    } else {
        if(DockPoints[dockpoint] != "") {
            MoveWindow(DockPoints[dockpoint])
        }
        DockPoints[dockpoint] := window
        dockpoint.GetWindowToPosition(window, false, tPoint)
        SetTimer, PopoutPulse, On
        LockWindow(window, true)
    }

    AnimateMovement(window, tPoint)
}

;moves a window slowly to target location based on screensize
AnimateMovement(window, pt) {
    global DOCKANIMSPEEDMOD
    
    if(!IsValidWindow(window))
        return
    
    WinGetPos, wPtx, wPty,,, ahk_id %window%
    wPt := new Point(wPtx, wPty)
    
    res := GetTimerRes()
    Mahou := (90 / res) * DOCKANIMSPEEDMOD
    
    JumpX := (pt.x - wPt.x) / Mahou
    JumpY := (pt.y - wPt.y) / Mahou
    
    Loop %Mahou% {
        wPt.x += JumpX
        wPt.y += JumpY
        SetWinPos(window, wPt)
        Sleep(res)
    }
    
    SetWinPos(window, pt, 1)
}

IsValidWindow(window) {
    if(!window)
        return false
    
    if(!WinExist("ahk_id " . window))
        return false
    
    if(window = DllCall("GetDesktopWindow"))
        return false
    
    static forbidden_windows := Array("Progman", "WorkerW", "Shell_TrayWnd", "Shell_SecondaryTrayWnd", "TaskManagerWindow")
    WinGetClass, wClass, ahk_id %window%
    For i, v in forbidden_windows
        if(v = wClass)
            return false
    
    return true
}

IsFullscreen(window) {
    ;check window validity
    if(!IsValidWindow(window))
        return
    
    ;get client and window size
    WinGetPos, X, Y, Width, Height, ahk_id %window%
    GetClientRect(window, cWidth, cHeight)
    
    ;pick monitor
    ;wCenterX := X + (Width / 2), wCenterY := Y + (Height / 2)
    SelectedMonitor := GetMonitorAtPoint(new Point(X + (Width / 2), Y + (Height / 2)))
    ; SysGet, MonCount, MonitorCount
    ; Loop %MonCount% {
    ;     SysGet, m, Monitor, %A_Index%
    ;     if(wCenterX >= mLeft and wCenterX <= mRight and wCenterY >= mTop and wCenterY <= mBottom) {
    ;         SelectedMonitor := A_Index
    ;     }
    ; }
    
    ;compare window to monitor
    SysGet, m, Monitor, %SelectedMonitor%
    MonWidth := Abs(mRight - mLeft), MonHeight := Abs(mBottom - mTop)
    if(X <= mLeft and Y <= mTop and Width >= MonWidth and Height >= MonHeight) {
        return true
    } else if(cWidth >= MonWidth and cHeight >= MonHeight) {
        return true
    } else {
        return false
    }
}

IsInWindow(window, pt, excludeclient) {
    global GRIPSIZE, TITLEGRIPSIZE
    WinGetPos, winX, winY, winW, winH, ahk_id %window% 
    
    ;exit if outside
    if( (pt.y < winY) or (pt.y > winH + winY) or (pt.x < winX) or (pt.x > winW + winX) )
        return false`
    
    if(excludeclient) {
        if((pt.y > (winY + TITLEGRIPSIZE)) and (pt.y < (winY + winH - GRIPSIZE)))
            if((pt.x > (winX + GRIPSIZE)) and (pt.x < (winX + winW - GRIPSIZE)))
                return false
    }
    
    return true
}

;determines if aWindow is the same or part of nWindow
IsSameWindow(window1, window2) {
    if(window1 != window2) {
    	;not sure why the following code was added, will keep it commented out until i know for sure
        ; WinGetTitle, title2, ahk_id %window2%
        ; if(title2 != "")
            return false
    }
    return true
    ;not sure of the point of this either.... ?_?
    ;return IsSameProcess(window1, window2)
}

IsSameProcess(window1, window2) {
    WinGet, pid1, PID, ahk_id %window1%
    WinGet, pid2, PID, ahk_id %window2%
    
    if(pid1 != pid2)
        return false
    return true
}

PopoutPulse() {
    WinGet, active, ID, A
    if(IsFullscreen(active))
        return
    
	MouseGetPos, asdfX, asdfY,
	asdfpt := new Point(asdfX, asdfY)
    
	global DockPoints
    count := 0, window := 0
	for k, v in DockPoints {
        if(IsInWindow(v, asdfpt, false)) {
            window := v
            dock := k
        }
        count += (v ? 1 : 0)
    }
    
    if(!count)
        SetTimer, PopoutPulse, Off
    
    if(window)
		HandlePopout(window, dock)
}

HandlePopout(window, dock) {
	global DOCKDELAY, DockPoints
	Sleep(DOCKDELAY)
    MouseGetPos, asdfX, asdfY,

    asdfpt := new Point(asdfX, asdfY)
    
    if(!IsInWindow(window, asdfpt, false))
        return

	WinGet, prevWindow,, A
	LockWindow(window, false)
    WinActivate, ahk_id %window%,
    dock.GetWindowToPosition(window, true, oPt)
    AnimateMovement(window, oPt)
    
    if(PopoutLoop(window, dock)) {
        dock.GetWindowToPosition(window, false, iPt)
        AnimateMovement(window, iPt)
        LockWindow(window, true)
        
        WinGet, aWindow, ID, A
        if(aWindow = prevWindow or aWindow = window) {
            WinGet, wStyle, Style, ahk_id %prevWindow%
            if(wStyle & 0x10000000)
                WinActivate, ahk_id %prevWindow%
        }
    } else {
        DockPoints[dock] := ""
    }
}

PopoutLoop(window, dock) {
    global LBLOCK, DOCKMODE, DOCKTIMEOUT
    
    Sleep(100)
    WinGetPos, sX, sY, sW, sH, ahk_id %window%
    
    Loop {
        Sleep(25)
        
        if(LBLOCK)
            KeyWait, LButton
        
        WinGetPos, cX, cY, cW, cH, ahk_id %window%
        if(cX != sX or cY != sY or cW != sW or cH != sH)
            return 0 ;window moved, so its removed from the docks
            
        if(DOCKMODE) {
            MouseGetPos, cmX, cmY, cmWin
            ; ToolTip, % "IsSameProcess(window, cmWin)=" . IsSameProcess(window, cmWin) . "`nIsSameWindow(window, cmWin)=" . IsSameWindow(window, cmWin),,,4
            if(!(IsInWindow(window, new Point(cmX, cmY), false) or IsSameWindow(window, cmWin))) {
                Sleep(DOCKTIMEOUT)
                MouseGetPos, cmX, cmY, cmWin
                if(!(IsInWindow(window, new Point(cmX, cmY), false) or IsSameWindow(window, cmWin))) {
                    return 1 ;user mouse left window
                }
            }
        }
        
        WinGet, active, ID, A
        if(!IsSameWindow(window, active))
            return 2 ;user clicked on another window
    }
}

LockWindow(window, LockWin := true) {
    global ENABLETRANSPARENCY, DockPoints, tLvl
    static locked_windows := {}
    
    if(!IsValidWindow(window))
        return
    tDock := Contains(window, DockPoints).safename
    
    if(!locked_windows[tDock]) {
        locked_windows[tDock] := {"hwnd":"", "style":"", "exstyle":"", "trans":""}
    }
    
    if(locked_windows[tDock]["hwnd"] != window) {
        locked_windows[tDock]["hwnd"] := window
        
        WinGet, ws_style, Style, ahk_id %window%
        locked_windows[tDock]["style"] := ws_style
        
        WinGet, ws_exstyle, ExStyle, ahk_id %window%
        locked_windows[tDock]["exstyle"] := ws_exstyle
        
        WinGet, trans_lvl, Transparent, ahk_id %window%
        locked_windows[tDock]["trans"] := trans_lvl
    } else {
        if(LockWin) {
            WinSet, Style, -0x20000, ahk_id %window%
            WinSet, Topmost, On, ahk_id %window%
            if(ENABLETRANSPARENCY)
                WinSet, Transparent, %tlvl%, ahk_id %window%
        } else {
            WinSet, Style, % locked_windows[tDock]["style"], ahk_id %window%
            if(!(locked_windows[tDock]["exstyle"] & 0x00000008))
                WinSet, Topmost, Off, ahk_id %window%
            if(ENABLETRANSPARENCY)
                WinSet, Transparent, % locked_windows[tDock]["trans"], ahk_id %window%
        }
    }
}


; LockWindow_old(window, LockWin := true) {
;     static
;     global ENABLETRANSPARENCY, TRANSLEVEL, DockPoints, tLvl
;     local tDock
    
;     if(!IsValidWindow(window))
;         return
    
;     ;get its docked position
;     tDock := Contains(window, DockPoints).safename
;     if(!tDock)
;         return
;     %tDock%_hwnd := 0
;     ;store original window props
;     if(%tDock%_hwnd != window) {
;         %tDock%_hwnd := window
;         WinGet, %tDock%_mb, Style, ahk_id %window%
;         WinGet, %tDock%_tm, ExStyle, ahk_id %window%
;         WinGet, %tDock%_tlvl, Transparent, ahk_id %window%
;         %tDock%_tlvl := (%tDock%_tlvl = "" ? 255 : %tDock%_tlvl)
;         %tDock%_mb := (%tDock%_mb & 0x20000) ? true : false
;         %tDock%_tm := (%tDock%_tm & 0x00000008) ? true : false
;     }
    
;     ;set new window props
;     if(!%tDock%_tm)
;         WinSet, Topmost, % (LockWin ? "On" : "Off"), ahk_id %window%
;     if(%tDock%_mb)
;         WinSet, Style, % (LockWin ? "-0x20000" : "+0x20000"), ahk_id %window%
;     if(ENABLETRANSPARENCY)
;         WinSet, Transparent, % (LockWin ? tLvl : %tDock%_tlvl), ahk_id %window%
; }

;;;;;;;;;;;;;;
;;new multi monitor code
;;;;;;;;;;;;;;

GetMonitorAtPoint(pt) {
    SysGet, MonCount, MonitorCount
    Loop %MonCount% {
        SysGet, m, Monitor, %A_Index%
        ;ToolTip, % "Pos: " . x . ":" . y . "`nMonitor: " . A_Index . "`nLeft=" . mLeft . " Top=" . mTop . "`nBottom=" . mBottom . " Right=" . mRight . "`n", mLeft, mTop, (A_Index+1)
        if(pt.x > mLeft and pt.x < mRight and pt.y > mTop and pt.y < mBottom) {
            return A_Index
        }
    }
    return 0
}

MouseDirectionToDock(line) {
    global DockPoints
    
    ;for k, v in DockPoints {
    ;    if(line.PointingTo(k.wall)) {
    ;        return k
    ;    }
    ;}
    
    XDist := Abs(line.start.x - line.end.x)
    YDist := Abs(line.start.y - line.end.y)
    
    mon := GetMonitorAtPoint(line.end)
    SysGet, m, Monitor, %mon%
    if(XDist < ((mRight - mLeft) * 0.01) and YDist < ((mBottom - mTop) * 0.005))
        return
    
    if(xDist > YDist) { ;left or right
        if(line.start.x > line.end.x)
            dir := "left"
        else
            dir := "right"
    } else {
        if(line.start.y > line.end.y)
            dir := "up"
        else
            dir := "down"
    }

    ;get screen now check for dock
    for k, v in DockPoints {
        if(k.monitor = mon and k.outside = dir) {
            return k
        }
    }
}

;generate dockable points
GenerateDockPoints() {
    global DockPoints := {}

    SysGet, MONITOR_COUNT, MonitorCount
    
    WinGet, tray_window, ID, ahk_class Shell_TrayWnd
    WinGet, tray_window2, ID, ahk_class Shell_SecondaryTrayWnd

    Loop %MONITOR_COUNT% {
        SysGet, m, Monitor, %A_Index%
        for i, dp in PointsFromScreen(mTop, mLeft, mRight, mBottom, A_Index) {
            if(!(IsInWindow(tray_window, dp.wall.center, false) or IsInWindow(tray_window2, dp.wall.center, false))) {
                DockPoints.Insert(dp, "")
            }
        }
    }
}

PointsFromScreen(t, l, r, b, mon) {
    Points := Array()
    
    xthird := Round((l + r) / 3)
    ythird := Round((t + b) / 3)
    offset := 10
    
    if(!GetMonitorAtPoint(new Point(xthird, t - offset)) or !GetMonitorAtPoint(new Point(xthird*2, t - offset))) {
        wall := new Line(new Point(l, t), new Point(r, t))
        Points.Insert(new DockPoint(wall, "up", mon))
    }
    
    if(!GetMonitorAtPoint(new Point(xthird, b + offset)) or !GetMonitorAtPoint(new Point(xthird*2, b + offset))) {
        wall := new Line(new Point(l, b), new Point(r, b))
        Points.Insert(new DockPoint(wall, "down", mon))
    }
        ;Points.Insert(new DockPoint((l + r) / 2, b, "down", mon))
    
    if(!GetMonitorAtPoint(new Point(l - offset, ythird)) or !GetMonitorAtPoint(new Point(l - offset, ythird*2))) {
        wall := new Line(new Point(l, t), new Point(l, b))
        Points.Insert(new DockPoint(wall, "left", mon))
    }
        ;Points.Insert(new DockPoint(l, (t + b) / 2, "left", mon))
    
    if(!GetMonitorAtPoint(new Point(r + offset, ythird)) or !GetMonitorAtPoint(new Point(r + offset, ythird*2))) {
        wall := new Line(new Point(r, t), new Point(r, b))
        Points.Insert(new DockPoint(wall, "right", mon))
    }
        ;Points.Insert(new DockPoint(r, (t + b) / 2, "right", mon))
    
    return Points
}

#include startupshortcut.ahk