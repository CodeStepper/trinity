--[[ ////////////////////////////////////////////////////////////////////////////////////////
 @author    : sobiemir
 @release   : v3.5.6

 Pojemnik do rysowania...
////////////////////////////////////////////////////////////////////////////////////////// ]]

--[[ require
========================================================================================== ]]

local capi = {
    drawin  = drawin,
    root    = root,
    awesome = awesome
}

local pairs        = pairs
local type         = type
local setmetatable = setmetatable

local surface = require("gears.surface")
local color   = require("gears.color")
local theme   = require("beautiful")
local cairo   = require("lgi").cairo
local signal  = require("trinity.signal")

local drawbox   = {}
local drawables = setmetatable( {}, { __mode = 'k' } )
local wallpaper = nil

--[[ redraw_drawbox
=============================================================================================
 Rysowanie pojemnika.
 
 - self : pojemnik do rysowania (jest to funkcja lokalna, więc pasuje go przekazać).
========================================================================================== ]]

local function redraw_drawbox( self )
    -- powierzchnia rysowania
    local surf = surface( self._drawable.surface )
    if not surf then
        return
    end
    
    -- przygotuj zmienne do rysowania
    local cr  = cairo.Context( surf )
    local dim = self._drawable:geometry()
    local x, y, width, height = dim.x, dim.y, dim.width, dim.height

    -- zapisz ustawienia rysowania
    cr:save()

    -- sprawdź czy menedżer kompozycji jest właczony
    if not capi.awesome.composite_manager_running then
        -- przezroczystość - rysowanie tapety w tle
        if not wallpaper then
            wallpaper = surface( capi.root.wallpaper() )
        else
            cr.operator = cairo.Operator.SOURCE
            cr:set_source_surface( wallpaper, -x, -y )
            cr:paint()
        end
        cr.operator = cairo.Operator.OVER
    else
        -- przezroczystość - gdy włączony menedżer kompozycji
        cr.operator = cairo.Operator.SOURCE
    end

    -- rysuj tło pojemnika
    cr:set_source( self._back )
    cr:paint()
    
    -- rysuj element...
    if self._widget then
        cr:set_source( self._fore )
        self._widget:draw( cr )
    end
    
    -- przywróć poprzednie ustawienia rysowania
    cr:restore()
    self._drawable:refresh()
end

--[[ drawbox:set_widget
=============================================================================================
 Wstawianie elementu do pojemnika.
 Najczęściej jest nim kontener (układ kontrolek).
 
 - widget : element do wstawienia.
========================================================================================== ]]

function drawbox:set_widget( widget )
    -- false zamiast nil, ponieważ nie można w obiekcie ustawiać nowych wartości...
    local widget = widget or false

    -- odłącz sygnał od starego elementu
    if self._widget then
        self._widget:disconnect_signal( "widget::updated", self.draw )
    end
    
    -- zmień element i przypisz do niego sygnał
    self._widget = widget    
    if widget then
        widget:connect_signal( "widget::updated", self.draw )
    end
    
    -- przypisz emiter do wstawianego elementu
    widget:signal_emiter( self )
    
    -- przerysuj pojemnik (aby pokazał się nowo dodany element)
    self.draw()
end

--[[ drawbox:set_background
=============================================================================================
 Kolor tła elementu.
 
 - fore : kolor w formacie HEX lub odpowiedni wzorzec dla obiektu Cairo.
========================================================================================== ]]

function drawbox:set_background( back )
    local back = back or theme.bg_normal or "#000000"

    -- rozpoznawanie koloru
    if type(back) == "string" or type(back) == "table" then
        back = color( back )
    end

    local redraw_on_move = not color.create_opaque_pattern( back )
    
    -- przerysowywanie przy przemieszczeniu (gdy tło jest przezroczyste)
    if self._redraw_on_move ~= redraw_on_move then
        self._redraw_on_move = redraw_on_move
        
        if redraw_on_move then
            self._drawable:connect_signal( "property::x", self.draw )
            self._drawable:connect_signal( "property::y", self.draw )
        else
            self._drawable:disconnect_signal( "property::x", self.draw )
            self._drawable:disconnect_signal( "property::y", self.draw )
        end
    end

    self._back = back
    self.draw()
end

--[[ drawbox:set_foreground
=============================================================================================
 Kolor czcionki.
 
 - fore : kolor w formacie HEX lub odpowiedni wzorzec dla obiektu Cairo.
========================================================================================== ]]

function drawbox:set_foreground( fore )
    local fore = fore or theme.fg_normal or "#FFFFFF"

    -- rozpoznawanie koloru
    if type(fore) == "string" or type(fore) == "table" then
        fore = color( fore )
    end
    
    self._fore = fore
    self.draw()
end

--[[ setup_signals
=============================================================================================
 Przechwytywanie sygnałów rodzica.
 
 - object : obiekt z elementami do przechwycenia.
========================================================================================== ]]

function setup_signals( object )
    function capture_event( from, signal )
        object:add_signal( signal )
    
        from:connect_signal( signal, function(_, ...)
            object:emit_signal( signal, ... )
        end )
    end

    capture_event( object._drawable, "button::press" )
    capture_event( object._drawable, "button::release" )
    capture_event( object._drawable, "mouse::enter" )
    capture_event( object._drawable, "mouse::leave" )
    capture_event( object._drawable, "mouse::move" )
    capture_event( object._drawable, "property::surface" )
    
    capture_event( object._drawin, "property::border_color" )
    capture_event( object._drawin, "property::border_width" )
    capture_event( object._drawin, "property::buttons" )
    capture_event( object._drawin, "property::cursor" )
    capture_event( object._drawin, "property::width" )
    capture_event( object._drawin, "property::height" )
    capture_event( object._drawin, "property::x" )
    capture_event( object._drawin, "property::y" )
    capture_event( object._drawin, "property::ontop" )
    capture_event( object._drawin, "property::visible" )
    capture_event( object._drawin, "property::opacity" )
    capture_event( object._drawin, "property::structs" )
end

--[[ drawbox:geometry
=============================================================================================
 Przechwytywanie sygnałów rodzica.
 
 - geo : tablica z ustawieniami krawędzi elementu (x, y, width, height).

 - return : table[4] { x, y, width, height }
========================================================================================== ]]

function drawbox:geometry( geo )
    -- pobieranie krawędzi
    if geo == nil then
        return self._drawin:geometry( geo )
    end
     
    -- ustawianie krawędzi
    self._drawin:geometry( geo )
end

--[[ new
=============================================================================================
 Tworzenie nowej instancji obiektu.
 Obiekt jest tworzony jako "pojemnik do rysowania" - może być ich wiele.
 Każdy obiekt aby został wyświetlony musi być przypięty do jednego z pojemników.
 
 - args : argumenty przekazywane do funkcji:
    > background   @ set_background
    > foreground   @ set_foreground
    > border_width @ ---
    > border_color @ ---
    > visible      @ set_visible
    > ontop        @ set_ontop
    > cursor       @ ---
    > width        @ geometry
    > height       @ geometry
    > x            @ geometry
    > y            @ geometry
    > type         @ ---
    
 - return : object
========================================================================================== ]]

local function new( args )
    local retval = {}
    local args   = args or {}
    
    -- domyślne wartości dla pustych pól
    args.border_color = args.border_color or theme.border_normal
    args.border_width = args.border_width or theme.border_width or 0
    
    -- inicjalizacja przechwytywania zdarzeń i tworzenie emitera (menedżera zdarzeń)
    signal.initialize( retval, true )

    -- przypisz funkcje do obiektu
    for key, val in pairs(drawbox) do
        if type(val) == "function" then
            retval[key] = val
        end
    end
    
    -- dodatkowe funkcje z obiektu _drawin
    local fcts = { "buttons", "struts", "get_xproperty", "set_xproperty" }
    for key, val in pairs(fcts) do
        retval[val] = function( self, ... )
            return self._drawin[val]( self._drawin, ... )
        end
    end

    retval._drawin   = capi.drawin( args )
    retval._drawable = retval._drawin.drawable
    retval._widget   = false
    
    -- przechwytywanie sygnałów
    setup_signals( retval )
    
    -- rysowanie elementu
    retval._redraw_pending = false
    retval._do_redraw = function()
        retval._redraw_pending = false
        capi.awesome.disconnect_signal( "refresh", retval._do_redraw )
        redraw_drawbox( retval )
    end
    
    -- przechwytywanie odświeżania
    retval.draw = function()
        if not retval._redraw_pending then
            capi.awesome.connect_signal( "refresh", retval._do_redraw )
            retval._redraw_pending = true
        end
    end
    
    drawables[retval.draw] = true
    retval._drawable:connect_signal( "property::surface", retval.draw )
    
    retval._redraw_on_move = false
    retval.draw()
    
    -- ustaw tło i kolor czcionki
    retval:set_background( args.background )
    retval:set_foreground( args.foreground )
    
    -- szukaj brakujących funkcji/zmiennych w obiekcie retval._drawin
    -- przez to nie będzie można ustawiać nowych wartości w obiekcie
    setmetatable( retval, {
        __index    = retval._drawin,
        __newindex = retval._drawin
    } )
    
    return retval
end

--[[ capi.awesome.connect_signal
=============================================================================================
 Przerysuj wszystkie pojemniki podczas zmiany tapety.
========================================================================================== ]]

capi.awesome.connect_signal( "wallpaper_changed", function()
    wallpaper = nil
    for key in pairs(drawables) do
        key()
    end
end )

--[[ drawbox.mt:xxx
=============================================================================================
 Tworzenie meta danych dla obiektu.
========================================================================================== ]]

drawbox.mt = {}

function drawbox.mt:__call(...)
    return new(...)
end

return setmetatable( drawbox, drawbox.mt )
