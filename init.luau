--!strict
local ffi = require("@lune/ffi")
local process = require("@lune/process")
local task = require("@lune/task")

type KeyCode = number | string
type InputModule = {
    Key: {[string]: KeyCode},
    down: (key: KeyCode) -> (),
    up: (key: KeyCode) -> (),
    press: (key: KeyCode) -> (),
    wait: (ms: number) -> ()
}

local os_str = process.os
local Input: InputModule = { Key = {} } :: InputModule

if os_str == "windows" then
    Input.Key = {
        LWIN = 0x5B, CONTROL = 0x11, SHIFT = 0x10, ALT = 0x12,
        ENTER = 0x0D, ESC = 0x1B, SPACE = 0x20, TAB = 0x09,
        V = 0x56, C = 0x43, T = 0x54,
        F1 = 0x70, LEFT = 0x25, UP = 0x26, RIGHT = 0x27, DOWN = 0x28
    }
else
    Input.Key = {
        LWIN = "Super", CONTROL = "ctrl", SHIFT = "shift", ALT = "alt",
        ENTER = "Return", ESC = "Escape", SPACE = "space", TAB = "Tab",
        V = "v", C = "c", T = "t",
        F1 = "F1", LEFT = "Left", UP = "Up", RIGHT = "Right", DOWN = "Down"
    }
end

if os_str == "windows" then
    local user32 = ffi.open("user32.dll")
    local kernel32 = ffi.open("kernel32.dll")
    local KEYEVENTF_KEYUP = 0x0002

    function Input.wait(ms: number)
        kernel32:call("Sleep", "void", {"u32"}, ms)
    end

    function Input.down(key: KeyCode)
        user32:call("keybd_event", "void", {"i32", "i32", "i32", "u64"}, key, 0, 0, 0)
    end

    function Input.up(key: KeyCode)
        user32:call("keybd_event", "void", {"i32", "i32", "i32", "u64"}, key, 0, KEYEVENTF_KEYUP, 0)
    end

elseif os_str == "linux" then
    function Input.wait(ms: number)
        task.wait(ms / 1000)
    end

    function Input.down(key: KeyCode)
        process.spawn("xdotool", {"keydown", tostring(key)})
    end

    function Input.up(key: KeyCode)
        process.spawn("xdotool", {"keyup", tostring(key)})
    end

elseif os_str == "macos" then
    function Input.wait(ms: number)
        task.wait(ms / 1000)
    end

    function Input.down(key: KeyCode) end 
    function Input.up(key: KeyCode) end
    
    function Input.press(key: KeyCode)
        local script = string.format('tell application "System Events" to keystroke "%s"', tostring(key))
        if key == "Return" then script = 'tell application "System Events" to key code 36' end
        process.spawn("osascript", {"-e", script})
    end
end

if os_str ~= "macos" then
    function Input.press(key: KeyCode)
        Input.down(key)
        if os_str == "windows" then Input.wait(10) else task.wait(0.01) end
        Input.up(key)
    end
end

return Input
