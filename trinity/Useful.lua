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

local pairs = pairs
local type  = type

local Beautiful = require("beautiful")
local Pango     = require("lgi").Pango
local Useful    = {}

Useful.FONT_STYLE = {
	Normal  = Pango.Style.NORMAL,
	Italic  = Pango.Style.ITALIC,
	Oblique = Pango.Style.OBLIQUE
}
Useful.FONT_VARIANT = {
	Normal    = Pango.Variant.NORMAL,
	SmallCaps = Pango.Variant.SMALL_CAPS
}
Useful.FONT_WEIGHT = {
	Thin       = Pango.Weight.THIN,
	UltraLight = Pango.Weight.ULTRALIGHT,
	Light      = Pango.Weight.LIGHT,
	SemiLight  = Pango.Weight.SEMILIGHT,
	Book       = Pango.Weight.BOOK,
	Normal     = Pango.Weight.NORMAL,
	Medium     = Pango.Weight.MEDIUM,
	SemiBold   = Pango.Weight.SEMIBOLD,
	Bold       = Pango.Weight.BOLD,
	UltraBold  = Pango.Weight.ULTRABOLD,
	Heavy      = Pango.Weight.HEAVY,
	UltraHeavy = Pango.Weight.ULTRAHEAVY
}
Useful.FONT_STRETCH = {
	UltraCondensed = Pango.Stretch.ULTRA_CONDENSED,
	ExtraCondensed = Pango.Stretch.EXTRA_CONDENSED,
	Condensed      = Pango.Stretch.CONDENSED,
	SemiCondensed  = Pango.Stretch.SEMI_CONDENSED,
	Normal         = Pango.Stretch.NORMAL,
	SemiExpanded   = Pango.Stretch.SEMI_EXPANDED,
	Expanded       = Pango.Stretch.EXPANDED,
	ExtraExpanded  = Pango.Stretch.EXTRA_EXPANDED,
	UltraExpanded  = Pango.Stretch.ULTRA_EXPANDED
}
Useful.FONT_GRAVITY = {
	South = Pango.Gravity.SOUTH,
	East  = Pango.Gravity.EAST,
	North = Pango.Gravity.NORTH,
	West  = Pango.Gravity.WEST,
	Auto  = Pango.Gravity.AUTO
}

--[[ Useful.monospace_font_list
=============================================================================================
 Pobiera czcionki o stałej szerokości.
 
 - layout : obiekt Pango.Layout.
========================================================================================== ]]

function Useful.MonospaceFontList( layout )
	-- zwróć istniejącą listę
	if Useful.monospace_fonts ~= nil then
		return Useful.monospace_fonts
	end
	
	-- utwórz nową listę czcionek
	Useful.monospace_fonts = {}

	-- wyszukaj czcionek o stałej szerokości
	for key, val in pairs(layout:get_context():list_families()) do
		if val:is_monospace() then
			table.insert( Useful.monospace_fonts, val:get_name() )
		end
	end
	
	return Useful.monospace_fonts
end

function Useful.CreateFontDescription( name, options )
	if Useful.fonts == nil then
		Useful.fonts = {}
	end

	if type(options) ~= "table" or options.family == nil then
		return
	end

	local desc = Pango.FontDescription.new()

	-- rodzina
	if options.family ~= nil then
		Pango.FontDescription.set_family( desc, options.family )
	end
	-- styl czcionki
	if options.style ~= nil then
		Pango.FontDescription.set_style( desc, Useful.FONT_STYLE[options.style] )
	end
	-- wariant
	if options.variant ~= nil then
		Pango.FontDescription.set_variant( desc, Useful.FONT_VARIANT[options.variant] )
	end
	-- grubość
	if options.weight ~= nil then
		Pango.FontDescription.set_weight( desc, Useful.FONT_WEIGHT[options.weight] )
	end
	-- rozciągnięcie liter czcionki
	if options.stretch ~= nil then
		Pango.FontDescription.set_stretch( desc, Useful.FONT_STRETCH[options.stretch] )
	end
	-- rozmiar czcionki
	if options.size == nil and Pango.FontDescription.get_size( desc ) == 0 then
		Pango.FontDescription.set_size( desc, 12 * Pango.SCALE )
	elseif options.size ~= nil then
		Pango.FontDescription.set_size( desc, options.size * Pango.SCALE )
	end
	-- punkt grawitacji
	if options.gravity ~= nil then
		Pango.FontDescription.set_gravity( desc, Useful.FONT_GRAVITY[options.gravity] )
	end

	Useful.fonts[name] = desc
end

function Useful.GetFontDescription( name )
	if Useful.fonts == nil then
		return nil
	end
	return Useful.fonts[name]
end

--[[ Useful.timer
=============================================================================================
 Tworzenie czasomierza.
 W przypadku gdy został już utworzony, zwraca go.
 
 - timeout : co ile sekund zdarzenie "timeout" ma zostac wywoływane.
 - name    : unikalna nazwa czasomierza - używana do zwracania istniejących.

 - return : timer
========================================================================================== ]]

function Useful.Timer( timeout, name )
	if type(timeout) ~= "number" then
		return
	end
	
	-- utwórz tablice gdy brak
	if Useful.timers == nil then
		Useful.timers = {}
	end

	-- brak nazwy, sprawdzaj po wartościach
	if name ~= nil then
		if Useful.timers[name] ~= nil then
			return Useful.timers[name]
		end
		
		Useful.timers[name] = timer({ timeout = timeout })
		return Useful.timers[name]
	end

	-- sprawdzaj czasomierze po nazwach
	if Useful.timers[timeout] ~= nil then
		return Useful.timers[timeout]
	end
	
	Useful.timers[timeout] = timer({ timeout = timeout })
	return Useful.timers[timeout]
end

-- =================================================================================================
-- Kopiuje funkcje z jednego obiektu do drugiego.
-- 
-- @param object Obiekt kopiowany.
-- @param retval Obiekt do którego mają być skopiowane funkcje.
-- =================================================================================================

function Useful.RewriteFunctions( object, retval )
	for key, val in pairs(object) do
		if type(val) == "function" then
			retval[key] = val
		end
	end
end

function Useful.Ternary( val, first, second )
	if val then
		return first
	end
	return second
end

--[[ return
========================================================================================== ]]

return Useful
