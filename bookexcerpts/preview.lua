--[[
    Full-screen preview of the finished excerpt with buttons:
        Keep | Layout | Theme | Delete
        Send to phone (Wi-Fi)

    Closing the preview (Keep, Delete or the Back key) stops any running
    web server and restores the Wi-Fi state from before the excerpt.
]]

local Blitbuffer = require("ffi/blitbuffer")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local ImageWidget = require("ui/widget/imagewidget")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local Layouts = require("bookexcerpts/layouts")
local Picker = require("bookexcerpts/picker")
local Sharing = require("bookexcerpts/sharing")
local Size = require("ui/size")
local Themes = require("bookexcerpts/themes")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local _ = require("gettext")
local Screen = Device.screen

local Preview = InputContainer:extend{
    path = nil,         -- PNG file
    text = nil,         -- excerpt text (to re-render with another layout/theme)
    plugin = nil,       -- the BookExcerpts plugin (provides :share())
    layout_key = nil,   -- layout used for this image
    theme_key = nil,    -- theme choice used for this image ("auto" allowed)
    wifi_was_on = true, -- Wi-Fi state before the excerpt was created
    covers_fullscreen = true,
}

function Preview:init()
    local sw, sh = Screen:getWidth(), Screen:getHeight()
    self.dimen = Geom:new{ w = sw, h = sh }
    if Device:hasKeys() then
        self.key_events = { Close = { { Device.input.group.Back } } }
    end

    local gap = Size.padding.large
    local btn_table = ButtonTable:new{
        width = sw - 2 * gap,
        show_parent = self,
        buttons = {{
            { text = _("Keep"), callback = function() self:onKeep() end },
            { text = _("Layout"), callback = function() self:onChooseLayout() end },
            { text = _("Theme"), callback = function() self:onChooseTheme() end },
            { text = _("Delete"), callback = function() self:onDelete() end },
        }, {
            { text = _("Send to phone (Wi-Fi)"),
              callback = function() Sharing.serve(self.path) end },
        }},
    }
    local btn_h = btn_table:getSize().h + 2 * gap
    local img_area_h = sh - btn_h

    local image = ImageWidget:new{
        file = self.path,
        width = sw - 2 * gap,
        height = img_area_h - 2 * gap,
        scale_factor = 0, -- fit, keep aspect ratio
        file_do_cache = false,
    }

    self[1] = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        margin = 0,
        VerticalGroup:new{
            align = "center",
            CenterContainer:new{ dimen = Geom:new{ w = sw, h = img_area_h }, image },
            CenterContainer:new{ dimen = Geom:new{ w = sw, h = btn_h }, btn_table },
        },
    }
end

function Preview:onShow()
    UIManager:setDirty(self, function() return "ui", self.dimen end)
end

function Preview:onCloseWidget()
    UIManager:setDirty(nil, "partial")
end

function Preview:onKeep()
    Sharing.stop(self.wifi_was_on) -- stop server, restore Wi-Fi
    UIManager:close(self)
    UIManager:show(InfoMessage:new{
        text = _("Excerpt saved to:") .. "\n" .. self.path,
        timeout = 3,
    })
end
Preview.onClose = Preview.onKeep -- Back key = keep

function Preview:onDelete()
    Sharing.stop(self.wifi_was_on)
    os.remove(self.path)
    UIManager:close(self)
    UIManager:show(InfoMessage:new{ text = _("Excerpt deleted."), timeout = 2 })
end

function Preview:onChooseLayout()
    Picker.show{
        title = _("Choose layout"),
        items = Layouts.list(),
        current = self.layout_key,
        on_select = function(key) self:rerender(key, self.theme_key) end,
    }
end

function Preview:onChooseTheme()
    Picker.show{
        title = _("Choose theme"),
        items = Themes.choices(),
        current = self.theme_key,
        on_select = function(key) self:rerender(self.layout_key, key) end,
    }
end

-- Re-renders the same excerpt with another layout and/or theme (this image
-- only; the preferred ones in the menu are not changed).
function Preview:rerender(layout_key, theme_key)
    local plugin, text, wifi_was_on = self.plugin, self.text, self.wifi_was_on
    Sharing.stopServer() -- stop the server, but keep Wi-Fi as it is for now
    os.remove(self.path)
    UIManager:close(self)
    UIManager:nextTick(function()
        plugin:share(text, { layout = layout_key, theme = theme_key }, wifi_was_on)
    end)
end

return Preview
