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

local Pango   = require("lgi").Pango
local Surface = require("gears.surface")
local Useful  = {}

-- Styl czcionki.
-- =============================================================================
Useful.FONT_STYLE = {
	Normal  = Pango.Style.NORMAL,
	Italic  = Pango.Style.ITALIC,
	Oblique = Pango.Style.OBLIQUE
}

-- Wariant czcionki (jeżeli czcionka wspiera).
-- =============================================================================
Useful.FONT_VARIANT = {
	Normal    = Pango.Variant.NORMAL,
	SmallCaps = Pango.Variant.SMALL_CAPS
}

-- Grubość czcionki.
-- =============================================================================
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

-- Rozciągnie tekstu (jeżeli czcionka wspiera).
-- =============================================================================
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

-- Grawitacja czcionki (w którą stronę litery będą rysowane).
-- =============================================================================
Useful.FONT_GRAVITY = {
	South = Pango.Gravity.SOUTH,
	East  = Pango.Gravity.EAST,
	North = Pango.Gravity.NORTH,
	West  = Pango.Gravity.WEST,
	Auto  = Pango.Gravity.AUTO
}

--[[
 * Tworzy listę czcionek o stałej szerokości zainstalowanych w systemie.
 *
 * PARAMETERS:
 *     layout Obiekt Pango.Layout
 *
 * RETURNS:
 *     Lista czcionek o stałej szerokości.
]]-- ===========================================================================
function Useful.MonospaceFontList( layout )
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

--[[
 * Tworzy obiekt zawierający opis czcionki.
 *
 * DESCRIPTION:
 *     Opis czcionki składa się z kilku elementów.
 *     Spośród wszystkich należy podać przynajmniej rodzinę czcionki.
 *     Lista możliwych opcji z których tworzony jest opis:
 *         - family - rodzina czcionki
 *         - style - jeden z Useful.FONT_STYLE
 *         - variant - jeden z Useful.FONT_VARIANT
 *         - weight - jeden z Useful.FONT_WEIGHT
 *         - stretch - jeden z Useful.FONT_STRETCH
 *         - size - rozmiar czcionki
 *         - gravity - jeden z Useful.FONT_GRAVITY
 *     Każdy opis jest zapisywany i identyfikowany przez podawaną nazwę.
 *     Można go potem pobrać używająć funkcji Useful.GetFontDescription.
 * 
 * PARAMETERS:
 *     name    Nazwa pod którą zapisany będzie opis czcionki.
 *     options Opcje używane podczas tworzenia obiektu opisu czcionki.
]]-- ===========================================================================
function Useful.CreateFontDescription( name, options )
	if not Useful.fonts then
		Useful.fonts = {}
	end

	if type(options) ~= "table" or not options.family then
		return
	end

	local desc = Pango.FontDescription.new()

	-- rodzina
	if options.family then
		Pango.FontDescription.set_family(
			desc,
			options.family
		)
	end
	-- styl czcionki
	if options.style then
		Pango.FontDescription.set_style(
			desc,
			Useful.FONT_STYLE[options.style]
		)
	end
	-- wariant
	if options.variant then
		Pango.FontDescription.set_variant(
			desc,
			Useful.FONT_VARIANT[options.variant]
		)
	end
	-- grubość
	if options.weight then
		Pango.FontDescription.set_weight(
			desc,
			Useful.FONT_WEIGHT[options.weight]
		)
	end
	-- rozciągnięcie liter czcionki
	if options.stretch then
		Pango.FontDescription.set_stretch(
			desc,
			Useful.FONT_STRETCH[options.stretch]
		)
	end
	-- rozmiar czcionki, domyślnie 12
	Pango.FontDescription.set_size(
		desc,
		options.size
			and options.size * Pango.SCALE
			or  12 * Pango.SCALE
	)
	-- punkt grawitacji
	if options.gravity then
		Pango.FontDescription.set_gravity(
			desc,
			Useful.FONT_GRAVITY[options.gravity]
		)
	end

	Useful.fonts[name] = desc
end

--[[
 * Pobiera obiekt opisu zapisany wcześniej pod podaną w argumencie nazwą.
 * 
 * PARAMETERS:
 *     name Nazwa pod którą został zapisany obiekt opisu czcionki.
 *
 * RETURNS:
 *     Obiekt opisu czcionki lub nil gdy brak.
]]-- ===========================================================================
function Useful.GetFontDescription( name )
	if Useful.fonts == nil then
		return nil
	end
	return Useful.fonts[name]
end

--[[
 * Tworzy obiekt wywołujący sygnał po upływie podanej ilości czasu.
 *
 * DESCRIPTION:
 *     Do licznika można podpiąć zdarzenie, które będzie wywoływane po upływie
 *     określonego czasu podawanego w sekundach.
 *     
 *     Przed utworzeniem nowego licznika funkcja sprawdza czy nie został już
 *     wcześniej utworzony licznik wywoływany z takim samym odstępem.
 *     
 *     Każdy licznik można nazwać, podając jego nazwę w drugim parametrze.
 *     Takim sposobem można utworzyć kilka liczników zawierających ten sam
 *     interwał czasowy.
 *
 *     Podanie innej wartości dla odstępu ale tej samej nazwy nie utworzy nowego
 *     licznika a zwróci stary z oryginalnym interwałem czasowym!
 *
 * PARAMETERS:
 *     timeout Odstęp czasu po jakim sygnał ma został wywołany.
 *     name    Nazwa pod którą ma zostać zapisany czasomierz.
 *
 * RETURNS:
 *     Obiekt utworzonego licznika.
]]-- ===========================================================================
function Useful.Timer( timeout, name )
	if type(timeout) ~= "number" then
		return
	end
	
	-- utwórz tablice gdy brak
	if not Useful.timers then
		Useful.timers = {}
	end

	-- brak nazwy, sprawdzaj po wartościach
	if name then
		if Useful.timers[name] then
			return Useful.timers[name]
		end
		
		Useful.timers[name] = timer({ timeout = timeout })
		return Useful.timers[name]
	end

	-- sprawdzaj czasomierze po nazwach
	if Useful.timers[timeout] then
		return Useful.timers[timeout]
	end
	
	Useful.timers[timeout] = timer({ timeout = timeout })
	return Useful.timers[timeout]
end

--[[
 * Przypisuje funkcje z jednego obiektu do drugiego.
 *
 * PARAMETERS:
 *     object Obiekt z którego funkcje będą kopiowane.
 *     retval Obiekt do którego funkcje mają być kopiowane.
]]-- ===========================================================================
function Useful.RewriteFunctions( object, retval )
	for key, val in pairs(object) do
		if type(val) == "function" then
			retval[key] = val
		end
	end
end

--[[
 * Wczytuje obraz z pliku i zwraca go.
 *
 * PARAMETERS:
 *     path Ścieżka obrazu do wczytania.
 *
 * RETURNS:
 *     Obiekt surface zawierający wczytany obraz lub wartość false.
]]-- ===========================================================================
function Useful.LoadImage( path )
	local success, result = pcall( Surface.load, path )

	if not success then
		error( "Error while reading '" .. path .. "': " .. result )
		return false
	end
	return result
end

return Useful
