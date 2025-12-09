--!nocheck
-- lune-input v3.0: Cross-platform input module (FFI Windows, xdotool Linux)
local ffi = require("@lune/ffi")
local process = require("@lune/process")
local task = require("@lune/task")

export type KeyCode = number | string
export type MouseButton = "left" | "right" | "middle"
export type Point = { x: number, y: number }
export type MoveOptions = { duration: number?, easing: string?, onComplete: (() -> ())?, onError: ((string) -> ())? }
export type Hotkey = {
	Fire: (self: Hotkey) -> (),
	Enable: (self: Hotkey) -> (),
	Disable: (self: Hotkey) -> (),
	IsEnabled: (self: Hotkey) -> boolean,
	keys: { KeyCode },
	enabled: boolean,
}

local KeyNames: { [string]: number } = {
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

local Keys = {
	windows = {
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
	},
	linux = {
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
	},
}
Keys.macos = Keys.linux

local Input: { [string]: any } = {}
Input.Key = Keys[process.os] or Keys.windows

local _running = true
local _escThread: thread? = nil

local function resolveKey(key: KeyCode): number
	if type(key) == "number" then
		return key
	end
	if type(key) == "string" then
		local k = KeyNames[key:lower()]
		if k then
			return k
		end
		if #key == 1 then
			return string.byte(key:upper()) or 0
		end
	end
	return 0
end

function Input.hotkey(...: KeyCode): Hotkey
	local keys = { ... }
	local codes: { number } = {}
	for _, k in keys do
		table.insert(codes, resolveKey(k))
	end
	local h: Hotkey = {
		keys = keys,
		enabled = true,
		Fire = function(self)
			if process.os == "windows" then
				local u32 = ffi.open("user32.dll")
				for _, c in codes do
					u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, c, 0, 0, 0)
				end
				task.wait(0.01)
				for i = #codes, 1, -1 do
					u32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, codes[i], 0, 0x0002, 0)
				end
			end
		end,
		Enable = function(self)
			self.enabled = true
		end,
		Disable = function(self)
			self.enabled = false
		end,
		IsEnabled = function(self)
			return self.enabled
		end,
	}
	return h
end

if process.os == "windows" then
	local user32, kernel32 = ffi.open("user32.dll"), ffi.open("kernel32.dll")
	local KEYUP, UNICODE = 0x0002, 0x0004
	local M_LDOWN, M_LUP, M_RDOWN, M_RUP, M_MDOWN, M_MUP = 0x0002, 0x0004, 0x0008, 0x0010, 0x0020, 0x0040
	local M_WHEEL, M_MOVE, M_ABS = 0x0800, 0x0001, 0x8000

	function Input.wait(ms: number)
		kernel32:call("Sleep", "void", { "u32" }, ms)
	end
	function Input.down(key: KeyCode)
		local c = resolveKey(key)
		if c > 0 then
			user32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, c, 0, 0, 0)
		end
	end
	function Input.up(key: KeyCode)
		local c = resolveKey(key)
		if c > 0 then
			user32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, c, 0, KEYUP, 0)
		end
	end
	function Input.tap(key: KeyCode)
		Input.down(key)
		Input.wait(10)
		Input.up(key)
	end
	Input.press = Input.tap

	local function utf8Decode(str: string): { number }
		local cp, i, len = {}, 1, #str
		while i <= len do
			local b1 = string.byte(str, i) :: number
			local c, n
			if b1 < 0x80 then
				c, n = b1, 1
			elseif b1 < 0xE0 then
				c, n =
					bit32.bor(bit32.lshift(bit32.band(b1, 0x1F), 6), bit32.band(string.byte(str, i + 1) or 0, 0x3F)), 2
			elseif b1 < 0xF0 then
				c, n =
					bit32.bor(
						bit32.lshift(bit32.band(b1, 0x0F), 12),
						bit32.lshift(bit32.band(string.byte(str, i + 1) or 0, 0x3F), 6),
						bit32.band(string.byte(str, i + 2) or 0, 0x3F)
					),
					3
			else
				c, n =
					bit32.bor(
						bit32.lshift(bit32.band(b1, 0x07), 18),
						bit32.lshift(bit32.band(string.byte(str, i + 1) or 0, 0x3F), 12),
						bit32.lshift(bit32.band(string.byte(str, i + 2) or 0, 0x3F), 6),
						bit32.band(string.byte(str, i + 3) or 0, 0x3F)
					),
					4
			end
			table.insert(cp, c)
			i += n
		end
		return cp
	end

	function Input.write(text: string, delayMs: number?)
		local delay = delayMs or 5
		for _, c in utf8Decode(text) do
			user32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, 0, c, UNICODE, 0)
			Input.wait(delay)
			user32:call("keybd_event", "void", { "i32", "i32", "i32", "u64" }, 0, c, UNICODE + KEYUP, 0)
			Input.wait(delay)
		end
	end
	Input.typeText = Input.write

	function Input.combo(...: KeyCode)
		local k = { ... }
		for _, key in k do
			Input.down(key)
			Input.wait(10)
		end
		for i = #k, 1, -1 do
			Input.up(k[i])
			Input.wait(10)
		end
	end
	function Input.isKeyDown(key: KeyCode): boolean
		local c = resolveKey(key)
		return c > 0 and bit32.band(user32:call("GetAsyncKeyState", "i32", { "i32" }, c), 0x8000) ~= 0
	end

	function Input.mousePosition(): Point
		local buf = ffi.buffer(8)
		user32:call("GetCursorPos", "i32", { "pointer" }, buf.ptr)
		return { x = buf:read(0, "i32"), y = buf:read(4, "i32") }
	end

	function Input.mouseMove(x: number, y: number, opts: MoveOptions?)
		local o = opts or {}
		local dur = o.duration or 0
		local sw = user32:call("GetSystemMetrics", "i32", { "i32" }, 0)
		local sh = user32:call("GetSystemMetrics", "i32", { "i32" }, 1)
		if dur <= 0 then
			user32:call(
				"mouse_event",
				"void",
				{ "u32", "u32", "u32", "u32", "u64" },
				M_MOVE + M_ABS,
				math.floor((x * 65535) / sw),
				math.floor((y * 65535) / sh),
				0,
				0
			)
			if o.onComplete then
				o.onComplete()
			end
		else
			task.spawn(function()
				local ok, err = pcall(function()
					local sp = Input.mousePosition()
					local steps = math.max(10, math.floor(dur / 10))
					local ease = o.easing == "ease"
							and function(t: number)
								return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
							end
						or function(t: number)
							return t
						end
					for i = 1, steps do
						if not _running then
							break
						end
						local t = ease(i / steps)
						user32:call(
							"mouse_event",
							"void",
							{ "u32", "u32", "u32", "u32", "u64" },
							M_MOVE + M_ABS,
							math.floor(((sp.x + (x - sp.x) * t) * 65535) / sw),
							math.floor(((sp.y + (y - sp.y) * t) * 65535) / sh),
							0,
							0
						)
						Input.wait(math.floor(dur / steps))
					end
				end)
				if ok and o.onComplete then
					o.onComplete()
				elseif not ok and o.onError then
					o.onError(tostring(err))
				end
			end)
		end
	end

	local function mf(b: MouseButton?, down: boolean): number
		b = b or "left"
		if b == "left" then
			return down and M_LDOWN or M_LUP
		elseif b == "right" then
			return down and M_RDOWN or M_RUP
		else
			return down and M_MDOWN or M_MUP
		end
	end
	function Input.mouseDown(b: MouseButton?)
		user32:call("mouse_event", "void", { "u32", "u32", "u32", "u32", "u64" }, mf(b, true), 0, 0, 0, 0)
	end
	function Input.mouseUp(b: MouseButton?)
		user32:call("mouse_event", "void", { "u32", "u32", "u32", "u32", "u64" }, mf(b, false), 0, 0, 0, 0)
	end
	function Input.mouseClick(b: MouseButton?)
		Input.mouseDown(b)
		Input.wait(10)
		Input.mouseUp(b)
	end
	function Input.mouseDoubleClick(b: MouseButton?)
		Input.mouseClick(b)
		Input.wait(50)
		Input.mouseClick(b)
	end
	function Input.mouseScroll(d: number)
		user32:call("mouse_event", "void", { "u32", "u32", "u32", "i32", "u64" }, M_WHEEL, 0, 0, d * 120, 0)
	end
	function Input.mouseDrag(tx: number, ty: number, b: MouseButton?, dur: number?)
		Input.mouseDown(b)
		Input.mouseMove(tx, ty, { duration = dur or 200 })
		task.wait((dur or 200) / 1000 + 0.1)
		Input.mouseUp(b)
	end

	function Input.onEscapeHold(secs: number, cb: () -> ())
		if _escThread then
			task.cancel(_escThread)
		end
		_escThread = task.spawn(function()
			local hold: number? = nil
			while _running do
				if Input.isKeyDown(0x1B) then
					if not hold then
						hold = os.clock() * 1000
					elseif (os.clock() * 1000 - hold) >= secs * 1000 then
						_running = false
						cb()
						break
					end
				else
					hold = nil
				end
				task.wait(0.05)
			end
		end)
	end

	function Input.registerHotkey(name: string, keys: { KeyCode }, cb: () -> ()) end -- stub
	function Input.unregisterHotkey(name: string) end -- stub
elseif process.os == "linux" then
	function Input.wait(ms: number)
		task.wait(ms / 1000)
	end
	function Input.down(k: KeyCode)
		process.exec("xdotool", { "keydown", tostring(k) })
	end
	function Input.up(k: KeyCode)
		process.exec("xdotool", { "keyup", tostring(k) })
	end
	function Input.tap(k: KeyCode)
		process.exec("xdotool", { "key", tostring(k) })
	end
	Input.press = Input.tap
	function Input.write(t: string, _: number?)
		process.exec("xdotool", { "type", "--clearmodifiers", t })
	end
	Input.typeText = Input.write
	function Input.combo(...: KeyCode)
		local k = { ... }
		for _, key in k do
			Input.down(key)
		end
		for i = #k, 1, -1 do
			Input.up(k[i])
		end
	end
	function Input.isKeyDown(_: KeyCode): boolean
		return false
	end
	function Input.mousePosition(): Point
		local r = process.exec("xdotool", { "getmouselocation" })
		return r.ok and { x = tonumber(r.stdout:match("x:(%d+)")) or 0, y = tonumber(r.stdout:match("y:(%d+)")) or 0 }
			or { x = 0, y = 0 }
	end
	function Input.mouseMove(x: number, y: number, opts: MoveOptions?)
		process.exec("xdotool", { "mousemove", tostring(x), tostring(y) })
		if opts and opts.onComplete then
			opts.onComplete()
		end
	end
	local bm = { left = "1", right = "3", middle = "2" }
	function Input.mouseDown(b: MouseButton?)
		process.exec("xdotool", { "mousedown", bm[b or "left"] })
	end
	function Input.mouseUp(b: MouseButton?)
		process.exec("xdotool", { "mouseup", bm[b or "left"] })
	end
	function Input.mouseClick(b: MouseButton?)
		process.exec("xdotool", { "click", bm[b or "left"] })
	end
	function Input.mouseDoubleClick(b: MouseButton?)
		process.exec("xdotool", { "click", "--repeat", "2", bm[b or "left"] })
	end
	function Input.mouseScroll(d: number)
		for _ = 1, math.abs(d) do
			process.exec("xdotool", { "click", d > 0 and "4" or "5" })
		end
	end
	function Input.mouseDrag(tx: number, ty: number, b: MouseButton?, dur: number?)
		Input.mouseDown(b)
		Input.mouseMove(tx, ty)
		Input.mouseUp(b)
	end
	function Input.onEscapeHold(_: number, _: () -> ()) end
	function Input.registerHotkey(_: string, _: { KeyCode }, _: () -> ()) end
	function Input.unregisterHotkey(_: string) end
elseif process.os == "macos" then
	function Input.wait(ms: number)
		task.wait(ms / 1000)
	end
	function Input.down(_: KeyCode) end
	function Input.up(_: KeyCode) end
	function Input.tap(k: KeyCode)
		process.exec("osascript", { "-e", `tell application "System Events" to keystroke "{k}"` })
	end
	Input.press = Input.tap
	function Input.write(t: string, _: number?)
		process.exec("osascript", { "-e", `tell application "System Events" to keystroke "{t}"` })
	end
	Input.typeText = Input.write
	function Input.combo(...: KeyCode)
		for _, k in { ... } do
			Input.tap(k)
			Input.wait(50)
		end
	end
	function Input.isKeyDown(_: KeyCode): boolean
		return false
	end
	function Input.mousePosition(): Point
		return { x = 0, y = 0 }
	end
	function Input.mouseMove(_: number, _: number, opts: MoveOptions?)
		if opts and opts.onComplete then
			opts.onComplete()
		end
	end
	function Input.mouseDown(_: MouseButton?) end
	function Input.mouseUp(_: MouseButton?) end
	function Input.mouseClick(_: MouseButton?)
		process.exec("osascript", { "-e", 'tell application "System Events" to click' })
	end
	function Input.mouseDoubleClick(b: MouseButton?)
		Input.mouseClick(b)
		Input.wait(50)
		Input.mouseClick(b)
	end
	function Input.mouseScroll(_: number) end
	function Input.mouseDrag(_: number, _: number, _: MouseButton?, _: number?) end
	function Input.onEscapeHold(_: number, _: () -> ()) end
	function Input.registerHotkey(_: string, _: { KeyCode }, _: () -> ()) end
	function Input.unregisterHotkey(_: string) end
end

function Input.stop()
	_running = false
end
function Input.isRunning(): boolean
	return _running
end

return Input
