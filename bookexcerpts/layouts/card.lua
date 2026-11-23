--[[
    Layout "card": the quote on top, a divider, then cover + details below,
    all inside a rounded, bordered card.

        ╭──────────────────────────────────────────╮
        │ “quote ...”                              │  <- grows with the text
        │ ──────────────────────────────────────── │
        │ [cover]  Book title                      │  <- always the same
        │          Author                          │
        │          Chapter                         │
        ╰──────────────────────────────────────────╯

    A layout is a table { key, name, build(ctx, palette) }.
    build() returns (widget, canvas_colour). The palette comes from the
    chosen theme: bg, fg, muted, line, border, outer (see themes/*.lua).
]]

local FrameContainer = require("ui/widget/container/framecontainer")
local Parts = require("bookexcerpts/parts")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")

local OUTER       = 24  -- margin between image edge and rounded card
local BORDER      = 3   -- card border thickness
local RADIUS      = 28  -- card corner radius
local PAD         = 56  -- padding inside the card
local QUOTE_SIZE  = 26  -- fixed font size of the quote
local SECTION_GAP = 28  -- space around the divider

-- Cover + details block (kept compact: tight lines, smaller cover)
local FOOTER = {
    title_size  = 26,   -- fixed font size of the title
    cover_h     = 160,  -- starting cover height
    cover_w     = 118,  -- reference width (keeps the cover's aspect box)
    gap         = 24,   -- space between cover and details
    small       = 18,   -- author size; the chapter is 2 smaller
    min_small   = 14,
    line_gap    = 5,    -- space between title, author and chapter
    line_height = 0.15, -- tighter line spacing than KOReader's default
}

local Card = {
    key = "card",
    name = _("Card"),
}

function Card.build(ctx, palette)
    local colors = Parts.colors(palette)
    local content_w = ctx.width - 2 * OUTER - 2 * BORDER - 2 * PAD

    local quote = Parts.quote(ctx, colors, content_w, QUOTE_SIZE)
    local divider = Parts.divider(colors, content_w, 3)
    local footer = Parts.footer(ctx, colors, content_w, FOOTER)

    local card = FrameContainer:new{
        background = colors.bg,
        color = colors.border,
        bordersize = BORDER,
        radius = RADIUS,
        padding = PAD,
        margin = 0,
        VerticalGroup:new{
            align = "left",
            quote,
            VerticalSpan:new{ width = SECTION_GAP },
            divider,
            VerticalSpan:new{ width = SECTION_GAP },
            footer,
        },
    }
    local outer = FrameContainer:new{
        background = colors.outer,
        bordersize = 0,
        padding = OUTER,
        margin = 0,
        card,
    }
    return outer, colors.outer
end

return Card
