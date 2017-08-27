-- biblioteki / zmienne
-- ==========================================================================================

local fixed  = require("wibox.layout.fixed")
local button = require("trinity.button")
local vars   = require("trinity.variables")
local tag    = require("awful.tag")
local client = require("awful.client")
local theme  = require("beautiful")

local taglist = {}

-- taglist.filter.xxx
-- ==========================================================================================
-- Lista filtrów dla przycisków przestrzeni roboczych.
-- ==========================================================================================

taglist.filter = {}

function taglist.filter.all( tag )
    -- pokaż wszystkie
    return true
end

function taglist.filter.noempty( tag )
    -- pokaż tylko te, które nie są puste
    return #tag:clients() > 0 or tag.selected
end

-- taglist.release_signal
-- ==========================================================================================
-- Funkcja wywoływana po puszczeniu przycisku myszy z przycisku.
-- ==========================================================================================

function taglist.release_signal( widget, x, y, button, modifier )
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

-- taglist:get_xxx_widget
-- ==========================================================================================
-- Zwraca wybrany element w zbiorze.
-- ==========================================================================================

function taglist:get_first_widget()
    -- zwróć pierwszy element ze zbioru
    return self.widgets[1]
end

function taglist:get_last_widget()
    -- zwróć ostatni element ze zbioru
    return self.widgets[#self.widgets]
end

-- taglist:create_list
-- ==========================================================================================
-- Tworzy listę przycisków na podstawie filtru i dostępnych przestrzeni roboczych.
-- ==========================================================================================

function taglist:create_list( screen, args )
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

-- taglist:create_list
-- ==========================================================================================
-- Aktualizacja własności przycisków.
-- ==========================================================================================

function taglist:update_list( screen )
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
    
    -- dodawanie funkcji do obiektu
    for key, val in pairs(taglist) do
        if type(val) == "function" then
            retval[key] = val
        end
    end
    
    -- filtr przycisków
    retval.filter = args.filter or taglist.filter.all
    
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

-- taglist.mt:xxx
-- ==========================================================================================
-- Tworzenie meta danych dla obiektu.
-- ==========================================================================================

taglist.mt = {}

function taglist.mt:__call(...)
    return new(...)
end

return setmetatable( taglist, taglist.mt )
