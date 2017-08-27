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

local error  = error
local pairs  = pairs
local type   = type

local Theme   = require("beautiful")
local LGI     = require("lgi")
local GColor  = require("gears.color")
local Surface = require("gears.surface")
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
	Original = 1,
	Zoom     = 2,
	Cover    = 3,
	Contain  = 4
}

-- metoda uzupełniania pustej przestrzeni z obrazkiem w tle
-- =============================================================================
Visual.IMAGE_EXTEND_TYPE = {
	None     = "NONE",
	Repeat   = "REPEAT",
	Reflect  = "REFLECT",
	Pad      = "PAD"
}

--[[

 Inicjalizacja zmiennych i funkcji dla klasy.
 Należy wywołać tą funkcję w konstruktorze aby automatycznie podczepić funkcje.

 - widget  : element do którego odnosi się funkcja (przekazywany automatycznie).
 - groups  : grupy zadań do których kontrolka ma mieć dostęp:
			 back, fore, padding, border, text
			 dodatkowo funkcja nie zastępuje istniejących funkcji.
 - emitup  : odświeżanie elementu po zmianie wartości [domyślnie TRUE].

////////////////////////////////////////////////////////////////////////////////
]]--

function Visual.Initialize( widget, groups, args )
	local group = {}
	local index = 0

	if widget._vinited then
		return
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
	widget.GetInnerBounds = Visual.GetInnerBounds
	widget.DrawVisual     = Visual.DrawVisual

	-- rozpoznaj style grupy
	for key, val in pairs(groups) do
		group[val] = true
	end
	
	-- kolor tła
	if group.background then
		widget.SetBackground = Visual.SetBackground
		widget:SetBackground( args.back_color, false )
	end
	-- obrazek w tle
	if group.image then
		widget.SetImage       = Visual.SetImage
		widget.SetImageAlign  = Visual.SetImageAlign
		widget.SetImageSize   = Visual.SetImageSize
		widget.SetImageExtend = Visual.SetImageExtend
		widget.CalcImageScale = Visual.CalcImageScale

		widget:SetImage( args.back_image, false )
		widget:SetImageAlign( args.image_align or "Center", false )
		widget:SetImageSize( args.image_size or "Zoom", false )
		widget:SetImageExtend( args.image_extend or "None", false )
	end
	-- wcięcie
	if group.padding then
		widget.SetPadding = Visual.SetPadding
		widget:SetPadding( args.padding, false )
	end
	-- ramka
	if group.border then
		widget.SetBorderSize  = Visual.SetBorderSize
		widget.SetBorderColor = Visual.SetBorderColor

		widget:SetBorderSize( args.border_size, false )
		widget:SetBorderColor( args.border_color, false )
	end
	-- tekst
	if group.text then
		-- tworzenie obiektu tekstu
		if widget._cairo_layout == nil then
			widget._cairo_layout = LGI.Pango.Layout.new(
				LGI.PangoCairo.font_map_get_default():create_context()
			)
		end

		widget.SetText       = Visual.SetText
		widget.SetMarkup     = Visual.SetMarkup
		widget.SetFont       = Visual.SetFont
		widget.SetEllipsize  = Visual.SetEllipsize
		widget.SetTextAlign  = Visual.SetTextAlign
		widget.SetWrap       = Visual.SetWrap
		widget.DrawText      = Visual.DrawText
		widget.CalcTextDims  = Visual.CalcTextDims
		widget.SetForeground = Visual.SetForeground

		widget:SetFont( args.font, false )
		widget:SetForeground( args.foreground, false )
		widget:SetEllipsize( args.ellipsize  or "None", false )
		widget:SetTextAlign( args.text_align or "Left", false )
		widget:SetWrap( args.wrap or "WordChar", false )

		if type(args.markup) == "string" then
			widget:SetMarkup( args.markup, false )
		elseif type(args.text) == "string" then
			widget:SetText( args.text, false )
		end
	end
	return widget
end

--[[ Visual.set_padding
=============================================================================================
 Margines wewnętrzny (wcięcie) elementu.

 - widget  : element do którego odnosi się funkcja (przekazywany automatycznie).
 - padding : wcięcie, tablica 4 wartościowa {lewo, góra, prawo, dół} lub liczba
			 reprezentująca wszystkie strony.
========================================================================================== ]]

function Visual.SetPadding( widget, padding, refresh )
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

--[[ Visual.set_background
=============================================================================================
 Kolor tła elementu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor tła w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function Visual.SetBackground( widget, color, refresh )
	widget._bgcolor = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

function Visual.SetImage( widget, image, refresh )
	-- ściezka do obrazka - załaduj obrazek
	if type(image) == "string" then
		local success, result = pcall( Surface.load, image )

		if not success then
			error( "Error while reading '" .. image .. "': " .. result )
			return widget
		end
		image = result
	end
	if image == nil then
		widget._image.dims    = { 0, 0 }
		widget._image.scale   = { 0, 0 }
		widget._image.surface = nil

		return widget
	end

	-- zapisz wymiary obrazka
	widget._image.dims    = { image.width, image.height }
	widget._image.scale   = { image.width, image.height }
	widget._image.surface = image

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

function Visual.SetImageAlign( widget, align, refresh )
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

function Visual.SetImageSize( widget, size, refresh )
	widget._image.size = Visual.IMAGE_SIZE_TYPE[size] or "Zoom"

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

function Visual.SetImageExtend( widget, extend, refresh )
	widget._image.extend = Visual.IMAGE_EXTEND_TYPE[extend] or "None"

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
	return widget
end

--[[ Visual.set_fore
=============================================================================================
 Kolor czcionki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor czcionki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function Visual.SetForeground( widget, color, refresh )
	widget._text.color = color
		and GColor( color )
		or  nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
end

--[[ Visual.set_border
=============================================================================================
 Kolor i grubość ramki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor ramki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
 - size   : rozmiar ramki dla poszczególnych stron, liczba traktowana jako wartość dla
			wszystkich stron lub tablica 4 wartości {lewo, góra, prawo, dół}.
========================================================================================== ]]

function Visual.SetBorderSize( widget, size, refresh )
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
end

function Visual.SetBorderColor( widget, color, refresh )
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
end

--[[ Visual.SetText
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function Visual.SetText( widget, text, refresh )
	if widget._cairo_layout.text == text then
		return
	end

	widget._cairo_layout.text       = text         
	widget._cairo_layout.attributes = nil

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
end

--[[ Visual.set_markup
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce (tryb znaczników HTML).

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function Visual.SetMarkup( widget, text, refresh )
	local attr, parsed = Pango.parse_markup( text, -1, 0 )
	if not attr then
		error( parsed )
	end

	if widget._cairo_layout.text == parsed then
		return
	end

	widget._cairo_layout.text       = parsed
	widget._cairo_layout.attributes = attr

	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
end

--[[ Visual.set_font
=============================================================================================
 Zmiana czcionki tekstu dla kontrolki.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - font   : nazwa czcionki [opcje] [rozmiar].
 - emitup : odświeżanie elementu po zmianie wartości [domyślnie TRUE].
========================================================================================== ]]

function Visual.SetFont( widget, font, refresh )
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
end

--[[ Visual.set_ellipsize
=============================================================================================
 Wstawianie trzykropka w miejsce zbyt długiego tekstu.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - place  : miejsce wstawiania - Visual.ELLIPSIZE_TYPE (klucze).
========================================================================================== ]]
 
function Visual.SetEllipsize( widget, place, refresh )
	widget._cairo_layout:set_ellipsize( Visual.ELLIPSIZE_TYPE[place] or "END" )

	if refresh == nil or refresh then
		widget:emit_signal( "widget::updated" )
	end
end

--[[ Visual.set_align
=============================================================================================
 Zmiana przylegania tekstu w pionie i w poziomie.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - horiz  : przyleganie w poziomie - Visual.ALIGN_TYPE (klucze).
 - vert   : przyleganie w pionie - Visual.VERTICAL_ALIGN (klucze).
========================================================================================== ]]

function Visual.SetTextAlign( widget, align, refresh )
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
end

--[[ Visual.set_wrap
=============================================================================================
 Metoda zawijania tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - wrap   : typ z Visual.WRAP_TYPE (klucze).
========================================================================================== ]]

function Visual.SetWrap( widget, wrap, refresh )
	widget._cairo_layout:set_wrap( Visual.WRAP_TYPE[wrap] or "WORD_CHAR" )

	-- wyślij sygnał aktualizacji elementu
	if refresh == nil or refresh then
		widget:emit_signal( "widget::resized" )
		widget:emit_signal( "widget::updated" )
	end
end

--[[ Visual.draw_Visual
=============================================================================================
 Rysowanie ramki i tła.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - cr     : obiekt Cairo.
========================================================================================== ]]

function Visual.DrawVisual( widget, cr )
	if  not widget._border.visible and
		not widget._bgcolor and
		not widget._image.surface then
		return
	end

	local px, py = widget._bounds[1], widget._bounds[2]
	local width, height = widget._bounds[5], widget._bounds[6]

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

	if widget._image.surface then
		local offx, offy = 0, 0

		if widget._image.halign ~= 1 then
			offx = width - widget._image.scaledv[1]
			if widget._image.halign == 2 then
				offx = offx / 2
			end
		end
		if widget._image.valign ~= 1 then
			offy = height - widget._image.scaledv[2]
			if widget._image.valign == 2 then
				offy = offy / 2
			end
		end

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
		else
			cr:set_source_surface( widget._image.surface, px + offx, py + offy )
			cr:rectangle( px, py, width, height )
			cr:clip()
		end

		LGI.cairo.Pattern.set_extend(
			cr:get_source(), LGI.cairo.Extend[widget._image.extend]
		)

		cr:paint()
	end

	-- sprawdź czy na pewno trzeba rysować ramkę
	if widget._border.visible then
		local size = widget._border.size
		cr:set_source( widget._border.color )

		-- góra (od lewej do prawej)
		if size[1] then
			cr:move_to( px, py )
			cr:rel_line_to( 0, height )
			cr:rel_line_to( size[1], -size[4] )
			cr:rel_line_to( 0, -height + size[2] + size[4] )
			cr:close_path()
		end
		if size[2] then
			cr:move_to( px, py )
			cr:rel_line_to( width, 0 )
			cr:rel_line_to( -size[1], size[2] )
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

--[[ Visual.draw_text
=============================================================================================
 Rysowanie tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - x      : pozycja x rysowanego tekstu.
 - y      : pozycja y rysowanego tekstu.
 - width  : szerokość obszaru rysowania.
 - height : wysokość obszaru rysowania.
========================================================================================== ]]

function Visual.DrawText( widget, cr )
	-- pobierz krawędzie kontrolki
	local x, y, width, height = widget:GetInnerBounds()

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

--[[ Visual.GetInnerBounds
=============================================================================================
 Oblicz wewnętrzne wymiary elementu po uwzględnieniu ramki i wcięcia.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 
 - return : table[4] { x, y, width, height }
========================================================================================== ]]

function Visual.GetInnerBounds( widget )
	local padding = widget._padding
	local bounds  = widget._bounds
	
	-- zwróć nowe wymiary i współrzędne x,y
	return bounds[1] + padding[1],
		   bounds[2] + padding[2],
		   bounds[5] - padding[1] - padding[3],
		   bounds[6] - padding[2] - padding[4]
end

--[[ Visual.CalcText
=============================================================================================
 Oblicz wymiary tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - width  : szerokość obszaru rysowania.
 - height : wysokość obszaru rysowania.
 
 - return : table[2] { width, height }
========================================================================================== ]]

function Visual.CalcTextDims( widget, width, height )
	-- przelicz jednostki
	widget._cairo_layout.width  = LGI.Pango.units_from_double( width )
	widget._cairo_layout.height = LGI.Pango.units_from_double( height )
	
	-- pobierz wymiary tekstu
	local ink, logical = widget._cairo_layout:get_pixel_extents()
	widget._text.lheight = logical.height
	
	-- zwróć wymiary
	return logical.width, logical.height
end

function Visual.CalcImageScale( widget, width, height )
	local new_width  = width
	local new_height = height
	
	widget._image.scale   = { 1.0, 1.0 }
	widget._image.scaledv = {
		widget._image.dims[1],
		widget._image.dims[2]
	}

	if width <= 0 or height <= 0 or widget._image.size == 1 then
		return widget._image.dims
	end

	local scalew = width / widget._image.dims[1]
	local scaleh = height / widget._image.dims[2]

	if widget._image.size == 2 then
		if scalew > scaleh then
			widget._image.scale = { scaleh, scaleh }
		else
			widget._image.scale = { scalew, scalew }
		end
	elseif widget._image.size == 3 then
		if scalew > scaleh then
			widget._image.scale = { scalew, scalew }
		else
			widget._image.scale = { scaleh, scaleh }
		end
	else
		widget._image.scale = { scalew, scaleh }
	end

-- local naughty = require("naughty")
-- naughty.notify({ preset = naughty.config.presets.critical,
--                                  title = "Oops, there were errors during startup!",
--                                  text = tostring(widget._image.scale[1]) .. " " .. tostring(widget._image.scale[2])
--                                  .. " " .. widget._image.dims[1] .. ":" .. widget._image.dims[2] .. " / "
--                                  .. width .. "#" .. height })

	widget._image.scaledv = {
		widget._image.dims[1] * widget._image.scale[1],
		widget._image.dims[2] * widget._image.scale[2]
	}

	return widget._image.scaledv[1], widget._image.scaledv[2]
end

--[[ return
========================================================================================== ]]

return Visual
