--!strict
--[[
	lune-input v3.0
	Cross-platform input module
]]

local ffi = require("@lune/ffi")
local process = require("@lune/process")
local task = require("@lune/task")

-- ═══════════════════════════════════════════════════════════════
-- TIPOS
-- ═══════════════════════════════════════════════════════════════

export type KeyCode = number | string
export type MouseButton = "left" | "right" | "middle"
export type Point = { x: number, y: number }
export type EasingFn = (t: number) -> number

export type MoveOptions = {
	duration: number?,
	easing: EasingFn?,
	onComplete: (() -> ())?,
	onError: ((err: string) -> ())?,
}

export type Hotkey = {
	keys: { KeyCode },
	codes: { number },
	enabled: boolean,
	Fire: (self: Hotkey) -> (),
	Enable: (self: Hotkey) -> (),
	Disable: (self: Hotkey) -> (),
	IsEnabled: (self: Hotkey) -> boolean,
}

export type InputModule = {
	Key: { [string]: number | string },
	wait: (ms: number) -> (),
	down: (key: KeyCode) -> (),
	up: (key: KeyCode) -> (),
	tap: (key: KeyCode) -> (),
	press: (key: KeyCode) -> (),
	write: (text: string, delayMs: number?) -> (),
	typeText: (text: string, delayMs: number?) -> (),
	combo: (...KeyCode) -> (),
	hotkey: (...KeyCode) -> Hotkey,
	isKeyDown: (key: KeyCode) -> boolean,
	mousePosition: () -> Point,
	mouseMove: (x: number, y: number, opts: MoveOptions?) -> (),
	mouseDown: (button: MouseButton?) -> (),
	mouseUp: (button: MouseButton?) -> (),
	mouseClick: (button: MouseButton?) -> (),
	mouseDoubleClick: (button: MouseButton?) -> (),
	mouseScroll: (delta: number) -> (),
	mouseDrag: (tx: number, ty: number, button: MouseButton?, duration: number?) -> (),
	onEscapeHold: (secs: number, callback: () -> ()) -> (),
	stop: () -> (),
	isRunning: () -> boolean,
	registerHotkey: (name: string, keys: { KeyCode }, callback: () -> ()) -> (),
	unregisterHotkey: (name: string) -> (),
}

-- ═══════════════════════════════════════════════════════════════
-- CONSTANTES
-- ═══════════════════════════════════════════════════════════════

local KEYUP: number = 0x0002
local UNICODE: number = 0x0004

local MOUSE_LDOWN: number = 0x0002
local MOUSE_LUP: number = 0x0004
local MOUSE_RDOWN: number = 0x0008
local MOUSE_RUP: number = 0x0010
local MOUSE_MDOWN: number = 0x0020
local MOUSE_MUP: number = 0x0040
local MOUSE_WHEEL: number = 0x0800
local MOUSE_MOVE: number = 0x0001
local MOUSE_ABS: number = 0x8000

local VK_MAP: { [string]: number } = {
	backspace = 0x08,
	tab = 0x09,
	enter = 0x0D,
	shift = 0x10,
	control = 0x11,
	ctrl = 0x11,
	alt = 0x12,
	pause = 0x13,
	capslock = 0x14,
	escape = 0x1B,
	esc = 0x1B,
	space = 0x20,
	[" "] = 0x20,
	pageup = 0x21,
	pagedown = 0x22,
	["end"] = 0x23,
	home = 0x24,
	left = 0x25,
	up = 0x26,
	right = 0x27,
	down = 0x28,
	printscreen = 0x2C,
	insert = 0x2D,
	delete = 0x2E,
	del = 0x2E,
	["0"] = 0x30,
	["1"] = 0x31,
	["2"] = 0x32,
	["3"] = 0x33,
	["4"] = 0x34,
	["5"] = 0x35,
	["6"] = 0x36,
	["7"] = 0x37,
	["8"] = 0x38,
	["9"] = 0x39,
	a = 0x41,
	b = 0x42,
	c = 0x43,
	d = 0x44,
	e = 0x45,
	f = 0x46,
	g = 0x47,
	h = 0x48,
	i = 0x49,
	j = 0x4A,
	k = 0x4B,
	l = 0x4C,
	m = 0x4D,
	n = 0x4E,
	o = 0x4F,
	p = 0x50,
	q = 0x51,
	r = 0x52,
	s = 0x53,
	t = 0x54,
	u = 0x55,
	v = 0x56,
	w = 0x57,
	x = 0x58,
	y = 0x59,
	z = 0x5A,
	lwin = 0x5B,
	rwin = 0x5C,
	win = 0x5B,
	f1 = 0x70,
	f2 = 0x71,
	f3 = 0x72,
	f4 = 0x73,
	f5 = 0x74,
	f6 = 0x75,
	f7 = 0x76,
	f8 = 0x77,
	f9 = 0x78,
	f10 = 0x79,
	f11 = 0x7A,
	f12 = 0x7B,
	numlock = 0x90,
	scrolllock = 0x91,
	lshift = 0xA0,
	rshift = 0xA1,
	lcontrol = 0xA2,
	rcontrol = 0xA3,
	lalt = 0xA4,
	ralt = 0xA5,
	semicolon = 0xBA,
	[";"] = 0xBA,
	plus = 0xBB,
	["="] = 0xBB,
	comma = 0xBC,
	[","] = 0xBC,
	minus = 0xBD,
	["-"] = 0xBD,
	period = 0xBE,
	["."] = 0xBE,
	slash = 0xBF,
	["/"] = 0xBF,
	grave = 0xC0,
	["`"] = 0xC0,
	bracketleft = 0xDB,
	["["] = 0xDB,
	backslash = 0xDC,
	["\\"] = 0xDC,
	bracketright = 0xDD,
	["]"] = 0xDD,
	quote = 0xDE,
	["'"] = 0xDE,
}

local WINDOWS_KEYS: { [string]: number | string } = {
	BACKSPACE = 0x08,
	TAB = 0x09,
	ENTER = 0x0D,
	SHIFT = 0x10,
	CONTROL = 0x11,
	ALT = 0x12,
	ESC = 0x1B,
	SPACE = 0x20,
	LEFT = 0x25,
	UP = 0x26,
	RIGHT = 0x27,
	DOWN = 0x28,
	DELETE = 0x2E,
	A = 0x41,
	B = 0x42,
	C = 0x43,
	D = 0x44,
	E = 0x45,
	F = 0x46,
	G = 0x47,
	H = 0x48,
	I = 0x49,
	J = 0x4A,
	K = 0x4B,
	L = 0x4C,
	M = 0x4D,
	N = 0x4E,
	O = 0x4F,
	P = 0x50,
	Q = 0x51,
	R = 0x52,
	S = 0x53,
	T = 0x54,
	U = 0x55,
	V = 0x56,
	W = 0x57,
	X = 0x58,
	Y = 0x59,
	Z = 0x5A,
	F1 = 0x70,
	F2 = 0x71,
	F3 = 0x72,
	F4 = 0x73,
	F5 = 0x74,
	F6 = 0x75,
	F7 = 0x76,
	F8 = 0x77,
	F9 = 0x78,
	F10 = 0x79,
	F11 = 0x7A,
	F12 = 0x7B,
}

local LINUX_KEYS: { [string]: number | string } = {
	BACKSPACE = "BackSpace",
	TAB = "Tab",
	ENTER = "Return",
	SHIFT = "Shift_L",
	CONTROL = "Control_L",
	ALT = "Alt_L",
	ESC = "Escape",
	SPACE = "space",
	LEFT = "Left",
	UP = "Up",
	RIGHT = "Right",
	DOWN = "Down",
	DELETE = "Delete",
	A = "a",
	B = "b",
	C = "c",
	D = "d",
	E = "e",
	F = "f",
	G = "g",
	H = "h",
	I = "i",
	J = "j",
	K = "k",
	L = "l",
	M = "m",
	N = "n",
	O = "o",
	P = "p",
	Q = "q",
	R = "r",
	S = "s",
	T = "t",
	U = "u",
	V = "v",
	W = "w",
	X = "x",
	Y = "y",
	Z = "z",
	F1 = "F1",
	F2 = "F2",
	F3 = "F3",
	F4 = "F4",
	F5 = "F5",
	F6 = "F6",
	F7 = "F7",
	F8 = "F8",
	F9 = "F9",
	F10 = "F10",
	F11 = "F11",
	F12 = "F12",
}

-- ═══════════════════════════════════════════════════════════════
-- ESTADO GLOBAL
-- ═══════════════════════════════════════════════════════════════

local _running: boolean = true
local _escThread: thread? = nil
local _pointBuffer: any = nil
local _user32: any = nil
local _kernel32: any = nil
local _screenW: number = 0
local _screenH: number = 0

-- ═══════════════════════════════════════════════════════════════
-- UTILITÁRIOS
-- ═══════════════════════════════════════════════════════════════

local function resolveKey(key: KeyCode): number
	if type(key) == "number" then
		return key
	end
	local str = key :: string
	local vk = VK_MAP[string.lower(str)]
	if vk then
		return vk
	end
	if #str == 1 then
		return string.byte(string.upper(str)) or 0
	end
	return 0
end

local function utf8ToCodepoints(str: string): { number }
	local codepoints: { number } = {}
	local i, len = 1, #str
	while i <= len do
		local b1 = string.byte(str, i) :: number
		local cp: number
		local size: number
		if b1 < 0x80 then
			cp, size = b1, 1
		elseif b1 < 0xE0 then
			local b2 = string.byte(str, i + 1) or 0
			cp = bit32.bor(bit32.lshift(bit32.band(b1, 0x1F), 6), bit32.band(b2, 0x3F))
			size = 2
		elseif b1 < 0xF0 then
			local b2 = string.byte(str, i + 1) or 0
			local b3 = string.byte(str, i + 2) or 0
			cp = bit32.bor(
				bit32.lshift(bit32.band(b1, 0x0F), 12),
				bit32.lshift(bit32.band(b2, 0x3F), 6),
				bit32.band(b3, 0x3F)
			)
			size = 3
		else
			local b2 = string.byte(str, i + 1) or 0
			local b3 = string.byte(str, i + 2) or 0
			local b4 = string.byte(str, i + 3) or 0
			cp = bit32.bor(
				bit32.lshift(bit32.band(b1, 0x07), 18),
				bit32.lshift(bit32.band(b2, 0x3F), 12),
				bit32.lshift(bit32.band(b3, 0x3F), 6),
				bit32.band(b4, 0x3F)
			)
			size = 4
		end
		table.insert(codepoints, cp)
		i += size
	end
	return codepoints
end

local function linearEasing(t: number): number
	return t
end

local function getMouseFlag(button: MouseButton?, down: boolean): number
	local b: MouseButton = button or "left"
	if b == "left" then
		return if down then MOUSE_LDOWN else MOUSE_LUP
	elseif b == "right" then
		return if down then MOUSE_RDOWN else MOUSE_RUP
	end
	return if down then MOUSE_MDOWN else MOUSE_MUP
end

-- ═══════════════════════════════════════════════════════════════
-- WINDOWS
-- ═══════════════════════════════════════════════════════════════

local function createWindowsInput(): InputModule
	if not _user32 then
		_user32 = ffi.open("user32.dll")
	end
	if not _kernel32 then
		_kernel32 = ffi.open("kernel32.dll")
	end
	local u32: any = _user32
	local k32: any = _kernel32

	if _screenW == 0 then
		_screenW = u32:call("GetSystemMetrics", "i32", { "i32" }, 0)
		_screenH = u32:call("GetSystemMetrics", "i32", { "i32" }, 1)
	end

	local function wait(ms: number)
		k32:call("Sleep", "void", { "u32" }, ms)
	end

	local function keyDown(key: KeyCode)
		local vk = resolveKey(key)
		if vk > 0 then
			u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, vk, 0, 0, 0)
		end
	end

	local function keyUp(key: KeyCode)
		local vk = resolveKey(key)
		if vk > 0 then
			u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, vk, 0, KEYUP, 0)
		end
	end

	local function tap(key: KeyCode)
		keyDown(key)
		wait(10)
		keyUp(key)
	end

	local function writeText(text: string, delayMs: number?)
		local delay = delayMs or 5
		for _, cp in utf8ToCodepoints(text) do
			u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, 0, cp, UNICODE, 0)
			wait(delay)
			u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, 0, cp, UNICODE + KEYUP, 0)
			wait(delay)
		end
	end

	local function combo(...: KeyCode)
		local keys = { ... }
		for _, key in keys do
			keyDown(key)
			wait(10)
		end
		for i = #keys, 1, -1 do
			keyUp(keys[i])
			wait(10)
		end
	end

	local function isKeyDown(key: KeyCode): boolean
		local vk = resolveKey(key)
		if vk <= 0 then
			return false
		end
		local state: number = u32:call("GetAsyncKeyState", "i32", { "i32" }, vk)
		return bit32.band(state, 0x8000) ~= 0
	end

	local function mousePosition(): Point
		if not _pointBuffer then
			_pointBuffer = ffi.buffer(8)
		end
		u32:call("GetCursorPos", "i32", { "pointer" }, _pointBuffer.ptr)
		return { x = _pointBuffer:read(0, "i32"), y = _pointBuffer:read(4, "i32") }
	end

	local function mouseMove(x: number, y: number, opts: MoveOptions?)
		local duration: number = 0
		local onComplete: (() -> ())? = nil
		local onError: ((string) -> ())? = nil
		local easing: EasingFn = linearEasing

		if opts then
			duration = opts.duration or 0
			onComplete = opts.onComplete
			onError = opts.onError
			if opts.easing then
				easing = opts.easing
			end
		end

		if duration <= 0 then
			local ax = math.floor((x * 65535) / _screenW)
			local ay = math.floor((y * 65535) / _screenH)
			u32:call("mouse_event", "void", { "u32", "u32", "u32", "u32", "u64" }, MOUSE_MOVE + MOUSE_ABS, ax, ay, 0, 0)
			if onComplete then
				onComplete()
			end
			return
		end

		task.spawn(function()
			local ok, err = pcall(function()
				local start = mousePosition()
				local steps = math.max(10, math.floor(duration / 10))
				for i = 1, steps do
					if not _running then
						break
					end
					local t = easing(i / steps)
					local cx = start.x + (x - start.x) * t
					local cy = start.y + (y - start.y) * t
					local ax = math.floor((cx * 65535) / _screenW)
					local ay = math.floor((cy * 65535) / _screenH)
					u32:call(
						"mouse_event",
						"void",
						{ "u32", "u32", "u32", "u32", "u64" },
						MOUSE_MOVE + MOUSE_ABS,
						ax,
						ay,
						0,
						0
					)
					wait(math.floor(duration / steps))
				end
			end)
			if ok and onComplete then
				onComplete()
			elseif not ok and onError then
				onError(tostring(err))
			end
		end)
	end

	local function mouseDown(button: MouseButton?)
		u32:call("mouse_event", "void", { "u32", "u32", "u32", "u32", "u64" }, getMouseFlag(button, true), 0, 0, 0, 0)
	end

	local function mouseUp(button: MouseButton?)
		u32:call("mouse_event", "void", { "u32", "u32", "u32", "u32", "u64" }, getMouseFlag(button, false), 0, 0, 0, 0)
	end

	local function mouseClick(button: MouseButton?)
		mouseDown(button)
		wait(10)
		mouseUp(button)
	end

	local function mouseDoubleClick(button: MouseButton?)
		mouseClick(button)
		wait(50)
		mouseClick(button)
	end

	local function mouseScroll(delta: number)
		u32:call("mouse_event", "void", { "u32", "u32", "u32", "i32", "u64" }, MOUSE_WHEEL, 0, 0, delta * 120, 0)
	end

	local function mouseDrag(tx: number, ty: number, button: MouseButton?, duration: number?)
		local dur = duration or 200
		mouseDown(button)
		mouseMove(tx, ty, { duration = dur })
		task.wait(dur / 1000 + 0.1)
		mouseUp(button)
	end

	local function hotkey(...: KeyCode): Hotkey
		local keys = { ... }
		local codes: { number } = {}
		for _, k in keys do
			table.insert(codes, resolveKey(k))
		end
		return {
			keys = keys,
			codes = codes,
			enabled = true,
			Fire = function(self: Hotkey)
				if not self.enabled then
					return
				end
				for _, vk in self.codes do
					u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, vk, 0, 0, 0)
				end
				wait(10)
				for i = #self.codes, 1, -1 do
					u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, self.codes[i], 0, KEYUP, 0)
				end
			end,
			Enable = function(self: Hotkey)
				self.enabled = true
			end,
			Disable = function(self: Hotkey)
				self.enabled = false
			end,
			IsEnabled = function(self: Hotkey): boolean
				return self.enabled
			end,
		}
	end

	local function onEscapeHold(secs: number, callback: () -> ())
		if _escThread then
			task.cancel(_escThread)
		end
		_escThread = task.spawn(function()
			local holdStart: number? = nil
			local thresholdMs = secs * 1000
			while _running do
				if isKeyDown(0x1B) then
					if not holdStart then
						holdStart = os.clock() * 1000
					elseif (os.clock() * 1000 - (holdStart :: number)) >= thresholdMs then
						_running = false
						callback()
						break
					end
				else
					holdStart = nil
				end
				task.wait(0.05)
			end
		end)
	end

	return {
		Key = WINDOWS_KEYS,
		wait = wait,
		down = keyDown,
		up = keyUp,
		tap = tap,
		press = tap,
		write = writeText,
		typeText = writeText,
		combo = combo,
		hotkey = hotkey,
		isKeyDown = isKeyDown,
		mousePosition = mousePosition,
		mouseMove = mouseMove,
		mouseDown = mouseDown,
		mouseUp = mouseUp,
		mouseClick = mouseClick,
		mouseDoubleClick = mouseDoubleClick,
		mouseScroll = mouseScroll,
		mouseDrag = mouseDrag,
		onEscapeHold = onEscapeHold,
		stop = function()
			_running = false
		end,
		isRunning = function(): boolean
			return _running
		end,
		registerHotkey = function(_name: string, _keys: { KeyCode }, _cb: () -> ()) end,
		unregisterHotkey = function(_name: string) end,
	}
end

-- ═══════════════════════════════════════════════════════════════
-- LINUX
-- ═══════════════════════════════════════════════════════════════

local function createLinuxInput(): InputModule
	local function wait(ms: number)
		task.wait(ms / 1000)
	end

	local function keyDown(key: KeyCode)
		process.exec("xdotool", { "keydown", tostring(key) })
	end

	local function keyUp(key: KeyCode)
		process.exec("xdotool", { "keyup", tostring(key) })
	end

	local function tap(key: KeyCode)
		process.exec("xdotool", { "key", tostring(key) })
	end

	local function writeText(text: string, _delayMs: number?)
		process.exec("xdotool", { "type", "--clearmodifiers", text })
	end

	local function combo(...: KeyCode)
		local keys = { ... }
		for _, key in keys do
			keyDown(key)
		end
		for i = #keys, 1, -1 do
			keyUp(keys[i])
		end
	end

	local function mousePosition(): Point
		local r = process.exec("xdotool", { "getmouselocation" })
		if r.ok then
			return {
				x = tonumber(r.stdout:match("x:(%d+)")) or 0,
				y = tonumber(r.stdout:match("y:(%d+)")) or 0,
			}
		end
		return { x = 0, y = 0 }
	end

	local function getButton(b: MouseButton?): string
		local btn: MouseButton = b or "left"
		if btn == "left" then
			return "1"
		elseif btn == "right" then
			return "3"
		end
		return "2"
	end

	local function mouseMove(x: number, y: number, opts: MoveOptions?)
		process.exec("xdotool", { "mousemove", tostring(x), tostring(y) })
		if opts and opts.onComplete then
			opts.onComplete()
		end
	end

	local function mouseDown(button: MouseButton?)
		process.exec("xdotool", { "mousedown", getButton(button) })
	end

	local function mouseUp(button: MouseButton?)
		process.exec("xdotool", { "mouseup", getButton(button) })
	end

	local function mouseClick(button: MouseButton?)
		process.exec("xdotool", { "click", getButton(button) })
	end

	local function mouseDoubleClick(button: MouseButton?)
		process.exec("xdotool", { "click", "--repeat", "2", getButton(button) })
	end

	local function mouseScroll(delta: number)
		local btn = if delta > 0 then "4" else "5"
		for _ = 1, math.abs(delta) do
			process.exec("xdotool", { "click", btn })
		end
	end

	local function mouseDrag(tx: number, ty: number, button: MouseButton?, _duration: number?)
		mouseDown(button)
		mouseMove(tx, ty)
		mouseUp(button)
	end

	local function hotkey(...: KeyCode): Hotkey
		local keys = { ... }
		local codes: { number } = {}
		for _, k in keys do
			table.insert(codes, resolveKey(k))
		end
		return {
			keys = keys,
			codes = codes,
			enabled = true,
			Fire = function(self: Hotkey)
				if not self.enabled then
					return
				end
				combo(table.unpack(self.keys))
			end,
			Enable = function(self: Hotkey)
				self.enabled = true
			end,
			Disable = function(self: Hotkey)
				self.enabled = false
			end,
			IsEnabled = function(self: Hotkey): boolean
				return self.enabled
			end,
		}
	end

	return {
		Key = LINUX_KEYS,
		wait = wait,
		down = keyDown,
		up = keyUp,
		tap = tap,
		press = tap,
		write = writeText,
		typeText = writeText,
		combo = combo,
		hotkey = hotkey,
		isKeyDown = function(_key: KeyCode): boolean
			return false
		end,
		mousePosition = mousePosition,
		mouseMove = mouseMove,
		mouseDown = mouseDown,
		mouseUp = mouseUp,
		mouseClick = mouseClick,
		mouseDoubleClick = mouseDoubleClick,
		mouseScroll = mouseScroll,
		mouseDrag = mouseDrag,
		onEscapeHold = function(_secs: number, _cb: () -> ()) end,
		stop = function()
			_running = false
		end,
		isRunning = function(): boolean
			return _running
		end,
		registerHotkey = function(_name: string, _keys: { KeyCode }, _cb: () -> ()) end,
		unregisterHotkey = function(_name: string) end,
	}
end

-- ═══════════════════════════════════════════════════════════════
-- MACOS
-- ═══════════════════════════════════════════════════════════════

local function createMacOSInput(): InputModule
	local function wait(ms: number)
		task.wait(ms / 1000)
	end

	local function noopKey(_key: KeyCode) end

	local function tap(key: KeyCode)
		process.exec("osascript", { "-e", `tell application "System Events" to keystroke "{key}"` })
	end

	local function writeText(text: string, _delayMs: number?)
		process.exec("osascript", { "-e", `tell application "System Events" to keystroke "{text}"` })
	end

	local function combo(...: KeyCode)
		for _, k in { ... } do
			tap(k)
			wait(50)
		end
	end

	local function hotkey(...: KeyCode): Hotkey
		local keys = { ... }
		local codes: { number } = {}
		for _, k in keys do
			table.insert(codes, resolveKey(k))
		end
		return {
			keys = keys,
			codes = codes,
			enabled = true,
			Fire = function(self: Hotkey)
				if not self.enabled then
					return
				end
				combo(table.unpack(self.keys))
			end,
			Enable = function(self: Hotkey)
				self.enabled = true
			end,
			Disable = function(self: Hotkey)
				self.enabled = false
			end,
			IsEnabled = function(self: Hotkey): boolean
				return self.enabled
			end,
		}
	end

	local function noopMouse(_button: MouseButton?) end

	return {
		Key = LINUX_KEYS,
		wait = wait,
		down = noopKey,
		up = noopKey,
		tap = tap,
		press = tap,
		write = writeText,
		typeText = writeText,
		combo = combo,
		hotkey = hotkey,
		isKeyDown = function(_key: KeyCode): boolean
			return false
		end,
		mousePosition = function(): Point
			return { x = 0, y = 0 }
		end,
		mouseMove = function(_x: number, _y: number, opts: MoveOptions?)
			if opts and opts.onComplete then
				opts.onComplete()
			end
		end,
		mouseDown = noopMouse,
		mouseUp = noopMouse,
		mouseClick = function(_button: MouseButton?)
			process.exec("osascript", { "-e", 'tell application "System Events" to click' })
		end,
		mouseDoubleClick = function(_button: MouseButton?)
			process.exec("osascript", { "-e", 'tell application "System Events" to click' })
			wait(50)
			process.exec("osascript", { "-e", 'tell application "System Events" to click' })
		end,
		mouseScroll = function(_delta: number) end,
		mouseDrag = function(_tx: number, _ty: number, _button: MouseButton?, _duration: number?) end,
		onEscapeHold = function(_secs: number, _cb: () -> ()) end,
		stop = function()
			_running = false
		end,
		isRunning = function(): boolean
			return _running
		end,
		registerHotkey = function(_name: string, _keys: { KeyCode }, _cb: () -> ()) end,
		unregisterHotkey = function(_name: string) end,
	}
end

-- ═══════════════════════════════════════════════════════════════
-- FACTORY
-- ═══════════════════════════════════════════════════════════════

local function createInput(): InputModule
	if process.os == "windows" then
		return createWindowsInput()
	elseif process.os == "linux" then
		return createLinuxInput()
	else
		return createMacOSInput()
	end
end

return createInput()
