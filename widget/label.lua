-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- @author    sobiemir
-- @release   v3.5.9
-- @license   GPL, see LICENSE file
--
-- Kontrolka etykiety.
-- Po ustawieniu przechwytywania akcji może stać się również przyciskiem.
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

local setmetatable = setmetatable
local type         = type
local pairs        = pairs
local table        = table

local signal = require("trinity.signal")
local visual = require("trinity.visual")
local label  = {}

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
--   - font         @ set_font       : Czcionka napisu.
--   - text_halign  @ set_align      : Przyleganie tekstu w poziomie.
--   - text_valign  @ set_align      : Przyleganie tekstu w pionie.
--   - text_wrap    @ set_wrap       : Zawijanie tekstu.
--   - ellipsize    @ set_ellipsize  : Umieszczenie lub wyłączenie trzykropka gdy za długi tekst.
--   - text         @ set_text       : Zwykły tekst.
--   - markup       @ set_markup     : Tekst w formacie PANGO Markup (podobny do HTML).
--
-- @param args    Tablica zawierająca wyżej wymienione argumenty (opcjonalny).
-- @param signals Przechwytywane przez kontrolkę sygnały (opcjonalny).
--
-- @return Nowy obiekt etykiety.
-- =================================================================================================

local function new( args, signals )
    local args = args or {}

    -- no niestety, coś trzeba podać w polu tekst lub markup
    args.text = args.text or "example"

    -- utwórz podstawę pola tekstowego
    local retval = {}

    -- inicjalizacja sygnałów
    signal.initialize( retval )

    -- przypisz funkcję do obiektu
    for key, val in pairs(label) do
        if type(val) == "function" then
            retval[key] = val
        end
    end
    
    -- pobierz grupy i dodaj grupę tekstu
    local groups = args.groups or {}
    table.insert( groups, "text" )
    
    -- inicjalizacja grup i funkcji
    visual.initialize( retval, groups, args )
    
    -- ustaw dodatkowe zmienne
    retval:show_empty( args.show_empty or false, false )
    
    -- tekst
    if type(args.markup) == "string" then
        retval:set_markup( args.markup )
    else
        retval:set_text( args.text )
    end
    
    return retval
end

-- =================================================================================================
-- Rysuje etykietę na kontrolce nadrzędnej.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function label:draw( cr )
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

function label:fit( width, height )
    local new_width  = width
    local new_height = height

    -- obszar do pominięcia (margines wewnętrzny kontrolki)
    local marw = self._padding[1] + self._padding[3]
    local marh = self._padding[2] + self._padding[4]
    
    -- zerowe wymiary (lub jeden z nich) - lub gdy kontrolka się nie zmieści
    if (width ~= -1 and width <= marw) or (height ~= -1 and height <= marh) then
        -- @info
        return 0, 0
    end
    
    -- odejmij wcięcia
    new_width  = width  > 0 and width  - marw or width
    new_height = height > 0 and height - marh or height
    
    -- wymiary tekstu
    local tw, th = self:calc_text( new_width, new_height )

    -- zerowe wymiary
    if (not self._drawnil and tw == 0) or th == 0 then
        -- @info
        return 0, 0
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

function label:show_empty( value, update )
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

label.mt = {}

function label.mt:__call(...)
    return new(...)
end

return setmetatable( label, label.mt )
