--!strict
local ffi = require("@lune/ffi")
local process = require("@lune/process")
local task = require("@lune/task")

type KeyCode = number | string
type InputModule = {
    Key: {[string]: KeyCode},
    down: (key: KeyCode) -> (),
    up: (key: KeyCode) -> (),
    tap: (key: KeyCode) -> (),
    wait: (ms: number) -> ()
}

local Input: InputModule = { Key = {} } :: InputModule

if process.os == "windows" then
    Input.Key = {
        BACKSPACE = 0x08, TAB = 0x09, CLEAR = 0x0C, ENTER = 0x0D,
        SHIFT = 0x10, CONTROL = 0x11, ALT = 0x12, PAUSE = 0x13, CAPSLOCK = 0x14,
        ESC = 0x1B, SPACE = 0x20, PAGEUP = 0x21, PAGEDOWN = 0x22,
        END = 0x23, HOME = 0x24, LEFT = 0x25, UP = 0x26, RIGHT = 0x27, DOWN = 0x28,
        PRINTSCREEN = 0x2C, INSERT = 0x2D, DELETE = 0x2E,
        N0 = 0x30, N1 = 0x31, N2 = 0x32, N3 = 0x33, N4 = 0x34,
        N5 = 0x35, N6 = 0x36, N7 = 0x37, N8 = 0x38, N9 = 0x39,
        A = 0x41, B = 0x42, C = 0x43, D = 0x44, E = 0x45, F = 0x46, G = 0x47,
        H = 0x48, I = 0x49, J = 0x4A, K = 0x4B, L = 0x4C, M = 0x4D, N = 0x4E,
        O = 0x4F, P = 0x50, Q = 0x51, R = 0x52, S = 0x53, T = 0x54, U = 0x55,
        V = 0x56, W = 0x57, X = 0x58, Y = 0x59, Z = 0x5A,
        LWIN = 0x5B, RWIN = 0x5C, APPS = 0x5D,
        NUMPAD0 = 0x60, NUMPAD1 = 0x61, NUMPAD2 = 0x62, NUMPAD3 = 0x63, NUMPAD4 = 0x64,
        NUMPAD5 = 0x65, NUMPAD6 = 0x66, NUMPAD7 = 0x67, NUMPAD8 = 0x68, NUMPAD9 = 0x69,
        MULTIPLY = 0x6A, ADD = 0x6B, SEPARATOR = 0x6C, SUBTRACT = 0x6D, DECIMAL = 0x6E, DIVIDE = 0x6F,
        F1 = 0x70, F2 = 0x71, F3 = 0x72, F4 = 0x73, F5 = 0x74, F6 = 0x75,
        F7 = 0x76, F8 = 0x77, F9 = 0x78, F10 = 0x79, F11 = 0x7A, F12 = 0x7B,
        NUMLOCK = 0x90, SCROLLLOCK = 0x91,
        LSHIFT = 0xA0, RSHIFT = 0xA1, LCONTROL = 0xA2, RCONTROL = 0xA3, LALT = 0xA4, RALT = 0xA5,
        SEMICOLON = 0xBA, PLUS = 0xBB, COMMA = 0xBC, MINUS = 0xBD, PERIOD = 0xBE, SLASH = 0xBF,
        GRAVE = 0xC0, BRACKETLEFT = 0xDB, BACKSLASH = 0xDC, BRACKETRIGHT = 0xDD, QUOTE = 0xDE
    }

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

    function Input.tap(key: KeyCode)
        Input.down(key)
        Input.wait(10)
        Input.up(key)
    end

elseif process.os == "linux" then
    Input.Key = {
        BACKSPACE = "BackSpace", TAB = "Tab", ENTER = "Return", ESC = "Escape", SPACE = "space",
        SHIFT = "Shift_L", CONTROL = "Control_L", ALT = "Alt_L", CAPSLOCK = "Caps_Lock",
        PAGEUP = "Page_Up", PAGEDOWN = "Page_Down", END = "End", HOME = "Home",
        LEFT = "Left", UP = "Up", RIGHT = "Right", DOWN = "Down",
        PRINTSCREEN = "Print", INSERT = "Insert", DELETE = "Delete",
        N0 = "0", N1 = "1", N2 = "2", N3 = "3", N4 = "4",
        N5 = "5", N6 = "6", N7 = "7", N8 = "8", N9 = "9",
        A = "a", B = "b", C = "c", D = "d", E = "e", F = "f", G = "g",
        H = "h", I = "i", J = "j", K = "k", L = "l", M = "m", N = "n",
        O = "o", P = "p", Q = "q", R = "r", S = "s", T = "t", U = "u",
        V = "v", W = "w", X = "x", Y = "y", Z = "z",
        LWIN = "Super_L", RWIN = "Super_R",
        F1 = "F1", F2 = "F2", F3 = "F3", F4 = "F4", F5 = "F5", F6 = "F6",
        F7 = "F7", F8 = "F8", F9 = "F9", F10 = "F10", F11 = "F11", F12 = "F12",
        SEMICOLON = "semicolon", PLUS = "plus", COMMA = "comma", MINUS = "minus",
        PERIOD = "period", SLASH = "slash", GRAVE = "grave",
        BRACKETLEFT = "bracketleft", BACKSLASH = "backslash", BRACKETRIGHT = "bracketright", QUOTE = "apostrophe"
    }

    function Input.wait(ms: number)
        task.wait(ms / 1000)
    end

    function Input.down(key: KeyCode)
        process.exec("xdotool", {"keydown", tostring(key)})
    end

    function Input.up(key: KeyCode)
        process.exec("xdotool", {"keyup", tostring(key)})
    end

    function Input.tap(key: KeyCode)
        process.exec("xdotool", {"key", tostring(key)})
    end

elseif process.os == "macos" then
    Input.Key = {
        ENTER = 36, TAB = 48, SPACE = 49, DELETE = 51, ESC = 53,
        LWIN = 55, SHIFT = 56, CAPSLOCK = 57, ALT = 58, CONTROL = 59,
        LEFT = 123, RIGHT = 124, DOWN = 125, UP = 126,
        F1 = 122, F2 = 120, F3 = 99, F4 = 118, F5 = 96, F6 = 97,
        F7 = 98, F8 = 100, F9 = 101, F10 = 109, F11 = 103, F12 = 111,
        N0 = "0", N1 = "1", N2 = "2", N3 = "3", N4 = "4",
        N5 = "5", N6 = "6", N7 = "7", N8 = "8", N9 = "9",
        A = "a", B = "b", C = "c", D = "d", E = "e", F = "f", G = "g",
        H = "h", I = "i", J = "j", K = "k", L = "l", M = "m", N = "n",
        O = "o", P = "p", Q = "q", R = "r", S = "s", T = "t", U = "u",
        V = "v", W = "w", X = "x", Y = "y", Z = "z",
        SEMICOLON = ";", PLUS = "+", COMMA = ",", MINUS = "-", PERIOD = ".", SLASH = "/",
        GRAVE = "`", BRACKETLEFT = "[", BACKSLASH = "\\", BRACKETRIGHT = "]", QUOTE = "'"
    }

    function Input.wait(ms: number)
        task.wait(ms / 1000)
    end

    function Input.down(key: KeyCode) end 
    function Input.up(key: KeyCode) end

    function Input.tap(key: KeyCode)
        local script
        if type(key) == "number" then
            script = string.format('tell application "System Events" to key code %d', key)
        else
            script = string.format('tell application "System Events" to keystroke "%s"', tostring(key))
        end
        process.exec("osascript", {"-e", script})
    end
end

return Input
