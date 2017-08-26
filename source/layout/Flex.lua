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
--  Układ rozmieszczający widżety.
--  Każdy widżet w układzie dostaje tyle samo miejsca.
-- 
--  Wzorowany na pliku: trinity/layout/fixed.lua
--
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--

local setmetatable = setmetatable
local type         = type
local pairs        = pairs

local Useful = require("trinity.Useful")
local Signal = require("trinity.Signal")
local Visual = require("trinity.Visual")
local Flex   = {}

-- =================================================================================================
-- Konstruktor - tworzy nową instancję panelu.
-- Lista możliwych do przekazania argumentów:
--   - direction   : Kierunek układu widżetów (x lub y), set_direction.
--   - fill_space  : Uzupełnianie pustej przestrzeni ostatnim elementem, set_fill_space.
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
-- @todo Kierunek przylegania widżetów (od lewej do prawej, od prawej do lewej).
-- @todo Możliwość późniejszego przestawienia przekazywanych sygnałów (argument emiter).
-- =================================================================================================

local function new( args )
    local args = args or {}
    
    -- utwórz podstawę elementu
    local retval = {}

    -- typ szablonu
    retval._type    = "layout"
    retval._control = "Flex"
    
    -- inicjalizacja sygnałów
    if args.emiter then
        Signal.initialize( retval, args.emiter )
    else
        Signal.initialize( retval )
    end
    
    -- dodawanie funkcji do obiektu
    Useful.rewrite_functions( Flex, retval )

    local groups = args.groups or {}
    
    -- nie pozwalaj na dodanie funkcji dla tekstu
    for key, val in pairs(groups) do
        if val == "text" then
            groups[key] = nil
        end
    end

    -- inicjalizacja strefy odpowiedzialnej za wygląd
    Visual.initialize( retval, groups, args )
    
    -- kierunek umieszczania elementów
    retval._widgets = {}

    -- aktualizacja elementu
    retval.emit_updated = function()
        retval:emit_signal( "widget::updated" )
    end
    -- odświeżenie wymiarów
    retval.emit_resized = function()
        retval:emit_signal( "widget::resized" )
    end

    -- przypisz zmienne
    retval:set_direction( args.direction or "x" )
    retval:set_element_space( args.elem_space or 0 )
    
    -- zwróć obiekt
    return retval
end

-- =================================================================================================
-- Rysuje układ na widżecie potomnym (układ, panel, okno).
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function Flex:draw( cr )
    -- część wizualna
    self:draw_visual( cr )
    
    -- rysuj elementy ze zmienionym kolorem czcionki
    if self._fore then
        cr:save()
        cr:set_source( self._fore )
        
        for key, val in pairs(self._widgets) do
            val:draw( cr )
        end
        
        cr:restore()
        
    -- rysuj element z domyślnym kolorem czcionki
    else
        for key, val in pairs(self._widgets) do
            val:draw( cr )
        end
    end
end

-- =================================================================================================
-- Ustawia z góry określone wymiary dla widżetów.
-- Wszystko zależy od argumentów.
-- Nie można żądać od funkcji obliczenia wymiarów.
-- 
-- @param width  Szerokość do której układ ma być rysowany.
-- @param height Wysokość do której układ ma być rysowany.
--
-- @return Szerokość i wysokość.
--
-- @todo Zrobić żądanie, elementem przewodnim będzie największy widżet.
-- =================================================================================================

function Flex:fit( width, height )
    local new_width, new_height = -1, -1
    local temp   = self._padding
    local px, py = temp[1], temp[2]
    local bounds = self._bounds

    -- rozmieszczenie poziome
    if self._direction == "x" then
        local part_width = 0

        -- szerokość i wysokość
        new_height = height - temp[2] - temp[4]
        new_width  = width  - temp[1] - temp[3] - self._space * (#self._widgets - 1)
        
        if #self._widgets then
            part_width = new_width / #self._widgets
        end

        -- oblicz rozmiary elementów podłączonych
        for key, val in pairs(self._widgets) do
            local w, h = val:fit( part_width, new_height )
            
            -- ustaw granice przechwytywania zdarzeń
            val:emit_bounds( bounds[1] + px, bounds[2] + py, part_width, new_height )
            
            px = px + part_width + self._space
        end
    -- rozmieszczenie pionowe
    else
        local part_height = 0

        -- kontrolowana szerokość
        new_width  = width  - temp[1] - temp[3]
        new_height = height - temp[2] - temp[4] - self._space * (#self._widgets - 1)
        
        if #self._widgets then
            part_height = new_height / #self._widgets
        end

        -- oblicz rozmiary elementów podłączonych
        for key, val in pairs(self._widgets) do
            -- sprawdź wymiary elementu
            local w, h = val:fit( new_width, part_height )
            
            -- ustaw granice przechwytywania zdarzeń
            val:emit_bounds( bounds[1] + px, bounds[2] + py, new_width, part_height )
            
            py = py + part_height + self._space
        end
    end

    return width, height
end

-- =================================================================================================
-- Dodaje widżet do listy.
-- 
-- @param widget Widżet do dodania.
-- @param emiter Ustawia aktualny układ jako emiter dla widżetu, domyślnie false.
--
-- @return Obiekt układu.
-- =================================================================================================

function Flex:add( widget, emiter )
    table.insert( self._widgets, widget )    
    
    widget:connect_signal( "widget::updated", self.emit_updated )
    widget:connect_signal( "widget::resized", self.emit_resized )

    if emiter then
        widget:signal_emiter( self )
    end

    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )

    return self
end

-- =================================================================================================
-- Usuwa wszystkie widżety z listy.
-- 
-- @todo Usuwanie tylko jednego widżetu.
-- =================================================================================================

function Flex:reset()
    for key, val in pairs(self._widgets) do
        val:disconnect_signal( "widget::updated", self.emit_updated )
        val:disconnect_signal( "widget::resized", self.emit_resized )
    end
    
    self._widgets = {}
    
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )
end

-- =================================================================================================
-- Ustawia przestrzeń pomiędzy kolejnymi widżetami przypisanymi do układu.
-- 
-- @param space  Przestrzeni pomiędzy kolejnymi widżetami wyrażona w px.
-- @param emitup Aktualizacja widżetów.
--
-- @return Obiekt układu.
-- =================================================================================================

function Flex:set_element_space( space, emitup )
    self._space = space
    
    if emitup == false then
        return self
    end
    
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )

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

function Flex:set_direction( value, emitup )
    self._direction = value == "y" and "y" or "x"

    if emitup == false then
        return self
    end
 
    -- wyślij sygnał aktualizacji elementu
    self:emit_signal( "widget::resized" )
    self:emit_signal( "widget::updated" )

    return self
end

-- =================================================================================================
-- Tworzenie metadanych obiektu.
-- =================================================================================================

Flex.mt = {}

function Flex.mt:__call(...)
    return new(...)
end

return setmetatable( Flex, Flex.mt )
