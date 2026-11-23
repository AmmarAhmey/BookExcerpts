--[[
    Renders an excerpt with a layout + theme and saves it as a PNG.
]]

local Blitbuffer = require("ffi/blitbuffer")
local Book = require("bookexcerpts/book")
local DataStorage = require("datastorage")
local Fonts = require("bookexcerpts/fonts")
local lfs = require("libs/libkoreader-lfs")

local Renderer = {}

Renderer.IMAGE_WIDTH = 900 -- constant width of every excerpt image

-- Where images are stored: <koreader data dir>/excerpts
function Renderer.outputDir()
    return DataStorage:getDataDir() .. "/excerpts"
end

-- Renders `text` and returns the path of the saved PNG.
-- layout: { key, build(ctx, palette) }   theme: { key, palette }
-- Raises an error (with a readable message) if anything goes wrong.
function Renderer.render(ui, text, layout, theme)
    local cover_bb = Book.cover(ui)
    local ctx = {
        ui = ui,
        text = text,
        info = Book.info(ui),
        cover_bb = cover_bb,
        width = Renderer.IMAGE_WIDTH,
        face = function(size, bold, italic)
            return Fonts.face(ui, size, bold, italic)
        end,
        uiFace = function(size, bold)
            return Fonts.uiFace(size, bold)
        end,
    }

    local ok, result = pcall(function()
        local widget, canvas_color = layout.build(ctx, theme.palette)
        local size = widget:getSize()
        local bb = Blitbuffer.new(size.w, size.h, Blitbuffer.TYPE_BBRGB32)
        bb:fill(canvas_color or Blitbuffer.COLOR_WHITE)
        widget:paintTo(bb, 0, 0)

        local dir = Renderer.outputDir()
        lfs.mkdir(dir)
        local path = string.format("%s/excerpt_%s_%s_%s.png", dir,
            os.date("%Y%m%d_%H%M%S"), layout.key, theme.key)
        bb:writePNG(path)

        bb:free()
        widget:free()
        return path
    end)

    if cover_bb then cover_bb:free() end
    if not ok then error(result, 0) end
    return result
end

return Renderer
