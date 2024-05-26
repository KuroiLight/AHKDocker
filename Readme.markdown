# AHKDocker
##### A window docker for Windows, written in AutoHotkey.
###### Last tested working with Autohotkey Unicode 1.1.22.07

#### Features
* Slide windows off-screen (top, left and right sides)

#### Installation
> Download the pre-compiled binary, or download the .ahk file and install AutoHotkey_L from the official site and run the script. All available settings can be changed from the INI that is created during the first run. An explanation of the INI settings is further below. AutoHotkey_L can be found here https://github.com/Lexikos/AutoHotkey_L or http://ahkscript.org/

#### Usage

* ##### Window Docking
> To slide a window into position, middle mouse down on the title-bar or side grips of a window and quickly drag in the direction you want to dock on the screen and release; to view the window again simply mouse over its edge sticking out, then move the mouse out to let it hide again.

#### INI Settings
iDockHideMode (default 1) (possible values 0, 1)
> when 0 a docked window will only hide itself when another window is activated, when 1 the window will hide itself when the mouse leaves it.

iPopoutTimeout (default 150) (possible values 0-5000)
> value is in mili-seconds, time until the window actually hides, allowing the mouse to fall out of the window for a limited amount of time.

iPopoutDelay (default 100) (possible values 0-5000)
> value is in mili-seconds, time until window pop-outs out when mouse is over it.

fAnimSpeedMod (default 1.0) (possible values 0.0-2.0)
> modifies how fast the window slides; number is a float value from 0.0 to 2.0; 0.0 being instant, 1.0 being default, 2.0 being twice as slow.

iBorderGripOverride (default 4) (possible values 2-50)
> value is in pixels, size of the grip/window border that will show on screen when window is docked.

iMouse1PopoutLock (default 1) (possible values 0, 1)
> when 1, window will not hide while left mouse button is dragging from within to outside of a popout window; when 0 left button down will be ignored.

iEnableTransparency (default 0) (possible values 0, 1)
> Set to 1 to enable transparency, 0 for off.

iTransparency (default 90) (possible values 10-100)
> Transparency level of a docked window, 100 being solid. Warning setting this too low may make a window invisible and un-clickable.

iDelayWindowCommands (default 2) (possible values -1-500)
> controls the sleep delay after each windowing command, values above 0 are in mili-seconds, 0 yields instead of sleeps and -1 is instant but should not be used. This setting is only in to help on slower computers where turning it up may help. for more information on this setting check here http://www.autohotkey.com/docs/commands/SetWinDelay.htm

iDisableAsyncWinMove (default 0) (possible values 0-1)
> added as a workaround; when 1, excludes SWP_ASYNCWINDOWPOS(0x4000) in calls to SetWindowPos, may cause some windows to dock slower if they draw alot but it removes the position timing issues.