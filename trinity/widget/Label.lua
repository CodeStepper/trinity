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

--
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--
-- Kontrolka etykiety.
-- Po ustawieniu przechwytywania akcji może stać się również przyciskiem.
--
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--

local setmetatable = setmetatable
local type         = type
local pairs        = pairs
local table        = table

local Signal = require("trinity.Signal")
local Visual = require("trinity.Visual")
local Useful = require("trinity.Useful")
local Label  = {}

-- =================================================================================================
-- Konstruktor etykiety.
-- 
-- Lista możliwych do przekazania argumentów i funkcje do ich późniejszego przestawienia:
--   - show_empty   @ show_empty     : Rysowanie pustej etykiety.
-- # group["padding"]
--   - padding      @ set_padding    : Margines wewnętrzny.
-- # group["back"]
--   - background   @ set_background : Tło kontrolki.
-- # group["fore"]
--   - foreground   @ set_foreground : Kolor napisu na kontrolce.
-- # group["border"]
--   - border_color @ set_border     : Kolor ramki wokół kontrolki.
--   - border_size  @ set_border     : Rozmiar ramki wokół kontrolki.
-- # group["text"]
--   - font             @ set_font       : Czcionka napisu.
--   - horizontal_align @ set_align      : Przyleganie tekstu w poziomie.
--   - vertical_align   @ set_align      : Przyleganie tekstu w pionie.
--   - text_wrap        @ set_wrap       : Zawijanie tekstu.
--   - ellipsize        @ set_ellipsize  : Umieszczenie lub wyłączenie trzykropka gdy za długi tekst.
--   - text             @ set_text       : Zwykły tekst.
--   - markup           @ set_markup     : Tekst w formacie PANGO Markup (podobny do HTML).
--
-- @param args Tablica zawierająca wyżej wymienione argumenty (opcjonalny).
--
-- @return Nowy obiekt etykiety.
-- =================================================================================================

local function new( args )
	local args = args or {}

	-- utwórz podstawę pola tekstowego
	local retval = {}

	-- inicjalizacja sygnałów
	Signal.initialize( retval )

	-- informacje o kontrolce
	retval._control = "Label"
	retval._type    = "widget"

	-- przypisz funkcję do obiektu
	Useful.rewrite_functions( Label, retval )
	
	-- pobierz grupy i dodaj grupę tekstu
	local groups = args.groups or {}
	table.insert( groups, "text" )
	
	-- inicjalizacja grup i funkcji
	Visual.initialize( retval, groups, args )
	
	-- ustaw dodatkowe zmienne
	retval:show_empty( args.show_empty or false, false )
	
	-- uruchamianie zadania dla kontrolki
	if args.worker ~= nil then		
		retval.worker = {}
		args.worker( retval, args )
	end

	return retval
end

-- =================================================================================================
-- Rysuje etykietę na kontrolce nadrzędnej.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function Label:draw( cr )
	-- nie rysuj gdy wymiary są zerowe...
	if self._bounds[5] == 0 or self._bounds[6] == 0 then
		return
	end

	-- rysuj kontrolkę i tekst
	self:draw_visual( cr )
	self:draw_text( cr )

end

-- =================================================================================================
-- Dopasowuje kontrolkę do wybranych rozmiarów.
-- Gdy chcemy zmierzyć szerokość i/lub wysokość kontrolki wystarczy jako parametr wpisać -1.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
--
-- @return Szerokość i wysokość całkowita kontrolki.
-- =================================================================================================

function Label:fit( width, height )
	local new_width  = width
	local new_height = height

	-- obszar do pominięcia (margines wewnętrzny kontrolki)
	local marw = self._padding[1] + self._padding[3]
	local marh = self._padding[2] + self._padding[4]
	
	-- zerowe wymiary (lub jeden z nich) - lub gdy kontrolka się nie zmieści
	if (width ~= -1 and width <= marw) or (height ~= -1 and height <= marh) then
		return 0, 0
	end
	
	-- odejmij wcięcia
	new_width  = width  > 0 and width  - marw or width
	new_height = height > 0 and height - marh or height
	
	-- wymiary tekstu
	local tw, th = self:calc_text_dims( new_width, new_height )

	-- zerowe wymiary
	if (not self._drawnil and tw == 0) or th == 0 then
		return 0, 0
	end
	
	if self.calc_image_scale then
		self:calc_image_scale( width, height )
		-- self:calc_image_scale( tw + marw, th + marh )
	end

	-- dodaj wcięcia
	return tw + marw, th + marh
end

-- =================================================================================================
-- Rysuj nawet gdy kontrolka nie ma przypisanego tekstu.
-- 
-- @param value  Flaga rysowania (true / false) pustej kontrolki.
-- @param update Wysyłanie sygnału aktualizacji kontrolki.
--
-- @return Obiekt etykiety.
-- =================================================================================================

function Label:show_empty( value, update )
	self._drawnil = value

	-- wyślij sygnał aktualizacji elementu
	if update == nil or update then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end

	return self
end

-- =================================================================================================
-- Tworzenie metadanych obiektu.
-- =================================================================================================

Label.mt = {}

function Label.mt:__call(...)
	return new(...)
end

return setmetatable( Label, Label.mt )
