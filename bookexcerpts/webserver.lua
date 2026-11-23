--[[
    Tiny one-file web server. Serves one image at http://<ip>:<port>/ for a
    few minutes and shows a QR code with that address.
]]

local Device = require("device")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local Screen = Device.screen

local Webserver = {}

local FIRST_PORT, LAST_PORT = 8089, 8099
local TIMEOUT_SECONDS = 300 -- auto-stop after 5 minutes

-- Starts serving `path`. Returns a stop() function (safe to call twice).
function Webserver.start(path, ip)
    local socket = require("socket")
    assert(ip, "could not find the Kindle's IP address (is Wi-Fi connected?)")

    local server, port
    for p = FIRST_PORT, LAST_PORT do
        server = socket.bind("*", p)
        if server then port = p break end
    end
    assert(server, "no free port")
    server:settimeout(0)

    local name = path:match("([^/]+)$") or "excerpt.png"
    local stopped = false
    local deadline = os.time() + TIMEOUT_SECONDS

    local qr_widget
    local function stop()
        if stopped then return end
        stopped = true
        pcall(function() server:close() end)
        if qr_widget then
            pcall(function() UIManager:close(qr_widget) end)
            qr_widget = nil
        end
    end

    local function readFile()
        local f = assert(io.open(path, "rb"))
        local data = f:read("*a")
        f:close()
        return data
    end

    local function respond(client, status, ctype, body, extra)
        local head = string.format(
            "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n%s\r\n",
            status, ctype, #body, extra or "")
        client:send(head .. body)
    end

    local page = '<!doctype html><html><head><meta name="viewport" '
        .. 'content="width=device-width,initial-scale=1"></head>'
        .. '<body style="margin:0;padding:12px;text-align:center;font-family:sans-serif">'
        .. '<img src="/image.png" style="max-width:100%">'
        .. '<p><a href="/download">Download image</a></p></body></html>'

    local function handle(client)
        client:settimeout(3)
        local line = client:receive("*l") or ""
        while true do -- drain request headers
            local h = client:receive("*l")
            if not h or h == "" then break end
        end
        local req = line:match("^GET%s+(%S+)")
        if req == "/image.png" then
            respond(client, "200 OK", "image/png", readFile())
        elseif req == "/download" then
            respond(client, "200 OK", "image/png", readFile(),
                'Content-Disposition: attachment; filename="' .. name .. '"\r\n')
        elseif req == "/" then
            respond(client, "200 OK", "text/html; charset=utf-8", page)
        else
            respond(client, "404 Not Found", "text/plain", "Not found")
        end
        client:close()
    end

    local function poll()
        if stopped then return end
        if os.time() > deadline then stop() return end
        local client = server:accept()
        if client then pcall(handle, client) end
        UIManager:scheduleIn(0.3, poll)
    end
    UIManager:scheduleIn(0.3, poll)

    -- Show the address: QR code if available, plain text otherwise
    local url = string.format("http://%s:%d/", ip, port)
    local shown = pcall(function()
        local QRMessage = require("ui/widget/qrmessage")
        local size = math.floor(Screen:getWidth() * 0.7)
        qr_widget = QRMessage:new{
            text = url,
            width = size,
            height = size,
            dismiss_callback = stop,
        }
        UIManager:show(qr_widget)
    end)
    if not shown then
        qr_widget = InfoMessage:new{
            text = _("Open this address on your phone (same Wi-Fi):") .. "\n\n" .. url
                .. "\n\n" .. _("Tap to stop sharing."),
            dismiss_callback = stop,
        }
        UIManager:show(qr_widget)
    end

    return stop
end

return Webserver
