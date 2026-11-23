--[[
    Theme registry. A theme is a colour palette: { key, name, palette }.

    To add one, create themes/<name>.lua (copy themes/_template.lua) and add
    "<name>" to ORDER below.

    Besides the real themes there is one special choice, "auto" (the
    default): it picks the Dark theme when the device is in night mode and
    the Classic theme otherwise.
]]

local Device = require("device")
local logger = require("logger")
local _ = require("gettext")

local ORDER = {
    "classic",   -- used by "auto" when the device is not in night mode
    "dark",      -- used by "auto" in night mode
    "sepia",
    "midnight",
}

local AUTO_KEY = "auto"
local LIGHT_KEY = "classic"
local DARK_KEY = "dark"

local Themes = {}
Themes.AUTO_KEY = AUTO_KEY

local loaded

local function loadAll()
    if loaded then return loaded end
    loaded = {}
    for i, name in ipairs(ORDER) do
        local ok, theme = pcall(require, "bookexcerpts/themes/" .. name)
        if ok and type(theme) == "table" and theme.key and theme.name
                and type(theme.palette) == "table" then
            table.insert(loaded, theme)
        else
            -- A broken theme must not break the plugin: skip it.
            logger.warn("BookExcerpts: skipping theme", name,
                ok and "(invalid theme table)" or theme)
        end
    end
    return loaded
end

local function find(key)
    for i, theme in ipairs(loadAll()) do
        if theme.key == key then return theme end
    end
end

-- Is the device currently in night (dark) mode?
function Themes.isNightMode()
    local ok, night = pcall(function()
        local screen = Device.screen
        if screen and screen.night_mode then return true end
        return G_reader_settings:isTrue("night_mode")
    end)
    return ok and night and true or false
end

-- Real themes only, in display order.
function Themes.list()
    return loadAll()
end

-- What the user can choose: "Auto" first, then every real theme.
function Themes.choices()
    local choices = { { key = AUTO_KEY, name = _("Auto (match device)") } }
    for i, theme in ipairs(loadAll()) do
        table.insert(choices, theme)
    end
    return choices
end

-- The choice entry (key + name) for a saved key; unknown/nil = auto.
function Themes.choice(key)
    for i, choice in ipairs(Themes.choices()) do
        if choice.key == key then return choice end
    end
    return Themes.choices()[1]
end

-- The theme to draw with. "auto", nil and unknown keys resolve to the
-- device's mode: Dark in night mode, Classic otherwise.
function Themes.get(key)
    if key and key ~= AUTO_KEY then
        local theme = find(key)
        if theme then return theme end
    end
    local want = Themes.isNightMode() and DARK_KEY or LIGHT_KEY
    return find(want) or loadAll()[1]
end

return Themes
