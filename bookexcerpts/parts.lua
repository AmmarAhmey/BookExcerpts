--[[
    Reusable building blocks for excerpt layouts.

    Every function takes `ctx` (what render() hands to a theme's build()):
        ctx.text      cleaned-up excerpt text
        ctx.info      { title, author, chapter }
        ctx.cover_bb  cover BlitBuffer (or nil)
        ctx.width     image width in pixels
        ctx.face(size, bold, italic)   font face of the book
        ctx.uiFace(size, bold)         KOReader's sans UI font

    and `colors`, a table of Blitbuffer colours made with Parts.colors().
]]

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local LeftContainer = require("ui/widget/container/leftcontainer")
local LineWidget = require("ui/widget/linewidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local Parts = {}

-- Converts a palette of "#RRGGBB" strings into Blitbuffer colours.
-- Keys used by the built-in layouts: bg, fg, muted, line, border, outer.
function Parts.colors(palette)
    local colors = {}
    for name, hex in pairs(palette) do
        colors[name] = Blitbuffer.colorFromString(hex)
    end
    return colors
end

-- The excerpt text, wrapped in curly quotes. Height depends on its length.
-- Pass italic = true for the book font's italic style.
function Parts.quote(ctx, colors, width, size, italic)
    return TextBoxWidget:new{
        text = "\u{201C}" .. ctx.text .. "\u{201D}",
        face = ctx.face(size, false, italic),
        width = width,
        fgcolor = colors.fg,
        bgcolor = colors.bg,
        alignment = "left",
    }
end

-- A horizontal line.
function Parts.divider(colors, width, thickness)
    return LineWidget:new{
        dimen = Geom:new{ w = width, h = thickness or 3 },
        background = colors.line,
    }
end

-- Cover of height h at its natural aspect ratio (scale_factor = 0 = "fit").
-- opts.cover_h / opts.cover_w describe the reference size.
function Parts.cover(ctx, colors, h, opts)
    if ctx.cover_bb then
        return ImageWidget:new{
            image = ctx.cover_bb,
            image_disposable = false,
            -- We paint into our own buffer, so never pre-invert the cover
            -- for the device's night mode.
            original_in_nightmode = false,
            width = math.floor(h * opts.cover_w / opts.cover_h),
            height = h,
            scale_factor = 0,
        }
    end
    -- No cover available: placeholder with the title's first letter
    local w = math.floor(h * 0.68)
    return FrameContainer:new{
        bordersize = 3,
        color = colors.line,
        padding = 0,
        background = colors.bg,
        CenterContainer:new{
            dimen = Geom:new{ w = w, h = h },
            TextWidget:new{
                text = (ctx.info.title or "?"):sub(1, 1):upper(),
                face = ctx.face(100, true),
                fgcolor = colors.fg,
                bgcolor = colors.bg,
            },
        },
    }
end

-- A TextBoxWidget; line_height (optional) tightens or loosens line spacing.
local function textBox(t, line_height)
    if line_height then t.line_height = line_height end
    return TextBoxWidget:new(t)
end

-- Title / author / chapter. The title keeps opts.title_size; author and
-- chapter shrink (down to opts.min_small) so the block fits in max_h.
-- Optional opts: line_gap (space between the three lines, default 8) and
-- line_height (TextBoxWidget line spacing, default = KOReader's).
function Parts.meta(ctx, colors, width, max_h, opts)
    local info = ctx.info
    local small = opts.small
    local gap = opts.line_gap or 8
    while true do
        local g = VerticalGroup:new{ align = "left" }
        table.insert(g, textBox({
            text = info.title,
            face = ctx.face(opts.title_size, true),
            width = width,
            fgcolor = colors.fg,
            bgcolor = colors.bg,
        }, opts.line_height))
        if info.author ~= "" then
            table.insert(g, VerticalSpan:new{ width = gap })
            table.insert(g, textBox({
                text = info.author,
                face = ctx.face(small),
                width = width,
                fgcolor = colors.muted,
                bgcolor = colors.bg,
            }, opts.line_height))
        end
        if info.chapter ~= "" then
            table.insert(g, VerticalSpan:new{ width = gap })
            table.insert(g, textBox({
                text = info.chapter,
                face = ctx.face(small - 2, false, true),
                width = width,
                fgcolor = colors.muted,
                bgcolor = colors.bg,
            }, opts.line_height))
        end
        if g:getSize().h <= max_h or small <= opts.min_small then
            return g
        end
        g:free()
        small = small - 1
    end
end

local FOOTER_DEFAULTS = {
    cover_h = 190,      -- starting cover height
    cover_w = 140,      -- reference cover width (for the aspect box)
    cover_max_h = 420,  -- the cover may grow up to this to match the details
    gap = 28,           -- space between cover and details
    title_size = 26,
    small = 20,         -- author size; the chapter is 2 smaller
    min_small = 16,
}

-- Cover (left) + details (right). The cover starts at opts.cover_h and only
-- grows if the details block would be taller than it.
function Parts.footer(ctx, colors, content_w, opts)
    local o = {}
    for k, v in pairs(FOOTER_DEFAULTS) do o[k] = v end
    for k, v in pairs(opts or {}) do o[k] = v end

    local cover, meta, cover_size
    local h = o.cover_h
    while true do
        cover = Parts.cover(ctx, colors, h, o)
        cover_size = cover:getSize()
        local meta_w = content_w - cover_size.w - o.gap
        meta = Parts.meta(ctx, colors, meta_w, cover_size.h, o)
        if meta:getSize().h <= cover_size.h or h >= o.cover_max_h then break end
        cover:free()
        meta:free()
        h = h + 10
    end
    local meta_w = content_w - cover_size.w - o.gap

    return HorizontalGroup:new{
        align = "top",
        cover,
        HorizontalSpan:new{ width = o.gap },
        LeftContainer:new{
            dimen = Geom:new{ w = meta_w, h = math.max(cover_size.h, meta:getSize().h) },
            meta,
        },
    }
end

return Parts
