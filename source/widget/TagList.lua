-- biblioteki / zmienne
-- ==========================================================================================

local Fixed  = require("wibox.layout.fixed")
local Button = require("trinity.button")
local Vars   = require("trinity.Variables")
local Tag    = require("awful.tag")
local Client = require("awful.client")
local Theme  = require("beautiful")
local Useful = require("trinity.Useful")

local TagList = {}

-- TagList.filter.xxx
-- ==========================================================================================
-- Lista filtrów dla przycisków przestrzeni roboczych.
-- ==========================================================================================

TagList.filter = {}

function TagList.filter.all( tag )
    -- pokaż wszystkie
    return true
end

function TagList.filter.noempty( tag )
    -- pokaż tylko te, które nie są puste
    return #tag:clients() > 0 or tag.selected
end

-- TagList.release_signal
-- ==========================================================================================
-- Funkcja wywoływana po puszczeniu przycisku myszy z przycisku.
-- ==========================================================================================

function TagList.release_signal( widget, x, y, button, modifier )
    local modkey = false
    
    -- sprawdź czy został naciśnięty klawisz modyfikatora
    for key, val in pairs(modifier) do
        if val == vars.MODKEY then
            modkey = true
        end
    end

    -- lpm
    if button == vars.LMB then
        -- win + lpm - przenieś okno na wybraną przestrzeń roboczą
        if modkey then
            client.movetotag( widget.tag )
        -- lpm - przłącz na wybraną przestrzeń roboczą
        else
            tag.viewonly( widget.tag )
        end
    -- ppm
    elseif button == vars.RMB then
        -- win + ppm - ??
        if modkey then
            client.toggletag( widget.tag )
        -- ppm - zaznacz widok do podglądu (współdzielenie ekranu)
        else
            tag.viewtoggle( widget.tag )
        end
    -- przełącz na poprzedni widok
    elseif button == vars.LMS then
        tag.viewprev( tag.getscreen(widget.tag) )
    -- przełącz na następny widok
    elseif button == vars.RMS then
        tag.viewnext( tag.getscreen(widget.tag) )
    end
end

-- TagList:get_xxx_widget
-- ==========================================================================================
-- Zwraca wybrany element w zbiorze.
-- ==========================================================================================

function TagList:get_first_widget()
    -- zwróć pierwszy element ze zbioru
    return self.widgets[1]
end

function TagList:get_last_widget()
    -- zwróć ostatni element ze zbioru
    return self.widgets[#self.widgets]
end

-- TagList:create_list
-- ==========================================================================================
-- Tworzy listę przycisków na podstawie filtru i dostępnych przestrzeni roboczych.
-- ==========================================================================================

function TagList:create_list( screen, args )
    -- dodaj przyciski do zbioru
    for key, val in ipairs(tag.gettags(screen)) do
        -- sprawdź czy obszar nie jest schowany, dodatkowo przefiltruj dane
        if not tag.getproperty(val, "hide") and self:filter(val) then
            args.text  = val.name
            args.image = tag.geticon(val)
            
            -- utwórz przycisk
            local button = button( args )
            button.tag   = val
            
            -- utwórz sygnał po puszczeniu klawisza
            button:connect_signal( "button::release", self.release_signal )
            self:add( button )
        end
    end
    
    -- aktualizuj wyświetlane przyciski
    self:update_list( screen )
end

-- TagList:create_list
-- ==========================================================================================
-- Aktualizacja własności przycisków.
-- ==========================================================================================

function TagList:update_list( screen )
    local background

    -- aktualizuj wszystkie przyciski
    for key, val in ipairs(tag.gettags(screen)) do
    
        -- zaznacz jeżeli obszar roboczy jest aktywny
        if val.selected == true then
            background = theme.widget_color.taglist.selected
        else
            background = theme.widget_color.taglist.normal
        end
        
        -- ustaw nowe tło przycisku
        self.widgets[key]:set_back( background )
    end
end

-- new
-- ==========================================================================================
-- Tworzenie nowego zbioru przycisków (listy obszarów roboczych).
-- ==========================================================================================

local function new( args )
    local args = args or {}
    
    -- utwórz szablon (poziomy)
    local retval = fixed.horizontal()
    local screen = args.screen or 1
    
    -- informacje o kontrolce
    retval._control = "TagList"
    retval._type    = "composite"

    -- przypisz funkcje do obiektu
    Useful.rewrite_functions( TagList, retval )
    
    -- filtr przycisków
    retval.filter = args.filter or TagList.filter.all
    
    -- przygotowanie do aktualizacji listy
    local function prepare_update( t )
        retval:update_list( tag.getscreen(t) )
    end
    
    -- przechwytywanie sygnału wywoływanego po zmianie obszaru roboczego
    tag.attached_connect_signal( screen, "property::selected", prepare_update )

    -- utwórz listę
    retval:create_list( screen, args )
    
    -- zwróć zbiór elementów
    return retval
end

-- TagList.mt:xxx
-- ==========================================================================================
-- Tworzenie meta danych dla obiektu.
-- ==========================================================================================

TagList.mt = {}

function TagList.mt:__call(...)
    return new(...)
end

return setmetatable( TagList, TagList.mt )
