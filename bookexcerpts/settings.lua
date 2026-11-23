--[[
    Persistent plugin settings (stored in KOReader's global settings).
    Add new settings here so the rest of the code never touches
    G_reader_settings directly.
]]

local Settings = {}

local THEME_KEY = "bookexcerpts_theme"
local LAYOUT_KEY = "bookexcerpts_layout"
local OLD_THEME_KEY = "excerpt_share_theme" -- used by the first version

-- Key of the user's preferred theme (nil = never chosen = automatic).
function Settings.getThemeKey()
    return G_reader_settings:readSetting(THEME_KEY)
        or G_reader_settings:readSetting(OLD_THEME_KEY)
end

function Settings.setThemeKey(key)
    G_reader_settings:saveSetting(THEME_KEY, key)
end

-- Key of the user's preferred layout (nil = never chosen = default layout).
function Settings.getLayoutKey()
    return G_reader_settings:readSetting(LAYOUT_KEY)
end

function Settings.setLayoutKey(key)
    G_reader_settings:saveSetting(LAYOUT_KEY, key)
end

return Settings
