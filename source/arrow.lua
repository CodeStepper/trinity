-- LIBRARIES
-- ==========================================================================================
local naughty = require("naughty")
local gears = require("gears")
local base = require("wibox.widget.base")

local arrow = { mt = {} }
local timer = (type(timer) == 'table' and timer or gears.timer)
local mouse = mouse

-- ARROW:DRAW
-- ==========================================================================================

function arrow:draw( wibox, cr, width, height )
   -- don't draw if width or height is 0
	if width == 0 or height == 0 then
		return
	end

	local back = self.back
	local fore = self.fore
	
	-- kolor tła elementu powiązanego
	if self.backobj ~= nil and self.backobj.back ~= nil then
		back = self.backobj.back
	end
	
	-- rysuj tło
	cr:set_source_rgba( back[1], back[2], back[3], back[4] )
	cr:rectangle( 0, 0, width, height )
	cr:fill()

	-- kolor tła strzałki elementu powiązanego
	if self.foreobj ~= nil and self.foreobj.back ~= nil then
		fore = self.foreobj.back
	end

	-- rysuj strzałkę
	cr:set_source_rgba( fore[1], fore[2], fore[3], fore[4] )
	
	if self.dir == 1 then
		local x = 0
	
		for i=width, 1, -1 do
			cr:move_to( i, 0+x )
			cr:line_to( i, height-x )
			x = x + 1
		end
	else
		for i=0, width-1 do
			cr:move_to( i, 0+i )
			cr:line_to( i, height-i )
		end
	end

	cr:stroke() 
end

-- ARROW:FIT
-- ==========================================================================================

function arrow:fit( width, height )
	-- zamień tylko wysokość i oblicz szerokość
	if self.height ~= height then
		self.width  = math.ceil( height/2 )
		self.height = height
	end

	return self.width, self.height
end

-- ON_MOUSE_ENTER
-- ==========================================================================================

local function on_mouse_enter( widget, data )
	arrow.ob = widget
	arrow.px = data.x
	arrow.py = data.y

	arrow.timer:start()
end

-- ON_MOUSE_LEAVE
-- ==========================================================================================

local function on_mouse_leave( widget )
	arrow.timer:stop()
end

-- ON_PRESS
-- ==========================================================================================

local function on_button_press( widget, x, y, button )
	local coords = mouse.coords()
	
	arrow.ob  = widget
	arrow.sig = "button::press"

	widget._hit_test( x, y, button )
end

-- ON_RELEASE
-- ==========================================================================================

local function on_button_release( widget, x, y, button )
	local coords = mouse.coords()
	
	arrow.ob  = widget
	arrow.sig = "button::release"
	
	widget._hit_test( x, y, button )
end

-- HIT_TEST
-- ==========================================================================================

local function hit_test( x, y, button )
	-- kierunek strzałki
	if arrow.ob.dir == 1 then
		-- obszar tła
		local wy = (arrow.ob.width - x - 1)
		
		-- strzałka
		if y >= wy and y < arrow.ob.height - wy then
			if arrow.ob.foreobj ~= nil then
				arrow.ob.foreobj:emit_signal( arrow.sig, x, y, button )
			end
		-- tło
		else
			if arrow.ob.backobj ~= nil then
				arrow.ob.backobj:emit_signal( arrow.sig, x, y, button )
			end
		end
	else
		-- obszar tła
		local wy = x
		
		-- strzałka
		if y >= wy and y < arrow.ob.height - wy then
			if arrow.ob.foreobj ~= nil then
				arrow.ob.foreobj:emit_signal( arrow.sig, x, y, button )
			end
		-- tło
		else
			if arrow.ob.backobj ~= nil then
				arrow.ob.backobj:emit_signal( arrow.sig, x, y, button )
			end
		end
	end
end

-- NEW
-- ==========================================================================================

local function new( args )
	-- brak argumentów...
	if args == nil then
		args = { background = "#FFFFFF", foreground = "#000000" }
	end

	local retval = base.make_widget()
	local dir    = args.direction or "left"
	local back   = args.background or "#FFFFFF"
	local fore   = args.foreground or "#000000"
	local r,g,b,a
	
	-- dodawanie funkcji do obiektu
	for key, val in pairs(arrow) do
		if type(val) == "function" then
			retval[key] = val
		end
	end
	
	-- test myszy (hit test)
	retval._hit_test = function( x, y, button )
		hit_test( x, y, button )
	end
	
	-- tło
	if args.backobj ~= nil and args.backobj.back ~= nil then
		retval.backobj = args.backobj
	end
	
	r,g,b,a = gears.color.parse_color( back )
	retval.back = { r, g, b, a } 
	
	-- strzałka
	if args.foreobj ~= nil and args.foreobj.back ~= nil then
		retval.foreobj = args.foreobj
	end
	
	r,g,b,a = gears.color.parse_color( fore )
	retval.fore = { r, g, b, a }
	
	retval.width  = width
	retval.height = height
	retval.dir    = dir == "left" and 1 or 2

	-- @SIGNALS {{
	-- naciśnięcie przycisku
	if args.press == true then
		retval:add_signal( "button::press" )
		retval:connect_signal( "button::press", on_button_press )
	end
	-- puszczenie przycisku
	if args.release == true then
		retval:add_signal( "button::release" )
		retval:connect_signal( "button::release", on_button_release )
	end
	-- wejście myszy w element
	if args.enter == true then
		retval:add_signal( "mouse::enter" )
		retval:connect_signal( "mouse::enter", on_mouse_enter )
	end
	-- wyjście myszy z elementu
	if args.leave == true then
		retval:add_signal( "mouse::leave" )
		retval:connect_signal( "mouse::leave", on_mouse_leave )
	end
	-- }} #SIGNALS
	
	-- licznik globalny dla czasomierza
	if arrow.timer == nil then
		arrow.timer = timer({ timeout = 0.1 })
		arrow.timer:connect_signal( "timeout", function()
			-- oblicz współrzędne pozycji myszy w elemencie
			local coords = mouse.coords()    
			local sx, sy = coords.x - arrow.px, coords.y - arrow.py
			
			hit_test( sx, sy )
		end )
	end
	
	return retval
end

-- ARROW.MT:CALL
-- ==========================================================================================

function arrow.mt:__call(...)
	return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( arrow, arrow.mt )