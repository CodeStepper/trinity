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

local Theme  = require("beautiful")
local LGI    = require("lgi")
local GColor = require("gears.color")
local Visual = {}

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
    WordChar = "WORD_CHAR"  -- próbuje zawijać najpierw po słowach potem po znakach
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

function Visual.initialize( widget, groups, args )
    local group = {}
    local index = 0

    -- sprawdź czy do kontrolki przypisane zostały już style
    if widget._visinit ~= nil then
        return
    end

    widget._border = {
        size    = { 0, 0, 0, 0 },
        color   = nil,
        visible = false
    }
    
    -- utwórz zmienne
    widget._visinit = true
    widget._padding = { 0, 0, 0, 0 }
    widget._bimage  = nil
    widget._back    = nil
    widget._image   = nil
    widget._fore    = nil
    widget._tvalign = "CENTER"
    widget._thalign = 2
    widget._ivalign = 2
    widget._ihalign = 2
    widget._fheight = 0

    widget.get_inner_bounds = Visual.get_inner_bounds
    widget.draw_visual      = Visual.draw_visual

    -- rozpoznaj style grupy
    for key, val in pairs(groups) do
        group[val] = true
    end
    
    -- kolor tła
    if group.background then
        widget.set_background = Visual.set_background

        widget:set_background( args.back_color )
    end
    -- obrazek w tle
    if group.image then
        widget.set_image         = Visual.set_image
        widget.set_image_align   = Visual.set_image_align
        widget.set_image_stretch = Visual.set_image_stretch
        widget.draw_image        = Visual.draw_image

        widget:set_image        ( args.back_image                )
        widget:set_image_align  ( args.image_align   or "Center" )
        widget:set_image_stretch( args.image_stretch or true     )
    end
    -- kolor tekstu
    if group.foreground then
        widget.set_foreground = Visual.set_foreground

        widget:set_foreground( args.foreground )
    end
    -- wcięcie
    if group.padding then
        widget.set_padding = Visual.set_padding

        widget:set_padding( args.padding )
    end
    -- ramka
    if group.border then
        widget.set_border = Visual.set_border

        widget:set_border( args.border_color, args.border_size )
    end
    -- operacje na tekście
    if group.text then
        -- tworzenie obiektu tekstu
        if widget._cairo_layout == nil then
            widget._cairo_layout = LGI.Pango.Layout.new(
                LGI.PangoCairo.font_map_get_default():create_context()
            )
        end

        widget.set_text      = Visual.set_text
        widget.set_markup    = Visual.set_markup
        widget.set_font      = Visual.set_font
        widget.set_ellipsize = Visual.set_ellipsize
        widget.set_align     = Visual.set_align
        widget.set_wrap      = Visual.set_wrap
        widget.draw_text     = Visual.draw_text
        widget.calc_text     = Visual.calc_text

        widget:set_font     ( args.font                     )
        widget:set_ellipsize( args.ellipsize  or "None"     )
        widget:set_align    ( args.text_align or "Center"   )
        widget:set_wrap     ( args.wrap       or "WordChar" )
    end
end

--[[ Visual.set_padding
=============================================================================================
 Margines wewnętrzny (wcięcie) elementu.

 - widget  : element do którego odnosi się funkcja (przekazywany automatycznie).
 - padding : wcięcie, tablica 4 wartościowa {lewo, góra, prawo, dół} lub liczba
             reprezentująca wszystkie strony.
========================================================================================== ]]

function Visual.set_padding( widget, padding )
    local padding = padding
    local obsize  = { 0, 0, 0, 0 }

    -- zamień na tablicę jeżeli zachodzi taka potrzeba
    if type(padding) ~= "table" or #padding ~= 4 then
        if type(padding) == "number" then
            padding = { padding, padding, padding, padding }
        elseif #padding == 2 then
            padding = { padding[0], padding[1], padding[0], padding[1] }
        else
            padding = { 0, 0, 0, 0 }
        end
    end
    
    -- pobierz rozmiar ramki
    if type(widget._bsize) == "table" and #widget._bsize == 4 then
        obsize = {
            widget._bsize[1],
            widget._bsize[2],
            widget._bsize[3],
            widget._bsize[4]
        }
    end

    -- zapisz wcięcie z uwzględnieniem ramki
    widget._padding = {
        padding[1] + obsize[1],
        padding[2] + obsize[2],
        padding[3] + obsize[3],
        padding[4] + obsize[4]
    }
    
    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_background
=============================================================================================
 Kolor tła elementu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor tła w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function Visual.set_background( widget, color )
    -- brak koloru
    if color == false then
        widget._back = nil
    -- hex lub wzór
    elseif color ~= nil then
        widget._back = GColor( color )
    end
    
    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_foreground
=============================================================================================
 Kolor czcionki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor czcionki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function Visual.set_foreground( widget, color )
    -- brak koloru
    if color == false then
        widget._fore = nil
    -- hex lub wzór
    elseif color ~= nil then
        widget._fore = GColor( color )
    end
    
    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_border
=============================================================================================
 Kolor i grubość ramki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor ramki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
 - size   : rozmiar ramki dla poszczególnych stron, liczba traktowana jako wartość dla
            wszystkich stron lub tablica 4 wartości {lewo, góra, prawo, dół}.
========================================================================================== ]]

function Visual.set_border( widget, color, size )
    widget._border.visible = false

    -- wartość false nie zmienia koloru
    if color == nil then
        widget._border.color = nil
    elseif color ~= false then
        widget._border.color = GColor( color )
    end

    if size then
        -- stary rozmiar ramki
        local obsize = {
            widget._border.size[1],
            widget._border.size[2],
            widget._border.size[3],
            widget._border.size[4]
        }
        -- aktualne wcięcie
        local owpadd = type(widget._padding) == "table" and #widget._padding == 4 
            and {
                    widget._padding[1],
                    widget._padding[2],
                    widget._padding[3],
                    widget._padding[4]
                }
            or  { 0, 0, 0, 0 }
        
        -- cała ramka ma taką samą grubość
        if type(size) == "number" then
            widget._border.size = { size, size, size, size }
        -- z dwóch wartości tworzy 2 grupy - lewo=prawo, góra=dół
        elseif type(size) == "table" and #size == 2 then
            widget._border.size = { size[1], size[2], size[1], size[2] }
        -- każdy bok może mieć inną długość
        elseif type(size) == "table" and #size == 4 then
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
    end
    
    -- sprawdź czy ramka będzie rysowana
    if (widget._border.size[1] > 0 or widget._border.size[2] > 0 or
        widget._border.size[3] > 0 or widget._border.size[4] > 0) and
        widget._border.color then
        widget._border.visible = true
    end

    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_text
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function Visual.set_text( widget, text )
    -- nie aktualizuj gdy ten sam tekst...
    if widget._cairo_layout.text == text then
        return
    end

    widget._cairo_layout.text       = text         
    widget._cairo_layout.attributes = nil

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_markup
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce (tryb znaczników HTML).

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function Visual.set_markup( widget, text )
    local attr, parsed = Pango.parse_markup( text, -1, 0 )
    
    -- błąd parsowania...
    if not attr then
        error( parsed )
    end

    -- nie aktualizuj gdy ten sam tekst...
    if widget._cairo_layout.text == parsed then
        return
    end

    widget._cairo_layout.text       = parsed
    widget._cairo_layout.attributes = attr

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_font
=============================================================================================
 Zmiana czcionki tekstu dla kontrolki.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - font   : nazwa czcionki [opcje] [rozmiar].
 - emitup : odświeżanie elementu po zmianie wartości [domyślnie TRUE].
========================================================================================== ]]

function Visual.set_font( widget, font )
    -- jeżeli podano nazwę, wczytaj
    if type(font) ~= "userdata" then
        widget._cairo_layout:set_font_description( Theme.get_font(font) )
    -- jeżeli nie, przypisz podany obiekt
    else
        widget._cairo_layout:set_font_description( font )
    end
    
    -- wymiary do sprawdzenia (-1 - nieokreślone)
    widget._cairo_layout.width  = LGI.Pango.units_from_double( -1 )
    widget._cairo_layout.height = LGI.Pango.units_from_double( -1 )
    
    -- pobierz wymiary tekstu
    local ink, logical = widget._cairo_layout:get_pixel_extents()
    
    -- zapisz wysokość czcionki
    widget._fheight = logical.height

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_ellipsize
=============================================================================================
 Wstawianie trzykropka w miejsce zbyt długiego tekstu.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - place  : miejsce wstawiania - Visual.ELLIPSIZE_TYPE (klucze).
========================================================================================== ]]
 
function Visual.set_ellipsize( widget, place )
    widget._cairo_layout:set_ellipsize( Visual.ELLIPSIZE_TYPE[place] or "END" )

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_align
=============================================================================================
 Zmiana przylegania tekstu w pionie i w poziomie.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - horiz  : przyleganie w poziomie - Visual.ALIGN_TYPE (klucze).
 - vert   : przyleganie w pionie - Visual.VERTICAL_ALIGN (klucze).
========================================================================================== ]]

function Visual.set_align( widget, align )
    if align == nil or Visual.ALIGN_TYPE[align] == nil then
        return
    end
    local aligntype = Visual.ALIGN_TYPE[align]

    -- przyleganie poziome
    widget._cairo_layout:set_alignment( Visual.TEXT_ALIGN[aligntype & 0x70] or "LEFT" )
    widget._valign = Visual.TEXT_ALIGN[aligntype & 0x07] or 2

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.set_wrap
=============================================================================================
 Metoda zawijania tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - wrap   : typ z Visual.WRAP_TYPE (klucze).
========================================================================================== ]]

function Visual.set_wrap( widget, wrap )
    widget._cairo_layout:set_wrap( Visual.WRAP_TYPE[wrap] or "WORD_CHAR" )

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ Visual.draw_Visual
=============================================================================================
 Rysowanie ramki i tła.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - cr     : obiekt Cairo.
========================================================================================== ]]

function Visual.draw_visual( widget, cr )
    if not widget._border and widget._back == nil and widget._image == nil then
        return
    end

    local temp
    local px, py = widget._bounds[1], widget._bounds[2]
    local width, height = widget._bounds[5], widget._bounds[6]

    cr:save()
    
    -- tło w kolorze
    if widget._back then
        cr:set_source( widget._back )
        
        -- uwzględnij ramkę
        temp = widget._bsize

        cr:rectangle( px, py, width, height )
        cr:fill()
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

function Visual.draw_text( widget, cr )
    -- pobierz krawędzie kontrolki
    local x, y, width, height = widget:get_inner_bounds()

    -- przesunięcie w pionie
    local offset = y

    -- oblicz przyleganie pionowe
    if height ~= widget._fheight then
        if widget._valign == 2 then
            offset = y + ((height - widget._fheight) / 2)
        elseif widget._valign == 3 then
            offset = y + height - widget._fheight
        end
    end
    
    cr:move_to( x, offset )
    
    -- rysuj tekst ze zmienionym kolorem czcionki
    if widget._fore then
        cr:save()
        cr:set_source( widget._fore )
        cr:show_layout( widget._cairo_layout )
        cr:restore()
        
    -- rysuj tekst z domyślnym kolorem czcionki
    else
        cr:show_layout( widget._cairo_layout )
    end
end

--[[ Visual.get_inner_bounds
=============================================================================================
 Oblicz wewnętrzne wymiary elementu po uwzględnieniu ramki i wcięcia.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 
 - return : table[4] { x, y, width, height }
========================================================================================== ]]

function Visual.get_inner_bounds( widget )
    local padding = widget._padding
    local bounds  = widget._bounds
    
    -- zwróć nowe wymiary i współrzędne x,y
    return bounds[1] + padding[1],
           bounds[2] + padding[2],
           bounds[5] - padding[1] - padding[3],
           bounds[6] - padding[2] - padding[4]
end

--[[ Visual.calc_text
=============================================================================================
 Oblicz wymiary tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - width  : szerokość obszaru rysowania.
 - height : wysokość obszaru rysowania.
 
 - return : table[2] { width, height }
========================================================================================== ]]

function Visual.calc_text( widget, width, height )
    -- przelicz jednostki
    widget._cairo_layout.width  = LGI.Pango.units_from_double( width )
    widget._cairo_layout.height = LGI.Pango.units_from_double( height )
    
    -- pobierz wymiary tekstu
    local ink, logical = widget._cairo_layout:get_pixel_extents()
    widget._fheight = logical.height
    
    -- zwróć wymiary
    return logical.width, logical.height
end

--[[ return
========================================================================================== ]]

return Visual
