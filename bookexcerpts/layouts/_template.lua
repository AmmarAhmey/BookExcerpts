--[[
    TEMPLATE for a new LAYOUT. This file is NOT loaded automatically.

    To add a layout:
      1. Copy this file to layouts/<name>.lua and edit it.
      2. Add "<name>" to the ORDER list in bookexcerpts/layouts.lua.
    It then appears in the preview's "Layout" button and in the menu's
    "Preferred layout" list, and works with every theme.

    A layout is a table with:
        key    unique id (saved in settings; don't change it later)
        name   label shown to the user
        build  function(ctx, palette) -> widget, canvas_colour

    ctx (see parts.lua):
        ctx.text, ctx.info{title,author,chapter}, ctx.cover_bb, ctx.width,
        ctx.face(size, bold, italic)  -> the book's font
        ctx.uiFace(size, bold)        -> KOReader's sans UI font
    palette: "#RRGGBB" strings: bg, fg, muted, line, border, outer.
             Convert them with Parts.colors(palette).

    The returned widget is drawn on a canvas of its own size, filled with
    canvas_colour. parts.lua offers ready-made pieces (quote, divider,
    cover, details, footer); you can also use any KOReader widget.
]]

local Parts = require("bookexcerpts/parts")
local _ = require("gettext")

local MyLayout = {
    key = "my_layout",
    name = _("My layout"),
}

function MyLayout.build(ctx, palette)
    local colors = Parts.colors(palette)
    -- ... create widgets with Parts.* and/or KOReader widgets ...
    -- local widget = ...
    -- return widget, colors.bg
    error("template: not implemented")
end

return MyLayout
