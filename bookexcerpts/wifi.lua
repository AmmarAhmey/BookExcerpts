--[[
    Wi-Fi helpers: state, switching on/off, and finding the device's IP.
]]

local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local Wifi = {}

local function networkMgr()
    local ok, mgr = pcall(require, "ui/network/manager")
    if ok then return mgr end
end

-- Is Wi-Fi switched on? (Assumes "yes" when it can't tell, so we never
-- switch off something we did not switch on.)
function Wifi.isWifiOn()
    local mgr = networkMgr()
    if not mgr then return true end
    local ok, on = pcall(function()
        if mgr.isWifiOn then return mgr:isWifiOn() end
        return mgr:isOnline()
    end)
    if ok then return on and true or false end
    return true
end

-- Calls callback() once the device is online, turning Wi-Fi on if needed.
function Wifi.ensureOnline(callback)
    local mgr = require("ui/network/manager")
    if mgr:isOnline() then
        callback()
    else
        UIManager:show(InfoMessage:new{ text = _("Turning on Wi-Fi…"), timeout = 2 })
        mgr:turnOnWifiAndWaitForConnection(callback)
    end
end

function Wifi.turnOff()
    local mgr = networkMgr()
    if mgr then
        pcall(function() mgr:turnOffWifi() end)
    end
end

-- Finds this device's LAN IP (nil if not found). Tries KOReader's own
-- helper first (its name differs between versions), then plain sockets,
-- then the system's network tools.
function Wifi.getLocalIp()
    local mgr = networkMgr()
    if mgr then
        for i, fname in ipairs({ "getLocalIpAddress", "getLocalIpAdress" }) do
            if type(mgr[fname]) == "function" then
                local ok, ip = pcall(mgr[fname], mgr)
                if ok and type(ip) == "string" and ip ~= "" and ip ~= "0.0.0.0"
                        and not ip:match("^127%.") then
                    return ip
                end
            end
        end
    end

    local socket = require("socket")
    -- "Connecting" a UDP socket sends no packets; it only makes the OS pick
    -- the outgoing interface, whose address we then read back.
    for i, target in ipairs({ "8.8.8.8", "192.168.1.1", "10.0.0.1" }) do
        local udp = socket.udp()
        if udp then
            local ip
            local ok = pcall(function()
                udp:setpeername(target, 80)
                ip = udp:getsockname()
            end)
            pcall(function() udp:close() end)
            if ok and ip and ip ~= "0.0.0.0" and not ip:match("^127%.") then
                return ip
            end
        end
    end

    -- Ask the system's network tools (Kindle: wlan0).
    for i, cmd in ipairs({
        "ip -4 addr show wlan0 2>/dev/null",
        "ifconfig wlan0 2>/dev/null",
        "ip -4 addr 2>/dev/null",
        "ifconfig 2>/dev/null",
    }) do
        local out
        pcall(function()
            local f = io.popen(cmd)
            if f then out = f:read("*a"); f:close() end
        end)
        if out then
            for ip in out:gmatch("inet%s+addr:(%d+%.%d+%.%d+%.%d+)") do
                if not ip:match("^127%.") then return ip end
            end
            for ip in out:gmatch("inet%s+(%d+%.%d+%.%d+%.%d+)") do
                if not ip:match("^127%.") then return ip end
            end
        end
    end

    -- Last resort: resolve our own hostname
    local ok, ip = pcall(function()
        return socket.dns.toip(socket.dns.gethostname())
    end)
    if ok and ip and not ip:match("^127%.") then return ip end
    return nil
end

return Wifi
