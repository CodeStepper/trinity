--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Funkcje miniaturki linii poleceń.
////////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
========================================================================================== ]]

local setmetatable = setmetatable
local type         = type
local assert       = assert
local table        = table
local io           = io
local pairs        = pairs

local useful = require("trinity.useful")
local popup  = require("trinity.popup")
local edit   = require("trinity.widget.edit")
local label  = require("trinity.widget.label")
local fixed  = require("trinity.layout.fixed")
local util   = require("awful.util")
local prompt = {}

--[[ prompt:load_history
=============================================================================================
 Wczytaj listę używanych poleceń z pliku (tzw. histora poleceń).
 Kilka linii poleceń może wczytać jedną historię, dlatego dane są współdzielone.
 Oznacza to że maksymalna ilość poleceń jest współdzielona, a więc może być zapisana tylko
 podczas pierwszego odwołania do pliku i potem nie może być zmieniona.

 - file : plik do wczytania.
 - max  : maksymalna ilość wczytywanych i zapisywanych poleceń.
 
 - return : table[max]{...}.
========================================================================================== ]]

function prompt.load_history( file, max )
    -- zwróć historię jeżeli już istnieje
    if type(prompt.history[file]) == "table" then
        return prompt.history[file]
    end
    
    -- utwórz dowiązanie dla ponownego użycia
    prompt.history[file] = {
        file  = file,
        max   = max,
        table = {}
    }
    
    -- otwórz plik w trybie do odczytu
    local f = io.open( file, "r" )
    local x = 0
    local h = prompt.history[file].table

    -- wczytuj linie
    if f then
        for line in f:lines() do
            -- sprawdź czy komenda już istnieje...
            if util.table.hasitem(h, line) == nil then
                table.insert( h, line )
                x = x + 1
                
                if x >= max then
                    break
                end
            end
        end
        -- zamknij plik
        f:close()
    end
    return prompt.history[file]
end

--[[ prompt:save_history
=============================================================================================
 Zapis całej historii do pliku.
========================================================================================== ]]

function prompt:save_history()
    if self.history == nil then
        return
    end
    
    -- otwórz plik w trybie do zapisu
    local f = io.open( self.history_file, "w" )
    
    -- utwórz ścieżkę do pliku jeżeli nie istnieje
    if not f then
        local x = 0
        for dir in self.history_file:gmatch(".-/") do
            x = x + #dir
        end
        util.mkdir( self.history_file:sub(1, x - 1) )
        
        -- ponownie podejmij próbę otwarcia pliku
        f = assert( io.open(id, "w") )
    end
    
    -- ilość poleceń nie może być większa niż limit...
    local start = 1
    if #self.history - self.history_max > 0 then
        start = #self.history - self.history_max + 1
    end
    
    -- zapisuj polecenia linia po linii...
    for x = start, #self.history do
        f:write( self.history[x] .. "\n" )
    end
    
    -- zamknij plik
    f:close()
end

--[[ prompt:add_to_history
=============================================================================================
 Dodaj podane polecenie do historii.
 
 - command : dodawane polecenie.
 - save    : zapis do pliku po dodaniu polecenia [domyślnie TRUE].
========================================================================================== ]]

function prompt:add_to_history( command, save )
    -- brak otworzonej historii...
    if self.history == nil then
        return
    end
    -- polecenie nie jest tekstem (wtf?)
    if type(command) ~= "string" then
        return
    end
    
    -- usuń białe znaki otaczające komendę
    local command = command:match "^%s*(.-)%s*$"
    -- nie zapisuj pustej komendy...
    if command == "" then
        return
    end
    
    -- sprawdź czy polecenie znajduje się już w historii
    local index = util.table.hasitem( self.history, command )
    
    -- dodaj jeżeli nie ma
    if index == nil then
        table.insert( self.history, command )
        
    -- w przeciwnym razie przenieś na początek
    else
        table.remove( self.history, index )
        table.insert( self.history, command )
    end
    
    -- usuń najstarsze polecenie w przypadku przepełnienia historii
    if #self.history > self.history_max then
        table.remove( self.history, 1 )
    end
    
    if save == false then
        return
    end
    
    -- zapis do pliku
    self:save_history()
end

--[[ prompt:run
=============================================================================================
 Uruchom przechwytywanie klawiszy i pokaż okno z linią poleceń. 
========================================================================================== ]]

function prompt:run()
    -- wczytaj historię poleceń
    local history = self.load_history( self.history_file, self.history_max )

    self.history          = history.table
    self.history_max      = history.max
    self.history_position = #self.history + 1

    -- pokaż okno
    self:set_visible( true )
    
    -- rozpocznij przechwytywanie klawiszy
    self.edit:start_key_capture()
end

--[[ prompt:stop
=============================================================================================
 Schowaj okno z linią poleceń i wyczyść w niej tekst.
 Funkcja uruchamiana po straceniu skupienia przez kontrolkę (naciśnięcie ESC lub ENTER).
========================================================================================== ]]

function prompt:stop()
    self:set_visible( false )
    self.edit:set_text( "" )
end

--[[ prompt:custom_bindings
=============================================================================================
 Rozszerzenie funkcjonalności pola edycji o następujące akcje:
 - Up     : poprzedni element w historii poleceń.
 - Down   : następny element w historii poleceń.
 - Return : wywołanie polecenia.
 Uwaga: nie można wywołać bezpośrednio funkcji set_text podczas przechwytywania klawiszy.
 Należy zwrócić wybrany tekst aby go zaakceptować!
 
 - widget : element wywołujący zdarzenie - tutaj self.edit.
 - mods   : naciśnięte modyfikatory.
 - key    : wciśnięty klawisz.
 
 - return : string / false / nil
========================================================================================== ]]

function prompt:custom_bindings( widget, mods, key )
    -- poprzedni element w historii poleceń
    if key == "Up" then
        if #self.history < 1 then
            return
        end
        
        -- zwiększ do 2 gdy licznik zejdzie poniżej
        if self.history_position < 2 then
            self.history_position = 2
        end
        
        -- zmniejsz pozycję
        self.history_position = self.history_position - 1
    
        -- zapisz aktualny tekst
        return self.history[self.history_position]
        
    -- następny element w historii poleceń
    elseif key == "Down" then
        if #self.history < 1 then
            return
        end
    
        -- wykasuj tekst gdy nie ma więcej poleceń
        if self.history_position >= #self.history then
            self.history_position = #self.history + 1
            
            return ""
        end
        
        -- zwiększ pozycję
        self.history_position = self.history_position + 1
        
        -- zapisz aktualny tekst
        return self.history[self.history_position]
        
    -- wykonanie polecenia
    elseif key == "Return" then
        -- pobierz i zapisz polecenie do historii
        local command = widget:get_text()
        self:add_to_history( command )
        
        -- wykonaj...
        local result = util.spawn( command )

        -- błąd składni?
        if type(result) == "string" then
            -- przewiń licznik na początek historii
            self.history_position = #self.history + 1
            
            -- zwróć błąd do wypisania
            return result
            
        -- wyłącz przechwytywanie klawiszy
        else
            widget:stop_key_capture()
            return false
        end
    end
end

--[[ new
=============================================================================================
 Tworzenie nowej instancji prostej linii poleceń.
 
 - args : argumenty pola edycji:
    > history       @ ---
    > entries       @ ---
    > background    @ set_background
    > foreground    @ set_foreground
    > border_size   @ ---
    > border_color  @ ---
    > min_width     @ set_limits
    > min_height    @ set_limits
    > max_width     @ set_limits
    > max_height    @ set_limits
    > width         @ set_size
    > height        @ set_size
    > posx          @ set_position
    > posy          @ set_position
    > wspace_pos    @ set_position
    > visible       @ set_visible
    > ontop         @ set_ontop
    > padding       @ layout.set_padding
    > elem_space    @ layout.set_elem_space
    > label         @ label.set_text
    > cursor_color  @ edit.set_cursor
    
 - return : popup [ex]
========================================================================================== ]]

local function new( args )
    local args   = args or {}
    local retval = popup( args )

    -- przypisz funkcje do obiektu
    useful.rewrite_functions( prompt, retval )
    -- for key, val in pairs(prompt) do
    --     if type(val) == "function" then
    --         retval[key] = val
    --     end
    -- end
    
    -- ustaw zmienne (nie można ich potem zmienić w trakcie działania)
    retval.history_file      = args.history or util.getdir("cache") .. "/history"
    retval.history_max       = args.entries or 50
    retval.history           = {}
    retval.history_position  = 1
    
    -- napis "wykonaj polecenie:" lub własny
    retval.label = label({
        text = args.label or "wykonaj polecenie:"
    })
    
    -- pole edycji jako linia poleceń
    retval.edit = edit({
        text_wrap    = "char",
        show_empty   = true,
        cursor_type  = "block",
        cursor_color = args.cursor_color
    })

    -- kontener dla napisu i pola edycji
    retval.layout = fixed({
        direction  = "y",
        groups     = {"padding"},
        padding    = args.padding,
        elem_space = args.elem_space
    })

    -- dodaj napis i pole edycji do kontenera
    retval.layout:add( retval.label )
    retval.layout:add( retval.edit )

    -- ustaw kontener jako element główny dla okienka
    retval:set_widget( retval.layout )
    
    -- rejestracja zdarzeń dla pola tekstowego
    retval.edit:connect_signal( "edit::blur", function()
        retval:stop()
    end )
    retval.edit:connect_signal( "key::press", function(widget, mods, key, refs)
        local val = retval:custom_bindings( widget, mods, key )

        if type(val) == "string" then
            refs.string = val
        else
            refs.retval = val
        end
    end )
    
    return retval
end

--[[ ===================================================================================================================
    # meta dane
=================================================================================================================== ]]--

prompt.mt      = {}
prompt.history = {}

function prompt.mt:__call(...)
    return new(...)
end

return setmetatable( prompt, prompt.mt )
