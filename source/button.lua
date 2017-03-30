-- LIBRARIES
-- ==========================================================================================

local wibox = require("wibox")
local gears = require("gears")
local defs  = require("trinity.useful")


local button = { mt = {} }

-- FIT_WIDGET
-- ==========================================================================================

local function fit_widget( widget, width, height )
    -- cache - nie można sprawdzić cache[width] ~= nil, a szkoda...
    local cache = widget._fit_geometry_cache

    -- local naughty = require("naughty")
    -- naughty.notify({ preset = naughty.config.presets.critical,
    --                  title = "Oops, there were errors during startup!",
    --                  text = "SIEMA " .. tostring(widget) })

    local result = cache[width]

    -- brak danych
    if not result then
        result = {}
        cache[width] = result
    end
    
    -- wysokość
    cache, result = result, result[height]
    
    -- brak danych, pobierz wymiary
    if not result then
        local w, h = widget:fit(width, height)
        result = { width = w, height = h }
        cache[height] = result
    end
    
    -- zwróć wymiary elementu
    return result.width, result.height
    
    -- awesome.wibox.layout.base.fit_widget
end

-- DRAW_WIDGET
-- ==========================================================================================

local function draw_widget( wibox, cr, widget, x, y, width, height )
    -- używaj save/restore aby modyfikacje nie były trwałe
    cr:save()

    -- zmień punkt startowy
    cr:translate(x, y)

    -- nie pozwól rysować poza wyznaczonym obszarem
    cr:rectangle(0, 0, width, height)
    cr:clip()

    -- rysuj element
    local success, msg = pcall(widget.draw, widget, wibox, cr, width, height)
    if not success then
        print("Error while drawing widget: " .. msg)
    end
    
    -- przywróć ustawienia
    cr:restore()
    
    -- awesome.wibox.layout.base.fit_widget
end

-- BUTTON:DRAW
-- ==========================================================================================

function button:draw( wibox, cr, width, height )
    -- rysuj tło
    if self.back ~= nil then
        cr:set_source_rgba( self.back[1], self.back[2], self.back[3], self.back[4] )
        cr:rectangle( 0, 0, width, height )
        cr:fill()
    end
    
    -- ustaw kolor czcionki
    if self.fore ~= nil then
        cr:set_source_rgba( self.fore[1], self.fore[2], self.fore[3], self.fore[4] )
    end
    
    local pos = 0

    -- rysuj poszczególne elementy
    for key, val in pairs(self.widgets) do
        -- lewy margines
        pos = pos + val.margin[1]
        
        -- pozycja x i y oraz wysokość i szerokość z uwzględnieniem marginesów
        local x, y = pos, val.margin[2]
        local w, h = width - pos, height - val.margin[2] - val.margin[4]
        
        if key ~= #self.widgets then
            w, _ = fit_widget( val, w, h )
        end
        
        -- nowa pozycja
        pos = pos + w
        
        -- element nie zmieści się na przycisku... nie rysuj
        if pos > width then
            break
        end
        
        -- rysuj element
        draw_widget( wibox, cr, val, x, y, w, h )
        
        -- prawy margines
        pos = pos + val.margin[3]
    end
end

-- BUTTON:FIT
-- ==========================================================================================

function button:fit( width, height )
    -- nowa szerokość
    local new_width  = self.margin[1] + self.margin[3] + self.margin[5]
    local new_height = height

    -- oblicz szerokość przycisku
    for key, val in pairs(self.widgets) do
        local w,h = fit_widget( val, width, height )
        
        new_width  = new_width + w
        new_height = new_height > h and new_height or h
    end
    
    -- uwzględnij marginesy dla wysokości
    new_height = new_height + self.margin[2] + self.margin[4]

    -- zwróć nowe wymiary
    return new_width, new_height
end

-- BUTTON:SET_BACK
-- ==========================================================================================

function button:set_back( color )
    local r,g,b,a = gears.color.parse_color( color )
    self.back = { r, g, b, a }
    
    self:emit_signal( "widget::updated" )
end

-- BUTTON:SET_FORE
-- ==========================================================================================

function button:set_fore( color )
    local r,g,b,a = gears.color.parse_color( color )
    self.fore = { r, g, b, a }
    
    self:emit_signal( "widget::updated" )
end

-- BUTTON:SET_TEXT
-- ==========================================================================================

function button:set_text( text )
    if self.textbox ~= nil then
        self.textbox:set_text( text )
    self:emit_signal( "widget::updated" )
    end
end

function button:set_ellipsize( type )
    if self.textbox ~= nil then
        self.textbox:set_ellipsize( type )
        self:emit_signal( "widget::updated" )
    end
end

-- BUTTON:SET_MARKUP
-- ==========================================================================================

function button:set_markup( text )
    if self.textbox ~= nil then
        self.textbox:set_markup( text )
    end
end

-- BUTTON:SET_IMAGE
-- ==========================================================================================

function button:set_image( image )
    if self.imagebox ~= nil then
        self.imagebox:set_image( image )
    end
end

function button:set_font( font )
end

-- BUTTON:ADD
-- ==========================================================================================

function button:add( widget )
    wibox.widget.base.check_widget( widget )
    table.insert( self.widgets, widget )
    
    widget:connect_signal( "widget::updated", self._emit_updated )
    self._emit_updated()
end

-- NEW
-- ==========================================================================================

local function new( args )
    -- brak argumentów...
    if args == nil then
        args = { text = "example" }
    end
    
    -- utwórz widget (poziomy szablon dla przycisku)
    local retval = wibox.widget.base.make_widget()
    local imgpos = args.image_pos or "left"
    local margin = args.margin
    
    -- margines
    if type(margin) ~= "table" or #margin ~= 5 then
        margin = { 0, 0, 0, 0, 0 }
    end
    retval.margin = margin
    
    -- tabela widżetów
    retval.widgets = {}
    retval._emit_updated = function()
        retval:emit_signal("widget::updated")
    end
    
    -- dodawanie funkcji do obiektu
    for key, val in pairs(button) do
        if type(val) == "function" then
            retval[key] = val
        end
    end

    -- kolor tła
    if type(args.background) == "string" then
        local r,g,b,a = gears.color.parse_color( args.background )
        retval.back = { r, g, b, a }
    end
    -- kolor tła
    if type(args.foreground) == "string" then
        local r,g,b,a = gears.color.parse_color( args.foreground )
        retval.fore = { r, g, b, a }
    end
    
    -- @SIGNALS {{ 
    -- naciśnięcie przycisku
    if type(args.press) == "function" then
        retval:connect_signal( "button::press", args.press )
    end
    -- puszczenie przycisku
    if type(args.release) == "function" then
        retval:connect_signal( "button::release", args.release )
    end
    -- wejście myszy na przycisk
    if type(args.enter) == "function" then
        retval:connect_signal( "mouse::enter", args.enter )
    end
    -- wyjście myszy z przycisku
    if type(args.leave) == "function" then
        retval:connect_signal( "mouse::leave", args.leave )
    end
    -- }} #SIGNALS
    
    -- utwórz tekst dla przycisku
    if args.text ~= nil or args.markup ~= nil then
        retval.textbox = wibox.widget.textbox()
        
        -- ustaw tekst
        if type(args.text) == "string" or type(args.markup) == "string" then
            if type(args.text) == "string" then
                retval.textbox:set_text(args.text)
            else
                retval.textbox:set_markup(args.markup)
            end
        end
    end
    
    -- utwórz obrazek dla przycisku
    if args.image ~= nil then
        retval.imagebox = wibox.widget.imagebox()
        
        -- ustaw obrazek
        if args.image ~= true then
            retval.imagebox:set_image( args.image )
        end
    else
        imgpos = "none"
    end
    
    -- dodaj obrazek po lewej stronie
    if retval.imagebox ~= nil and imgpos == "left" then
        retval:add( retval.imagebox )
        retval.imagebox.margin = {
            margin[1],
            margin[2],
            margin[5],
            margin[4]
        }
    end
    
    -- dodaj tekst
    if retval.textbox ~= nil then
        retval:add( retval.textbox )
        retval.textbox.margin = {
            (imgpos == "left" and 0 or margin[1]),
            margin[2],
            (imgpos == "right" and 0 or margin[3]),
            margin[4]
        }
        
    retval.textbox:connect_signal( "mouse::enter", function()
        local naughty = require("naughty")
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
    end )
    end
    
    -- dodaj obrazek po prawej stronie
    if retval.imagebox ~= nil and imgpos == "right" then
        retval:add( retval.imagebox )
        retval.imagebox.margin = {
            margin[5],
            margin[2],
            margin[3],
            margin[4]
        }
    end
    
    -- uruchamianie dodatkowej funkcji dla zadania
    if args.worker ~= nil then
        retval.worker = {}
        args.worker( retval, args )
    end
    
    return retval
end

-- BUTTON.MT:CALL
-- ==========================================================================================

function button.mt:__call(...)
    return new(...)
end

-- SETMETATABLE
-- ==========================================================================================

return setmetatable( button, button.mt )
