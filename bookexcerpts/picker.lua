--[[
    Generic "choose one" dialog used for layouts and themes.
    The current choice is marked with a check.
]]

local ButtonDialog = require("ui/widget/buttondialog")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local Picker = {}

-- opts.title      dialog title
-- opts.items      list of { key, name }
-- opts.current    key of the choice in use
-- opts.on_select  function(key), called when a *different* item is picked
function Picker.show(opts)
    local dialog
    local buttons = {}
    for i, item in ipairs(opts.items) do
        local mark = (item.key == opts.current) and "✓  " or ""
        table.insert(buttons, {{
            text = mark .. item.name,
            callback = function()
                UIManager:close(dialog)
                if item.key ~= opts.current then
                    opts.on_select(item.key)
                end
            end,
        }})
    end
    table.insert(buttons, {{
        text = _("Cancel"),
        callback = function() UIManager:close(dialog) end,
    }})

    dialog = ButtonDialog:new{
        title = opts.title,
        title_align = "center",
        buttons = buttons,
    }
    UIManager:show(dialog)
end

return Picker
