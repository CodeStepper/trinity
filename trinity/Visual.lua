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
local Screen  = require("awful").screen
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
Visual.IMAGE_SIZING_TYPE = {
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
 *             - background - kolor kontrolki
 *         - image
 *             - image - obraz w tle kontrolki
 *             - image_align - przyleganie obrazu do wybranej krawędzi
 *             - image_sizing - powiększanie obrazu
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
function Visual:initialize( groups, args )
	local group = {}
	local index = 0

	if self._V then
		return
	end
	-- informacje o otoczeniu kontrolki
	if not self.Bounds then
		self.Bounds = { 0, 0, 0, 0, 0, 0 }
	end
	if not self._Screen then
		self._Screen = 1
	end

	-- mnożnik DPI, domyślnie 96 = 1.0
	if not Visual.DPIFactor then
		Visual.DPIFactor = {}
		Screen.connect_for_each_screen( function(s)
			idx = s.index
			Visual.DPIFactor[idx] = Theme.xresources.get_dpi( idx ) / 96
		end )
	end

	-- tablica z ustawieniami wizualnymi kontrolki
	self.V = {
		-- dane na temat ramki
		BOR = {
			Width   = { 0, 0, 0, 0 },
			Color   = nil,
			Visible = false
		},

		-- dane obrazka
		IMG = {
			Surface = nil,
			Extend  = "NONE",
			Sizing  = 2,
			HAlign  = 2,
			VAlign  = 2,
			Dims    = { 0, 0 },
			SFactor = { 1.0, 1.0 },
			Scaled  = { 0, 0 }
		},

		-- informacje o tekście
		TXT = {
			HAlign  = 2,
			VAlign  = "LEFT",
			Font    = nil,
			LHeight = 0,
			Color   = nil,
			Cairo   = nil
		},

		Padding    = { 0, 0, 0, 0 },
		Background = nil,

		-- oryginalne wartości przed skalowaniem na DPI
		OV = {
			BOR_Width   = { 0, 0, 0, 0 },
			Padding     = { 0, 0, 0, 0 },
			TXT_LHeight = 0
		}
	}

	-- wspólne funkcje
	self.get_inner_bounds = Visual.get_inner_bounds
	self.draw_visual      = Visual.draw_visual

	-- rozpoznaj style grupy
	for key, val in ipairs(groups) do
		group[val] = true
	end
	
	-- kolor tła
	if group.background then
		self.set_background = Visual.set_background
		self:set_background( args.background, false )
	end

	-- obrazek w tle
	if group.image then
		self.set_image        = Visual.set_image
		self.set_image_align  = Visual.set_image_align
		self.set_image_sizing = Visual.set_image_sizing
		self.set_image_extend = Visual.set_image_extend
		self.calc_image_scale = Visual.calc_image_scale

		self:set_image       ( args.image,                    false )
			:set_image_align ( args.image_align  or "Center", false )
			:set_image_sizing( args.image_sizing or "Zoom",   false )
			:set_image_extend( args.image_extend or "None",   false )
	end
	-- wcięcie
	if group.padding then
		self.set_padding = Visual.set_padding
		self:set_padding( args.padding or 0, false )
	end
	-- ramka
	if group.border then
		self.set_border_width = Visual.set_border_width
		self.set_border_color = Visual.set_border_color

		self:set_border_width( args.border_width or 0, false )
			:set_border_color( args.border_color,      false )
	end
	-- kolor czcionki
	-- układ może mieć możliwość ustawienia koloru czcionki ale nie tekstu
	if group.foreground then
		self.set_foreground = Visual.set_foreground
		self:set_foreground( args.foreground, false )
	end
	-- tekst
	if group.text then
		self.V.TXT.Cairo = LGI.Pango.Layout.new(
			LGI.PangoCairo.font_map_get_default():create_context()
		)

		self.set_text       = Visual.set_text
		self.set_markup     = Visual.set_markup
		self.set_font       = Visual.set_font
		self.set_ellipsize  = Visual.set_ellipsize
		self.set_text_align = Visual.set_text_align
		self.set_wrap       = Visual.set_wrap
		self.draw_text      = Visual.draw_text
		self.calc_text_dims = Visual.calc_text_dims

		self:set_font      ( args.font,                     false )
			:set_ellipsize ( args.ellipsize  or "None",     false )
			:set_text_align( args.text_align or "Left",     false )
			:set_wrap      ( args.wrap       or "WordChar", false )

		if args.markup then
			self:set_markup( args.markup, false )
		elseif args.text then
			self:set_text( args.text, false )
		end
	end
	return self
end

--[[
 * Rysuje oprawę wizualną kontrolki używając biblioteki Cairo.
 *
 * PARAMETERS:
 *     cr Obiekt Cairo.
]]-- ===========================================================================
function Visual:draw_visual( cr )
	if  not self.V.BOR.Visible and
		not self.V.Background and
		not self.V.IMG.Surface then
		return
	end

	local px, py, width, height =
		self.Bounds[1],
		self.Bounds[2],
		self.Bounds[5],
		self.Bounds[6]

	-- nie rysuj gdy wymiary są zerowe
	if width <= 0 or height <= 0 then
		return
	end

	cr:save()
	
	-- tło w kolorze
	if self.V.Background then
		cr:set_source( self.V.Background )

		cr:rectangle( px, py, width, height )
		cr:fill()
	end

	-- obraz w tle
	if self.V.IMG.Surface then
		local offx, offy = 0, 0

		-- przyleganie poziome
		if self.V.IMG.HAlign ~= 1 then
			offx = width - self.V.IMG.Scaled[1]
			if self.V.IMG.HAlign == 2 then
				offx = offx / 2
			end
		end
		-- przyleganie pionowe
		if self.V.IMG.VAlign ~= 1 then
			offy = height - self.V.IMG.Scaled[2]
			if self.V.IMG.VAlign == 2 then
				offy = offy / 2
			end
		end

		-- skalowanie obrazu
		if self.V.IMG.Sizing ~= 1 then
			cr:scale( self.V.IMG.SFactor[1], self.V.IMG.SFactor[2] )

			cr:set_source_surface(
				self.V.IMG.Surface,
				(px + offx) / self.V.IMG.SFactor[1],
				(py + offy) / self.V.IMG.SFactor[2]
			)
			cr:rectangle(
				px / self.V.IMG.SFactor[1],
				py / self.V.IMG.SFactor[2],
				width / self.V.IMG.SFactor[1],
				height / self.V.IMG.SFactor[2]
			)
			cr:clip()
		-- obraz w oryginale
		else
			cr:set_source_surface( self.V.IMG.Surface, px + offx, py + offy )
			cr:rectangle( px, py, width, height )
			cr:clip()
		end

		-- uzupełnianie pustej przestrzeni
		LGI.cairo.Pattern.set_extend(
			cr:get_source(), LGI.cairo.Extend[self.V.IMG.Extend]
		)

		cr:paint()
	end

	-- sprawdź czy na pewno trzeba rysować ramkę
	if self.V.BOR.Visible then
		local size = self.V.BOR.Width
		cr:set_source( self._B.BOR.Color )

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
 * RETURNS:
 *     Pozycję X, Y, szerokość i wysokość kontrolki.
]]-- ===========================================================================
function Visual:get_inner_bounds()
	local padding = self.V.Padding
	local bounds  = self.Bounds
	
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
 *     padding Wewnętrzny margines elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_padding( padding, refresh )
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
	
	local obsize = self.V.OV.BOR_Width

	-- zapisz wcięcie z uwzględnieniem ramki
	self.V.OV.Padding = {
		padding[1] + obsize[1],
		padding[2] + obsize[2],
		padding[3] + obsize[3],
		padding[4] + obsize[4]
	}
	-- rzeczywiste wcięcie
	local dpifactor = Visual.DPIFactor[self._Screen]
	self.V.Padding = {
		self.V.OV.Padding[1] * dpifactor,
		self.V.OV.Padding[2] * dpifactor,
		self.V.OV.Padding[3] * dpifactor,
		self.V.OV.Padding[4] * dpifactor
	}

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     color   Kolor elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_background( color, refresh )
	self.V.Background = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     image   Ścieżka do obrazka lub obiekt Surface.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_image( image, refresh )
	-- ściezka do obrazka - załaduj obrazek
	if type(image) == "string" then
		image = Useful.load_image( image )
	end
	if image == nil then
		self.V.IMG.Dims    = { 0, 0 }
		self.V.IMG.SFactor = { 0, 0 }
		self.V.IMG.Scaled  = { 0, 0 }
		self.V.IMG.Surface = nil

		return self
	end
	local factor = Visual.DPIFactor[self._Screen]

	-- zapisz wymiary obrazka
	self.V.IMG.Dims    = { image.width, image.height }
	self.V.IMG.SFactor = { 1.0, 1.0 }
	self.V.IMG_Scaled  = { image.width * factor, image.height * factor }
	self.V.IMG.Surface = image

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     align   Typ przylegania obrazu w tle do kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:e
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_image_align( align, refresh )
	if not align or not Visual.ALIGN_TYPE[align] then
		return self
	end
	local aligntype = Visual.ALIGN_TYPE[align]

	self.V.IMG.VAlign =  Visual.IMAGE_ALIGN[aligntype & 0x07] or 1
	self.V.IMG.HAlign = (Visual.IMAGE_ALIGN[aligntype & 0x70] or 0x10) >> 4

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
end

--[[
 * Ustawia typ rozciągania obrazu w tle kontrolki.
 *
 * DESCRIPTION:
 *     Funkcja przyjmuje w argumencie jedną z wartości Visual.IMAGE_SIZING_TYPE.
 *     Niezależnie od ustawienia obraz jest obcinany jeżeli wychodzi poza
 *     granice wymiarów kontrolki.
 *
 * CODE:
 *     widget:set_image_sizing( "Contains" )
 *
 * PARAMETERS:
 *     size    Typ rozciągania obrazu w tle kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_image_sizing( size, refresh )
	self.V.IMG.Sizing = Visual.IMAGE_SIZING_TYPE[size] or "Zoom"

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     extend  Typ powtarzania obrazu w tle kontrolki.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_image_extend( extend, refresh )
	self.V.IMG.Extend = Visual.IMAGE_EXTEND_TYPE[extend] or "NONE"

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
end

--[[
 * Oblicza wymiary obrazka w tle z zastosowaniem wybranego skalowania.
 *
 * PARAMETERS:
 *     width  Szerokość do wykorzystania lub -1.
 *     height Wysokość do wykorzystania lub -1.
 *
 * RETURNS:
 *     Szerokość i wysokość obrazka po przeskalowaniu.
]]-- ===========================================================================
function Visual:calc_image_scale( width, height )
	local new_width  = width
	local new_height = height
	local factor     = Visual.DPIFactor[self._Screen]
	
	-- resetuj ustawienia skalowania
	self.V.IMG.SFactor   = { 1.0, 1.0 }
	self.V.IMG.Scaled = {
		self.V.IMG.Dims[1] * factor,
		self.V.IMG.Dims[2] * factor
	}

	-- wymiary mniejsze lub równe zero lub format ma pozostać bez zmiany
	if width <= 0 or height <= 0 or self.V.IMG.Sizing == 1 then
		return self.V.IMG.Dims
	end

	local scalew = width / self.V.IMG.Dims[1]
	local scaleh = height / self.V.IMG.Dims[2]

	-- powiększanie lub pomniejszanie z uwzględnieniem formatu
	if self.V.IMG.Sizing == 2 then
		if scalew > scaleh then
			self.V.IMG.SFactor = { scaleh, scaleh }
		else
			self.V.IMG.SFactor = { scalew, scalew }
		end
	-- nakrywanie kontrolki z uwzględnieniem formatu
	elseif self.V.IMG.Sizing == 3 then
		if scalew > scaleh then
			self.V.IMG.SFactor = { scalew, scalew }
		else
			self.V.IMG.SFactor = { scaleh, scaleh }
		end
	-- rozciąganie obrazka na całą kontrolkę
	else
		self.V.IMG.SFactor = { scalew, scaleh }
	end

	self.V.IMG.Scaled = {
		self.V.IMG.Dims[1] * self.V.IMG.SFactor[1],
		self.V.IMG.Dims[2] * self.V.IMG.SFactor[2]
	}

	return self.V.IMG.Scaled[1], self.V.IMG.Scaled[2]
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
 *     color   Kolor czcionki tekstu w elemencie.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_foreground( color, refresh )
	self.V.TXT.Color = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     widget:set_border_width( 5 )
 *     widget:set_border_width( {5, 2} )
 *     widget:set_border_width( {1, 4, 5, 2} )
 *
 * PARAMETERS:
 *     size    Rozmiar ramki w postaci cyfry lub tablicy cyfr.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_border_width( size, refresh )
	size = (type(size) == "number" or type(size) == "table")
		and size
		or  0

	-- stary rozmiar ramki
	local obsize = {
		self.V.OV.BOR_Width[1],
		self.V.OV.BOR_Width[2],
		self.V.OV.BOR_Width[3],
		self.V.OV.BOR_Width[4]
	}
	-- aktualne wcięcie
	local owpadd = self.V.OV.Padding
	
	-- cała ramka ma taką samą grubość
	if type(size) == "number" then
		self.V.OV.BOR_Width = { size, size, size, size }
	-- z dwóch wartości tworzy 2 grupy - lewo=prawo, góra=dół
	elseif #size == 2 then
		self.V.OV.BOR_Width = { size[1], size[2], size[1], size[2] }
	-- każdy bok może mieć inną długość
	elseif #size == 4 then
		self.V.OV.BOR_Width = { size[1], size[2], size[3], size[4] }
	else
		self.V.OV.BOR_Width = { 0, 0, 0, 0 }
	end
	
	-- przelicz ponownie wcięcia
	self.V.OV.Padding = {
		owpadd[1] - obsize[1] + self.V.OV.BOR_Width[1],
		owpadd[2] - obsize[2] + self.V.OV.BOR_Width[2],
		owpadd[3] - obsize[3] + self.V.OV.BOR_Width[3],
		owpadd[4] - obsize[4] + self.V.OV.BOR_Width[4]
	}
	
	-- sprawdź czy ramka będzie rysowana
	if (self.V.OV.BOR_Width[1] > 0 or self.V.OV.BOR_Width[2] > 0 or
		self.V.OV.BOR_Width[3] > 0 or self.V.OV.BOR_Width[4] > 0) and
		self.V.BOR.Color
	then
		self.V.BOR.Visible = true
	else
		self.V.BOR.Visible = false
	end

	local dpifactor = Visual.DPIFactor[self._Screen]

	-- wartości po uwzględnieniu DPI
	self.V.Padding = {
		self.V.OV.Padding[1] * dpifactor,
		self.V.OV.Padding[2] * dpifactor,
		self.V.OV.Padding[3] * dpifactor,
		self.V.OV.Padding[4] * dpifactor
	}
	self.V.BOR.Width = {
		self.V.OV.BOR_Width[1] * dpifactor,
		self.V.OV.BOR_Width[2] * dpifactor,
		self.V.OV.BOR_Width[3] * dpifactor,
		self.V.OV.BOR_Width[4] * dpifactor
	}

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     color   Kolor ramki elementu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_border_color( color, refresh )
	self.V.BOR.Visible = false
	self.V.BOR.Color   = color
		and GColor( color )
		or  nil
	
	-- sprawdź czy ramka będzie rysowana
	if (self.V.BOR.Width[1] > 0 or self.V.BOR.Width[2] > 0 or
		self.V.BOR.Width[3] > 0 or self.V.BOR.Width[4] > 0) and
		self._B.BOR.Color
	then
		self.V.BOR.Visible = true
	end

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     text    Tekst do wyświetlenia.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_text( text, refresh )
	if self.V.TXT.Cairo.text == text then
		return self
	end

	self.V.TXT.Cairo.text       = text         
	self.V.TXT.Cairo.attributes = nil

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     text    Tekst do wyświetlenia.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_markup( text, refresh )
	local attr, parsed = Pango.parse_markup( text, -1, 0 )
	if not attr then
		error( parsed )
	end

	if self.V.TXT.Cairo.text == parsed then
		return self
	end

	self.V.TXT.Cairo.text       = parsed
	self.V.TXT.Cairo.attributes = attr

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     font    Czcionka do ustawienia podczas wyświetlania tekstu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_font( font, refresh )
	local fobj = type(font) ~= "userdata"
		and Theme.get_font(font)
		or  font

	self.V.TXT.Cairo:set_font_description( fobj )
	
	-- wymiary do sprawdzenia (-1 - nieokreślone)
	self.V.TXT.Cairo.width  = LGI.Pango.units_from_double( -1 )
	self.V.TXT.Cairo.height = LGI.Pango.units_from_double( -1 )
	
	-- pobierz wymiary tekstu
	local ink, logical = self.V.TXT.Cairo:get_pixel_extents()
	
	-- zapisz wysokość linii tekstu
	self.V.TXT.LHeight = logical.height
	self.V.TXT.Font    = fobj

	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     type    Jedna z metod wstawiania trzykropka w zdaniu.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_ellipsize( type, refresh )
	self.V.TXT.Cairo:set_ellipsize( Visual.ELLIPSIZE_TYPE[type] or "END" )

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     color   Typ przylegania tekstu w kontrolce.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_text_align( align, refresh )
	if align == nil or Visual.ALIGN_TYPE[align] == nil then
		return
	end
	local aligntype = Visual.ALIGN_TYPE[align]

	self.V.TXT.VAlign = Visual.TEXT_ALIGN[aligntype & 0x07] or 2
	self.V.TXT.HAlign = Visual.TEXT_ALIGN[aligntype & 0x70] or "LEFT"
	self.V.TXT.Cairo:set_alignment( self.V.TXT.HAlign )

	if refresh == nil or refresh then
		self:emit_signal( "widget::updated" )
	end
	return self
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
 *     wrap    Typ zawijania tekstu w kontrolce.
 *     refresh Czy emitować sygnał o odświeżeniu wyglądu kontrolki?
 *
 * RETURNS:
 *     Obiekt kontrolki.
]]-- ===========================================================================
function Visual:set_wrap( wrap, refresh )
	self.V.TXT.Cairo:set_wrap( Visual.WRAP_TYPE[wrap] or "WORD_CHAR" )

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		self:emit_signal( "widget::resized" )
		self:emit_signal( "widget::updated" )
	end
	return self
end

--[[
 * Rysuje tekst na kontrolce z uwzględnieniem ustawionych opcji.
 *
 * CODE:
 *     widget:set_text_align( "BottomRight" )
 *
 * PARAMETERS:
 *     cr Obiekt Cairo.
]]-- ===========================================================================
function Visual:draw_text( cr )
	-- pobierz krawędzie kontrolki
	local x, y, width, height = self:get_inner_bounds()

	-- przesunięcie w pionie
	local offset = y

	-- oblicz przyleganie pionowe
	if height ~= self.V.TXT.LHeight then
		if self.V.TXT.VAlign == 2 then
			offset = y + ((height - self.V.TXT.LHeight) / 2)
		elseif self.V.TXT.VAlign == 3 then
			offset = y + height - self.V.TXT.LHeight
		end
	end
	
	cr:move_to( x, offset )
	
	if self.V.TXT.Color then
		cr:save()
		cr:set_source( self.V.TXT.Color )
		cr:show_layout( self.V.TXT.Cairo )
		cr:restore()
	else
		cr:show_layout( self.V.TXT.Cairo )
	end
end

--[[
 * Oblicza wymiary pola tekstowego.
 *
 * PARAMETERS:
 *     width  Szerokość do wykorzystania lub -1.
 *     height Wysokość do wykorzystania lub -1.
 *
 * RETURNS:
 *     Szerokość i wysokość pola tekstowego w kontrolce.
]]-- ===========================================================================
function Visual:calc_text_dims( width, height )
	-- przelicz jednostki
	self.V.TXT.Cairo.width  = LGI.Pango.units_from_double( width )
	self.V.TXT.Cairo.height = LGI.Pango.units_from_double( height )
	
	-- pobierz wymiary tekstu
	local ink, logical = self.V.TXT.Cairo:get_pixel_extents()
	self.V.TXT.LHeight = logical.height
	
	-- zwróć wymiary
	return logical.width, logical.height
end

return Visual
