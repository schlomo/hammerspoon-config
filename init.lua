require "tabletools"

hs.window.animationDuration=0

local ctrlaltcmd = {"⌃", "⌥", "⌘"}


function notify(text)
    hs.notify.new({title="Hammerspoon", informativeText=text}):send()
end

function screenWatcher()
    notify("Screens changed\n")
    print(table.show(hs.screen.allScreens(), "allScreens"))
end
hs.screen.watcher.new(screenWatcher):start()

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
notify("Config loaded")

hs.dockicon.hide()
