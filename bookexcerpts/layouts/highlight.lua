--[[
    Layout "highlight": inspired by e-reader highlight cards.

        ┌────────────────────────────────────────┐
        │ The Brothers Karamazov   <- one line   │
        │ by Fyodor Dostoevsky                   │
        │ VIII. The Third and Final Meeting      │
        │                                        │
        │ │ “It was precisely in the posing of   │
        │ │ those three questions ...”           │
        │ — shared on 23 Nov '26 at 10:09        │
        └────────────────────────────────────────┘

    * The title size is fixed: the largest size (up to 26) at which the
      reference title below fits on ONE line. Every excerpt uses that same
      size, so all images from this layout look consistent.
    * Image width and font sizes follow the "card" layout.
]]

local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local LineWidget = require("ui/widget/linewidget")
local Parts = require("bookexcerpts/parts")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local _ = require("gettext")

local OUTER        = 24   -- margin between image edge and the card
local FRAME_GAP    = 14   -- card edge -> thin inner frame
local FRAME_BORDER = 2    -- thin inner frame thickness
local RADIUS       = 18   -- card corner radius
local PAD          = 48   -- padding inside the thin frame
local QUOTE_SIZE   = 26   -- same as the "card" layout
local TITLE_MAX    = 26   -- same as the "card" layout; shrinks only to fit
local MIN_TITLE    = 12
local BAR_W        = 3    -- vertical bar left of the quote
local BAR_GAP      = 20
local LINE_HEIGHT  = 0.15 -- tight line spacing for the details lines
local DETAIL_GAP   = 2    -- space between title, author and chapter
local QUOTE_GAP    = 18   -- space between the details and the quote
local FOOTER_GAP   = 14   -- space between the quote and "shared on"

-- The title size is measured with this title so that it fits on one line.
local REFERENCE_TITLE = "The Brothers Karamazov"

local Highlight = {
    key = "highlight",
    name = _("Highlight"),
}

-- Largest title size (<= TITLE_MAX) at which REFERENCE_TITLE fits in `width`.
local function fitTitleSize(ctx, width)
    for size = TITLE_MAX, MIN_TITLE, -1 do
        local probe = TextWidget:new{
            text = REFERENCE_TITLE,
            face = ctx.uiFace(size),
        }
        local w = probe:getSize().w
        probe:free()
        if w <= width then return size end
    end
    return MIN_TITLE
end

local function line(ctx, colors, text, size, color, width)
    return TextBoxWidget:new{
        text = text,
        face = ctx.uiFace(size),
        width = width,
        fgcolor = color,
        bgcolor = colors.bg,
        line_height = LINE_HEIGHT,
    }
end

-- "23 Nov '26 at 10:09" (no leading zero on the day)
local function nowText()
    local s = os.date("%d %b '%y at %H:%M")
    return (s:gsub("^0", ""))
end

function Highlight.build(ctx, palette)
    local colors = Parts.colors(palette)
    local info = ctx.info
    local content_w = ctx.width - 2 * OUTER - 2 * FRAME_GAP
        - 2 * FRAME_BORDER - 2 * PAD

    local title_size = fitTitleSize(ctx, content_w)
    local small = math.max(12, math.floor(title_size * 0.72))

    local group = VerticalGroup:new{ align = "left" }

    -- Book details: title, "by Author", chapter
    table.insert(group, line(ctx, colors, info.title, title_size, colors.fg, content_w))
    if info.author ~= "" then
        table.insert(group, VerticalSpan:new{ width = DETAIL_GAP })
        table.insert(group, line(ctx, colors, _("by") .. " " .. info.author,
            small, colors.muted, content_w))
    end
    if info.chapter ~= "" then
        table.insert(group, VerticalSpan:new{ width = DETAIL_GAP })
        table.insert(group, line(ctx, colors, info.chapter,
            small, colors.muted, content_w))
    end
    table.insert(group, VerticalSpan:new{ width = QUOTE_GAP })

    -- The excerpt, italic, with a vertical bar on its left
    local quote = Parts.quote(ctx, colors, content_w - BAR_W - BAR_GAP, QUOTE_SIZE, true)
    local bar = LineWidget:new{
        dimen = Geom:new{ w = BAR_W, h = quote:getSize().h },
        background = colors.line,
    }
    table.insert(group, HorizontalGroup:new{
        align = "top",
        bar,
        HorizontalSpan:new{ width = BAR_GAP },
        quote,
    })

    -- "— shared on ..."
    table.insert(group, VerticalSpan:new{ width = FOOTER_GAP })
    table.insert(group, line(ctx, colors,
        "— " .. _("shared on") .. " " .. nowText(), small, colors.muted, content_w))

    -- Thin frame inside a rounded card, inside a margin
    local frame = FrameContainer:new{
        background = colors.bg,
        color = colors.border,
        bordersize = FRAME_BORDER,
        padding = PAD,
        margin = 0,
        group,
    }
    local card = FrameContainer:new{
        background = colors.bg,
        bordersize = 0,
        radius = RADIUS,
        padding = FRAME_GAP,
        margin = 0,
        frame,
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

return Highlight
