--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Funkcje wizualizacji elementu.
 Najczęstsze używane funkcje na elementach.
 Po przypięciu do elementu można wywoływać na dwa sposoby:
    1: widget.set_padding( widget, 5 )
    2: widget:set_padding( 5 )
 Trzeci sposób to wywołanie na sztywno - bezpośrednio z obiektu visual:
    3: visual.set_padding( widget, 5 )
////////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
TODO Zrobić margines... (chociaż nie wiem czy potrzebny).
TODO Sprawdzić i porównać zwracane atrybuty przez funkcję parse_markup...
========================================================================================== ]]

local error  = error
local pairs  = pairs
local type   = type

local theme  = require("beautiful")
local lgi    = require("lgi")
local gcolor = require("gears.color")
local visual = {}

-- przyleganie poziome
visual.align_type = {
    left   = "LEFT",
    center = "CENTER",
    right  = "RIGHT"
}

-- przyleganie poziome (obrazki)
visual.halign_type = {
    left   = 1,
    center = 2,
    right  = 3
}

-- przyleganie pionowe
visual.valign_type = {
    top    = 1,
    center = 2,
    bottom = 3
}

-- zwężanie tekstu - gdy jest za długi, wstawia trzykropek (...)
visual.ellipsize_type = {
    none    = "NONE",       -- wyłączone
    start   = "START",      -- trzykropek na początku
    middle  = "MIDDLE",     -- trzykropek w środku
    ["end"] = "END"         -- trzykropek na końcu
}

-- metoda zawijania tekstu
visual.wrap_type = {
    word      = "WORD",     -- zawijanie po słowach
    char      = "CHAR",     -- zawijanie po znakach
    word_char = "WORD_CHAR" -- za chuja nie wiem czym się różni od WORD
}

--[[ visual.initialize
=============================================================================================
 Inicjalizacja zmiennych i funkcji dla klasy.
 Należy wywołać tą funkcję w konstruktorze aby automatycznie podczepić funkcje.

 - widget  : element do którego odnosi się funkcja (przekazywany automatycznie).
 - groups  : grupy zadań do których kontrolka ma mieć dostęp:
             back, fore, padding, border, text
             dodatkowo funkcja nie zastępuje istniejących funkcji.
 - emitup  : odświeżanie elementu po zmianie wartości [domyślnie TRUE].
========================================================================================== ]]

function visual.initialize( widget, groups, args )
    local group = {}
    local index = 0
    
    -- utwórz zmienne
    widget._padding = { 0, 0, 0, 0 }
    widget._bsize   = { 0, 0, 0, 0 }
    widget._bcolor  = { 0, 0, 0, 0 }
    widget._back    = nil
    widget._fore    = nil
    widget._border  = false
    widget._valign  = 2
    widget._halign  = 2
    widget._fheight = 0
    
    widget.get_inner_bounds = visual.get_inner_bounds
    widget.draw_visual      = visual.draw_visual
    
    -- rozpoznaj style grupy
    for key, val in pairs(groups) do
        group[val] = true
    end
    
    -- kolor tła
    if group.back then
        if widget.set_background == nil then
            widget.set_background = visual.set_background
            widget:set_background( args.background )
        end
    end
    -- kolor tekstu
    if group.fore then
        if widget.set_foreground == nil then
            widget.set_foreground = visual.set_foreground
            widget:set_foreground( args.foreground )
        end
    end
    -- wcięcie
    if group.padding then
        if widget.set_padding == nil then
            widget.set_padding = visual.set_padding
            widget:set_padding( args.padding )
        end
    end
    -- ramka
    if group.border then
        if widget.set_border == nil then
            widget.set_border = visual.set_border
            widget:set_border( args.border_color, args.border_size )
        end
    end
    -- operacje na tekście
    if group.text then
        -- tworzenie obiektu tekstu
        if widget._cairo_layout == nil then
            widget._cairo_layout = lgi.Pango.Layout.new(
                lgi.PangoCairo.font_map_get_default():create_context()
            )
        end
        -- zmiana tekstu
        if widget.set_text == nil then
            widget.set_text = visual.set_text
        end
        -- zmiana tekstu (znaczniki HTML)
        if widget.set_markup == nil then
            widget.set_markup = visual.set_markup
        end
        -- zmiana czcionki
        if widget.set_font == nil then
            widget.set_font = visual.set_font
            widget:set_font( args.font )
        end
        -- trzykropek
        if widget.set_ellipsize == nil then
            widget.set_ellipsize = visual.set_ellipsize
            widget:set_ellipsize( args.ellipsize )
        end
        -- przyleganie
        if widget.set_align == nil then
            widget.set_align = visual.set_align
            widget:set_align( args.halign, args.valign )
        end
        -- zawijanie
        if widget.set_wrap == nil then
            widget.set_wrap = visual.set_wrap
            widget:set_wrap( args.wrap )
        end
        -- rysowanie tekstu
        if widget.draw_text == nil then
            widget.draw_text = visual.draw_text
        end
        -- obliczanie wymiarów tekstu
        if widget.calc_text == nil then
            widget.calc_text = visual.calc_text
        end
    end
end

--[[ visual.set_padding
=============================================================================================
 Margines wewnętrzny (wcięcie) elementu.

 - widget  : element do którego odnosi się funkcja (przekazywany automatycznie).
 - padding : wcięcie, tablica 4 wartościowa {lewo, góra, prawo, dół} lub liczba
             reprezentująca wszystkie strony.
========================================================================================== ]]

function visual.set_padding( widget, padding )
    local padding = padding
    local obsize  = { 0, 0, 0, 0 }

    -- zamień na tablicę jeżeli zachodzi taka potrzeba
    if type(padding) ~= "table" or #padding ~= 4 then
        if type(padding) == "number" then
            padding = { padding, padding, padding, padding }
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

--[[ visual.set_background
=============================================================================================
 Kolor tła elementu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor tła w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function visual.set_background( widget, color )
    -- brak koloru
    if color == false then
        widget._back = nil
    -- hex lub wzór
    elseif color ~= nil then
        widget._back = gcolor( color )
    end
    
    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_foreground
=============================================================================================
 Kolor czcionki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor czcionki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
========================================================================================== ]]

function visual.set_foreground( widget, color )
    -- brak koloru
    if color == false then
        widget._fore = nil
    -- hex lub wzór
    elseif color ~= nil then
        widget._fore = gcolor( color )
    end
    
    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_border
=============================================================================================
 Kolor i grubość ramki.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - color  : kolor ramki w formacie HEX lub wzór Cairo w formacie tekstu lub tablicy.
 - size   : rozmiar ramki dla poszczególnych stron, liczba traktowana jako wartość dla
            wszystkich stron lub tablica 4 wartości {lewo, góra, prawo, dół}.
========================================================================================== ]]

function visual.set_border( widget, color, size )
    -- brak koloru
    if color == false then
        widget._bcolor = nil
    -- hex lub wzór
    elseif color ~= nil then
        widget._bcolor = gcolor( color )
    end
    
    -- rozmiary ramki
    if size ~= nil then
        local obsize = { 0, 0, 0, 0 }
        local owpadd = { 0, 0, 0, 0 }
       
        -- rozmiar starej ramki
        if type(widget._bsize) == "table" and #widget._bsize == 4 then
            obsize = {
                widget._bsize[1],
                widget._bsize[2],
                widget._bsize[3],
                widget._bsize[4]
            }
        end
        -- rozmiar wcięcia
        if type(widget._padding) == "table" and #widget._padding == 4 then
            owpadd = {
                widget._padding[1],
                widget._padding[2],
                widget._padding[3],
                widget._padding[4]
            }
        end
        
        -- zamień liczbę na tablice
        if type(size) == "number" then
            widget._bsize = { size, size, size, size }
        -- błędne dane, 0 grubość linii
        elseif type(size) ~= "table" or #size ~= 4 then
            widget._bsize = { 0, 0, 0, 0 }
        -- grubość linii podana w tabeli
        else
            widget._bsize = size
        end
        
        -- oblicz nowe wcięcia
        widget._padding = {
            owpadd[1] - obsize[1] + widget._bsize[1],
            owpadd[2] - obsize[2] + widget._bsize[2],
            owpadd[3] - obsize[3] + widget._bsize[3],
            owpadd[4] - obsize[4] + widget._bsize[4]
        }
    end
    
    -- przełącznik dla rysowania ramki (przyspieszenie działania)
    if widget._bsize ~= nil and (widget._bsize[1] > 0 or widget._bsize[2] > 0
    or widget._bsize[3] > 0 or widget._bsize[4] > 0) and widget._bcolor ~= nil then
        widget._border = true
    else
        widget._border = false
    end

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_text
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function visual.set_text( widget, text )
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

--[[ visual.set_markup
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce (tryb znaczników HTML).

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - text   : nowy wyświetlany tekst.
========================================================================================== ]]

function visual.set_markup( widget, text )
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

--[[ visual.set_font
=============================================================================================
 Zmiana czcionki tekstu dla kontrolki.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - font   : nazwa czcionki [opcje] [rozmiar].
 - emitup : odświeżanie elementu po zmianie wartości [domyślnie TRUE].
========================================================================================== ]]

function visual.set_font( widget, font )
    widget._cairo_layout:set_font_description( theme.get_font(font) )
    
    -- wymiary do sprawdzenia (-1 - nieokreślone)
    widget._cairo_layout.width  = lgi.Pango.units_from_double( -1 )
    widget._cairo_layout.height = lgi.Pango.units_from_double( -1 )
    
    -- pobierz wymiary tekstu
    local ink, logical = widget._cairo_layout:get_pixel_extents()
    
    -- zapisz wysokość czcionki
    widget._fheight = logical.height

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_ellipsize
=============================================================================================
 Wstawianie trzykropka w miejsce zbyt długiego tekstu.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - place  : miejsce wstawiania - defs.ellipsize_type (klucze).
========================================================================================== ]]
 
function visual.set_ellipsize( widget, place )
    widget._cairo_layout:set_ellipsize( visual.ellipsize_type[place] or "END" )

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_align
=============================================================================================
 Zmiana przylegania tekstu w pionie i w poziomie.

 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - horiz  : przyleganie w poziomie - visual.align_type (klucze).
 - vert   : przyleganie w pionie - visual.align_vtype (klucze).
========================================================================================== ]]

function visual.set_align( widget, horiz, vert )
    -- przyleganie poziome
    if horiz ~= nil then
        widget._cairo_layout:set_alignment( visual.align_type[horiz] or "LEFT" )
    end
    -- przyleganie pionowe
    if vert ~= nil then
        widget._valign = visual.valign_type[vert] or 2
    end

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::updated" )
end

--[[ visual.set_wrap
=============================================================================================
 Metoda zawijania tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - wrap   : typ z visual.wrap_type (klucze).
========================================================================================== ]]

function visual.set_wrap( widget, wrap )
    widget._cairo_layout:set_wrap( visual.wrap_type[wrap] or "WORD_CHAR" )

    -- wyślij sygnał aktualizacji elementu
    widget:emit_signal( "widget::resized" )
    widget:emit_signal( "widget::updated" )
end

--[[ visual.draw_visual
=============================================================================================
 Rysowanie ramki i tła.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - cr     : obiekt Cairo.
========================================================================================== ]]

function visual.draw_visual( widget, cr )
    if not widget._border and not widget._back then
        return
    end

    local temp
    local px, py = widget._bounds[1], widget._bounds[2]
    local width, height = widget._bounds[5], widget._bounds[6]

    cr:save()

    -- sprawdź czy na pewno trzeba rysować ramkę
    if widget._border then
        local size = widget._bsize
        
        -- ustaw kolor ramki
        cr:set_source( widget._bcolor )

        -- lewo (od dołu do góry)
        if size[1] then
            temp = size[1] - 1
        
            cr:move_to( px + temp, height )
            cr:line_to( px + temp, py )
        end
        -- góra (od lewej do prawej)
        if size[2] then
            temp = size[2] - 1
        
            cr:move_to( px, py + temp )
            cr:line_to( width, py + temp )
        end
        -- prawo (od góry do dołu)
        if size[3] then
            temp = size[3] - 1
        
            cr:move_to( width - temp, py )
            cr:line_to( width - temp, height )
        end
        -- dół (od prawej do lewej)
        if size[4] then
            temp = size[4] - 1
        
            cr:move_to( width, height - temp )
            cr:line_to( px, height - temp )
        end
        
        cr:stroke()
    end
    
    -- nie rysuj gdy nie potrzeba
    if widget._back then
        cr:set_source( widget._back )
        
        -- uwzględnij ramkę
        temp = widget._bsize

        cr:rectangle( px + temp[1], py + temp[2], width - temp[1] - temp[3],
            height - temp[2] - temp[4] )
        cr:fill()
    end
    
    cr:restore()
end

--[[ visual.draw_text
=============================================================================================
 Rysowanie tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - x      : pozycja x rysowanego tekstu.
 - y      : pozycja y rysowanego tekstu.
 - width  : szerokość obszaru rysowania.
 - height : wysokość obszaru rysowania.
========================================================================================== ]]

function visual.draw_text( widget, cr )
    -- pobierz krawędzie kontrolki
    local x, y, width, height = widget:get_inner_bounds()

    -- przesunięcie w pionie
    local offset = y

    -- oblicz przyleganie pionowe
    if height ~= widget._fheight then
        if widget._valign == visual.valign_type.center then
            offset = y + ((height - widget._fheight) / 2)
        elseif widget._valign == visual.valign_type.bottom then
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

--[[ visual.get_inner_bounds
=============================================================================================
 Oblicz wewnętrzne wymiary elementu po uwzględnieniu ramki i wcięcia.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 
 - return : table[4] { x, y, width, height }
========================================================================================== ]]

function visual.get_inner_bounds( widget )
    local padding = widget._padding
    local bounds  = widget._bounds
    
    -- zwróć nowe wymiary i współrzędne x,y
    return bounds[1] + padding[1],
           bounds[2] + padding[2],
           bounds[5] - padding[1] - padding[3],
           bounds[6] - padding[2] - padding[4]
end

--[[ visual.calc_text
=============================================================================================
 Oblicz wymiary tekstu.
 
 - widget : element do którego odnosi się funkcja (przekazywany automatycznie).
 - width  : szerokość obszaru rysowania.
 - height : wysokość obszaru rysowania.
 
 - return : table[2] { width, height }
========================================================================================== ]]

function visual.calc_text( widget, width, height )
    -- przelicz jednostki
    widget._cairo_layout.width  = lgi.Pango.units_from_double( width )
    widget._cairo_layout.height = lgi.Pango.units_from_double( height )
    
    -- pobierz wymiary tekstu
    local ink, logical = widget._cairo_layout:get_pixel_extents()
    widget._fheight = logical.height
    
    -- zwróć wymiary
    return logical.width, logical.height
end

--[[ return
========================================================================================== ]]

return visual
