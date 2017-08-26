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
--  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--
--  Panel zawierający dwa panele o stałych rozmiarach elementów (fixed) i jeden o zmiennych
--  rozmiarach elementów znajdujący się na środku (flex).
--  W tym układzie wszystkie trzy panele muszą być ustawione.
--
--  Wzorowany na pliku: trinity/layout/fixed.lua
--
--  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--

local setmetatable = setmetatable
local type         = type
local pairs        = pairs
local error        = error

local Useful     = require("trinity.Useful")
local Signal     = require("trinity.Signal")
local Visual     = require("trinity.Visual")
local FillCenter = {}

-- =================================================================================================
-- Konstruktor - tworzy nową instancję układu o nazwie FillCenter.
-- Lista możliwych do przekazania argumentów:
--   - direction   : Kierunek układu widżetów (x lub y), set_direction.
--   - left        : [obowiązkowy] Układ z lewej strony (fixed), set_layouts.
--   - center      : [obowiązkowy] Układ na środku (flex), set_layouts.
--   - right       : [obowiązkowy] Układ z prawej strony (fixed), set_layouts.
--   - elem_space  : Przestrzeń pomiędzy kolejnymi elementami, set_element_space.
--   - emiter      : Tabela z sygnałami, które mają być przekazywane dalej.
-- # group["padding"]
--   - padding     : Margines wewnętrzny, set_padding.
-- # group["back"]
--   - background  : Tło układu, set_background.
-- # group["border"]
--   - border_color: Kolor ramki, set_border.
--   - border_size : Rozmiar ramki, set_border. 
--
-- @param args Argumenty przekazywane do funkcji lub używane w konstruktorze.
--
-- @todo Możliwość późniejszego przestawienia przekazywanych sygnałów (argument emiter).
-- =================================================================================================

local function new( args )
    local args = args or {}
    
    -- utwórz podstawę elementu
    local retval = {}

    -- typ szablonu
    retval._type    = "layout"
    retval._control = "FillCenter"

    -- sprawdź czy podano dobre szablony
    if type(args.left) ~= "table" or args.left._control ~= "Fixed" or args.left._type ~= "layout" then
        error( "You passed bad layout on left position." )
        return nil
    end
    if type(args.center) ~= "table" or args.center._control ~= "Flex" or args.left._type ~= "layout" then
        error( "You passed bad layout on center position." )
        return nil
    end
    if type(args.right) ~= "table" or args.right._control ~= "Fixed" or args.left._type ~= "layout" then
        error( "You passed bad layout on right position." )
        return nil
    end
    
    -- inicjalizacja sygnałów
    if args.emiter then
        Signal.initialize( retval, args.emiter )
    else
        Signal.initialize( retval )
    end
    
    -- dodawanie funkcji do obiektu
    Useful.rewrite_functions( FillCenter, retval )

    local groups = args.groups or {}
    
    -- nie pozwalaj na dodanie funkcji dla tekstu
    for key, val in pairs(groups) do
        if val == "text" then
            groups[key] = nil
        end
    end

    -- inicjalizacja strefy odpowiedzialnej za wygląd
    Visual.initialize( retval, groups, args )

    -- aktualizacja elementu
    retval.emit_updated = function()
        retval:emit_signal( "widget::updated" )
    end
    -- odświeżenie wymiarów
    retval.emit_resized = function()
        retval:emit_signal( "widget::resized" )
    end

    retval._widgets = {}

    -- przypisz zmienne
    retval:set_layouts( args.left, args.center, args.right, false )
    retval:set_direction( args.direction or "x", false )
    retval:set_element_space( args.elem_space or 0, false )
    
    -- zwróć obiekt
    return retval
end

-- =================================================================================================
-- Rysuje układ na rysowalnym widżecie potomnym.
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function FillCenter:draw( cr )
    -- część wizualna
    self:draw_visual( cr )
    
    -- rysuj układy ze zmienionym kolorem czcionki
    if self._fore then
        cr:save()
        cr:set_source( self._fore )

        self._widgets.left:draw( cr )
        self._widgets.center:draw( cr )
        self._widgets.right:draw( cr )

        cr:restore()
        
    -- rysuj układy z domyślnym kolorem czcionki
    else
        self._widgets.left:draw( cr )
        self._widgets.center:draw( cr )
        self._widgets.right:draw( cr )
    end
end

-- =================================================================================================
-- Oblicza wymiary widżetu lub ustawia z góry określone.
-- Wszystko zależy od argumentów, wartość -1 jest żądaniem o zwrócenie określonego wymiaru.
-- 
-- @param width  Szerokość do której układ ma być rysowany lub -1.
-- @param height Wysokość do której układ ma być rysowany lub -1.
--
-- @return Obliczona szerokość i wysokość w przypadku podania -1.
-- =================================================================================================

function FillCenter:fit( width, height )    
    local new_width, new_height = -1, -1
    local temp   = self._padding
    local px, py = temp[1], temp[2]
    local bounds = self._bounds

    -- -- rozmieszczenie w poziome
    if self._direction == "x" then
        local w, h = 0, 0
        local cpos = 0

        new_height = height - temp[2] - temp[4]
        new_width  = width  - temp[1] - temp[3] - self._space * (#self._widgets - 1)

        -- lewy element, nie kombinuj, dopasuj i ustaw krawędzie widżetów
        w, h = self._widgets.left:fit( -1, new_height )
        new_width = new_width - w
        self._widgets.left:emit_bounds( bounds[1] + px, bounds[2] + py, w, new_height )
        cpos = bounds[1] + px + w

        -- prawy element, dopasuj widżet
        w, h = self._widgets.right:fit( -1, new_height )
        
        -- szerokość środkowego widżetu
        new_width = new_width - w

        -- najpierw krawędzie a potem dopasuj element centralny
        self._widgets.center:emit_bounds( cpos + self._space, bounds[2] + py, new_width, new_height )
        w, h = self._widgets.center:fit( new_width, new_height )

        -- pozycja ostatniego widżetu
        cpos = cpos + new_width + self._space * 2

        -- prawy element, krawędzie emisji, dopasuj element jeszcze raz, aby krawędzie dla widżetów mogły się zaktualizować
        self._widgets.right:emit_bounds( cpos, bounds[2] + py, w, new_height )
        w, h = self._widgets.right:fit( -1, new_height )

    -- rozmieszczenie w pionie
    else
        local w, h = 0, 0
        local cpos = 0

        new_height = height - temp[2] - temp[4] - self._space * (#self._widgets - 1)
        new_width  = width  - temp[1] - temp[3]

        -- lewy element, nie kombinuj, dopasuj i ustaw krawędzie widżetów
        w, h = self._widgets.left:fit( new_width, -1 )
        new_height = new_height - h
        self._widgets.left:emit_bounds( bounds[1] + px, bounds[2] + py, new_width, h )
        cpos = bounds[2] + py + h

        -- prawy element, dopasuj widżet
        w, h = self._widgets.right:fit( new_width, -1 )
        
        -- szerokość środkowego widżetu
        new_height = new_height - h

        -- najpierw krawędzie a potem dopasuj element centralny
        self._widgets.center:emit_bounds( bounds[1] + px, cpos + self._space, new_width, new_height )
        w, h = self._widgets.center:fit( new_width, new_height )

        -- pozycja ostatniego widżetu
        cpos = cpos + new_height + self._space * 2

        -- prawy element, krawędzie emisji, dopasuj element jeszcze raz, aby krawędzie dla widżetów mogły się zaktualizować
        self._widgets.right:emit_bounds( bounds[1] + px, cpos, new_width, h )
        w, h = self._widgets.right:fit( new_width, -1 )
    end

    return width, height
end

-- =================================================================================================
-- Zmiana układów na poszczególnych miejscach.
-- Lewy i prawy musi być układem FIXED, środkowy zaś układem FLEX.
-- 
-- @param fixedleft  Układ z lewej strony (fixed).
-- @param flexcenter Układ na środku (flex).
-- @param fixedright Układ z prawej strony (fixed).
-- @param emitup     Wysyłanie sygnału (true/false) dla aktualizacji widżetu (domyślnie true).
--
-- @return Wskaźnik do układu.
--
-- @todo Do wyboru - czy na pewno chcemy aby dany układ miał emiter? Nie każdy musi.
-- =================================================================================================

function FillCenter:set_layouts( fixedleft, flexcenter, fixedright, emitup )
    -- sprawdź czy podano dobre szablony
    if (fixedleft  ~= nil and (type(fixedleft ) ~= "table" or fixedleft._control  ~= "Fixed" or fixedleft._type  ~= "layout")) or
       (flexcenter ~= nil and (type(flexcenter) ~= "table" or flexcenter._control ~= "Flex"  or flexcenter._type ~= "layout")) or
       (fixedright ~= nil and (type(fixedright) ~= "table" or fixedright._control ~= "Fixed" or fixedright._type ~= "layout")) then
        error( "You passed bad layout on left, right or center position." )
        return
    end

    -- ustaw te które zostały podane
    if fixedleft ~= nil then
        self._widgets.left = fixedleft
        self._widgets.left:signal_emiter( self )
        self._widgets.left:connect_signal( "widget::updated", self.emit_updated )
        self._widgets.left:connect_signal( "widget::resized", self.emit_resized )
    end
    if flexcenter ~= nil then
        self._widgets.center = flexcenter
        self._widgets.center:signal_emiter( self )
        self._widgets.center:connect_signal( "widget::updated", self.emit_updated )
        self._widgets.center:connect_signal( "widget::resized", self.emit_resized )
    end
    if fixedright ~= nil then
        self._widgets.right = fixedright
        self._widgets.right:signal_emiter( self )
        self._widgets.right:connect_signal( "widget::updated", self.emit_updated )
        self._widgets.right:connect_signal( "widget::resized", self.emit_resized )
    end

    -- wyślij sygnał aktualizacji elementu
    if emitup == nil or emitup then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Ustawia przestrzeń pomiędzy kolejnymi przypisanymi układami.
-- 
-- @param space  Przestrzeni pomiędzy kolejnymi widżetami wyrażona w pikselach.
-- @param emitup Aktualizacja widżetów.
--
-- @return Obiekt układu.
-- =================================================================================================

function FillCenter:set_element_space( space, emitup )
    self._space = space
    
    -- wyślij sygnał aktualizacji elementu
    if emitup == nil or emitup then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Ustawia kierunek w którym widżety będą rozmieszczane (x lub y).
-- 
-- @param value  Kierunek rozmieszczania widżetów.
-- @param emitup Aktualizacja widżetów.
--
-- @return Obiekt układu.
-- =================================================================================================

function FillCenter:set_direction( value, emitup )
    self._direction = value == "y" and "y" or "x"

    -- wyślij sygnał aktualizacji elementu
    if emitup == nil or emitup then
        self:emit_signal( "widget::resized" )
        self:emit_signal( "widget::updated" )
    end

    return self
end

-- =================================================================================================
-- Tworzenie metadanych obiektu.
-- =================================================================================================

FillCenter.mt = {}

function FillCenter.mt:__call(...)
    return new(...)
end

return setmetatable( FillCenter, FillCenter.mt )
