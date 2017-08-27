-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- author    : sobiemir
-- release   : v3.5.9
-- license   : GPL2
--
-- Układ rozmieszczający widżety.
-- Widżety rozmieszczane są względem tego ile miejsca potrzebują.
-- Każdy widżet dostaje tyle miejsca o ile prosi.
-- 
-- Wzorowany na pliku: wibox/layout/fixed.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

local setmetatable = setmetatable
local type         = type
local pairs        = pairs

local useful = require("trinity.useful")
local signal = require("trinity.signal")
local visual = require("trinity.visual")
local fixed  = {}

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
    retval._ltype = "fixed" 
    
    -- inicjalizacja sygnałów
    if args.emiter then
        signal.initialize( retval, args.emiter )
    else
        signal.initialize( retval )
    end
    
    -- dodawanie funkcji do obiektu
    useful.rewrite_functions( fixed, retval )
    
    local groups = args.groups or {}
    
    -- nie pozwalaj na dodanie funkcji dla tekstu
    for key, val in pairs(groups) do
        if val == "text" then
            groups[key] = nil
        end
    end

    -- inicjalizacja strefy odpowiedzialnej za wygląd
    visual.initialize( retval, groups, args )
    
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
    retval:set_fill_space( args.fill_space or false )
    retval:set_element_space( args.elem_space or 0 )
    
    -- zwróć obiekt
    return retval
end

-- =================================================================================================
-- Rysuje układ na widżecie potomnym (układ, panel, okno).
-- 
-- @param cr Obiekt CAIRO (biblioteka graficzna).
-- =================================================================================================

function fixed:draw( cr )
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
-- Oblicza wymiary widżetu lub ustawia z góry określone.
-- Wszystko zależy od argumentów, wartość -1 jest żądaniem o zwrócenie określonego wymiaru.
-- 
-- @param width  Szerokość do której układ ma być rysowany lub -1.
-- @param height Wysokość do której układ ma być rysowany lub -1.
--
-- @return Obliczona szerokość i wysokość w przypadku podania -1.
-- =================================================================================================

function fixed:fit( width, height )
    local new_width, new_height = -1, -1
    local temp   = self._padding
    local px, py = temp[1], temp[2]
    local bounds = self._bounds

    -- rozmieszczenie poziome
    if self._direction == "x" then
        local maxh = 0
        
        -- kontrolowana wysokość
        if height ~= -1 then
            new_height = height - temp[2] - temp[4]
        end
        -- kontrolowana szerokość
        if width ~= -1 then
            new_width = width - temp[1] - temp[3] - self._space * (#self._widgets - 1)
        else
            new_width = temp[1] + temp[3] + self._space * (#self._widgets - 1)
        end
        
        -- oblicz rozmiary elementów podłączonych
        for key, val in pairs(self._widgets) do
            -- sprawdź wymiary elementu
            local w, h = val:fit( -1, new_height )
            
            -- ustaw granice przechwytywania zdarzeń
            if height == -1 then
                val:emit_bounds( bounds[1] + px, bounds[2] + py, w, false )
            else
                val:emit_bounds( bounds[1] + px, bounds[2] + py, w, new_height )
            end
            
            -- oblicz maksymalną wysokość (gdy nie jest zdefiniowana)
            if height == -1 and h > maxh then
                maxh = h
            end
            
            -- oblicz szerokość układu
            if width == -1 then
                new_width = new_width + w
            -- lub po prostu zobacz ile może wejść elementów
            else
                new_width = new_width - w
                
                -- dopasuj ostatni element do pozostałego miejsca
                if new_width < 0 then
                    val:emit_bounds( false, false, new_width + w, false )
                    break
                end
            end
            
            px = px + w + self._space
        end
        
        -- uzupełnij wolną przestrzeń ostatnim elementem
        if width ~= -1 and new_width > 0 and self._fill_space then
            local widget = self._widgets[#self._widgets]
            widget:emit_bounds( false, false, widget._bounds[5] + new_width, false )
        end
        
        -- przypisz wcześniejszą szerokość
        if width ~= -1 then
            new_width = width
        end
        
        -- po znalezieniu maksymalnej wysokości przypisz ją do wszystkich elementów
        if height == -1 then
            new_height = maxh
            for key, val in pairs(self._widgets) do
                val:emit_bounds( false, false, false, new_height )
            end
        end
        
        -- dodaj marginesy do wysokości
        new_height = new_height + temp[1] + temp[3]
        
    -- rozmieszczenie pionowe
    else
        local maxw = 0
        
        -- kontrolowana szerokość
        if width ~= -1 then
            new_width = width - temp[1] - temp[3]
        end
        -- kontrolowana wysokość
        if height ~= -1 then
            new_height = height - temp[2] - temp[4] - self._space * (#self._widgets - 1)
        else
            new_height = temp[2] + temp[4] + self._space * (#self._widgets - 1)
        end
        
        -- oblicz rozmiary elementów podłączonych
        for key, val in pairs(self._widgets) do
            -- sprawdź wymiary elementu
            local w, h = val:fit( new_width, -1 )
            
            -- ustaw granice przechwytywania zdarzeń
            if width == -1 then
                val:emit_bounds( bounds[1] + px, bounds[2] + py, false, h )
            else
                val:emit_bounds( bounds[1] + px, bounds[2] + py, new_width, h )
            end
            
            -- oblicz maksymalną szerokość (gdy nie jest zdefiniowana)
            if width == -1 and w > maxw then
                maxw = w
            end
            
            -- oblicz wysokość układu
            if height == -1 then
                new_height = new_height + h
            -- lub po prostu zobacz ile może wejść elementów
            else
                new_height = new_height - h
                
                -- dopasuj ostatni element do pozostałego miejsca
                if new_height < 0 then
                    val:emit_bounds( false, false, new_width + w, false )
                    break
                end
            end
            
            py = py + h + self._space
        end
        
        -- uzupełnij wolną przestrzeń ostatnim elementem
        if height ~= -1 and new_height > 0 and self._fill_space then
            local widget = self._widgets[#self._widgets]
            widget:emit_bounds( false, false, false, widget._bounds[6] + new_height )
        end
        
        -- przypisz wcześniejszą wysokość
        if height ~= -1 then
            new_height = height
        end
        
        -- po znalezieniu maksymalnej szerokości przypisz ją do wszystkich elementów
        if width == -1 then
            new_width = maxw
            for key, val in pairs(self._widgets) do
                val:emit_bounds( false, false, new_width, false )
            end
        end
        
        -- dodaj marginesy do szerokości
        new_width = new_width + temp[1] + temp[3]
    end

    -- zwróć nowe wymiary
    return new_width, new_height
end

-- =================================================================================================
-- Dodaje widżet do listy.
-- 
-- @param widget Widżet do dodania.
-- @param emiter Ustawia aktualny układ jako emiter dla widżetu, domyślnie false.
--
-- @return Obiekt układu.
-- =================================================================================================

function fixed:add( widget, emiter )
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

function fixed:reset()
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

function fixed:set_element_space( space, emitup )
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

function fixed:set_direction( value, emitup )
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
-- Ustawia wypełnianie ostatniego elementu do końca układu.
-- Gdy rozmiar układu jest z góry ustalony, a rozmiar wszystkich widżetów nie przekracza rozmiaru
-- układu, to gdy wartość ustawiona jest na true, ostatni element będzie rozszerzony tak, aby
-- wypełnić całą pozostałą przestrzeń.
-- 
-- @param value  Wypełnianie pustej przestrzeni (true / false).
-- @param emitup Aktualizacja widżetów.
--
-- @return Obiekt układu.
-- =================================================================================================

function fixed:set_fill_space( value, emitup )
    self._fill_space = value
    
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

fixed.mt = {}

function fixed.mt:__call(...)
    return new(...)
end

return setmetatable( fixed, fixed.mt )
