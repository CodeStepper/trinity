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

local ATag    = require("awful.tag")
local WLayout = require("awful.layout")
local Theme   = require("beautiful")
local Useful  = require("trinity.Useful")
local Layout  = {}

--[[
 * Konstruktor zadania w tle odpowiedzialnego za zmianę szablonu.
 *
 * DESCRIPTION:
 *     Lista dostępnych ustawień dla konstruktora:
 *         - worker_screen - ekran na którym zadanie działa
 *         - worker_image - czy wyświetlać obraz szablonu na kontrolce?
 *         - worker_text - czy wyświetlać nazwę aktualnego szablonu?
 *         - worker_imgfunc - nazwa funkcji używanej przy ustawianiu obrazka
 *         - worker_txtfunc - nazwa funkcji używanej przy ustawianiu tekstu
 *         - worker_imgsrc - tablica z listą ścieżek do obrazków szablonów
 *         - worker_signal - czy podpiąć domyślne zdarzenia dla zadania?
 *
 *     Po podpięciu zdarzeń kliknięcie w kontrolkę lewym przyciskiem myszy
 *     spowoduje zmianę szablonu do przodu, kliknięcie prawym zaś do tyłu.
 *
 * PARAMETERS:
 *     widget Element do stylizacji [automat].
 *     groups Grupy do stylizacji do których kontrolka może mieć dostęp.
 *     args   Argumenty przekazane podczas tworzenia kontrolki.
]]-- ===========================================================================
local function Constructor( widget, args )
	args = args or {}
	local screen = args.worker_screen or 1

	-- zwykły or nie wystarczy, gdyż po or musiałoby być true
	if args.worker_image == nil then
		args.worker_image = true
	end
	if not widget.worker then
		widget.worker = {}
	end

	Useful.RewriteFunctions( Layout, widget.worker )

	widget.worker._widget  = widget
	widget.worker._screen  = screen
	widget.worker._image   = args.worker_image
	widget.worker._text    = args.worker_text
	widget.worker._imgfunc = args.worker_imgfunc or "SetImage"
	widget.worker._txtfunc = args.worker_txtfunc or "SetText"
	widget.worker._imgsrc  = args.worker_imgsrc or Theme.layouts

	widget.worker:Update()
	
	-- aktualizacja rozmieszczenia okien
	local function TagUpdate( tag )
		return widget.worker:Update()
	end
	
	-- odbieranie sygnałów
	ATag.attached_connect_signal( screen, "property::layout", TagUpdate )
	ATag.attached_connect_signal( screen, "property::selected", TagUpdate )
	
	-- reagowanie na naciśnięcie przycisku
	if args.worker_signal == nil or args.worker_signal then
		widget:connect_signal(
			"button::release",
			widget.worker.OnButtonRelease
		)
	end
end

--[[
 * Funkcja aktualizująca zawartość kontrolki.

 * PARAMETERS:
 *     worker Zadanie przypisane do kontrolki.
]]-- ===========================================================================
function Layout.Update( worker )
	local name   = WLayout.getname( WLayout.get(worker._screen) )
	local widget = worker._widget

	if worker._image then
		widget[worker._imgfunc]( widget, worker._imgsrc[name] )
	end
	if worker._text then
		widget[worker._txtfunc]( widget, name )
	end
end

--[[
 * Funkcja wywoływana po zwolnieniu przycisku myszy z kontrolki.
 *
 * DESCRIPTION:
 *     Zmienia aktualnie przypisany szablon do ekranu.
 *     Kliknięcie prawym przyciskiem myszy zmienia szablon do przodu, zaś
 *     kliknięcie lewym zmienia szablon do tyłu.
 * 
 * PARAMETERS:
 *     widget Kontrolka do której zdarzenie jest wysyłane.
 *     x      Pozycja X kursora.
 *     y      Pozycja Y kursora.
 *     button Numer przycisku który kliknał użytkownik.
]]-- ===========================================================================
function Layout.OnButtonRelease( widget, x, y, button )
	if button == 1 then
		WLayout.inc( 1, widget.worker._screen )
	elseif button == 3 then
		WLayout.inc( -1, widget.worker._screen )
	end
end

Layout.mt = {}

function Layout.mt:__call(...)
	return Constructor(...)
end

return setmetatable( Layout, Layout.mt )
