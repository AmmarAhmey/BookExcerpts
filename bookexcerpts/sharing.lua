--[[
    "Send to phone": turns Wi-Fi on if needed, runs the one-file web server,
    and cleans everything up (server + Wi-Fi) afterwards.

    Only one server runs at a time.
]]

local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local Webserver = require("bookexcerpts/webserver")
local Wifi = require("bookexcerpts/wifi")
local logger = require("logger")
local _ = require("gettext")

local Sharing = {
    stop_fn = nil, -- stops the running server
    token = nil,   -- identifies the pending start request (for cancelling)
}

-- Starts serving `path` (turning Wi-Fi on first if it is off).
function Sharing.serve(path)
    Sharing.stopServer() -- never run two servers at once
    local token = {}
    Sharing.token = token

    local attempts = 0
    local function start()
        if Sharing.token ~= token then return end -- cancelled meanwhile
        -- Right after Wi-Fi comes up the address may not be assigned yet,
        -- so retry for up to ~12 seconds before giving up.
        local ip = Wifi.getLocalIp()
        if not ip and attempts < 12 then
            attempts = attempts + 1
            UIManager:scheduleIn(1, start)
            return
        end
        local ok, result = pcall(Webserver.start, path, ip)
        if ok then
            Sharing.stop_fn = result
        else
            logger.err("BookExcerpts: server failed:", result)
            UIManager:show(InfoMessage:new{
                text = _("Could not start sharing:") .. "\n" .. tostring(result),
            })
        end
    end

    local ok, err = pcall(Wifi.ensureOnline, start)
    if not ok then
        logger.err("BookExcerpts: Wi-Fi failed:", err)
        UIManager:show(InfoMessage:new{
            text = _("Could not start sharing:") .. "\n" .. tostring(err),
        })
    end
end

-- Stops the web server (and closes the QR window). Leaves Wi-Fi alone.
function Sharing.stopServer()
    Sharing.token = nil
    if Sharing.stop_fn then
        local stop = Sharing.stop_fn
        Sharing.stop_fn = nil
        pcall(stop)
    end
end

-- Stops the server and, if Wi-Fi was off before the excerpt was created,
-- switches it off again. Pass nothing to keep Wi-Fi as it is.
function Sharing.stop(wifi_was_on)
    Sharing.stopServer()
    if wifi_was_on == false and Wifi.isWifiOn() then
        Wifi.turnOff()
    end
end

return Sharing
