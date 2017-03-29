-- DEFAULT COMMANDS
-- ==========================================================================================

-- This is used later as the default terminal and editor to run.
terminal   = "terminator"
editor     = "nano"
editor_cmd = terminal .. " -x " .. editor
editor_gui = "mousepad"
my_theme   = "default"
home_dir   = os.getenv("HOME")
theme_dir  = home_dir .. "/.config/awesome/themes/" .. my_theme .. "/"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- LIBRARIES
-- ==========================================================================================

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")

-- Widget and layout library
local common  = require("awful.widget.common")
local wibox   = require("wibox")
local vicious = require("vicious")
local surface = require("gears.surface")

-- Custom libraries
local vicbatt = require("batterybox")
local arrowbox  = require("arrowbox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local trinity = require("trinity")
local vars    = require("trinity.variables")

-- Variables...
local appicon = {}

-- ERROR HANDLING
-- ==========================================================================================

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end

-- LAYOUTS
-- ==========================================================================================

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}

-- THEME
-- ==========================================================================================

-- Themes define colours, icons, font and wallpapers.
beautiful.init( theme_dir .. "theme.lua" )

-- WALLPAPER
-- ==========================================================================================

if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end

-- TAGS
-- ==========================================================================================

tags = {
   names  = { "term", "www", "gcc", "dir", "graf", "inne" },
   layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1] },
   images = nil
}

for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag( tags.names, s, tags.layout )
end

-- MENU
-- ==========================================================================================

-- Awesome submenu
myawesomemenu = {
   { "manual", terminal .. " -x man awesome" },
   { "edit config", editor_gui .. " " .. awesome.conffile },
   { "edit theme", editor_gui .. " " .. theme_dir .. "theme.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

-- Main menu
mymainmenu = awful.menu({
    items = {
        { "awesome", myawesomemenu, beautiful.awesome_icon },
        { "terminal", terminal }
    }
})


-- Menubar configuration
-- Set the terminal for applications that require it
menubar.utils.terminal = terminal

-- CUSTOM TASKLIST UPDATE
-- ==========================================================================================

function tasklist_update(w, buttons, label, data, objects)
    -- update the widgets, creating them if needed
    w:reset()

    -- just a loop...
    for i, o in ipairs(objects) do
        local cache = data[o]
        local ib, tb, bgb, tbm, ibm, l
        
        -- cached data
        if cache then
            ib = cache.ib
            tb = cache.tb
            bgb = cache.bgb
            tbm = cache.tbm
            ibm = cache.ibm
        else
            -- create new widgets...
            ib = wibox.widget.imagebox()
            tb = wibox.widget.textbox()
            bgb = wibox.widget.background()
            tbm = wibox.layout.margin(tb, 4, 4)
            ibm = wibox.layout.margin(ib, 4)
            l = wibox.layout.fixed.horizontal()

            -- all of this is added in a fixed widget
            l:fill_space(true)
            l:add(ibm)
            l:add(tbm)

            -- and all of this gets a background
            bgb:set_widget(l)

            -- create buttons
            bgb:buttons(common.create_buttons(buttons, o))

            data[o] = {
                ib  = ib,
                tb  = tb,
                bgb = bgb,
                tbm = tbm,
                ibm = ibm,
            }
            
            -- check if there is custom icon for application
            if beautiful.tasklist_icons == true and appicon[o.class] == nil then
                local fsuc, fres = pcall( surface.load, theme_dir .. "appicon/" .. o.class .. ".png" )
               
                -- set icon or false
                if fsuc == true then           
                    appicon[o.class] = fres
                else
                    appicon[o.class] = false
                end
                
                -- check app class name (debug only)
                -- {{ ------------------------------------- --
                --naughty.notify({
                --    preset = naughty.config.presets.low,
                --    title = "Icon loading",
                --    text = "Checking icon for " .. o.class .. " application..."
                --})
                -- ------------------------------------- }} --
            end
        end

        local text, bg, bg_image, icon = label(o, tb)
        
        -- The text might be invalid, so use pcall.
        if text == nil or text == "" then
            tbm:set_margins(0)
        else
            if not pcall(tb.set_markup, tb, text) then
                tb:set_markup( "<i>&lt;Invalid text&gt;</i>" )
            end
        end
        
        -- background
        bgb:set_bg( bg )
        if type(bg_image) == "function" then
            bg_image = bg_image(tb,o,m,objects,i)
        end
        bgb:set_bgimage(bg_image)
        
        -- check if icons are enabled
        if beautiful.tasklist_icons == true then
            -- set custom or default icon for application
            if appicon[o.class] == nil or appicon[o.class] == false then 
                if icon then
                    ib:set_image( icon )
                else
                    -- set margin if there is no even default icon
                    ibm:set_margins( 2 )
                end
            else
                -- custom icon
                ib:set_image( appicon[o.class] )
            end
        -- icons are disabled...
        else
            ibm:set_margins( 2 )
        end  
        
        -- add button
        w:add( bgb )
    end
end


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mytaglist = {}
mynwibox = {}

local topbar = {}

widgets = {
    layout   = {},
    clock    = nil,
    battery  = nil,
    sound    = nil,
    launcher = nil,
    taglist  = {},
    prompt   = {},
    arrows   = {
        layout   = {},
        clock    = nil,
        battery  = nil,
        sound    = nil,
        launcher = {},
        taglist  = {}
    }
}

-- kalendarz
widgets.clock = trinity.button({
    background = beautiful.widget_color.clock,
    foreground = beautiful.fg_normal,
    worker     = trinity.clock,
    image      = beautiful.widget_icon.callendar,
    margin     = { 2, 0, 5, 0, 5 },
    format     = "%d/%m/%Y %H:%M",
    text       = true
})
-- bateria
widgets.battery = trinity.button({
    background = beautiful.widget_color.battery,
    foreground = beautiful.fg_normal,
    worker     = trinity.battery,
    margin     = { 0, 0, 5, 0, 0 },
    battery    = "BAT0",
    text       = true,
    image      = true
})

local cairo = require("lgi").cairo
local color = require("gears.color")
local surface = require("gears.surface")
--local timer = require("gears.timer")

local root_geom
do
    local geom = screen[1].geometry
    root_geom = {
        x = 0, y = 0,
        width = geom.x + geom.width,
        height = geom.y + geom.height
    }
    for s = 1, screen.count() do
        local g = screen[s].geometry
        root_geom.width = math.max(root_geom.width, g.x + g.width)
        root_geom.height = math.max(root_geom.height, g.y + g.height)
    end
end

function wpset(pattern)
    if cairo.Surface:is_type_of(pattern) then
        pattern = cairo.Pattern.create_for_surface(pattern)
    end
    if type(pattern) == "string" or type(pattern) == "table" then
        pattern = color(pattern)
    end
    if not cairo.Pattern:is_type_of(pattern) then
        error("wallpaper.set() called with an invalid argument")
    end
    root.wallpaper(pattern._native)
end

function wprepctx(s)
    local geom = s and screen[s].geometry or root_geom
    local img = surface(root.wallpaper())

    if not img then
        -- No wallpaper yet, create an image surface for just the part we need
        img = cairo.ImageSurface(cairo.Format.RGB24, geom.width, geom.height)
        img:set_device_offset(-geom.x, -geom.y)
    end

    local cr = cairo.Context(img)

    -- Only draw to the selected area
    cr:translate(geom.x, geom.y)
    cr:rectangle(0, 0, geom.width, geom.height)
    cr:clip()

    return geom, img, cr
end

local l_size = 0.1
local useful = require("trinity.useful")

function btclick()
    --gears.wallpaper.maximized(beautiful.wallpaper2, 1, true)
    local s = 1
    local ignore_aspect = true
    local offset = nil
    local surf = beautiful.wallpaper3
   
    local geom, img, cr = wprepctx(s)
    local surf = surface(surf)
    local w, h = surface.get_size(surf)
    local aspect_w = geom.width / w
    local aspect_h = geom.height / h

    if not ignore_aspect then
        aspect_h = math.max(aspect_w, aspect_h)
        aspect_w = math.max(aspect_w, aspect_h)
    end
    cr:scale(aspect_w, aspect_h)

    if offset then
        cr:translate(offset.x, offset.y)
    end
    
    --local timer = useful.timer( 1.0, "wallpaper::transition" )
    --timer:connect_signal( "timeout", function()
        cr:set_source_surface(surf, 0, 0)
        cr.operator = cairo.Operator.SOURCE
        cr:paint()
        wpset(img)
    --end )
    --timer:start()
end

widgets.battery:connect_signal("button::press", btclick)

-- dźwięk
widgets.sound = trinity.button({
    background = beautiful.widget_color.sound,
    foreground = beautiful.fg_normal,
    margin     = { 1, 0, 5, 0, 5 },
    worker     = trinity.sound,
    mixer      = "Master",
    zerosep    = true,
    text       = true,
    image      = true
})
widgets.launcher = trinity.button({
    background = beautiful.widget_color.launcher,
    image      = beautiful.widget_icon.launcher,
    worker     = trinity.launcher,
    menu       = mymainmenu,
    margin     = { 4, 0, 2, 0, 0 }
})

-- strzałki
widgets.arrows.clock = trinity.arrow({
    backobj   = widgets.battery,
    foreobj   = widgets.clock,
    direction = "left"
})
widgets.arrows.battery = trinity.arrow({
    backobj   = widgets.sound,
    foreobj   = widgets.battery,
    direction = "left",
    press     = true
})
widgets.arrows.sound = trinity.arrow({
    background = "#222222",
    foreobj    = widgets.sound,
    direction  = "left"
})

mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


    widgets.lays = {{}}
    widgets.wids = {{}}

function avcxx()
            naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end
function avcxx2(a)
    a:set_background("#000000")
end

for s = 1, screen.count() do
    local colors = beautiful.w_color    

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(
        s,
        awful.widget.tasklist.filter.currenttags,
        mytasklist.buttons,
        nil,
        tasklist_update
    )

    -- Create the wibox
    mywibox[s] = awful.wibox({
        position = "top",
        screen = s,
        height = 18
    })

--[[    topbar[s] = trinity.panel({
        position     = "bottom",
        screen       = s,
        height       = 18,
        border_width = 0,
        background   = "#004444",
        foreground   = "#ffffff"
    })

    widgets.lays[s][1] = trinity.layout.fixed({
        direction = "x",
        emiter    = { "button::press", "button::release" } 
    })
    widgets.lays[s][2] = trinity.layout.fixed({
        direction = "x"    
    })
    widgets.lays[s][3] = trinity.layout.flex({
        direction = "x"    
    })

    widgets.lays[s][0] = trinity.layout.fillcenter({
        direction = "x",
        left      = widgets.lays[s][1],
        center    = widgets.lays[s][3],
        right     = widgets.lays[s][2],
        emiter    = { "button::press", "button::release" }
    })

    widgets.wids[s][0] = trinity.widget.image({
        groups      = {"padding"},
        padding     = {15, 0, 15, 0},
        stretch     = false,
        keep_aspect = false,
        image       = beautiful.widget_icon.launcher
    })

    widgets.wids[s][0]:connect_signal("button::press", avcxx)

    widgets.wids[s][1] = trinity.widget.label({
        text       = "Drugi widżet",
        groups     = {"padding"},
        groups     = {"back"},
        padding    = {5, 0, 5, 0},
        background = "#111399"
    })
    :connect_signal("button::press", avcxx2)
    :connect_signal("button::release", avcxx)

    widgets.wids[s][2] = trinity.widget.label({
        text       = "Trzeci widżet",
        background = "#425349",
        halign     = vars.text_halign.center
    })

    widgets.wids[s][3] = trinity.widget.label({
        text       = "Pierwszy widżet",
        groups     = {"back"},
        background = "#011349"
    })
    widgets.wids[s][4] = trinity.widget.label({
        text       = "Drugi widżet",
        groups     = {"back"},
        background = "#111399"
    })
    widgets.wids[s][5] = trinity.widget.label({
        text       = "Trzeci widżet",
        groups     = {"back"},
        background = "#425349",
        halign     = vars.text_halign.center
    })

    widgets.wids[s][6] = trinity.widget.label({
        text       = "Pierwszy widżet",
        groups     = {"back"},
        background = "#011349"
    })
    widgets.wids[s][7] = trinity.widget.label({
        text       = "Drugi widżet",
        groups     = {"back"},
        background = "#111399"
    })
    widgets.wids[s][8] = trinity.widget.label({
        text       = "Trzeci widżet",
        groups     = {"back"},
        background = "#425349",
        halign     = vars.text_halign.center
    })

    widgets.wids[s][9] = trinity.widget.arrow({
        bind_left  = widgets.wids[s][1],
        bind_right = widgets.wids[s][2],
        direction  = "left",
        emiter     = {"button::press", "button::release"}
    })

    widgets.lays[s][1]:add( widgets.wids[s][0], true )
                      :add( widgets.wids[s][1], true )
                      :add( widgets.wids[s][9], true )
                      :add( widgets.wids[s][2] )

    widgets.lays[s][2]:add( widgets.wids[s][3] )
                      :add( widgets.wids[s][4] )
                      :add( widgets.wids[s][5] )

    widgets.lays[s][3]:add( widgets.wids[s][6] )
                      :add( widgets.wids[s][7] )
                      :add( widgets.wids[s][8] )

    topbar[s]:set_widget( widgets.lays[s][0] ) ]]--

    widgets.taglist[s] = trinity.widget.taglist({
        background = beautiful.widget_color.taglist.normal,
        foreground = beautiful.fg_normal,
        margin     = { 5, 0, 5, 0, 0 }
    })
    widgets.arrows.launcher[s] = trinity.arrow({
        backobj   = widgets.taglist[s]:get_first_widget(),
        foreobj   = widgets.launcher,
        direction = "right",
        release   = true
    })
    widgets.arrows.taglist[s] = trinity.arrow({
        background = "#222222",
        foreobj    = widgets.taglist[s]:get_last_widget(),
        direction  = "right",
        release    = true
    })
    
    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    
    left_layout:add( widgets.launcher )
    left_layout:add( widgets.arrows.launcher[s] )
    left_layout:add( widgets.taglist[s] )
    left_layout:add( widgets.arrows.taglist[s] )
    
    --left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    
    --right_layout:add(batterybox.icon)
    --right_layout:add(batterybox.text)
    
    widgets.prompt[s] = trinity.widget.prompt({
        background   = "#483C70",
        foreground   = "#D0D0D0",
        border_color = "#261F3D",
        border_size  = 1,
        screen       = s,
        min_width    = 170,
        max_width    = 248,
        posx         = 0,
        posy         = 0,
        padding      = 7,
        elem_space   = 3,
        cursor_color = "#D0D0D0"
    })

    -- opcje ułożenia okien (layouts)
    widgets.layout[s] = trinity.button({
        background = beautiful.widget_color.layout,
        screen     = s,
        layouts    = layouts,
        worker     = trinity.layoutx,
        image      = true
    })

    widgets.arrows.layout[s] = trinity.arrow({
        foreobj    = widgets.layout[s],
        backobj    = widgets.clock,
        direction  = "left",
        release    = true
    })

    
    right_layout:add( widgets.arrows.sound )
    right_layout:add( widgets.sound )
    right_layout:add( widgets.arrows.battery )
    right_layout:add( widgets.battery )
    right_layout:add( widgets.arrows.clock )
    right_layout:add( widgets.clock )
    right_layout:add( widgets.arrows.layout[s] )
    right_layout:add( widgets.layout[s] )

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- HIT TEST HELPER! {{

    awful.key({ modkey, "Shift"   }, "Left", function()
        local coords = mouse.coords()
        
        mouse.coords({x = coords.x - 1})
    end),
    awful.key({ modkey, "Shift"   }, "Right", function()
        local coords = mouse.coords()
        
        mouse.coords({x = coords.x + 1})
    end),
    awful.key({ modkey, "Shift"   }, "Up", function()
        local coords = mouse.coords()
        
        mouse.coords({y = coords.y - 1})
    end),
    awful.key({ modkey, "Shift"   }, "Down", function()
        local coords = mouse.coords()
        
        mouse.coords({y = coords.y + 1})
    end),
    
    -- }} HIT TEST HELPER

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
        
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.util.spawn("amixer set Master 5%+",    false)
        widgets.sound.worker.update( widgets.sound )
    end),
    awful.key({}, "XF86AudioLowerVolume", function()
        awful.util.spawn("amixer set Master 5%-",    false)
        widgets.sound.worker.update( widgets.sound )
    end),
    awful.key({}, "XF86AudioMute", function()
        awful.util.spawn("amixer set Master toggle", false)
        widgets.sound.worker.update( widgets.sound )
    end),


    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () 
    --mypromptbox[mouse.screen]:run()
        widgets.prompt[mouse.screen]:run()
    end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     size_hints_honor = false } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


