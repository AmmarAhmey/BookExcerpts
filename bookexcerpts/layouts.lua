--[[
    Layout registry.

    A layout is a table { key, name, build(ctx, palette) } (see
    layouts/card.lua and layouts/_template.lua). To add one, create
    layouts/<name>.lua and add "<name>" to ORDER below.
    The FIRST entry is the default layout.
]]

local logger = require("logger")

local ORDER = {
    "card",       -- default
    "highlight",
}

local Layouts = {}
local loaded

local function loadAll()
    if loaded then return loaded end
    loaded = {}
    for i, name in ipairs(ORDER) do
        local ok, layout = pcall(require, "bookexcerpts/layouts/" .. name)
        if ok and type(layout) == "table" and layout.key and layout.name
                and type(layout.build) == "function" then
            table.insert(loaded, layout)
        else
            -- A broken layout must not break the plugin: skip it.
            logger.warn("BookExcerpts: skipping layout", name,
                ok and "(invalid layout table)" or layout)
        end
    end
    return loaded
end

-- All usable layouts, in display order.
function Layouts.list()
    return loadAll()
end

-- The default layout.
function Layouts.default()
    return loadAll()[1]
end

-- Layout with this key; falls back to the default for unknown/nil keys.
function Layouts.get(key)
    for i, layout in ipairs(loadAll()) do
        if layout.key == key then return layout end
    end
    return Layouts.default()
end

return Layouts
