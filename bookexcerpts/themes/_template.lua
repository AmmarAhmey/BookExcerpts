--[[
    TEMPLATE for a new THEME (a colour palette). This file is NOT loaded
    automatically.

    To add a theme:
      1. Copy this file to themes/<name>.lua and edit it.
      2. Add "<name>" to the ORDER list in bookexcerpts/themes.lua.
    It then appears in the preview's "Theme" button and in the menu's
    "Preferred theme" list, and works with every layout.

    A theme is a table with:
        key      unique id (saved in settings; don't change it later)
        name     label shown to the user
        palette  "#RRGGBB" colours:
                   bg      card background       fg     quote / title text
                   muted   author, chapter       line   dividers and bars
                   border  card border           outer  margin around the
                                                        card (a PNG has no
                                                        transparency)
]]

local _ = require("gettext")

return {
    key = "my_colours",
    name = _("My colours"),
    palette = {
        bg = "#FFFFFF", fg = "#000000", muted = "#555555", line = "#000000",
        border = "#000000", outer = "#FFFFFF",
    },
}
