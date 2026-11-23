-- Dark: light text on a near-black card. Used by "Auto" in night mode.
local _ = require("gettext")

return {
    key = "dark",
    name = _("Dark"),
    palette = {
        bg = "#16181D", fg = "#F2F2F2", muted = "#A8ADB7", line = "#F2F2F2",
        border = "#F2F2F2", outer = "#000000",
    },
}
