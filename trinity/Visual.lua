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

local Theme   = require("beautiful")
local LGI     = require("lgi")
local GColor  = require("gears.color")
local Useful  = require("trinity.Useful")
local Visual  = {}

-- Przyleganie poziome dla tekstu.
-- =============================================================================
Visual.ALIGN_TYPE = {
	TopLeft      = 0x09,
	TopCenter    = 0x11,
	TopRight     = 0x21,
	MiddleLeft   = 0x0A,
	MiddleCenter = 0x12,
	MiddleRight  = 0x22,
	BottomLeft   = 0x0C,
	BottomCenter = 0x14,
	BottomRight  = 0x24,
	Left         = 0x0A,
	Right        = 0x22,
	Top          = 0x11,
	Bottom       = 0x14,
	Center       = 0x12
}

-- Przyleganie poziome dla obrazków.
-- =============================================================================
Visual.TEXT_ALIGN = {
	[0x08] = "LEFT",
	[0x10] = "CENTER",
	[0x20] = "RIGHT",
	[0x01] = 1,
	[0x02] = 2,
	[0x04] = 3
}

-- Przyleganie pionowe dla tekstu i obrazków.
-- =============================================================================
Visual.IMAGE_ALIGN = {
	[0x08] = 1,
	[0x10] = 2,
	[0x20] = 3,
	[0x01] = 1,
	[0x02] = 2,
	[0x04] = 3
}

-- zwężanie tekstu gdy jest za długi, wstawia trzykropek (...)
-- =============================================================================
Visual.ELLIPSIZE_TYPE = {
	None    = "NONE",       -- wyłączone
	Start   = "START",      -- trzykropek na początku
	Middle  = "MIDDLE",     -- trzykropek w środku
	End     = "END"         -- trzykropek na końcu
}

-- metoda zawijania tekstu
-- =============================================================================
Visual.WRAP_TYPE = {
	Word     = "WORD",      -- zawijanie po słowach
	Char     = "CHAR",      -- zawijanie po znakach
	WordChar = "WORD_CHAR"  -- zawijanie najpierw po słowach, potem po znakach
}

-- metoda powiększania obrazka
-- =============================================================================
Visual.IMAGE_SIZE_TYPE = {
	Original = 1, -- rysuj w oryginalnych rozmiarach
	Zoom     = 2, -- powiększaj lub pomniejszaj zachowując oryginalny format
	Cover    = 3, -- przykryj całą kontrolkę zachowując oryginalny format
	Contain  = 4  -- przykryj całą kontrolkę rozciągając obraz do jej rozmiaru
}

-- metoda uzupełniania pustej przestrzeni z obrazkiem w tle
-- =============================================================================
Visual.IMAGE_EXTEND_TYPE = {
	None     = "NONE",    -- nie uzupełniaj pustej przestrzeni
	Repeat   = "REPEAT",  -- powtarzaj obraz
	Reflect  = "REFLECT", -- powtarzaj obraz z użyciem odbicia lustrzanego
	Pad      = "PAD"      -- powtarzaj graniczne piksele obrazu
}

--[[
 * Inicjalizuje zmienne i funkcje wyglądu dla kontrolki.
 *
 * DESCRIPTION:
 *     Lista grup i argumentów możliwych do stylizacji:
 *         - background
 *             - back_color - kolor kontrolki
 *         - image
 *             - back_image - obraz w tle kontrolki
 *             - image_align - przyleganie obrazu do wybranej krawędzi
 *             - image_size - powiększanie obrazu
 *             - image_extend - uzupełnianie pustej przestrzeni
 *         - padding
 *             - padding - margines wewnętrzny
 *         - border
 *             - border_size - rozmiar ramki
 *             - border_color - kolor ramki
 *         - foreground
 *             - foreground - kolor czcionki
 *         - text
 *             - ellipsize - skracanie zbyt długiego tekstu
 *             - text_align - przyleganie tekstu do krawędzi kontrolki
 *             - wrap - zawijanie tekstu
 *             - markup - tekst w postaci Pango Markup
 *             - text - zwykły tekst do wyświetlenia
 * 
 * PARAMETERS:
 *     widget Element do stylizacji [automat].
 *     groups Grupy do stylizacji do których kontrolka może mieć dostęp.
 *     args   Argumenty przekazane podczas tworzenia kontrolki.
]]-- ===========================================================================
function Visual.initialize( widget, groups, args )
	local group = {}
	local index = 0

	if widget._vinited then
		return
	end
	if not widget._bounds then
		widget._bounds = { 0, 0, 0, 0, 0, 0 }
	end

	-- ustawienia ramki
	widget._border = {
		size    = { 0, 0, 0, 0 },
		color   = nil,
		visible = false
	}
	widget._image = {
		surface = nil,
		extend  = 1,
		size    = 2,
		halign  = 2,
		valign  = 2,
		dims    = { 0, 0 },
		scale   = { 0, 0 },
		scaledv = { 0, 0 }
	}
	-- ustawienia tekstu
	widget._text = {
		valign  = "LEFT",
		halign  = 2,
		font    = nil,
		lheight = 0,
		color   = nil
	}
	
	-- utwórz zmienne
	widget._vinited = true
	widget._padding = { 0, 0, 0, 0 }
	widget._bgcolor = nil

	-- wspólne funkcje
	widget.get_inner_bounds = Visual.get_inner_bounds
	widget.draw_visual      = Visual.draw_visual

	-- rozpoznaj style grupy
	for key, val in pairs(groups) do
		group[val] = true
	end
	
	-- kolor tła
	if group.background then
		widget.set_background = Visual.set_background
		widget:set_background( args.back_color, false )
	end
	-- obrazek w tle
	if group.image then
		widget.set_image        = Visual.set_image
		widget.set_image_align  = Visual.set_image_align
		widget.set_image_size   = Visual.set_image_size
		widget.set_image_extend = Visual.set_image_extend
		widget.calc_image_scale = Visual.calc_image_scale

		widget:set_image( args.back_image, false )
			:set_image_align( args.image_align or "Center", false )
			:set_image_size( args.image_size or "Zoom", false )
			:set_image_extend( args.image_extend or "None", false )
	end
	-- wcięcie
	if group.padding then
		widget.set_padding = Visual.set_padding
		widget:set_padding( args.padding or 0, false )
	end
	-- ramka
	if group.border then
		widget.set_border_size  = Visual.set_border_size
		widget.set_border_color = Visual.set_border_color

		widget:set_border_size( args.border_size or 0, false )
			:set_border_color( args.border_color, false )
	end
	-- kolor czcionki
	-- na pierwszy rzut oka może wydawać się nielogiczne oddzielanie koloru
	-- czionki od samej czcionki, jednak kolor czcionki jest dziedziczony
	-- np. układ może mieć możliwość ustawienia koloru czcionki ale nie tekstu
	if group.foreground then
		widget.set_foreground = Visual.set_foreground
		widget:set_foreground( args.foreground, false )
	end
	-- tekst
	if group.text then
		-- tworzenie obiektu tekstu
		if widget._cairo_layout == nil then
			widget._cairo_layout = LGI.Pango.Layout.new(
				LGI.PangoCairo.font_map_get_default():create_context()
			)
		end

		widget.set_text       = Visual.set_text
		widget.set_markup     = Visual.set_markup
		widget.set_font       = Visual.set_font
		widget.set_ellipsize  = Visual.set_ellipsize
		widget.set_text_align = Visual.set_text_align
		widget.set_wrap       = Visual.set_wrap
		widget.draw_text      = Visual.draw_text
		widget.calc_text_dims = Visual.calc_text_dims

		widget:set_font( args.font, false )
			:set_ellipsize( args.ellipsize  or "None", false )
			:set_text_align( args.text_align or "Left", false )
			:set_wrap( args.wrap or "WordChar", false )

		if type(args.markup) == "string" then
			widget:set_markup( args.markup, false )
		elseif type(args.text) == "string" then
			widget:set_text( args.text, false )
		end
	end
	return widget
end

--[[
 * Rysuje oprawę wizualną kontrolki używając biblioteki Cairo.
 *
 * PARAMETERS:
 *     widget Element do rysowania [automat].
 *     cr     Obiekt Cairo.
]]-- ===========================================================================
function Visual.draw_visual( widget, cr )
	if  not widget._border.visible and
		not widget._bgcolor and
		not widget._image.surface then
		return
	end

	local px, py = widget._bounds[1], widget._bounds[2]
	local width, height = widget._bounds[5], widget._bounds[6]

	-- nie rysuj gdy wymiary są zerowe
	if width <= 0 or height <= 0 then
		return
	end

	cr:save()
	
	-- tło w kolorze
	if widget._bgcolor then
		cr:set_source( widget._bgcolor )

		cr:rectangle( px, py, width, height )
		cr:fill()
	end

	-- obraz w tle
	if widget._image.surface then
		local offx, offy = 0, 0

		-- przyleganie poziome
		if widget._image.halign ~= 1 then
			offx = width - widget._image.scaledv[1]
			if widget._image.halign == 2 then
				offx = offx / 2
			end
		end
		-- przyleganie pionowe
		if widget._image.valign ~= 1 then
			offy = height - widget._image.scaledv[2]
			if widget._image.valign == 2 then
				offy = offy / 2
			end
		end

		-- skalowanie obrazu
		if widget._image.size ~= 1 then
			cr:scale( widget._image.scale[1], widget._image.scale[2] )

			cr:set_source_surface(
				widget._image.surface,
				(px + offx) / widget._image.scale[1],
				(py + offy) / widget._image.scale[2]
			)
			cr:rectangle(
				px / widget._image.scale[1],
				py / widget._image.scale[2],
				width / widget._image.scale[1],
				height / widget._image.scale[2]
			)
			cr:clip()
		-- obraz w oryginale
		else
			cr:set_source_surface( widget._image.surface, px + offx, py + offy )
			cr:rectangle( px, py, width, height )
			cr:clip()
		end

		-- uzupełnianie pustej przestrzeni
		LGI.cairo.Pattern.set_extend(
			cr:get_source(), LGI.cairo.Extend[widget._image.extend]
		)

		cr:paint()
	end

	-- sprawdź czy na pewno trzeba rysować ramkę
	if widget._border.visible then
		local size = widget._border.size
		cr:set_source( widget._border.color )

		-- lewo (od góry do dołu)
		if size[1] then
			cr:move_to( px, py )
			cr:rel_line_to( 0, height )
			cr:rel_line_to( size[1], -size[4] )
			cr:rel_line_to( 0, -height + size[2] + size[4] )
			cr:close_path()
		end
		-- góra (od lewej do prawej)
		if size[2] then
			cr:move_to( px, py )
			cr:rel_line_to( width, 0 )
			cr:rel_line_to( -size[3], size[2] )
			cr:rel_line_to( -width + size[1] + size[3], 0 )
			cr:close_path()
		end
		-- prawo (od góry do dołu)
		if size[3] then
			cr:move_to( px + width, py )
			cr:rel_line_to( 0, height )
			cr:rel_line_to( -size[3], -size[4] )
			cr:rel_line_to( 0, -height + size[4] + size[2] )
			cr:close_path()
		end
		-- dół (od prawej do lewej)
		if size[4] then
			cr:move_to( px, py + height )
			cr:rel_line_to( width, 0 )
			cr:rel_line_to( -size[3], -size[4] )
			cr:rel_line_to( -width + size[3] + size[1], 0 )
			cr:close_path()
		end
		
		cr:fill()
	end
	
	cr:restore()
end

--[[
 * Oblicza wymiary kontrolki po uwzględnieniu wielkości ramki i wcięcia.
 *
 * PARAMETERS:
 *     widget Element którego wymiary mają być obliczone [automat].
 *
 * RETURNS:
 *     Pozycję X, Y, szerokość i wysokość kontrolki.
]]-- ===========================================================================
function Visual.get_inner_bounds( widget )
	local padding = widget._padding
	local bounds  = widget._bounds
	
	-- zwróć nowe wymiary i współrzędne x,y
	return bounds[1] + padding[1],
		   bounds[2] + padding[2],
		   bounds[5] - padding[1] - padding[3],
		   bounds[6] - padding[2] - padding[4]
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: PADDING
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Ustawia wewnętrzny margines elementu.
 *
 * DESCRIPTION:
 *     Wewnętrzny margines to nic innego jak pusta przestrzeń w kontrolce.
 *     Używany jest do tworzenia odstępów pomiędzy krawędzią kontrolki a
 *     kontrolkami wewnętrznymi lub tekstem.
 *     
 *     Margines wewnętrzny nie działa na tło kontrolki i liczony jest od
 *     końca ramki (gdy ramka ma 5px, margines 2px, odstęp będzie równy 7px)
 *
 *     Odstęp można ustawić różny dla każdej strony kontrolki, podając jako
 *     wartość argumentu padding tablicę czteroelementową.
 *     Schemat tablicy jest następujący: { lewa, góra, prawa, dół }.
 *     Do funkcji można podać również tablicę z dwiema wartościami, które
 *     będą uzupełnione nstępująco: { 1, 2, 1, 2 }.
 *
 *     Zamiast tablicy można podać liczbę, która będzie oznaczała odstęp dla
 *     każdej strony kontrolki.
 *
 * CODE:
 *     -- wszystkie strony kontrolki mają to samo wcięcie
 *     widget:set_padding( 4 )
 *     -- prawa i lewa ma wcięcie 4, góra i dół 8
 *     widget:set_padding( {4, 8} )
 *     -- tutaj każda strona ma inne wcięcie
 *     widget:set_padding( {2, 4, 6, 8} )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     padding Wewnętrzny margines elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_padding( widget, padding, refresh )
	size = (type(size) == "number" or type(size) == "table")
		and size
		or  0

	-- zamień na tablicę jeżeli zachodzi taka potrzeba
	if type(padding) == "number" then
		padding = { padding, padding, padding, padding }
	elseif #padding == 2 then
		padding = { padding[1], padding[2], padding[1], padding[2] }
	elseif #padding == 4 then
		padding = { padding[1], padding[2], padding[3], padding[4] }
	else
		padding = { 0, 0, 0, 0 }
	end
	
	local obsize = widget._border.size

	-- zapisz wcięcie z uwzględnieniem ramki
	widget._padding = {
		padding[1] + obsize[1],
		padding[2] + obsize[2],
		padding[3] + obsize[3],
		padding[4] + obsize[4]
	}
	
	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: BACKGROUND
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Ustawia kolor tła kontrolki.
 *
 * DESCRIPTION:
 *     Szczegóły dotyczące tego, jakie wartości przyjmuje funkcja znajdują
 *     się na stronie AwesomeWM w sekcji gears.color.
 *     Najbardziej popularnym formatem koloru jest format HEX (np. #0125AA).
 *
 * CODE:
 *     -- zwykły kolor w formacie HEX
 *     widget:set_background( "#0125AA" )
 *     -- gradient radialny
 *     widget:set_background({
 *         type = "radial",
 *         from = { 50, 50, 10 },
 *         to = { 55, 55, 30 },
 *         stops = {
 *             { 0, "#ff0000" },
 *             { 0.5, "#00ff00" },
 *             { 1, "#0000ff" }
 *         }
 *     })
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     color   Kolor elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_background( widget, color, refresh )
	widget._bgcolor = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: IMAGE
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Ustawia obrazek dla tła kontrolki.
 *
 * DESCRIPTION:
 *     Funkcja jako argument przyjmuje ścieżkę do obrazka.
 *     Może również przyjmować obiekt załadowanego wcześniej obrazka poprzez
 *     użycie funkcji z biblioteki gears zwracających obiekt Surface.
 *
 * CODE:
 *     widget:set_image( "/home/user/images/sample.jpg" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     image   Ścieżka do obrazka lub obiekt Surface.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_image( widget, image, refresh )
	-- ściezka do obrazka - załaduj obrazek
	if type(image) == "string" then
		image = Useful.load_image( image )
	end
	if image == nil then
		widget._image.dims    = { 0, 0 }
		widget._image.scale   = { 0, 0 }
		widget._image.scaledv = { 0, 0 }
		widget._image.surface = nil

		return widget
	end

	-- zapisz wymiary obrazka
	widget._image.dims    = { image.width, image.height }
	widget._image.scale   = { image.width, image.height }
	widget._image.scaledv = { image.width, image.height }
	widget._image.surface = image

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia przyleganie obrazka w tle do kontrolki.
 *
 * DESCRIPTION:
 *     Jako argument funkcja przyjmuje jedną z wartości Visual.ALIGN_TYPE.
 *     Wartość przylegania jest ignorowana gdy obrazek przykrywa całą kontrolkę
 *     lub jest ustawiony na typ powiększenia "Contains".
 *
 * CODE:
 *     widget:set_image_align( "BottomRight" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     align   Typ przylegania obrazu w tle do kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_image_align( widget, align, refresh )
	if not align or not Visual.ALIGN_TYPE[align] then
		return widget
	end
	local aligntype = Visual.ALIGN_TYPE[align]

	widget._image.valign = Visual.IMAGE_ALIGN[aligntype & 0x07] or 1
	widget._image.halign = Visual.IMAGE_ALIGN[aligntype & 0x70] or 1

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia typ rozciągania obrazu w tle kontrolki.
 *
 * DESCRIPTION:
 *     Jako argument funkcja przyjmuje jedną z wartości Visual.IMAGE_SIZE_TYPE.
 *     Niezależnie od ustawienia obraz jest obcinany jeżeli wychodzi poza
 *     granice wymiarów kontrolki.
 *
 * CODE:
 *     widget:set_image_size( "Contains" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     size    Typ rozciągania obrazu w tle kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_image_size( widget, size, refresh )
	widget._image.size = Visual.IMAGE_SIZE_TYPE[size] or "Zoom"

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia typ powtarzania obrazu w tle kontrolki.
 *
 * DESCRIPTION:
 *     Gdy obraz nie jest wyświetlany na całej kontrolce, można zastosować
 *     na nim jedną z technik powtarzania - rozszerzania obrazu na kontrolce
 *     bez modyfikacji powiększenia lub formatu obrazu.
 *     Lista trybów powtarzania znajduje się w Visual.IMAGE_EXTEND_TYPE.
 *
 * CODE:
 *     widget:set_image_extend( "Reflect" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     extend  Typ powtarzania obrazu w tle kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_image_extend( widget, extend, refresh )
	widget._image.extend = Visual.IMAGE_EXTEND_TYPE[extend] or "None"

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Oblicza wymiary obrazka w tle z zastosowaniem wybranego skalowania.
 *
 * PARAMETERS:
 *     widget Element do rysowania [automat].
 *     width  Szerokość do wykorzystania lub -1.
 *     height Wysokość do wykorzystania lub -1.
 *
 * RETURNS:
 *     Szerokość i wysokość obrazka po przeskalowaniu.
]]-- ===========================================================================
function Visual.calc_image_scale( widget, width, height )
	local new_width  = width
	local new_height = height
	
	-- resetuj ustawienia skalowania
	widget._image.scale   = { 1.0, 1.0 }
	widget._image.scaledv = {
		widget._image.dims[1],
		widget._image.dims[2]
	}

	-- wymiary mniejsze lub równe zero lub format ma pozostać bez zmiany
	if width <= 0 or height <= 0 or widget._image.size == 1 then
		return widget._image.dims
	end

	local scalew = width / widget._image.dims[1]
	local scaleh = height / widget._image.dims[2]

	-- powiększanie lub pomniejszanie z uwzględnieniem formatu
	if widget._image.size == 2 then
		if scalew > scaleh then
			widget._image.scale = { scaleh, scaleh }
		else
			widget._image.scale = { scalew, scalew }
		end
	-- nakrywanie kontrolki z uwzględnieniem formatu
	elseif widget._image.size == 3 then
		if scalew > scaleh then
			widget._image.scale = { scalew, scalew }
		else
			widget._image.scale = { scaleh, scaleh }
		end
	-- rozciąganie obrazka na całą kontrolkę
	else
		widget._image.scale = { scalew, scaleh }
	end

	widget._image.scaledv = {
		widget._image.dims[1] * widget._image.scale[1],
		widget._image.dims[2] * widget._image.scale[2]
	}

	return widget._image.scaledv[1], widget._image.scaledv[2]
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: FOREGROUND
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Ustawia kolor czcionki wyświetlanej w kontrolce lub kontrolkach potomnych.
 *
 * DESCRIPTION:
 *     Szczegóły dotyczące tego, jakie wartości przyjmuje funkcja znajdują
 *     się na stronie AwesomeWM w sekcji gears.color.
 *     Najbardziej popularnym formatem koloru jest format HEX (np. #0125AA).
 *
 * CODE:
 *     widget:set_foreground( "#0125AA" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     color   Kolor czcionki tekstu w elemencie.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_foreground( widget, color, refresh )
	widget._text.color = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: BORDER
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Ustawia rozmiar ramki rysowanej dla kontrolki.
 *
 * DESCRIPTION:
 *     Rozmiar ramki nie przesuwa tła kontrolki, jest rysowany na nim, jednak
 *     ma wpływ na margines wewnętrzny który jest liczony od końca ramki.
 *     
 *     Rozmiar ramki może być różny dla każdej strony kontrolki, podając jako
 *     wartość argumentu padding tablicę czteroelementową.
 *     Schemat tablicy jest następujący: { lewa, góra, prawa, dół }.
 *     Do funkcji można podać również tablicę z dwiema wartościami, które
 *     będą uzupełnione nstępująco: { 1, 2, 1, 2 }.
 *
 *     Zamiast tablicy można podać liczbę, która będzie oznaczała odstęp dla
 *     każdej strony kontrolki.
 *
 * CODE:
 *     widget:set_border_size( 5 )
 *     widget:set_border_size( {5, 2} )
 *     widget:set_border_size( {1, 4, 5, 2} )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     size    Rozmiar ramki w postaci cyfry lub tablicy cyfr.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_border_size( widget, size, refresh )
	size = (type(size) == "number" or type(size) == "table")
		and size
		or  0

	-- stary rozmiar ramki
	local obsize = {
		widget._border.size[1],
		widget._border.size[2],
		widget._border.size[3],
		widget._border.size[4]
	}
	-- aktualne wcięcie
	local owpadd = widget._padding
	
	-- cała ramka ma taką samą grubość
	if type(size) == "number" then
		widget._border.size = { size, size, size, size }
	-- z dwóch wartości tworzy 2 grupy - lewo=prawo, góra=dół
	elseif #size == 2 then
		widget._border.size = { size[1], size[2], size[1], size[2] }
	-- każdy bok może mieć inną długość
	elseif #size == 4 then
		widget._border.size = { size[1], size[2], size[3], size[4] }
	else
		widget._border.size = { 0, 0, 0, 0 }
	end
	
	-- przelicz ponownie wcięcia
	widget._padding = {
		owpadd[1] - obsize[1] + widget._border.size[1],
		owpadd[2] - obsize[2] + widget._border.size[2],
		owpadd[3] - obsize[3] + widget._border.size[3],
		owpadd[4] - obsize[4] + widget._border.size[4]
	}
	
	-- sprawdź czy ramka będzie rysowana
	if (widget._border.size[1] > 0 or widget._border.size[2] > 0 or
		widget._border.size[3] > 0 or widget._border.size[4] > 0) and
		widget._border.color then
		widget._border.visible = true
	end

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia kolor ramki.
 *
 * DESCRIPTION:
 *     Nie można na razie ustawić koloru ramki dla każdej strony kontrolki.
 *     Aktualnie ramka jest w jednym kolorze.
 *     Szczegóły dotyczące tego, jakie wartości przyjmuje funkcja znajdują
 *     się na stronie AwesomeWM w sekcji gears.color.
 *     Najbardziej popularnym formatem koloru jest format HEX (np. #0125AA).
 *
 * CODE:
 *     widget:set_border_color( "#0125AA" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     color   Kolor ramki elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_border_color( widget, color, refresh )
	widget._border.visible = false
	widget._border.color   = color
		and GColor( color )
		or  nil
	
	-- sprawdź czy ramka będzie rysowana
	if (widget._border.size[1] > 0 or widget._border.size[2] > 0 or
		widget._border.size[3] > 0 or widget._border.size[4] > 0) and
		widget._border.color then
		widget._border.visible = true
	end

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

-- /////////////////////////////////////////////////////////////////////////////
-- // GROUP: TEXT
-- /////////////////////////////////////////////////////////////////////////////

--[[
 * Zmienia tekst wyświetlany w kontrolce.
 *
 * CODE:
 *     widget:set_text( "Example" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     text    Tekst do wyświetlenia.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_text( widget, text, refresh )
	if widget._cairo_layout.text == text then
		return widget
	end

	widget._cairo_layout.text       = text         
	widget._cairo_layout.attributes = nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Zmienia tekst wyświetlany w kontrolce używając składni Pango markup.
 *
 * DESCRIPTION:
 *     Tekst w formacie Pango markup (podobny do HTML).
 *     Na początku jest parsowany a potem dopisywany do kontrolki jako
 *     zwykły tekst z atrybutami utworzonymi podczas parsowania.
 * 
 * CODE:
 *     widget:set_markup( "<b>E</b><s>x</s>am<i>ple</i>" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     text    Tekst do wyświetlenia.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_markup( widget, text, refresh )
	local attr, parsed = Pango.parse_markup( text, -1, 0 )
	if not attr then
		error( parsed )
	end

	if widget._cairo_layout.text == parsed then
		return widget
	end

	widget._cairo_layout.text       = parsed
	widget._cairo_layout.attributes = attr

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Zmienia czcionkę używaną przy wyświetlaniu tekstu.
 *
 * DESCRIPTION:
 *     Jako argument funkcja może przyjąć opis czcionki w postaci słownej,
 *     np. Times New Roman 8, lub w postaci zapisanego obiektu utworzonej
 *     wcześniej czcionki (taką możliwość oferują funkcje z biblioteki
 *     Useful - CreateFontDescription i GetFontDescription).
 * 
 * CODE:
 *     widget:set_font( "Arial 8" )
 *     Useful.CreateFontDescription("DJV8", {
 *         family: "DejaVu Sans",
 *         size: 8,
 *         style: "Italic",
 *         weight: "Bold"
 *     })
 *     widget:set_font( Useful.GetFontDescription("DJV8") )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     font    Czcionka do ustawienia podczas wyświetlania tekstu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_font( widget, font, refresh )
	local fobj = type(font) ~= "userdata"
		and Theme.get_font(font)
		or  font

	widget._cairo_layout:set_font_description( fobj )
	
	-- wymiary do sprawdzenia (-1 - nieokreślone)
	widget._cairo_layout.width  = LGI.Pango.units_from_double( -1 )
	widget._cairo_layout.height = LGI.Pango.units_from_double( -1 )
	
	-- pobierz wymiary tekstu
	local ink, logical = widget._cairo_layout:get_pixel_extents()
	
	-- zapisz wysokość linii tekstu
	widget._text.lheight = logical.height
	widget._text.font    = fobj

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Skraca tekst gdy nie mieści się w kontenerze, wstawiając trzykropek.
 *
 * DESCRIPTION:
 *     Gdy tekst nie mieści się w kontenerze w miejsce tego który wystaje poza
 *     wstawiany jest trzykropek.
 *     Miejsce jego położenia definiuje jedna z wartości Vsiual.ELLIPSIZE_TYPE.
 * 
 * CODE:
 *     widget:set_ellipsizeType( "Middle" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     type    Jedna z metod wstawiania trzykropka w zdaniu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_ellipsize( widget, type, refresh )
	widget._cairo_layout:set_ellipsize( Visual.ELLIPSIZE_TYPE[type] or "END" )

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia przyleganie tekstu wyświetlanego w kontrolce.
 *
 * DESCRIPTION:
 *     Jako argument funkcja przyjmuje jedną z wartości Visual.ALIGN_TYPE.
 *     Domyślnie tekst przylega do lewej strony na środku.
 *
 * CODE:
 *     widget:set_text_align( "BottomRight" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     color   Typ przylegania tekstu w kontrolce.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_text_align( widget, align, refresh )
	if align == nil or Visual.ALIGN_TYPE[align] == nil then
		return
	end
	local aligntype = Visual.ALIGN_TYPE[align]

	widget._text.valign = Visual.TEXT_ALIGN[aligntype & 0x07] or 2
	widget._text.halign = Visual.TEXT_ALIGN[aligntype & 0x70] or "LEFT"
	widget._cairo_layout:set_alignment( widget._text.halign )

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Ustawia metodę zawijania tekstu.
 *
 * DESCRIPTION:
 *     Jako argument funkcja przyjmuje jedną z wartości Visual.WRAP_TYPE.
 *     Domyślnie tekst zawijany jest najpierw po słowach a potem po znakach
 *     w przypadku gdy słowo nie mieści się w kontenerze.
 *
 * CODE:
 *     widget:set_wrap( "WrapChar" )
 *
 * PARAMETERS:
 *     widget  Element do stylizacji [automat].
 *     wrap    Typ zawijania tekstu w kontrolce.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual.set_wrap( widget, wrap, refresh )
	widget._cairo_layout:set_wrap( Visual.WRAP_TYPE[wrap] or "WORD_CHAR" )

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[
 * Rysuje tekst na kontrolce z uwzględnieniem ustawionych opcji.
 *
 * CODE:
 *     widget:set_text_align( "BottomRight" )
 *
 * PARAMETERS:
 *     widget Element do rysowania [automat].
 *     cr     Obiekt Cairo.
]]-- ===========================================================================
function Visual.draw_text( widget, cr )
	-- pobierz krawędzie kontrolki
	local x, y, width, height = widget:get_inner_bounds()

	-- przesunięcie w pionie
	local offset = y

	-- oblicz przyleganie pionowe
	if height ~= widget._text.lheight then
		if widget._text.valign == 2 then
			offset = y + ((height - widget._text.lheight) / 2)
		elseif widget._text.valign == 3 then
			offset = y + height - widget._text.lheight
		end
	end
	
	cr:move_to( x, offset )
	
	if widget._text.color then
		cr:save()
		cr:set_source( widget._text.color )
		cr:show_layout( widget._cairo_layout )
		cr:restore()
	else
		cr:show_layout( widget._cairo_layout )
	end
end

--[[
 * Oblicza wymiary pola tekstowego.
 *
 * PARAMETERS:
 *     widget Element do obliczenia wymiarów [automat].
 *     width  Szerokość do wykorzystania lub -1.
 *     height Wysokość do wykorzystania lub -1.
 *
 * RETURNS:
 *     Szerokość i wysokość pola tekstowego w kontrolce.
]]-- ===========================================================================
function Visual.calc_text_dims( widget, width, height )
	-- przelicz jednostki
	widget._cairo_layout.width  = LGI.Pango.units_from_double( width )
	widget._cairo_layout.height = LGI.Pango.units_from_double( height )
	
	-- pobierz wymiary tekstu
	local ink, logical = widget._cairo_layout:get_pixel_extents()
	widget._text.lheight = logical.height
	
	-- zwróć wymiary
	return logical.width, logical.height
end

return Visual
