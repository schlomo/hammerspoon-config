require "tabletools"

hs.window.animationDuration=0

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
    {"iTerm",            nil,           display_laptop, hs.layout.maximized, nil, nil},
}

local desk_display = {
    {"Mail",              nil,          display_desk_left,  hs.layout.right50, nil, nil},
    {"Microsoft Outlook", nil,          display_desk_left, hs.layout.maximized, nil, nil},
    {"Calendar",          nil,          display_desk_left, hs.layout.left50, nil, nil},
    {"Jabber",            nil,          display_desk_left,  hs.layout.maximized, nil, nil},
    {"Evernote",          nil,          display_desk_right, hs.layout.maximized,   nil, nil},
    {"iTerm",             nil,          display_desk_right, hs.layout.maximized,   nil, nil},
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
