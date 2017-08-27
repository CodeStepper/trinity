--[[ ///////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Tworzenie okienka dla kontrolek.
 Może pomieścić tylko jedną, dlatego zazwyczaj do okienka przypina się układ.
///////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
TODO Poprawić działanie maksymalnych wartości [edit][refresh_geometry].
========================================================================================== ]]

local setmetatable = setmetatable
local type         = type
local pairs        = pairs

local useful  = require("trinity.Useful")
local drawbox = require("trinity.drawbox")
local signal  = require("trinity.Signal")
local popup   = {}

local capi =
{
	awesome = awesome,
	screen = screen,
	client = client
}

--[[ popup:set_widget
=============================================================================================
 Wstawianie elementu do okna.
 
 - widget : wstawiany element.
========================================================================================== ]]

function popup:set_widget( widget )
	local draw = self._drawbox
	
	-- przy zamianie odłącz podłączone sygnały
	if draw._widget then
		draw._widget:disconnect_signal( "widget::updated", self.emit_updated )
		draw._widget:disconnect_signal( "widget::resized", self.emit_resized )
	end
	
	-- podłącz sygnały
	draw:set_widget( widget )
	widget:connect_signal( "widget::updated", self.emit_updated )
	widget:connect_signal( "widget::resized", self.emit_resized )
	
	self.emit_resized()
	self.emit_updated()
end

--[[ popup:refresh_geometry
=============================================================================================
 Obliczanie nowych wymiarów okna.
========================================================================================== ]]

function popup:refresh_geometry()
	-- pobierz szerokość i wysokość
	local width, height = 0, 0
	local equw,  equh   = false, false
	local limits = self._limits
	
	-- szerokość i wysokość do pobrania (-1,-1)
	if self._drawbox._widget then
		width, height = -1, -1
	end
	
	-- dokładna szerokość i wysokość
	if limits[1] and limits[1] == limits[3] then
		width = limits[1]
		equw  = true
	end
	if limits[2] and limits[2] == limits[4] then
		height = limits[2]
		equh   = true
	end
	
	-- spróbuj dopasować element do podanych wymiarów
	if self._drawbox._widget then
		width, height = self._drawbox._widget:fit( width, height )
	end
	
	-- minimalna / maksymalna szerokość
	if limits[1] or limits[3] and equw ~= true then    
		if limits[1] and width < limits[1] then
			width = limits[1]
		elseif limits[3] and width > limits[3] then
			width = limits[3]
		end
		
		-- dopasuj wysokość
		if self._drawbox._widget then
			width, height = self._drawbox._widget:fit( width, -1 )
		end
	end
		
	-- minimalna / maksymalna wysokość
	if limits[2] or limits[4] and equh ~= true then
		if limits[2] and height < limits[2] then
			height = limits[2]
		elseif limits[4] and height > limits[4] then
			height = limits[4]
		end
		
		if self._drawbox._widget then        
			width, height = self._drawbox._widget:fit( width, height )
		end
	end

	-- popraw - od wersji 4.0 wyświetla błąd że 0 nie może być w wymiarze kontrolki
	width  = width  > 0 and width  or 1
	height = height > 0 and height or 1

	-- local naughty = require("naughty")
	-- naughty.notify({ preset = naughty.config.presets.critical,
	--                  title = "Oops, there were errors during startup!",
	--                  text = tostring(width) .. " " .. tostring(height) })

	-- zapisz nowe wymiary okna
	self._drawbox:geometry({
		width  = width,
		height = height
	})
	
	-- krawędzie emisji sygnału
	if self._drawbox._widget then
		self._drawbox._widget:emit_bounds( 0, 0, width, height )
	end
	
	return
end

--[[ popup:set_visible
=============================================================================================
 Zmiana stanu okna - wyświetlanie / ukrywanie okna.
   
 - state : stan okna - true/false [wyświetlane / ukryte].
========================================================================================== ]]

function popup:set_visible( state )
	self._drawbox.visible = state
	
	self.emit_updated()
end

--[[ popup:set_ontop
=============================================================================================
 Zmiana zachowania pozycji okna (jeżeli TRUE, okno zawsze jest na wierzchu).
   
 - state : stan pozycji - true/false.
========================================================================================== ]]

function popup:set_ontop( state )
	self._drawbox.ontop = state
	
	self.emit_updated()
end

--[[ popup:set_background
=============================================================================================
 Zmiana tła okna. Można ustawić przezroczyste.
   
 - back : kolor w kodzie HEX.
========================================================================================== ]]

function popup:set_background( back )
	self._drawbox:set_background( back )
end

--[[ popup:set_foreground
=============================================================================================
 Zmiana koloru czcionek.
   
 - back : kolor w kodzie HEX.
========================================================================================== ]]

function popup:set_foreground( fore )
	self._drawbox:set_foreground( fore )
end

--[[ popup:set_limits
=============================================================================================
 Ograniczenia okna - minimalne i maksymalne rozmiary.
   
 - minw : minimalna szerokość.
 - minh : minimalna wysokość.
 - maxw : maksymalna szerokość.
 - maxh : maksymalna wysokość.
========================================================================================== ]]

function popup:set_limits( minw, minh, maxw, maxh )
	local limits = self._limits

	-- minimalna szerokość
	if minw == false then
		self._limits[1] = nil
	elseif minw ~= nil then
		self._limits[1] = minw
	end
	
	-- minimalna wysokość
	if minh == false then
		self._limits[2] = nil
	elseif minh ~= nil then
		self._limits[2] = minh
	end
	
	-- maksymalna szerokość
	if maxw == false then
		self._limits[3] = nil
	elseif maxw ~= nil then
		self._limits[3] = maxw
	end
	
	-- maksymalna wysokość
	if maxh == false then
		self._limits[4] = nil
	elseif maxh ~= nil then
		self._limits[4] = maxh
	end
	
	-- zamień wartości gdy minimum jest większe niż maksimum
	if limits[1] and limits[3] and limits[1] > limits[3] then
		local temp = limits[3]
		self._limits[3] = limits[1]
		self._limits[1] = temp
	end
	if limits[2] and limits[4] and limits[2] > limits[4] then
		local temp = limits[4]
		self._limits[4] = limits[2]
		self._limits[2] = temp
	end
	
	-- przerysuj
	-- self.emit_resized()
	-- self.emit_updated()
end

--[[ popup:set_size
=============================================================================================
 Zmiana rozmiaru okna.
 UWAGA: Zmienia limity ustawione funkcją set_limits!
 Funkcja jest skrótem - uruchamia set_limits...
   
 - width  : szerokość okna.
 - height : wysokość okna.
========================================================================================== ]]

function popup:set_size( width, height )
	self:set_limits( width, height, width, height )
end

--[[ popup:set_position
=============================================================================================
 Zmiana pozycji wyświetlania okna.
 Pozycje można ustawić globalnie lub względem obszaru roboczego.

 - px   : pozycja X.
 - py   : pozycja Y.
 - byws : ustal pozycje względem obszaru roboczego [domyślnie TRUE].
========================================================================================== ]]

function popup:set_position( px, py, byws )
	local ws = screen[self._screen].workarea
	
	-- zmień pozycję
	if byws == false then
		self._drawbox:geometry({
			x = px or 0,
			y = py or 0
		})
	-- zmień pozycję względem wolnej przestrzeni na ekranie
	else
		self._drawbox:geometry({
			x = ws.x + (px or 0),
			y = ws.y + (py or 0)
		})
	end
	
	-- przerysuj
	self.emit_resized()
	self.emit_updated()
end

--[[ popup:set_position
=============================================================================================
 Tworzenie nowego okna.

 - args : lista przekazywanych argumentów do funkcji:
	> screen        @ ---
	> background    @ set_background
	> foreground    @ set_foreground
	> border_size   @ ---
	> border_color  @ ---
	> min_width     @ set_limits
	> min_height    @ set_limits
	> max_width     @ set_limits
	> max_height    @ set_limits
	> width         @ set_size
	> height        @ set_size
	> posx          @ set_position
	> posy          @ set_position
	> wspace_pos    @ set_position
	> visible       @ set_visible
	> ontop         @ set_ontop
========================================================================================== ]]

local function new( args )
	local args = args or {}
	
	local retval = {
		_screen = args.screen or 1,
		_limits = {} -- { min_width, min_height, max_width, max_height }
	}
	-- dodawanie funkcji do obiektu
	useful.RewriteFunctions( popup, retval )
	
	-- tworzenie panelu
	retval._drawbox = drawbox({
		background   = args.background,
		foreground   = args.foreground,
		border_width = args.border_size,
		border_color = args.border_color,
		type         = "notification"
	})

	-- ponowne rysowanie
	retval.emit_updated = function()
		retval._drawbox:draw()
	end
	-- aktualizacja wymiarów elementów
	retval.emit_resized = function()
		retval:refresh_geometry()
	end
	
	-- ustaw zmienne
	retval:set_limits( args.min_width, args.min_height, args.max_width, args.max_height )
	retval:set_size( args.width, args.height )
	retval:set_position( args.posx, args.posy, args.wspace_pos )
	retval:set_visible( args.visible or false )
	retval:set_ontop( args.ontop or true )
	
	return retval
end

-- popup.mt:xxx
-- ==========================================================================================
-- Tworzenie meta danych dla obiektu.
-- ==========================================================================================

popup.mt = {}

function popup.mt:__call(...)
	return new(...)
end

return setmetatable( popup, popup.mt )
