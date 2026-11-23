-- Classic: black on white. Used by "Auto" when the device is NOT in night mode.
local _ = require("gettext")

return {
    key = "classic",
    name = _("Classic"),
    palette = {
        bg = "#FFFFFF", fg = "#000000", muted = "#555555", line = "#000000",
        border = "#000000", outer = "#FFFFFF",
    },
}
