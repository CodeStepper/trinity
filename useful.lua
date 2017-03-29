--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Funkcje do zarządzanie danymi.
////////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
========================================================================================== ]]

local pairs = pairs
local type  = type

local useful = {}

--[[ useful.monospace_font_list
=============================================================================================
 Pobiera czcionki o stałej szerokości.
 
 - layout : obiekt Pango.Layout.
========================================================================================== ]]

function useful.monospace_font_list( layout )
    -- zwróć istniejącą listę
    if useful.monospace_fonts ~= nil then
        return useful.monospace_fonts
    end
    
    -- utwórz nową listę czcionek
    useful.monospace_fonts = {}

    -- wyszukaj czcionek o stałej szerokości
    for key, val in pairs(layout:get_context():list_families()) do
        if val:is_monospace() then
            table.insert( useful.monospace_fonts, val:get_name() )
        end
    end
    
    return useful.monospace_fonts
end

--[[ useful.timer
=============================================================================================
 Tworzenie czasomierza.
 W przypadku gdy został już utworzony, zwraca go.
 
 - timeout : co ile sekund zdarzenie "timeout" ma zostac wywoływane.
 - name    : unikalna nazwa czasomierza - używana do zwracania istniejących.

 - return : timer
========================================================================================== ]]

function useful.timer( timeout, name )
    if type(timeout) ~= "number" then
        return
    end
    
    -- utwórz tablice gdy brak
    if useful.timers == nil then
        useful.timers = {}
    end

    -- brak nazwy, sprawdzaj po wartościach
    if name ~= nil then
        if useful.timers[name] ~= nil then
            return useful.timers[name]
        end
        
        useful.timers[name] = timer({ timeout = timeout })
        return useful.timers[name]
    end

    -- sprawdzaj czasomierze po nazwach
    if useful.timers[timeout] ~= nil then
        return useful.timers[timeout]
    end
    
    useful.timers[timeout] = timer({ timeout = timeout })
    return useful.timers[timeout]
end

--[[ return
========================================================================================== ]]

return useful
