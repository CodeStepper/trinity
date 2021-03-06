--
--  Trinity Widget Library >>> http://trinity.aculo.pl
--   _____     _     _ _       
--  |_   _|___|_|___|_| |_ _ _ 
--    | | |  _| |   | |  _| | |
--    |_| |_| |_|_|_|_|_| |_  |
--                        |___|
--
--  This file is part of Trinity Widget Library for AwesomeWM
--  Copyright (c) by sobiemir <sobiemir@aculo.pl>
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

--[[ require
========================================================================================== ]]

-- local naughty = require("naughty")
-- local gears = require("gears")
-- local base = require("wibox.widget.base")

-- local Arrow = { mt = {} }
-- local timer = (type(timer) == 'table' and timer or gears.timer)
-- local mouse = mouse

local setmetatable = setmetatable
local type         = type
local pairs        = pairs
local table        = table
local mouse        = mouse

local Signal = require("trinity.Signal")
local Visual = require("trinity.Visual")
local Useful = require("trinity.Useful")
local Arrow  = {}

-- -- Arrow:DRAW
-- -- ==========================================================================================

-- function Arrow:draw( wibox, cr, width, height )
--    -- don't draw if width or height is 0
--  if width == 0 or height == 0 then
--      return
--  end

--  local back = self.back
--  local fore = self.fore
	
--  -- kolor tła elementu powiązanego
--  if self.backobj ~= nil and self.backobj.back ~= nil then
--      back = self.backobj.back
--  end
	
--  -- rysuj tło
--  cr:set_source_rgba( back[1], back[2], back[3], back[4] )
--  cr:rectangle( 0, 0, width, height )
--  cr:fill()

--  -- kolor tła strzałki elementu powiązanego
--  if self.foreobj ~= nil and self.foreobj.back ~= nil then
--      fore = self.foreobj.back
--  end

--  -- rysuj strzałkę
--  cr:set_source_rgba( fore[1], fore[2], fore[3], fore[4] )
	
--  if self.dir == 1 then
--      local x = 0
	
--      for i=width, 1, -1 do
--          cr:move_to( i, 0+x )
--          cr:line_to( i, height-x )
--          x = x + 1
--      end
--  else
--      for i=0, width-1 do
--          cr:move_to( i, 0+i )
--          cr:line_to( i, height-i )
--      end
--  end

--  cr:stroke() 
-- end

-- -- Arrow:FIT
-- -- ==========================================================================================

-- function Arrow:fit( width, height )
--  -- zamień tylko wysokość i oblicz szerokość
--  if self.height ~= height then
--      self.width  = math.ceil( height/2 )
--      self.height = height
--  end

--  return self.width, self.height
-- end

-- -- ON_MOUSE_ENTER
-- -- ==========================================================================================

-- local function on_mouse_enter( widget, data )
--  Arrow.ob = widget
--  Arrow.px = data.x
--  Arrow.py = data.y

--  Arrow.timer:start()
-- end

-- -- ON_MOUSE_LEAVE
-- -- ==========================================================================================

-- local function on_mouse_leave( widget )
--  Arrow.timer:stop()
-- end

-- -- ON_PRESS
-- -- ==========================================================================================

-- local function on_button_press( widget, x, y, button )
--  local coords = mouse.coords()
	
--  Arrow.ob  = widget
--  Arrow.sig = "button::press"

--  widget._hit_test( x, y, button )
-- end

-- -- ON_RELEASE
-- -- ==========================================================================================

-- local function on_button_release( widget, x, y, button )
--  local coords = mouse.coords()
	
--  Arrow.ob  = widget
--  Arrow.sig = "button::release"
	
--  widget._hit_test( x, y, button )
-- end

-- -- HIT_TEST
-- -- ==========================================================================================

-- local function hit_test( x, y, button )
--  -- kierunek strzałki
--  if Arrow.ob.dir == 1 then
--      -- obszar tła
--      local wy = (Arrow.ob.width - x - 1)
		
--      -- strzałka
--      if y >= wy and y < Arrow.ob.height - wy then
--          if Arrow.ob.foreobj ~= nil then
--              Arrow.ob.foreobj:emit_signal( Arrow.sig, x, y, button )
--          end
--      -- tło
--      else
--          if Arrow.ob.backobj ~= nil then
--              Arrow.ob.backobj:emit_signal( Arrow.sig, x, y, button )
--          end
--      end
--  else
--      -- obszar tła
--      local wy = x
		
--      -- strzałka
--      if y >= wy and y < Arrow.ob.height - wy then
--          if Arrow.ob.foreobj ~= nil then
--              Arrow.ob.foreobj:emit_signal( Arrow.sig, x, y, button )
--          end
--      -- tło
--      else
--          if Arrow.ob.backobj ~= nil then
--              Arrow.ob.backobj:emit_signal( Arrow.sig, x, y, button )
--          end
--      end
--  end
-- end

-- -- NEW
-- -- ==========================================================================================

-- local function new( args )
--  -- brak argumentów...
--  if args == nil then
--      args = { background = "#FFFFFF", foreground = "#000000" }
--  end

--  local retval = base.make_widget()
--  local dir    = args.direction or "left"
--  local back   = args.background or "#FFFFFF"
--  local fore   = args.foreground or "#000000"
--  local r,g,b,a
	
--  -- dodawanie funkcji do obiektu
--  for key, val in pairs(Arrow) do
--      if type(val) == "function" then
--          retval[key] = val
--      end
--  end
	
--  -- test myszy (hit test)
--  retval._hit_test = function( x, y, button )
--      hit_test( x, y, button )
--  end
	
--  -- tło
--  if args.backobj ~= nil and args.backobj.back ~= nil then
--      retval.backobj = args.backobj
--  end
	
--  r,g,b,a = gears.color.parse_color( back )
--  retval.back = { r, g, b, a } 
	
--  -- strzałka
--  if args.foreobj ~= nil and args.foreobj.back ~= nil then
--      retval.foreobj = args.foreobj
--  end
	
--  r,g,b,a = gears.color.parse_color( fore )
--  retval.fore = { r, g, b, a }
	
--  retval.width  = width
--  retval.height = height
--  retval.dir    = dir == "left" and 1 or 2

--  -- @SIGNALS {{
--  -- naciśnięcie przycisku
--  if args.press == true then
--      retval:add_signal( "button::press" )
--      retval:connect_signal( "button::press", on_button_press )
--  end
--  -- puszczenie przycisku
--  if args.release == true then
--      retval:add_signal( "button::release" )
--      retval:connect_signal( "button::release", on_button_release )
--  end
--  -- wejście myszy w element
--  if args.enter == true then
--      retval:add_signal( "mouse::enter" )
--      retval:connect_signal( "mouse::enter", on_mouse_enter )
--  end
--  -- wyjście myszy z elementu
--  if args.leave == true then
--      retval:add_signal( "mouse::leave" )
--      retval:connect_signal( "mouse::leave", on_mouse_leave )
--  end
--  -- }} #SIGNALS
	
--  -- licznik globalny dla czasomierza
--  if Arrow.timer == nil then
--      Arrow.timer = timer({ timeout = 0.1 })
--      Arrow.timer:connect_signal( "timeout", function()
--          -- oblicz współrzędne pozycji myszy w elemencie
--          local coords = mouse.coords()    
--          local sx, sy = coords.x - Arrow.px, coords.y - Arrow.py
			
--          hit_test( sx, sy )
--      end )
--  end
	
--  return retval
-- end

--[[ new
=============================================================================================
 Tworzenie nowej instancji strzałki.
 Emiter odpowiedzialny jest za wysyłanie sygnałów do obiektów połączonych.
 Obiekty połączone to fore_object i back_object.
 W emit_signals można podać wszystkie możliwe sygnały do emisji.
 
 - args : argumenty pola edycji:
	> width        @ set_dimensions
	> height       @ set_dimensions
	> fore_object  @ set_objects
	> back_object  @ set_objects
	> emit_signals @ ---
 # group["back"]
	> background   @ set_background
 # group["fore"]
	> foreground   @ set_foreground
 # group["border"]
	> border_color @ set_border
	> border_size  @ set_border
	
 - return : object

 -- @todo Ramka dla kontrolki
========================================================================================== ]]

local function draw_left_arrow( cr, self, back, fore )
	local px, py = self.Bounds[1], self.Bounds[2]
	local width, height = self.Bounds[5], self.Bounds[6]

	if fore then
		cr:set_source( fore )

		local x = 0

		for i = width, 0, -1 do
			cr:move_to( px + i, py + x )
			cr:line_to( px + i, py + height - x )
			x = x + 1
		end
	elseif back then
		cr:set_source( back )

		local halfzero = math.ceil(height / 2)
		local x = width

		for i = 0, height do
			if halfzero > -1 then
				x = x - 1
			else
				x = x + 1
			end

			cr:move_to( px, py + i )
			cr:line_to( px + x, py + i )

			halfzero = halfzero - 1
		end
	end

	cr:stroke()
end

local function draw_right_arrow( cr, self, back, fore )
	local px, py = self.Bounds[1], self.Bounds[2]
	local width, height = self.Bounds[5], self.Bounds[6]

	if back then
		cr:set_source( back )

		local x = width

		for i = width, 0, -1 do
			cr:move_to( px + i, py + x )
			cr:line_to( px + i, py + height - x )
			x = x - 1
		end
	elseif fore then
		cr:set_source( fore )

		local halfzero = math.ceil(height / 2)
		local x = 0

		for i = 0, height do
			if halfzero > -1 then
				x = x + 1
			else
				x = x - 1
			end

			cr:move_to( px + x, py + i )
			cr:line_to( px + width, py + i )

			halfzero = halfzero - 1
		end
	end

	cr:stroke()
end

local function draw_top_arrow( cr, self, back, fore )
end

local function draw_bottom_arrow( cr, self, back, fore )
end

function Arrow:draw( cr )
	local temp
	local px, py = self.Bounds[1], self.Bounds[2]
	local width, height = self.Bounds[5], self.Bounds[6]

	-- nie rysuj gdy wymiary są zerowe...
	if self.Bounds[5] == 0 or self.Bounds[6] == 0 then
		return
	end
	
	local back = (self._near_widget and self._near_widget.V.Background) and self._near_widget.V.Background or self.V.Background
	local fore = (self._far_widget  and self._far_widget.V.Background ) and self._far_widget.V.Background  or self.V.TXT.Color

	-- nie rysuj coś czego nie ma...
	if not self._border and back == nil and fore == nil then
		return
	end

	cr:save()

	-- tło kontrolki
	if back and fore then
		if self._direction == 1 or self._direction == 3 then
			cr:set_source( back )
		else
			cr:set_source( fore )
		end

		cr:rectangle( px, py, width, height )
		cr:fill()
	end

	-- ograniczenie rysowania widżetu
	cr:rectangle( px, py, width, height )
	cr:clip()

	if self._direction == 1 then
		draw_left_arrow( cr, self, back, fore )
	elseif self._direction == 2 then
		draw_right_arrow( cr, self, back, fore )
	elseif self._direction == 3 then
		draw_top_arrow( cr, self, back, fore )
	else
		draw_bottom_arrow( cr, self, back, fore )
	end

	cr:restore()
end

function Arrow:fit( width, height )
	local new_width  = width
	local new_height = height
	
	-- zapytanie o dwa wymiary nie ma tutaj sensu
	if width == -1 and height == -1 then
		return 0, 0
	end
	
	-- automatycznie dopasuj szerokość
	if height > 0 and width == -1 then
		if self._direction == 1 or self._direction == 2 then
			new_width = math.ceil( height / 2 )
		else
			new_width = height * 2
		end
	end

	-- automatycznie dopasuj wysokość
	if width > 0 and height == -1 then
		if self._direction == 1 or self._direction == 2 then
			new_height = new_width * 2
		else
			new_height = math.ceil( new_width / 2 )
		end
	end
	
	-- krok do przesuwania pikseli
	if self._direction == 1 or self._direction == 2 then
		self._step = new_width / (new_height / 2)
	else
		self._step = new_height / (new_width / 2)
	end

	-- dodaj wcięcia
	return new_width, new_height
end

local function hit_test( widget, signal, x, y, button )
	-- -- kierunek strzałki
	-- if Arrow.ob.dir == 1 then
	--     -- obszar tła
	--     local wy = (Arrow.ob.width - x - 1)
			
	--     -- strzałka
	--     if y >= wy and y < Arrow.ob.height - wy then
	--         if Arrow.ob.foreobj ~= nil then
	--             Arrow.ob.foreobj:emit_signal( Arrow.sig, x, y, button )
	--         end
	--     -- tło
	--     else
	--         if Arrow.ob.backobj ~= nil then
	--             Arrow.ob.backobj:emit_signal( Arrow.sig, x, y, button )
	--         end
	--     end
	-- else
	--     -- obszar tła
	--     local wy = x
			
	--     -- strzałka
	--     if y >= wy and y < Arrow.ob.height - wy then
	--         if Arrow.ob.foreobj ~= nil then
	--             Arrow.ob.foreobj:emit_signal( Arrow.sig, x, y, button )
	--         end
	--     -- tło
	--     else
	--         if Arrow.ob.backobj ~= nil then
	--             Arrow.ob.backobj:emit_signal( Arrow.sig, x, y, button )
	--         end
	--     end
	-- end
end


local function mouse_enter_emiter()
end

local function mouse_move_emiter()
end

local function mouse_leave_emiter()
end

local function button_press_emiter( widget, x, y, button )
	widget._near_widget:emit_signal("button::press", x, y, button)
end

local function button_click_emiter()
end

local function button_release_emiter( widget, x, y, button )
	widget._near_widget:emit_signal("button::release", x, y, button)
end

local function new( args )
	local args = args or {}

	-- utwórz podstawę strzałki
	local retval = {}
	
	-- inicjalizacja sygnałów
	Signal.initialize( retval )

	-- informacje o kontrolce
	retval._control = "Arrow"
	retval._type    = "composite"

	-- przypisz funkcje do obiektu
	Useful.rewrite_functions( Arrow, retval )
	
	-- pobierz grupy i dodaj grupę tekstu
	local groups = args.groups or {}

	-- nie pozwalaj na dodanie określonych grup
	for key, val in pairs(groups) do
		if val == "text" or val == "padding" then
			groups[key] = nil
		end
	end
	
	-- inicjalizacja grup i funkcji
	Visual.initialize( retval, groups, args )
	
	-- aktualizacja elementu
	retval.emit_updated = function()
		retval:emit_signal( "widget::updated" )
	end
	-- odświeżenie wymiarów
	retval.emit_resized = function()
		retval:emit_signal( "widget::resized" )
	end

	-- zapisz obiekty wokoło
	retval._near_widget = args.bind_left  or args.bind_top
	retval._far_widget  = args.bind_right or args.bind_bottom

	-- sygnały aktualizacji
	if type(retval._near_widget) == "table" and retval._near_widget._Type == "widget" then
		-- retval._near_widget:connect_signal( "widget::resized", retval.emit_resized )
		-- retval._near_widget:connect_signal( "widget::updated", retval.emit_updated )
	else
		retval._near_widget = nil
	end
	if type(retval._far_widget) == "table" and retval._far_widget._Type == "widget" then
		-- retval._far_widget:connect_signal( "widget::resized", retval.emit_resized )
		-- retval._far_widget:connect_signal( "widget::updated", retval.emit_updated )
	else
		retval._far_widget = nil
	end

	retval:emit_signals ( args.emiter or {} )
		  :set_direction( args.direction or "left" )

	return retval
end

function Arrow:emit_signals( signals )
	for key, val in pairs(signals) do
		if val == "mouse::enter" then
			self:connect_signal( "mouse::enter", mouse_enter_emiter )
		elseif val == "mouse::move" then
			self:connect_signal( "mouse::move", mouse_move_emiter )
		elseif val == "mouse::leave" then
			self:connect_signal( "mouse::leave", mouse_leave_emiter )
		elseif val == "button::press" then
			self:connect_signal( "button::press", button_press_emiter )
		elseif val == "button::click" then
			self:connect_signal( "button::click", button_click_emiter )
		elseif val == "button::release" then
			self:connect_signal( "button::release", button_release_emiter )
		end
	end

	return self
end

function Arrow:set_direction( dir, update )
	if dir == "left" then
		self._direction = 1
	elseif dir == "right" then
		self._direction = 2
	elseif dir == "top" then
		self._direction = 3
	else
		self._direction = 4
	end

	if update == nil or update then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end

	return self
end

--[[ Arrow.mt:xxx
=============================================================================================
 Tworzenie meta danych dla obiektu.
========================================================================================== ]]

Arrow.mt = {}

function Arrow.mt:__call(...)
	return new(...)
end

return setmetatable( Arrow, Arrow.mt )
