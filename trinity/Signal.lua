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

local capi = {
	mouse    = mouse,
	mgrabber = mousegrabber
}
local Signal = {}

-- Sygnały długodystansowe.
-- =============================================================================
Signal.long_emitter = {
	["mouse::enter"   ] = "_mouse_regs",
	["mouse::move"    ] = "_mouse_regs",
	["mouse::leave"   ] = "_mouse_regs",
	["button::press"  ] = "_button_regs",
	["button::release"] = "_button_regs",
	["button::click"  ] = "_button_regs"
}

-- Szybkie ustawianie zmiennych dla sygnałów długodystansowych.
-- =============================================================================
Signal.long_setter = {
	["mouse::enter"   ] = function(t,w,b) t._mouse_regs[w][1]  = b end,
	["mouse::move"    ] = function(t,w,b) t._mouse_regs[w][2]  = b end,
	["mouse::leave"   ] = function(t,w,b) t._mouse_regs[w][3]  = b end,
	["button::press"  ] = function(t,w,b) t._button_regs[w][1] = b end,
	["button::release"] = function(t,w,b) t._button_regs[w][2] = b end,
	["button::click"  ] = function(t,w,b) t._button_regs[w][3] = b end
}

--[[
 * Inicjalizuje system wysyłania i przechwytywania sygnałów.
 *
 * DESCRIPTION:
 *     Każda szanująca się kontrolka powinna mieć możliwość przypięcia się do
 *     sygnału lub jego emisji.
 *     Sygnał można podpiąć do kontrolki funkcją connect_signal.
 *
 *     Aby wysyłanie sygnałów było możliwe, należy do każdego z nich podpiąć
 *     menedżer, który będzie je rozsyłał po kontrolkach potomnych.
 *     
 *     Lista domyślnych sygnałów możliwych do podpięcia:
 *         - mouse::enter
 *         - mouse::move
 *         - mouse::leave
 *         - button::press
 *         - button::release
 *         - button::click
 * 
 * PARAMETERS:
 *     widget Element do stylizacji [automat].
 *     groups Grupy do stylizacji do których kontrolka może mieć dostęp.
 *     args   Argumenty przekazane podczas tworzenia kontrolki.
]]-- ===========================================================================
function Signal.initialize( object, manager )
	object._signals = {}

	if not object._bounds then
		object._bounds  = { 0, 0, 0, 0, 0, 0 }
	end

	object.add_signal        = Signal.add_signal
	object.connect_signal    = Signal.connect_signal
	object.multi_connect     = Signal.multi_connect
	object.get_signals       = Signal.get_signals
	object.disconnect_signal = Signal.disconnect_signal
	object.emit_signal       = Signal.emit_signal
	object.signal_emitter    = Signal.signal_emitter
	object.emit_bounds       = Signal.emit_bounds
	
	-- obiekt będzie przechwytywał sygnały
	if type(manager) == "table" then
		object.register_signal = Signal.register_signal
		
		-- zmienne rejestracji elementów
		object._mouse_regs  = {}
		object._button_regs = {}

		for key, val in pairs(manager) do
			if val == "mouse::move" then
				object:connect_signal( "mouse::move",
					Signal.move_emitter
				)
			elseif val == "mouse::leave" then
				object:connect_signal( "mouse::leave",
					Signal.leave_emitter
				)
			elseif val == "button::press" then
				object:connect_signal( "button::press",
					Signal.press_emitter
				)
			elseif val == "button::release" then
				object:connect_signal( "button::release",
					Signal.release_emitter
				)
			end
		end

	-- obiekt będzie zarządzał sygnałami
	elseif manager then
		object.signal_emitter   = nil
		object.register_signal = Signal.register_signal
		
		-- zmienne rejestracji elementów
		object._mouse_regs  = {}
		object._button_regs = {}

		-- przechwytywane zdarzenia do przetworzenia
		object:connect_signal( "mouse::move", Signal.move_emitter )
		object:connect_signal( "mouse::leave", Signal.leave_emitter )
		object:connect_signal( "button::press", Signal.press_emitter )
		object:connect_signal( "button::release", Signal.release_emitter )
	end
end

--[[ Signal:connect_signal
=============================================================================================
 Przyłączenie funkcji do podanego sygnału - tworzy tablicę gdy brak sygnału.
 
 - name : nazwa sygnału do dołączenia.
 - func : nazwa funkcji do dołączenia przy emisji podanego sygnału.
========================================================================================== ]]

function Signal:connect_signal( name, func )
	if not self._signals[name] then
		self._signals[name] = {}
	end

	self._signals[name][func] = func
	
	-- rejestruj element z sygnałem w emitterze
	if self._emitter then
		self._emitter:register_signal( self, name )
	end

	return self
end

function Signal:get_signals()
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

function Signal:multi_connect( signals )
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

--[[ Signal:disconnect_signal
=============================================================================================
 Odłączenie funkcji od podanego sygnału.
 
 - name : nazwa sygnału do sprawdzenia.
 - func : nazwa funkcji do odłączenia od podanego sygnału.
========================================================================================== ]]

function Signal:disconnect_signal( name, func )
	if not self._signals[name] then
		return
	end
	
	self._signals[name][func] = nil
	
	if self._emitter then
		-- wyrejestruj element dla sygnału w emitterze gdy tablica jest pusta
		if next(self._signals[name]) == nil then
			self._emitter:deregister_signal( self, name )
		end
	end
end

--[[ Signal:emit_signal
=============================================================================================
 Uruchom wszystkie przypisane funkcje do danego sygnału.
 
 - name : nazwa sygnału do emisji.
 - ...  : dodatkowe argumenty funkcji.
========================================================================================== ]]

function Signal:emit_signal( name, ... )
	if not self._signals[name] then
		return
	end
	
	-- uruchamiaj przypisane funkcje
	for func in pairs(self._signals[name]) do
		func( self, ... )
	end
end

--[[ Signal:signal_emitter
=============================================================================================
 Ustaw nowy emitter sygnału dla podanej kontrolki.
 Emiter musi zawierać kontrolkę, dlatego emitterem powinno być okienko lub układ.
 
 - emitter : ---
========================================================================================== ]]

function Signal:signal_emitter( emitter )
	if not emitter.register_signal then
		error( "This object is not valid signal emitter." )
		return
	end
	
	-- nic się nie zmieniło...
	if self._emitter == emitter then
		return
	end
	
	-- wyrejestruj sygnały dla poprzedniego emittera
	if self._emitter then
		self._emitter:deregister_signal( self, nil )
	end
	
	self._emitter = emitter
	
	-- rejestruj sygnały...
	for key, val in pairs(self._signals) do
		if next(val) ~= nil then
			emitter:register_signal( self, key )
		end
	end
end

--[[ Signal:register_signal
=============================================================================================
 Rejestracja sygnału w emitterze dla podanego elementu.
 Lista dostępnych sygnałów: Signal.long_emitter.
 
 - widget : element do rejestracji.
 - name   : sygnał do rejestracji (musi już istnieć).
========================================================================================== ]]

function Signal:register_signal( widget, name )
	if not widget then
		return
	end
	
	-- podany sygnał długodystansowy nie istnieje...
	if not Signal.long_emitter[name] then
		return
	end
	
	local sigvar = Signal.long_emitter[name]

	-- utwórz nową tablicę
	if not self[sigvar][widget] then
		self[sigvar][widget] = { false, false, false, false }
	end
	
	-- ustaw odpowiedni sygnał
	Signal.long_setter[name]( self, widget, true )
end

--[[ Signal:deregister_signal
=============================================================================================
 Wyrejestrowywanie sygnału z emittera.
 Przeważnie funkcja uruchamiana jest automatycznie.
 
 - widget : element do usunięcia.
 - name   : sygnał do przeszukania.
========================================================================================== ]]

function Signal:deregister_signal( widget, name )
	if not widget then
		return
	end
	
	-- podany sygnał długodystansowy nie istnieje...
	if not Signal.long_emitter[name] then
		return
	end

	-- wyrejestrowywanie wszystkich sygnałów dla podanego elementu
	if name == nil then
		self._mouse_regs[widget]  = nil
		self._button_regs[widget] = nil
	else
		local sigvar = Signal.long_emitter[name]
		
		-- nie ma niczego do wyrejestrowywania
		if not self[sigvar][widget] then
			return
		end
		
		-- usuń podany sygnał
		Signal.long_setter[name]( self, widget, false )
		
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

--[[ Signal.move_emitter
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

function Signal.move_emitter( object, x, y )
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

--[[ Signal.leave_emitter
=============================================================================================
 Dalsza emisja sygnałów (do zarejestrowanych kontrolek).
 Emitowane sygnały: "mouse::leave".
 
 - object : obiekt przechwytujący zdarzenie.
========================================================================================== ]]

function Signal.leave_emitter( object )
	-- sprawdzaj wszystkie zarejestrowane elementy
	for key, val in pairs(object._mouse_regs) do
		-- wyjście z kontrolki
		if val[3] and val[4] then
			key:emit_signal( "mouse::leave" )
		end
		val[4] = false
	end
end

--[[ Signal.press_emitter
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

function Signal.press_emitter( object, x, y, button, mods )
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

--[[ Signal.release_emitter
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

function Signal.release_emitter( object, x, y, button, mods )
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

--[[ Signal:emit_bounds
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

function Signal:emit_bounds( gx, gy, gw, gh )
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

--[[ return
========================================================================================== ]]

return Signal
