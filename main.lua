--[[
    BookExcerpts - KOReader plugin

    Adds a "Share excerpt" button to the highlight dialog. It renders the
    selected text as a PNG image, shows a preview (Keep / Layout / Theme /
    Delete / Send to phone) and can serve the image to your phone over Wi-Fi.

    LAYOUT = how the excerpt is arranged     (layouts/*.lua)
    THEME  = the colours it is drawn with    (themes/*.lua)
    Any layout works with any theme. The default theme "Auto" follows the
    device: dark card in night mode, light card otherwise.

    Code map (everything lives in the bookexcerpts/ folder):
        settings.lua       saved settings (preferred layout and theme)
        layouts.lua        layout registry -> add new layouts here
        layouts/*.lua      one file per layout (see layouts/_template.lua)
        themes.lua         theme registry  -> add new themes here
        themes/*.lua       one file per theme (see themes/_template.lua)
        parts.lua          reusable layout building blocks
        book.lua           title / author / chapter / cover of the open book
        fonts.lua          the book's current font
        renderer.lua       layout + theme -> PNG file
        preview.lua        preview window with the buttons
        picker.lua         "Layout" / "Theme" button dialog
        sharing.lua        "Send to phone" orchestration (Wi-Fi + server)
        webserver.lua      the one-file web server and QR code
        wifi.lua           Wi-Fi state and IP lookup

    Images are saved in <koreader data dir>/excerpts/.
    Preferred layout and theme: Main menu > Tools > More tools > BookExcerpts.
]]

-- Make "require('bookexcerpts/...')" work no matter how KOReader set up the
-- plugin's search path.
do
    local src = debug.getinfo(1, "S").source or ""
    local dir = src:match("^@(.*)/[^/]*$")
    if dir and not package.path:find(dir .. "/?.lua", 1, true) then
        package.path = dir .. "/?.lua;" .. package.path
    end
end

local InfoMessage = require("ui/widget/infomessage")
local Layouts = require("bookexcerpts/layouts")
local Preview = require("bookexcerpts/preview")
local Renderer = require("bookexcerpts/renderer")
local Settings = require("bookexcerpts/settings")
local Themes = require("bookexcerpts/themes")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Wifi = require("bookexcerpts/wifi")
local logger = require("logger")
local _ = require("gettext")

local BookExcerpts = WidgetContainer:extend{
    name = "bookexcerpts",
    is_doc_only = true,
}

function BookExcerpts:init()
    if not self.ui or not self.ui.highlight then return end
    self.ui.menu:registerToMainMenu(self)
    self.ui.highlight:addToHighlightDialog("13_bookexcerpts_share", function(this)
        return {
            text = _("Share excerpt"),
            callback = function()
                local text = this.selected_text and this.selected_text.text
                this:onClose()
                UIManager:nextTick(function()
                    self:share(text)
                end)
            end,
        }
    end)
end

-- Layout the user prefers (the default layout if none chosen).
function BookExcerpts:getPreferredLayout()
    return Layouts.get(Settings.getLayoutKey())
end

-- Theme *choice* the user prefers: a theme key or "auto" (the default).
function BookExcerpts:getPreferredThemeKey()
    return Themes.choice(Settings.getThemeKey()).key
end

-- Radio items for a "preferred ..." submenu.
local function radioItems(choices, is_current, on_pick)
    local items = {}
    for i, choice in ipairs(choices) do
        table.insert(items, {
            text = choice.name,
            radio = true,
            keep_menu_open = true,
            checked_func = function() return is_current(choice.key) end,
            callback = function(touchmenu_instance)
                on_pick(choice.key)
                if touchmenu_instance then touchmenu_instance:updateItems() end
            end,
        })
    end
    return items
end

-- Menu: Tools > More tools > BookExcerpts
function BookExcerpts:addToMainMenu(menu_items)
    menu_items.book_excerpts = {
        text = _("BookExcerpts"),
        sorting_hint = "more_tools",
        sub_item_table = {
            {
                text_func = function()
                    return _("Preferred layout") .. ": " .. self:getPreferredLayout().name
                end,
                sub_item_table = radioItems(Layouts.list(),
                    function(key) return self:getPreferredLayout().key == key end,
                    function(key) Settings.setLayoutKey(key) end),
            },
            {
                text_func = function()
                    return _("Preferred theme") .. ": "
                        .. Themes.choice(self:getPreferredThemeKey()).name
                end,
                sub_item_table = radioItems(Themes.choices(),
                    function(key) return self:getPreferredThemeKey() == key end,
                    function(key) Settings.setThemeKey(key) end),
            },
        },
    }
end

-- Creates the excerpt image and opens the preview.
--   choice       optional { layout = key, theme = key }; missing parts use
--                the preferred layout / theme
--   wifi_was_on  Wi-Fi state before the very first excerpt; passed along
--                when re-rendering with another layout or theme
function BookExcerpts:share(text, choice, wifi_was_on)
    choice = choice or {}
    if wifi_was_on == nil then
        wifi_was_on = Wifi.isWifiOn() -- first call: remember the original state
    end
    text = (text or ""):gsub("%s+", " ")
    text = text:gsub("^ ", ""):gsub(" $", "")
    if text == "" then
        UIManager:show(InfoMessage:new{ text = _("No text selected.") })
        return
    end

    local layout = choice.layout and Layouts.get(choice.layout)
        or self:getPreferredLayout()
    local theme_key = choice.theme or self:getPreferredThemeKey()
    local theme = Themes.get(theme_key) -- "auto" resolves to the device mode

    local ok, path = pcall(Renderer.render, self.ui, text, layout, theme)
    if not ok then
        logger.err("BookExcerpts: render failed:", path)
        UIManager:show(InfoMessage:new{
            text = _("Could not create excerpt:") .. "\n" .. tostring(path),
        })
        return
    end

    UIManager:show(Preview:new{
        path = path,
        text = text,
        plugin = self,
        layout_key = layout.key,
        theme_key = theme_key,
        wifi_was_on = wifi_was_on,
    })
end

return BookExcerpts
