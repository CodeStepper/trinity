--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6
 @license   : GPL2, plik LICENSE

 Funkcje pola edycji.
 Pole edycji obsługuje dwa dodatkowe zdarzenia: edit::blur i edit::focus.
////////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
TODO obsługa wszystkich czcionek (na razie obsługuje tylko czcionki o stałej szerokości)
========================================================================================== ]]

local type         = type
local pairs        = pairs
local ipairs       = ipairs
local setmetatable = setmetatable

local kgrab  = require("awful.keygrabber")
local gcolor = require("gears.color")
local theme  = require("beautiful")
local useful = require("trinity.useful")
local visual = require("trinity.visual")
local signal = require("trinity.signal")
local edit   = {}

-- typ kursora, do wyboru 3 opcje
edit.cursor_type = {
    block = 1,      -- kursor blokowy (tło)
    line  = 2,      -- kursor liniowy (cienka linia po znaku)
    under = 3       -- podkreślenie
}

--[[ update_blinker
=============================================================================================
 Aktualizacja migacza kursora.
 Funkcja wykonywana jest automatycznie przez czasomierz.
========================================================================================== ]]

local function update_blinker()
    -- przełącz stan kursora
    if edit.obj._draw_cursor then
        edit.obj._draw_cursor = false
    else
        edit.obj._draw_cursor = true
    end
    
    -- aktualizuj pole tekstowe
    edit.obj:emit_signal( "widget::updated" )
end

--[[ edit:draw
=============================================================================================
 Rysowanie pola tekstowego w całej okazałości.
 Funkcja ta wywoływana jest automatycznie przy aktualizacji pola tekstowego.
 
 - cr : obiekt Cairo.
========================================================================================== ]]

function edit:draw( cr )
    local px, py = self._bounds[1], self._bounds[2]
    local width, height = self._bounds[5], self._bounds[6]

    -- nie rysuj gdy wymiary są zerowe...
    if width == 0 or height == 0 then
        return
    end
    
    -- część wizualna
    self:draw_visual( cr )
    
    -- kursor blokowy (rysowanie pod tekstem)
    if self._draw_cursor and self._cursor_type == edit.cursor_type.block then
        local sx, sy
        cr:save()
        
        -- oblicz pozycje
        sx = px + self._padding[1] + (self._monospace_dim[1] * self._caret_pos)
        sy = py + self._padding[2]
        
        -- ustaw tło i rysuj kursor
        cr:set_source( self._cursor_color )
        cr:rectangle( sx, sy, self._monospace_dim[1], self._monospace_dim[2] )
        
        cr:fill()
        cr:restore()
    end

    -- rysowanie tekstu
    self:draw_text( cr )
    
    -- kursor liniowy i podkreślenie
    if self._draw_cursor and self._cursor_type ~= edit.cursor_type.block then
        local sx, sy
        cr:save()
        
        -- ustaw tło i oblicz pozycje
        cr:set_source( self._cursor_color )
        sx = px + self._padding[1] + (self._monospace_dim[1] * self._caret_pos)
        
        -- kursor liniowy
        if self._cursor_type == edit.cursor_type.line then
            sy = py + self._padding[2]
            cr:rectangle( sx, sy, self._cursor_size, self._monospace_dim[2] )
        -- podkreślenie
        else
            sy = py + self._padding[2] + (self._monospace_dim[2] - self._cursor_size)
            cr:rectangle( sx, sy, self._monospace_dim[1], self._monospace_dim[2] )
        end
        cr:fill()
        cr:restore()
    end
end

--[[ edit:fit
=============================================================================================
 Dopasowywanie pola do podanych rozmiarów (lub zwracanie żądanych rozmiarów tekstu).

 - width  : szerokość do dyspozycji lub -1 (zwraca żądaną szerokość).
 - height : wysokość do dyspozycji lub -1 (zwraca żądaną wysokość).
 
 - return : table[2] { width, height }.
========================================================================================== ]]

function edit:fit( width, height )
    local width  = width
    local height = height
 
    local marw = self._padding[1] + self._padding[3]
    local marh = self._padding[2] + self._padding[4]

    -- dodatkowy zapas dla kursora
    if self._cursor_type == edit.cursor_type.line then
        marw = marw + 1
    end
    
    -- zerowe wymiary (lub jeden z nich)
    if (width ~= -1 and width <= marw) or (height ~= -1 and height <= marh) then
        return 0, 0
    end
    
    -- odejmij wcięcia
    if width > 0 then
        width = width - marw
    end
    if height > 0 then
        height = height - marh
    end
    
    local tw, th = self:calc_text( width, height )

    -- zerowe wymiary
    if (not self._drawnil and tw == 0) or th == 0 then
        return 0, 0
    end
    
    -- dodaj wcięcia
    return tw + marw, th + marh
end

--[[ edit:stop_key_capture
=============================================================================================
 Zatrzymanie przechwytywania klawiszy.
========================================================================================== ]]

function edit:stop_key_capture( deblu )
    if self._kgrabber == nil then
        return
    end

    -- zatrzymaj czasomierz i przechwytywanie klawiatury
    kgrab.stop( self._kgrabber )

    if self._timer then
        self._timer:stop()
    end

    -- nie rysuj kursora gdy pole tekstowe jest nieaktywne
    self._draw_cursor = false

    -- można wyłączyć zdarzenie utraty skupienia przez kontrolkę
    if not deblu then
        self:emit_signal( "edit::blur" )
    end
    self:emit_signal( "widget::updated" )
end

--[[ edit:start_key_capture
=============================================================================================
 Przechwytywanie klawiszy (aktywacja pola tekstowego).
 
 Klawisze sterujące:
 - Left, Right - przesuwanie kursora
 - Backspace   - usuwanie znaku przed kursorem
 - Escape      - wyjście z trybu przechwytywania klawiszy / deaktywacja
 - Delete      - usuń cały tekst.
 
 - return : true/false/nil
========================================================================================== ]]

function edit:start_key_capture()    
    local refs = {
        string = nil,
        retval = nil
    }

    -- można wyłączyć zdarzenie uzyskania skupienia przez kontrolkę
    if not defoc then
        self:emit_signal( "edit::focus" )
    end
    self:emit_signal( "widget::updated" )
    
    local command = self:get_text()
    
    self._draw_cursor = true
    edit.obj = self
    
    -- uruchom czasomierz
    if self._timer then
        self._timer:start()
    end

    -- przechwytywanie klawiatury
    self._kgrabber = kgrab.run( function(mods, key, ev)
        local mod = {}
        
        -- zamień na lepszą tablicę...
        for _, val in ipairs(mods) do
            mod[val] = true
        end
        
        -- resetuj wartości na kolejne okrążenie
        refs.retval = nil
        refs.string = nil
        
        -- przetwarzaj tylko naciśnięcia
        if ev ~= "press" then        
            self:emit_signal( "key::release", mods, key, refs )
        
            -- sprawdź zwracaną wartość
            if refs.retval ~= nil then
                return refs.retval
            elseif refs.string then
                self:set_text( refs.string )
                command = refs.string
            end

            return
        end
        
        -- resetuj czasomierz
        if self._timer then
            self._timer:again()
        end
        self._draw_cursor = true
        
        -- zdarzenie po naciśnięciu przycisku
        ret = self:emit_signal( "key::press", mods, key, refs )

        -- sprawdź zwracaną wartość
        if refs.retval ~= nil then
            return refs.retval
        elseif refs.string then
            self:set_text( refs.string )
            command = refs.string
        end
        
        -- przesuwanie kursora w lewo
        if key == "Left" then
            if self._caret_pos > 0 then
                self._caret_sum = self._caret_sum - self._char_size[self._caret_pos]
                self._caret_pos = self._caret_pos - 1
            end
            
            self:emit_signal( "widget::updated" )
            
        -- przesuwanie kursora w prawo
        elseif key == "Right" then
            if self._caret_pos < #self._char_size then
                self._caret_pos = self._caret_pos + 1
                self._caret_sum = self._caret_sum + self._char_size[self._caret_pos]
            end
            self:emit_signal( "widget::updated" )
            
        -- usuwanie tekstu
        elseif key == "BackSpace" and self._caret_pos > 0 then        
            local csum = self._caret_sum
            local cpos = self._caret_pos
            
            -- podziel tekst, pomijając usuwany znak
            if self._caret_pos < #self._char_size then
                command = command:sub( 1, csum - (self._char_size[cpos] or 0) ) ..
                          command:sub( csum + 1 )
            else
                command = command:sub( 1, csum - (self._char_size[cpos] or 0) )
            end
            
            -- przesuń kursor
            self._caret_pos = self._caret_pos - 1
            self._caret_sum = self._caret_sum - self._char_size[cpos]
            table.remove( self._char_size, cpos )
            
            self:set_text( command, false )
          
        -- usuwanie całości
        elseif key == "Delete" then
            command = ""
            self:set_text("")
            
        -- wyjście z edycji tekstu
        elseif key == "Escape" then
            self:stop_key_capture()
            return false
        end
        
        if key:wlen() == 1 then
            -- podziel tekst i wstaw w odpowiednie miejsce wpisywany znak
            if self._caret_pos < #self._char_size then
                command = command:sub( 1, self._caret_sum) .. key ..
                          command:sub( self._caret_sum + 1 )
            else
                command = command .. key
            end
            
            self._caret_pos = self._caret_pos + 1
            self._caret_sum = self._caret_sum + #key
            table.insert( self._char_size, self._caret_pos, #key )
            
            -- ustaw nowy tekst i nie aktualizuj znaków UTF-8
            self:set_text( command, false )
        end
    end )
end

--[[ edit:set_text
=============================================================================================
 Zmiana wyświetlanego tekstu w kontrolce.
 
 - text   : nowy wyświetlany tekst.
 - cntchr : zliczanie znaków UTF-8 [domyślnie TRUE].
========================================================================================== ]]

function edit:set_text( text, cntchr )
    -- nie przetwarzaj gdy tekst się nie zmienił
    if text == self._cairo_layout.text then
        return
    end

    -- zliczanie znaków UTF-8
    if cntchr ~= false then
        for key, val in ipairs(self._char_size) do
            self._char_size[key] = nil
        end
        self._caret_pos = 0
        self._caret_sum = 0
        
        -- pętla zliczająca znaki
        for key, val in text:gmatch(utf8.charpattern) do
            self._caret_pos = self._caret_pos + 1
            self._caret_sum = self._caret_sum + #key
            table.insert( self._char_size, #key )
        end
    end

    -- ustaw tekst
    self._cairo_layout.text = self._cursor_type ~= edit.cursor_type.line
                              and text .. " " or text         
    self._cairo_layout.attributes = nil
    
    -- wyślij sygnał aktualizacji elementu
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )
end

--[[ edit:get_text
=============================================================================================
 Pobieranie tekstu z pola edycji.
 
 - return : string
========================================================================================== ]]

function edit:get_text()
    if self._cursor_type ~= edit.cursor_type.line then
        return self._cairo_layout.text:sub( 1, #self._cairo_layout.text - 1 )
    end
        
    return self._cairo_layout.text
end

--[[ edit:set_font
=============================================================================================
 Zmiana czcionki tekstu dla pola tekstowego.
 
 - font : nazwa czcionki [opcje] [rozmiar].
========================================================================================== ]]

function edit:set_font( font )
    local desc = theme.get_font( font )
    local name = desc:get_family()
    
    self._cairo_layout:set_font_description( desc )
    self._is_monospace = false
    
    -- sprawdź czy czcionka posiada stałą szerokość znaków
    for key, val in pairs(edit.monospace_fonts) do
        if name == val then
            self._is_monospace = true
            break
        end
    end
    
    -- przyspieszanie działania
    if self._is_monospace then
        local text = self._cairo_layout:get_text()
        
        -- ustaw znak do sprawdzenia szerokości i wysokości znaków
        self._cairo_layout:set_text( "a" )
        
        -- pobierz szerokość i wysokość znaku
        local ink, logical = self._cairo_layout:get_pixel_extents()
        
        -- zapisz wymiary
        self._monospace_dim = {
            logical.width,
            logical.height
        }
        
        -- ustaw poprzedni tekst
        self._cairo_layout:set_text( text )
    end
    
    -- wyślij sygnał aktualizacji elementu
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )
end

--[[ edit:show_empty
=============================================================================================
 Pokazywanie kontrolki nawet gdy brak tekstu do wyświetlenia.
 
 - show : true / false - pokazuj lub nie.
========================================================================================== ]]

function edit:show_empty( show )
    self._drawnil = show 

    -- wyślij sygnał aktualizacji elementu
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )
end

--[[ edit:set_cursor
=============================================================================================
 Zmiana typu kursora dla pola tekstowego (domyślnie kursor blokowy).
 
 - cursor : typ kursora - edit.cursor_type (klucze).
 - color  : kolor (tło) kursora (format HEX lub wzór Cairo).
 - size   : rozmiar kursora (tylko dla under i line).
========================================================================================== ]]

function edit:set_cursor( cursor, color, size )
    self._cursor_type = edit.cursor_type[cursor] or edit.cursor_type.block
    
    self._draw_cursor  = false
    self._cursor_size  = size or 1
    
    -- brak koloru
    if color == false then
        self._cursor_color = nil
    -- hex lub wzór
    elseif color ~= nil then
        self._cursor_color = gcolor( color )
    end
    
    -- wyślij sygnał aktualizacji elementu
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )
end

--[[ new
=============================================================================================
 Tworzenie nowej instancji pola edycji.
 
 - args : argumenty pola edycji:
    > cursor_type  @ set_cursor
    > cursor_color @ set_cursor
    > cursor_size  @ set_cursor
    > show_empty   @ show_empty
    > blink_speed  @ ---
 # group["padding"]
    > padding      @ set_padding
 # group["back"]
    > background   @ set_background
 # group["fore"]
    > foreground   @ set_foreground
 # group["border"]
    > border_color @ set_border
    > border_size  @ set_border
 # group["text"]
    > font         @ set_font
    > text_halign  @ set_align
    > text_valign  @ set_align
    > text_wrap    @ set_wrap
    > ellipsize    @ set_ellipsize
    > start_text   @ set_text
    
 - return : object
========================================================================================== ]]

local function new( args )
    local args = args or {}

    -- utwórz podstawę pola tekstowego
    local retval = {}
    
    signal.initialize( retval )

    -- przypisz funkcję do obiektu
    for key, val in pairs(edit) do
        if type(val) == "function" then
            retval[key] = val
        end
    end
    
    retval._events = {}

    -- pozycja kursora
    retval._caret_pos = 0
    retval._caret_sum = 0
    retval._char_size = {}
    
    -- domyślne wartości
    args.halign    = args.halign    or "left"
    args.valign    = args.valign    or "center"
    args.wrap      = args.wrap      or "char"
    args.ellipsize = args.ellipsize or "start"
    
    -- pobierz grupy i dodaj grupę tekstu
    local groups = args.groups or {}
    table.insert( groups, "text" )
    
    -- inicjalizacja grup
    visual.initialize( retval, groups, args )
    
    -- lista czcionek
    if edit.monospace_fonts == nil then
        edit.monospace_fonts = useful.monospace_font_list( retval._cairo_layout )
    end
    
    -- ustaw dodatkowe zmienne
    retval.set_markup = nil
    retval:show_empty( args.show_empty or false )
    retval:set_text( args.start_text or "" )
    retval:set_font( args.font )
    retval:set_cursor( args.cursor_type, args.cursor_color, args.cursor_size )
    
    -- czasomierz dla kursora (szybkość migania kursora)
    if args.blink_speed ~= false then
        if type(args.blink_speed) ~= "number" then
            args.blink_speed = 0.7
        end
        
        retval._timer = useful.timer( args.blink_speed, "editbox" )
        retval._timer:connect_signal( "timeout", update_blinker )
    end

    return retval
end

--[[ edit.mt:xxx
=============================================================================================
 Tworzenie meta danych dla obiektu.
========================================================================================== ]]

edit.mt = {}

function edit.mt:__call(...)
    return new(...)
end

return setmetatable( edit, edit.mt )
