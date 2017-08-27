return
{
    layout = {
        fixed      = require("trinity.layout.Fixed"),
        flex       = require("trinity.layout.Flex"),
        fillcenter = require("trinity.layout.FillCenter")
    },
    widget = {
        arrow    = require("trinity.widget.Arrow"),
        label    = require("trinity.widget.Label"),
        edit     = require("trinity.widget.TextBox"),
        image    = require("trinity.widget.Image"),
        taglist  = require("trinity.widget.TagList"),
        prompt   = require("trinity.widget.Prompt")
    },
    worker = {
        layout = require("trinity.worker.Layout")
    },
    
    popup     = require("trinity.Popup"),
    panel     = require("trinity.panel"),
    drawbox   = require("trinity.drawbox"),
    visual    = require("trinity.Visual"),
    signal    = require("trinity.Signal"),
    Useful    = require("trinity.Useful"),
    variables = require("trinity.Variables"),

    button  = require("trinity.button" ),
    arrow   = require("trinity.arrow"  ),
    
    
    layoutx   = require("trinity.layout"  ),
    clock    = require("trinity.clock"   ),
    battery  = require("trinity.battery" ),
    sound    = require("trinity.sound"   ),
    launcher = require("trinity.launcher")
}