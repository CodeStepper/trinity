-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- author    : sobiemir
-- release   : v3.5.9
-- license   : GPL2
--
-- Panel pozwalający na rozmieszczenie widżetów.
-- Do panelu przypina się tylko jeden widżet, zważywszy na to iż panel raczej nie będzie się
-- składał z jednego widżetu, do panelu podpina się układ (layout).
--
-- TODO: Przeanalizować dokładnie działanie struts.
-- 
-- Wzorowany na pliku: awful/wibox.lua
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

local beautiful = require("beautiful")
local drawbox   = require("trinity.drawbox")

local capi = {
    awesome = awesome,
    screen  = screen,
    client  = client
}

local setmetatable = setmetatable
local tostring     = tostring
local ipairs       = ipairs
local table        = table
local error        = error

local panel  = {}
local panels = {}

-- =================================================================================================
-- Odświeża pozycje wszystkich utworzonych paneli.
-- =================================================================================================

local function refresh_all_panels_positions()
    for _, wprop in ipairs(panels) do
        wprop.panel:set_position( wprop.position )
    end
end

-- =================================================================================================
-- Odświeża wymiary miejsca zajmowanego przez panel.
-- 
-- @param drawbox Obiekt na którym rysowane będą widżety.
--
-- @todo Dowiedzieć się jak działa struts...
-- =================================================================================================

local function refresh_drawbox_strut( drawbox )
    for _, wprop in ipairs(panels) do
        if wprop.wibox == drawbox then
            -- jeżeli nie jest widoczny, nie wyświetlaj... logiczne...
            if not drawbox.visible then
                drawbox:struts { left = 0, right = 0, bottom = 0, top = 0 }
            elseif wprop.position == "top" then
                drawbox:struts { left = 0, right = 0, bottom = 0, top = drawbox.height + 2 * drawbox.border_width }
            elseif wprop.position == "bottom" then
                drawbox:struts { left = 0, right = 0, bottom = drawbox.height + 2 * drawbox.border_width, top = 0 }
            elseif wprop.position == "left" then
                drawbox:struts { left = drawbox.width + 2 * drawbox.border_width, right = 0, bottom = 0, top = 0 }
            elseif wprop.position == "right" then
                drawbox:struts { left = 0, right = drawbox.width + 2 * drawbox.border_width, bottom = 0, top = 0 }
            end
            break
        end
    end
end

-- =================================================================================================
-- Aktualizuje pozycje wszystkich utworzonych paneli gdy zaszły zmiany w zajmowanym miejscu.
-- Funkcja wywoływana jest przez sygnał, przyjmując jeden argument, choć w dokumentacji nie jest
-- sprecyzowane żeby cokolwiek przyjmowała.
--
-- @param c ...
--
-- @see https://awesome.naquadah.org/wiki/Signals
--
-- @todo Dowiedzieć się co to jest to C.
-- =================================================================================================

local function update_panels_on_struts( c )
    local struts = c:struts()

    if struts.left ~= 0 or struts.right ~= 0 or struts.top ~= 0 or struts.bottom ~= 0 then
        refresh_all_panels_positions()
    end
end

-- =================================================================================================
-- Wstawia nowy panel do listy utworzonych paneli.
-- W przypadku gdy panel istnieje, zmienia mu tylko pozycję.
-- Czy taka sytuacja w ogóle będzie miała miejsce?
--
-- @param panel    Panel dodawany do listy.
-- @param position Pozycja wyświetlania panelu.
-- @param screen   Pulpit na którym panel będzie wyświetlany.
-- =================================================================================================

local function attach_panel( panel, position, screen )
    local wibox_prop

    -- sprawdź czy panel już istnieje
    for x = #panels, 1, -1 do
        if panels[x].panel == nil or panels[x].wibox == nil then
            table.remove( panels, x )
        elseif panels[x].panel == panel then
            wibox_prop = panels[x]
        end
    end

    -- zmień pozycje istniejącego lub dodaj nowy
    if wibox_prop then
        wibox_prop.panel._position = position
        wibox_prop.position        = position
    else
        table.insert( panels, setmetatable({
            wibox    = panel._drawbox,
            panel    = panel,
            position = position,
            screen   = screen
        }, { __mode = 'v' }) )
    end

    -- przechwytuj sygnały
    panel._drawbox:connect_signal( "property::width",   refresh_drawbox_strut )
    panel._drawbox:connect_signal( "property::height",  refresh_drawbox_strut )
    panel._drawbox:connect_signal( "property::visible", refresh_drawbox_strut )

    panel._drawbox:connect_signal( "property::width",        refresh_all_panels_positions )
    panel._drawbox:connect_signal( "property::height",       refresh_all_panels_positions )
    panel._drawbox:connect_signal( "property::visible",      refresh_all_panels_positions )
    panel._drawbox:connect_signal( "property::border_width", refresh_all_panels_positions )
end

-- =================================================================================================
-- Konstruktor - tworzy nową instancję panelu.
-- Lista możliwych do przekazania argumentów:
--   - background  : Tło panelu, set_background.
--   - foreground  : Kolor napisów na panelu, set_foreground.
--   - border_width: Rozmiar ramki panelu.
--   - border_color: Kolor ramki dla panelu.
--   - visible     : Widoczność panelu, domyślnie true, set_visible.
--   - cursor      : Kursor widoczny po najechaniu myszą na panel.
--   - width       : Szerokość panelu, set_dimensions, stretch_panel
--   - height      : Wysokość panelu, set_dimensions, stretch_panel
--   - align       : Przyleganie panelu gdy nie jest rozciągnięty, set_align.
--   - position    : Pozycja panelu, domyślnie "top", set_position.
--   - screen      : Numer pulpitu na którym panel ma się pojawić.
--
-- @param args Argumenty przekazywane do funkcji lub używane w konstruktorze.
--
-- @todo Ramki z różną wielkością, przezroczystość (niby jest, ale nie pamiętam jak).
-- @todo Sprawdzić dokładnie jakie argumenty może jeszcze przyjąć.
-- =================================================================================================

local function new( args )
    local args    = args or {}
    local stretch = true

    -- wartości domyślne
    args.position = args.position or "top"
    args.screen   = args.screen   or 1
    args.type     = args.type     or "dock"
    args.visible  = args.visible  or true
    args.align    = args.align    or "left"

    -- sprawdź czy podana została odpowiednia pozycja
    if args.position ~= "top"  and args.position ~= "bottom" and
       args.position ~= "left" and args.position ~= "right" then
        error( "Invalid position, use only 'top', 'bottom', 'left', and 'right'." )
        return
    end

    -- oblicz wysokości i szerokości w zależności od położenia
    if args.position == "left" or args.position == "right" then
        args.width = args.width or beautiful.get_font_height( args.font ) * 1.5

        if args.height then
            -- procent zajęcia powierzchni
            local hp = tostring(args.height):match("(%d+)%%")
            stretch  = false

            -- oblicz ilość pikseli dla danego procentu zajęcia powierzchni
            if hp then
                args.height = capi.screen[args.screen].geometry.height * hp / 100
            end
        end
    else
        args.height = args.height or beautiful.get_font_height( args.font ) * 1.5

        if args.width then
            -- procent zajęcia powierzchni
            local wp = tostring(args.width):match("(%d+)%%")
            stretch  = false

            -- oblicz ilość pikseli dla danego procentu zajęcia powierzchni
            if wp then
                args.width = capi.screen[args.screen].geometry.width * wp / 100
            end
        end
    end

    -- kontener do rysowania
    local retval = {
        _drawbox  = drawbox( args ),
        _position = args.position,
        _screen   = args.screen,
        _align    = args.align
    }

    -- przypisz funkcje do obiektu
    for key, val in pairs(panel) do
        if type(val) == "function" then
            retval[key] = val
        end
    end

    -- ponowne rysowanie
    retval.emit_updated = function()
        retval._drawbox:draw()
    end

    -- aktualizacja wymiarów elementów
    retval.emit_resized = function()
        retval:refresh_geometry()
    end

    -- dodaj panel do listy
    attach_panel( retval, args.position, args.screen )

    -- rozciągnij panel po całej szerokości lub wysokości ekranu
    if stretch then
        retval:stretch_panel()
    -- ustaw przyleganie panelu do konkretnej krawędzi ekranu
    else
        retval:set_align( args.align )
    end

    -- ustaw pozycję wyświetlania panelu
    retval:set_position( args.position )

    return retval
end

-- =================================================================================================
-- Odświeża wymiary kontrolek w środku układu.
-- Wywoływane automatycznie przy operacjach aktualizacji wymiarów i zmiany widżetu.
-- =================================================================================================

function panel:refresh_geometry()
    -- pobierz szerokość i wysokość
    local width, height = self._drawbox.width, self._drawbox.height

    if not self._drawbox._widget then
        return
    end

    -- odśwież wymiary ustawionego widżetu
    self._drawbox._widget:fit( width, height )
    self._drawbox._widget:emit_bounds( 0, 0, width, height )
end

-- =================================================================================================
-- Chowa lub pokazuje na sztywno panel.
--
-- @param value Wartość do przekazania (TRUE - pokaż, FALSE - ukryj).
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_visible( value )
    self._drawbox.visible = value
    refresh_drawbox_strut( self._drawbox )

    self:emit_resized()
    self:emit_updated()

    return self
end

-- =================================================================================================
-- Zmienia kolor tła panelu.
-- Po więcej informacji patrz na drawbox.set_background.
--
-- @param color Kolor tła.
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_background( color )
    self._drawbox.set_background( color )

    return self
end

-- =================================================================================================
-- Zmienia kolor czcionki rysowanej na panelu.
-- Po więcej informacji patrz na drawbox.set_foreground.
--
-- @param color Kolor czcionki.
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_foreground( color )
    self._drawbox.set_foreground( color )

    return self
end

-- =================================================================================================
-- Zmienia szerokości i/lub wysokości panelu.
--
-- @param width  Szerokość panelu, można podać w procentach gdy układ poziomy, opcjonalna.
-- @param height Wysokość panelu, można podać w procentach gdy układ pionowy, opcjonalna.
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_dimensions( width, height )
    local stretch = true

    -- oblicz wysokości i szerokości w zależności od położenia
    if self._position == "left" or self._position == "right" then
        if width then
            self._drawbox.width = width
        end
        if height then
            -- procent zajęcia powierzchni
            local hp = tostring(height):match("(%d+)%%")
            stretch  = false

            -- oblicz ilość pikseli dla danego procentu zajęcia powierzchni
            if hp then
                self._drawbox.height = capi.screen[self._screen].geometry.height * hp / 100
            else
                self._drawbox.height = height
            end
        end
    else
        if height then
            self._drawbox.height = height
        end

        if width then
            -- procent zajęcia powierzchni
            local wp = tostring(width):match("(%d+)%%")
            stretch  = false

            -- oblicz ilość pikseli dla danego procentu zajęcia powierzchni
            if wp then
                self._drawbox.width = capi.screen[self._screen].geometry.width * wp / 100
            else
                self._drawbox.width = width
            end
        end
    end

    -- rozciągnij panel po całej szerokości lub wysokości ekranu
    if stretch then
        self:stretch_panel()
    -- ustaw przyleganie panelu do konkretnej krawędzi ekranu
    else
        self:set_align( self._align )
    end

    self:emit_resized()
    self:emit_updated()

    return self
end

-- =================================================================================================
-- Zmienia pozycję rozmieszczenia panelu.
--
-- @param position Pozycja rozmieszczenia panelu (top, bottom, left, right).
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_position( position )
    local area = capi.screen[self._screen].geometry

    -- oblicz pozycje X lub Y w zależności od ustawienia
    if position == "right" then
        self._drawbox.x = area.x + area.width - (self._drawbox.width + 2 * self._drawbox.border_width)
    elseif position == "left" then
        self._drawbox.x = area.x
    elseif position == "bottom" then
        self._drawbox.y = (area.y + area.height) - (self._drawbox.height + 2 * self._drawbox.border_width)
    elseif position == "top" then
        self._drawbox.y = area.y
    end

    -- ustaw pozycję panelu
    self._position = position

    for _, wprop in ipairs(panels) do
        if wprop.panel == self then
            wprop.position = position
            break
        end
    end

    self:emit_resized()
    self:emit_updated()

    return self
end

-- =================================================================================================
-- Zmienia przyleganie nierozciągniętego panelu.
-- Panel nie jest rozciągnięty gdy podana jest szerokość lub wysokość (w zależności od ułożenia)
-- i nie zajmuje on 100% powierzchni względem osi X lub Y.
-- Wartość near przyciąga do najbliższej krawędzi, far do najdalszej, center wyśrodkowuje panel.
--
-- @param align Przyciąganie do boku (near, center, far)
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_align( align )
    local position = self:get_position()
    local area     = capi.screen[self._screen].workarea

    -- panel z prawej strony
    if position == "right" then
        if align == "near" then
            self._drawbox.y = area.y
        elseif align == "far" then
            self._drawbox.y = area.y + area.height - (self._drawbox.height + 2 * self._drawbox.border_width)
        elseif align == "center" then
            self._drawbox.y = area.y + (area.height - self._drawbox.height) / 2
        end
    -- panel z lewej strony
    elseif position == "left" then
        if align == "far" then
            self._drawbox.y = (area.y + area.height) - (self._drawbox.height + 2 * self._drawbox.border_width)
        elseif align == "near" then
            self._drawbox.y = area.y
        elseif align == "center" then
            self._drawbox.y = area.y + (area.height - self._drawbox.height) / 2
        end
    -- panel na dole
    elseif position == "bottom" then
        if align == "far" then
            self._drawbox.x = area.x + area.width - (self._drawbox.width + 2 * self._drawbox.border_width)
        elseif align == "near" then
            self._drawbox.x = area.x
        elseif align == "center" then
            self._drawbox.x = area.x + (area.width - self._drawbox.width) / 2
        end
    -- panel na górze
    elseif position == "top" then
        if align == "far" then
            self._drawbox.x = area.x + area.width - (self._drawbox.width + 2 * self._drawbox.border_width)
        elseif align == "near" then
            self._drawbox.x = area.x
        elseif align == "center" then
            self._drawbox.x = area.x + (area.width - self._drawbox.width) / 2
        end
    end

    -- aktualizuj dane
    refresh_drawbox_strut( self._drawbox )

    self:emit_resized()
    self:emit_updated()

    return self
end

-- =================================================================================================
-- Rozciąga panel na całą długość lub szerokość ekranu w zależności od położenia.
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:stretch_panel()
    local position = self:get_position()
    local area     = capi.screen[self._screen].workarea

    if position == "right" or position == "left" then
        self._drawbox.height = area.height - (2 * self._drawbox.border_width)
        self._drawbox.y      = area.y
    else
        self._drawbox.width = area.width - (2 * self._drawbox.border_width)
        self._drawbox.x     = area.x
    end

    self:emit_resized()
    self:emit_updated()

    return self
end

-- =================================================================================================
-- Zmienia widżet wyświetlany w panelu.
-- Panel może mieć tylko jeden widżet, dlatego warto wstawić tutaj układ.
--
-- @param widget Widżet do ustawienia.
--
-- @return Obiekt panelu.
-- =================================================================================================

function panel:set_widget( widget )
    local draw = self._drawbox
    
    -- przy zamianie odłącz podłączone sygnały
    if draw._widget then
        draw._widget:disconnect_signal( "widget::updated", self.emit_updated )
        draw._widget:disconnect_signal( "widget::resized", self.emit_resized )
    end
    
    -- podłącz sygnały
    draw:set_widget( widget )
    widget:connect_signal( "widget::updated", self.emit_updated )
    widget:connect_signal( "widget::resized", self.emit_resized )
    
    self.emit_resized()
    self.emit_updated()

    return self
end

-- =================================================================================================
-- Pobiera aktualną pozycję rozmieszczenia panelu.
--
-- @return Pozycja rozmieszczenia panelu (top, bottom, left, right).
-- =================================================================================================

function panel:get_position()
    return self._position
end

-- =================================================================================================
-- Pobiera ustawioną wartość przylegania panelu.
--
-- @return Przyleganie panelu.
-- =================================================================================================

function panel:get_align()
    return self._align
end

-- =================================================================================================
-- Pobiera pulpit na którym ustawiony jest panel.
--
-- @return Numer pulpitu.
-- =================================================================================================

function panel:get_screen()
    return self._screen
end

-- =================================================================================================
-- Aktualizacja pozycji paneli po zmianie danych.
-- =================================================================================================

capi.client.connect_signal( "property::struts", update_panels_on_struts )
capi.client.connect_signal( "unmanage",         update_panels_on_struts )

-- =================================================================================================
-- Tworzenie metadanych obiektu.
-- =================================================================================================

panel.mt = {}

function panel.mt:__call(...)
    return new(...)
end

return setmetatable( panel, panel.mt )
