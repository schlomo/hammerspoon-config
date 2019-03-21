require "tabletools"

function get_key_for_value( t, value )
    for k,v in pairs(t) do
        if v==value then 
            return k
        end
        return nil
    end
end

hs.window.animationDuration=0

--[[ 
keepAwakeId=0
function keepAwakeTimerAction()
    print("Keep Awake Timer")
    keepAwakeId=hs.caffeinate.declareUserActivity(keepAwakeId)
end
keepAwakeTimer = hs.timer.new(5, keepAwakeTimerAction, true):start()
]]

local yubicoAuthenticator="Yubico Authenticator"

function usbEvent(event)
    print(table.show(event, "USB Event"))
    if string.find(event["productName"], "Yubikey NEO") then
        if event["eventType"] == "added" then
            print("added Yubikey")
            if not hs.application.launchOrFocus(yubicoAuthenticator) then
                notify(yubicoAuthenticator .. " is not installed")
            end
        else
            print("removed Yubikey")
            local yubicoAuthenticatorApp=hs.application.get(yubicoAuthenticator)
            if yubicoAuthenticatorApp then
                yubicoAuthenticatorApp:kill()
            else
                print(yubicoAuthenticator .. " is not running")
            end
        end
    end
end
usbWatcher = hs.usb.watcher.new(usbEvent):start()



-- my magic shortcut base
local ctrlaltcmd = {"⌃", "⌥", "⌘"}
-- Define monitor names for layout purposes
local display_laptop = "Color LCD"
local display_desk_right = "DELL 2408WFP - forced RGB mode (EDID override)"
local display_desk_left = "DELL U2410 - forced RGB mode (EDID override)"

-- Define window layouts
--   Format reminder:
--     {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
local internal_display = {
    {"Mail",              nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Microsoft Outlook", nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Calendar",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"iTerm",             nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"Google Chrome",     nil,          display_laptop, hs.layout.maximized, nil, nil},
    {"IntelliJ IDEA",     nil,          display_laptop, hs.layout.maximized, nil, nil},
}

local desk_display = {
    {"Mail",              nil,          display_desk_left, hs.layout.right50, nil, nil},
    {"Microsoft Outlook", nil,          display_desk_left, hs.layout.maximized, nil, nil},
    {"Calendar",          nil,          display_desk_left, hs.layout.left50, nil, nil},
    {"Jabber",            nil,          display_desk_left, hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_desk_right, hs.layout.maximized, nil, nil},
    {"iTerm",             nil,          display_desk_right, hs.layout.maximized, nil, nil},
    {"Google Chrome",     nil,          display_desk_right, hs.layout.maximized, nil, nil},
    {"IntelliJ IDEA",     nil,          display_desk_right, hs.layout.maximized, nil, nil},
}

function notify(text)
    -- hs.notify.new({title="Hammerspoon", informativeText=text}):send()
    hs.alert(text)
end

local lastNumberOfScreens = #hs.screen.allScreens()
function screenWatcher()
    print(table.show(hs.screen.allScreens(), "allScreens"))
    newNumberOfScreens = #hs.screen.allScreens()

    -- FIXME: This is awful if we swap primary screen to the external display. all the windows swap around, pointlessly.
    -- if lastNumberOfScreens ~= newNumberOfScreens then
        if newNumberOfScreens == 1 then
            notify("Screens changed to Internal Display")
            hs.layout.apply(internal_display)
        elseif newNumberOfScreens == 2 then
            notify("Screens changed to Desk Display")
            hs.layout.apply(desk_display)
        end
    -- end

    lastNumberOfScreens = newNumberOfScreens
end
hs.screen.watcher.new(screenWatcher):start()
hs.hotkey.bind(ctrlaltcmd, 'S', screenWatcher)


function sleepWatch(eventType)
	if (eventType == hs.caffeinate.watcher.systemWillSleep) then
        notify("Going to sleep!")
        print("Going to sleep!")
	elseif (eventType == hs.caffeinate.watcher.systemDidWake) then
        notify("Waking up!")
        print("Waking up!")
	end
end

local sleepWatcher = hs.caffeinate.watcher.new(sleepWatch)
sleepWatcher:start()

hs.hints.showTitleThresh=10
hs.hotkey.bind(ctrlaltcmd, "H", function() hs.hints.windowHints() end)

-- Defines for window maximize toggler
local frameCache = {}
-- Toggle a window between its normal size, and being maximized
hs.hotkey.bind(ctrlaltcmd, "M", function()
    local win = hs.window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
        win:maximize()
    end
end)

hs.hotkey.bind(ctrlaltcmd, 'LEFT', function() hs.window.focusedWindow():moveToUnit(hs.layout.left50) end)
hs.hotkey.bind(ctrlaltcmd, 'RIGHT', function() hs.window.focusedWindow():moveToUnit(hs.layout.right50) end)
hs.hotkey.bind(ctrlaltcmd, 'F', function() hs.window.focusedWindow():toggleFullScreen() end)

hs.pathwatcher.new(hs.configdir, hs.reload):start()
notify("Hammerspoon config loaded")
print("Config loaded")

hs.dockicon.hide()
