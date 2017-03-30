return
{
    layout = {
        fixed      = require("trinity.layout.fixed"),
        flex       = require("trinity.layout.flex"),
        fillcenter = require("trinity.layout.fillcenter")
    },
    widget = {
        arrow    = require("trinity.widget.arrow"),
        label    = require("trinity.widget.label"),
        edit     = require("trinity.widget.edit"),
        image    = require("trinity.widget.image"),
        taglist  = require("trinity.widget.taglist"),
        prompt   = require("trinity.widget.prompt")
    },
    worker = {
        layout = require("trinity.worker.layout")
    },
    
    popup     = require("trinity.popup"),
    panel     = require("trinity.panel"),
    drawbox   = require("trinity.drawbox"),
    visual    = require("trinity.visual"),
    signal    = require("trinity.signal"),
    useful    = require("trinity.useful"),
    variables = require("trinity.variables"),

    button  = require("trinity.button" ),
    arrow   = require("trinity.arrow"  ),
    
    
    layoutx   = require("trinity.layout"  ),
    clock    = require("trinity.clock"   ),
    battery  = require("trinity.battery" ),
    sound    = require("trinity.sound"   ),
    launcher = require("trinity.launcher")
}