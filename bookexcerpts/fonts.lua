--[[
    Font helpers.
]]

local Font = require("ui/font")

local Fonts = {}

-- Face for the font currently selected in the book (falls back to
-- KOReader's default fonts, e.g. for PDFs).
function Fonts.face(ui, size, bold, italic)
    local name = ui.font and ui.font.font_face
    if name then
        local ok, face = pcall(function()
            local cre = require("document/credocument"):engineInit()
            local file, idx = cre.getFontFaceFilenameAndFaceIndex(name, bold, italic)
            if file then
                return Font:getFace(file, size, idx)
            end
        end)
        if ok and face then return face end
    end
    return Font:getFace(bold and "NotoSans-Bold.ttf" or "cfont", size)
end

-- KOReader's own sans-serif UI font (the same on every book).
function Fonts.uiFace(size, bold)
    return Font:getFace(bold and "NotoSans-Bold.ttf" or "cfont", size)
end

return Fonts
