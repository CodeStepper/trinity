--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Nowa koncepcja wysyłania / odbierania sygnałów.
////////////////////////////////////////////////////////////////////////////////////////// ]]

-- @todo Możliwość wyrzucenia wszystkich przypisanych zdarzeń

--[[ require
========================================================================================== ]]

local capi = {
    mouse    = mouse,
    mgrabber = mousegrabber
}

local pairs  = pairs
local type   = type
local error  = error
local next   = next
local signal = {}

-- sygnały długodystansowe
signal.long_emiter = {
    ["mouse::enter"   ] = "_mouse_regs",
    ["mouse::move"    ] = "_mouse_regs",
    ["mouse::leave"   ] = "_mouse_regs",
    ["button::press"  ] = "_button_regs",
    ["button::release"] = "_button_regs",
    ["button::click"  ] = "_button_regs"
}

-- szybkie ustawianie zmiennych dla sygnałów długodystansowych
signal.long_setter = {
    ["mouse::enter"   ] = function(t,w,b) t._mouse_regs[w][1]  = b end,
    ["mouse::move"    ] = function(t,w,b) t._mouse_regs[w][2]  = b end,
    ["mouse::leave"   ] = function(t,w,b) t._mouse_regs[w][3]  = b end,
    ["button::press"  ] = function(t,w,b) t._button_regs[w][1] = b end,
    ["button::release"] = function(t,w,b) t._button_regs[w][2] = b end,
    ["button::click"  ] = function(t,w,b) t._button_regs[w][3] = b end
}

--[[ signal:add_signal
=============================================================================================
 Zachowana dla kompatybilności z wcześniejszym systemem.
 Zawsze można jej użyć aby zaznaczyć w kodzie, że sygnał został w tym miejscu dodany.
 
 - name : nazwa sygnału do dodania.
========================================================================================== ]]

function signal:add_signal( name )
    if not self._signals[name] then
        self._signals[name] = {}
    end
end

--[[ signal:connect_signal
=============================================================================================
 Przyłączenie funkcji do podanego sygnału - tworzy tablicę gdy brak sygnału.
 
 - name : nazwa sygnału do dołączenia.
 - func : nazwa funkcji do dołączenia przy emisji podanego sygnału.
========================================================================================== ]]

function signal:connect_signal( name, func )
    if not self._signals[name] then
        self._signals[name] = {}
    end

    self._signals[name][func] = func
    
    -- rejestruj element z sygnałem w emiterze
    if self._emiter then
        self._emiter:register_signal( self, name )
    end

    return self
end

function signal:get_signals()
    local signames = {}

    for signame, data in pairs(self._signals) do
        table.insert( signames, signame )
    end

    return signames
end

--
-- Lista możliwych sygnałów i ich zależności:
--   - mouse_enter    @ mouse_move, mouse_leave      : Przy wejściu w kontrolkę wskaźnikiem myszy.
--   - mouse_move     @ mouse_move                   : Przy poruszaniu po kontrolce myszą.
--   - mouse_leave    @ mouse_leave                  : Przy wyjściu z kontrolki wskaźnikiem myszy. 
--   - button_press   @ button_press                 : Po naciśnięciu przycisku myszy.
--   - button_click   @ button_press, button_release : Po kliknięciu w kontrolkę.
--   - button_release @ button_release               : Po puszczeniu przycisku myszy.

function signal:multi_connect( signals )
    if type(signals) ~= "table" then
        return
    end

    if type(signals.mouse_enter) == "function" then
        self:connect_signal( "mouse::enter", signals.mouse_enter )
    end
    if type(signals.mouse_move) == "function" then
        self:connect_signal( "mouse::move", signals.mouse_move )
    end
    if type(signals.mouse_leave) == "function" then
        self:connect_signal( "mouse::leave", signals.mouse_leave )
    end
    if type(signals.button_press) == "function" then
        self:connect_signal( "button::press", signals.button_press )
    end
    if type(signals.button_click) == "function" then
        self:connect_signal( "button::click", signals.button_click )
    end
    if type(signals.button_release) == "function" then
        self:connect_signal( "button::release", signals.button_release )
    end

    return self
end

--[[ signal:disconnect_signal
=============================================================================================
 Odłączenie funkcji od podanego sygnału.
 
 - name : nazwa sygnału do sprawdzenia.
 - func : nazwa funkcji do odłączenia od podanego sygnału.
========================================================================================== ]]

function signal:disconnect_signal( name, func )
    if not self._signals[name] then
        return
    end
    
    self._signals[name][func] = nil
    
    if self._emiter then
        -- wyrejestruj element dla sygnału w emiterze gdy tablica jest pusta
        if next(self._signals[name]) == nil then
            self._emiter:unregister_signal( self, name )
        end
    end
end

--[[ signal:emit_signal
=============================================================================================
 Uruchom wszystkie przypisane funkcje do danego sygnału.
 
 - name : nazwa sygnału do emisji.
 - ...  : dodatkowe argumenty funkcji.
========================================================================================== ]]

function signal:emit_signal( name, ... )
    if not self._signals[name] then
        return
    end
    
    -- uruchamiaj przypisane funkcje
    for func in pairs(self._signals[name]) do
        func( self, ... )
    end
end

--[[ signal:signal_emiter
=============================================================================================
 Ustaw nowy emiter sygnału dla podanej kontrolki.
 Emiter musi zawierać kontrolkę, dlatego emiterem powinno być okienko lub układ.
 
 - emiter : ---
========================================================================================== ]]

function signal:signal_emiter( emiter )
    if not emiter.register_signal then
        error( "This object is not valid signal emiter." )
        return
    end
    
    -- nic się nie zmieniło...
    if self._emiter == emiter then
        return
    end
    
    -- wyrejestruj sygnały dla poprzedniego emitera
    if self._emiter then
        self._emiter:unregister_signal( self, nil )
    end
    
    self._emiter = emiter
    
    -- rejestruj sygnały...
    for key, val in pairs(self._signals) do
        if next(val) ~= nil then
            emiter:register_signal( self, key )
        end
    end
end

--[[ signal:register_signal
=============================================================================================
 Rejestracja sygnału w emiterze dla podanego elementu.
 Lista dostępnych sygnałów: signal.long_emiter.
 
 - widget : element do rejestracji.
 - name   : sygnał do rejestracji (musi już istnieć).
========================================================================================== ]]

function signal:register_signal( widget, name )
    if not widget then
        return
    end
    
    -- podany sygnał długodystansowy nie istnieje...
    if not signal.long_emiter[name] then
        return
    end
    
    local sigvar = signal.long_emiter[name]

    -- utwórz nową tablicę
    if not self[sigvar][widget] then
        self[sigvar][widget] = { false, false, false, false }
    end
    
    -- ustaw odpowiedni sygnał
    signal.long_setter[name]( self, widget, true )
end

--[[ signal:unregister_signal
=============================================================================================
 Wyrejestrowywanie sygnału z emitera.
 Przeważnie funkcja uruchamiana jest automatycznie.
 
 - widget : element do usunięcia.
 - name   : sygnał do przeszukania.
========================================================================================== ]]

function signal:unregister_signal( widget, name )
    if not widget then
        return
    end
    
    -- podany sygnał długodystansowy nie istnieje...
    if not signal.long_emiter[name] then
        return
    end

    -- wyrejestrowywanie wszystkich sygnałów dla podanego elementu
    if name == nil then
        self._mouse_regs[widget]  = nil
        self._button_regs[widget] = nil
    else
        local sigvar = signal.long_emiter[name]
        
        -- nie ma niczego do wyrejestrowywania
        if not self[sigvar][widget] then
            return
        end
        
        -- usuń podany sygnał
        signal.long_setter[name]( self, widget, false )
        
        local breg, mreg = self._button_regs, self._mouse_regs
        
        -- sprawdź czy usunąć tablicę (gdy zmienna nie ma sygnałów)
        if breg[1] == false and breg[2] == false and breg[3] == false then
            self._button_regs[widget] = nil
        end
        if mreg[1] == false and mreg[2] == false and mreg[3] == false then
            self._mouse_regs[widget] = nil
        end
    end
end

--[[ signal.move_emiter
=============================================================================================
 Dalsza emisja sygnałów (do zarejestrowanych kontrolek).
 Emitowane sygnały: "mouse::enter", "mouse::move", "mouse::leave".
 Aby mouse::enter został wyemitowany, obiekt musi odbierać dwa podstawowe zdarzenia:
 mouse::move i mouse::leave.
 To samo zdanie dotyczy zdarzenia mouse::leave.
 
 - object : obiekt przechwytujący zdarzenie.
 - x      : pozycja X myszy.
 - y      : pozycja Y myszy.
========================================================================================== ]]

function signal.move_emiter( object, x, y )
    local bds
    
    -- sprawdzaj wszystkie zarejestrowane elementy
    for key, val in pairs(object._mouse_regs) do
        bds = key._bounds
        
        -- sprawdź czy mysz znajduje się na kontrolce
        if x >= bds[1] and y <= bds[4] and x <= bds[3] and y >= bds[2] then
            -- wejście w kontrolkę
            if val[1] and not val[4] then
                key:emit_signal( "mouse::enter" )
            end
            val[4] = true
            
            -- ruch po kontrolce
            if val[2] then
                key:emit_signal( "mouse::move", x, y )
            end
        else
            -- wyjście z kontrolki
            if val[3] and val[4] then
                key:emit_signal( "mouse::leave" )
            end
            val[4] = false
        end
    end
end

--[[ signal.leave_emiter
=============================================================================================
 Dalsza emisja sygnałów (do zarejestrowanych kontrolek).
 Emitowane sygnały: "mouse::leave".
 
 - object : obiekt przechwytujący zdarzenie.
========================================================================================== ]]

function signal.leave_emiter( object )
    -- sprawdzaj wszystkie zarejestrowane elementy
    for key, val in pairs(object._mouse_regs) do
        -- wyjście z kontrolki
        if val[3] and val[4] then
            key:emit_signal( "mouse::leave" )
        end
        val[4] = false
    end
end

--[[ signal.press_emiter
=============================================================================================
 Dalsza emisja sygnałów (do zarejestrowanych kontrolek).
 Emitowane sygnały:
 "mouse::leave", "mouse::enter", "mouse::move", "button::press", "button::release".
 
 - object : obiekt przechwytujący zdarzenie.
 - x      : pozycja X myszy.
 - y      : pozycja Y myszy.
 - button : wciśnięty przycisk.
 - mods   : wciśnięte modyfikatory (klawiatura).
========================================================================================== ]]

function signal.press_emiter( object, x, y, button, mods )
    local bds

    -- sprawdzaj wszystkie zarejestrowane elementy
    for key, val in pairs(object._button_regs) do
        bds = key._bounds

        -- sprawdź czy mysz znajduje się na kontrolce
        if x >= bds[1] and y <= bds[4] and x <= bds[3] and y >= bds[2] then
            -- wciśnięcie przycisku myszy na kontrolce
            if val[1] then
                key:emit_signal( "button::press", x, y, button, mods )
            end
            -- obsługa kliknięcia
            if val[3] and button == 1 then
                val[4] = true
                
                -- pobierz obiekt i aktualne koordynaty pod myszką
                local pressobj = capi.mouse.object_under_pointer()
                local mcoords  = capi.mouse.coords()
                local inobject = true
                local mousedif = {
                    x = mcoords.x - x,
                    y = mcoords.y - y
                }
                
                -- przechwytywanie ruchu myszy
                if not capi.mgrabber.isrunning() then
                    capi.mgrabber.run( function(data)
                        -- pobierz koordynaty (wykrycie kliknięcia) i obiekt pod myszką
                        local ndata  = capi.mouse.coords()
                        local objup  = capi.mouse.object_under_pointer()
                        local key    = key
                        local value  = value
                        local object = object
                    
                        -- opuszczenie kontrolki
                        if pressobj ~= objup then
                            if inobject then
                                pressobj.drawable:emit_signal( "mouse::leave" )
                            end
                            inobject = false
                        else
                            -- wejście w kontrolkę
                            if not inobject then
                                pressobj.drawable:emit_signal( "mouse::enter" )
                            end
                            -- ruch po kontrolce
                            pressobj.drawable:emit_signal( "mouse::move",
                                data.x - mousedif.x, data.y - mousedif.y )
                            inobject = true
                        end
                    
                        -- puszczenie przycisku myszy
                        if ndata.buttons[1] == false then
                            -- emituj zdarzenie puszczenia klawisza myszy
                            -- kontrolka potraktuje to jako kliknięcie gdy val[4] = true
                            if pressobj == objup then
                                pressobj.drawable:emit_signal( "button::release",
                                    data.x - mousedif.x, data.y - mousedif.y, button, mods )
                            else
                                -- przycisk został puszczony na innym obiekcie
                                -- zresetuj val[4] - możliwość odebrania kliknięcia myszy
                                for key, val in pairs(object._button_regs) do
                                    val[4] = false
                                end
                            end
                            -- zatrzymaj przechwytywanie myszy
                            capi.mgrabber.stop()
                            return false
                        end
                        return true
                    end, "arrow" ) -- capi.mgrabber.run
                end -- if not capi.mgrabber.isrunning
            end -- if val[3] and button == 1
        end -- if
    end -- for
end

--[[ signal.release_emiter
=============================================================================================
 Dalsza emisja sygnałów (do zarejestrowanych kontrolek).
 Emitowane sygnały: "button::click", "button::release".
 Aby button::click poprawnie został wyemitowany, musi odbierać dwa podstawowe zdarzenia:
 button::press i button::release.
 
 - object : obiekt przechwytujący zdarzenie.
 - x      : pozycja X myszy.
 - y      : pozycja Y myszy.
 - button : wciśnięty przycisk.
 - mods   : wciśnięte modyfikatory (klawiatura).
========================================================================================== ]]

function signal.release_emiter( object, x, y, button, mods )
    local bds

    -- sprawdzaj wszystkie zarejestrowane elementy
    for key, val in pairs(object._button_regs) do
        bds = key._bounds

        -- sprawdź czy mysz znajduje się na kontrolce
        if x >= bds[1] and y <= bds[4] and x <= bds[3] and y >= bds[2] then
            -- emitowanie kliknięcia myszy (gdy ustawione val[4])
            if val[4] and button == 1 then
                key:emit_signal( "button::click", x, y )
            end
            -- emitowanie puszczenia przycisku myszy
            if val[2] then
                key:emit_signal( "button::release", x, y, button, mods )
            end
        end
        val[4] = false
    end
end

--[[ signal:emit_bounds
=============================================================================================
 Krawędzie emisji sygnałów długodystansowych.
 Krawędzie są równocześnie (muszą być) krawędziami kontrolki.
 Wywoływane zazwyczaj automatycznie przez funkcję rysującą kontrolkę.
 
 - cr : obiekt Cairo.
 - gx : pozycja X obiektu.
 - gy : pozycja Y obiektu.
 - gw : szerokość obiektu.
 - gh : wysokość obiektu.
========================================================================================== ]]

function signal:emit_bounds( gx, gy, gw, gh )
    if gx ~= false then
        self._bounds[1] = gx
    end
    if gy ~= false then
        self._bounds[2] = gy
    end
    if gw ~= false then
        self._bounds[5] = gw
    end
    if gh ~= false then
        self._bounds[6] = gh
    end

    self._bounds[3] = self._bounds[1] + self._bounds[5]
    self._bounds[4] = self._bounds[2] + self._bounds[6]
end

--[[ signal.initialize
=============================================================================================
 Inicjalizacja systemu przechwytywania i emisji sygnałów.
 
 - object  : obiekt do inicjalizacji.
 - manager : menedżer - obiekt będzie rozsyłał sygnały po dzieciach.
========================================================================================== ]]

function signal.initialize( object, manager )
    -- dodaj zmienne
    object._signals = {}
    object._bounds  = { 0, 0, 0, 0, 0, 0 }

    -- dodaj funkcje
    object.add_signal        = signal.add_signal
    object.connect_signal    = signal.connect_signal
    object.multi_connect     = signal.multi_connect
    object.get_signals       = signal.get_signals
    object.disconnect_signal = signal.disconnect_signal
    object.emit_signal       = signal.emit_signal
    object.signal_emiter     = signal.signal_emiter
    object.emit_bounds       = signal.emit_bounds
    
    -- menedżer częściowy, dla układów, znajdują się w menedżerze i rozsyłają zdarzenia po dzieciach
    -- działają na dwa fronty, dlatego możliwy jest wybór rozsyłanych sygnałów
    -- można oczywiście każdy element podrzędny podpiąć do najwyższego, czyli do menedżera
    if type(manager) == "table" then
        object.register_signal = signal.register_signal
        
        -- zmienne rejestracji elementów
        object._mouse_regs  = {}
        object._button_regs = {}

        for key, val in pairs(manager) do
            if val == "mouse::move" then
                object:connect_signal( "mouse::move", signal.move_emiter )
            elseif val == "mouse::leave" then
                object:connect_signal( "mouse::leave", signal.leave_emiter )
            elseif val == "button::press" then
                object:connect_signal( "button::press", signal.press_emiter )
            elseif val == "button::release" then
                object:connect_signal( "button::release", signal.release_emiter )
            end
        end

    -- ustanów podany obiekt menedżerem
    elseif manager then
        object.signal_emiter   = nil
        object.register_signal = signal.register_signal
        
        -- zmienne rejestracji elementów
        object._mouse_regs  = {}
        object._button_regs = {}

        -- przechwytywane zdarzenia do przetworzenia
        object:connect_signal( "mouse::move", signal.move_emiter )
        object:connect_signal( "mouse::leave", signal.leave_emiter )
        object:connect_signal( "button::press", signal.press_emiter )
        object:connect_signal( "button::release", signal.release_emiter )
    end
end

--[[ return
========================================================================================== ]]

return signal
