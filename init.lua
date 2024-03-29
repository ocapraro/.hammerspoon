hs = hs
local padding = 12
local menuBar = 25
local ok,result = hs.applescript('tell Application "Finder" to get bounds of window of desktop')
local screenHeight =  result[4]-menuBar
local screenWidth =  result[3]
local secondaryApps = (hs.application.get("Trello") and 1 or 0)+(hs.application.get("MongoDB Compass") and 1 or 0)
local laptopScreen = hs.screen.allScreens()[1]:name()
local terminalWindows = hs.application.get("Terminal"):allWindows()

-- --------
-- Layouts:
-- --------

function Rect(x,y,w,h,b,r)
  b=(y+h==1 and true) or false
  r=(x+w==1 and true) or false
  return hs.geometry.rect(math.floor(screenWidth*x+padding), math.floor(screenHeight*y+padding+menuBar), math.floor(screenWidth*w-padding-(r and padding or 0)), math.floor(screenHeight*h-padding-((b) and padding or 0)))
end

if (screenWidth>=3000) then
  -- Monitor Layout
  WindowLayout = {
    {"Code", nil, laptopScreen, nil, nil, Rect(1/3,0,2/3,1)},
    {"Messages", nil, laptopScreen, nil, nil, Rect(1/3,0,1/3,1/2)},
    {"Discord", nil, laptopScreen, nil, nil, Rect(1/3,1/2,2/3,1/2)},
    {"Skype", nil, laptopScreen, nil, nil, Rect(2/3,0,1/3,1/2)},
    {"Obsidian", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1)},
    {"Google Chrome", nil, laptopScreen, nil, nil, Rect(0,0,1,1)},
  }

  SecondaryAppCodeLayout = {
    {"Terminal", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/2)},
    {"Trello", nil, laptopScreen, nil, nil, Rect(0,1/2,1/3,1/2, true)},
    {"MongoDB Compass", nil, laptopScreen, nil, nil, Rect(0,1/2,1/3,1/2, true)},
  }
else
  -- Laptop Layout
  WindowLayout = {
    {"Code", nil, laptopScreen, nil, nil, Rect(1/3,0,2/3,1, true, true)},
    {"Messages", nil, laptopScreen, nil, nil, Rect(0,0,2/3,1/2)},
    {"Discord", nil, laptopScreen, nil, nil, Rect(0,1/2,2/3,1/2, true)},
    {"Skype", nil, laptopScreen, nil, nil, Rect(2/3,0,1/3,1, true, true)},
    {"Obsidian", nil, laptopScreen, nil, nil, Rect(0,0,1,1)},
    {"Google Chrome", nil, laptopScreen, nil, nil, Rect(0,0,1,1)},
  }

  SecondaryAppCodeLayout = {
    {"Terminal", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/3)},
    {"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/3)},
    {"Trello", nil, laptopScreen, nil, nil, Rect(0,1/3,1/3,2/3)},
    {"MongoDB Compass", nil, laptopScreen, nil, nil, Rect(0,1/3,1/3,2/3)},
  }
end


-- ----------
-- Functions:
-- ----------

local function getDesktop()
  -- Gets the current Desktop based on what applications are in view
  local discriminators = {"Discord","Code","Google Chrome","Google Chrome"}
  for i, v in ipairs(discriminators) do
    if (#hs.application.get(v):allWindows()>0) then
      if (not(v=="Google Chrome")) then
        return i
      end
      -- Since I have Chrome running on multiple Desktops, I diffentiate between them based on the window name
      if (string.find(tostring(hs.application.get(v):allWindows()[1]),"(Person 1)") and true or false) then
        return 3
      else
        return 4
      end
    end
  end
end

local clock = os.clock
local function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

function Split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end

local function reloadTerminalLayout()
  if secondaryApps<1 then
    local terminalLayout = {}
    terminalWindows = hs.application.get("Terminal"):allWindows()
    for i, v in pairs(terminalWindows) do
      table.insert(terminalLayout,{"Terminal", v, laptopScreen, nil, nil, Rect(0,(i-1)/#terminalWindows,1/3,1/#terminalWindows)})
    end
    hs.layout.apply(terminalLayout)
  else
    hs.layout.apply(SecondaryAppCodeLayout)
  end
end


-- Apply Layouts
reloadTerminalLayout()

hs.layout.apply(WindowLayout)


-- -----------
-- App Events:
-- -----------

local function applicationWatcher(appName, eventType, appObject)
  -- On app Launch
  if (eventType == hs.application.watcher.launched) then
      if (appName == "Music") then
          -- Reload Layout
          hs.layout.apply({{"Music", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/2)}})
      elseif (appName == "Trello" or appName == "MongoDB Compass") then
        secondaryApps = secondaryApps + 1
        -- Swap to Secondary code app Layout
        sleep(0.8)
        hs.layout.apply(SecondaryAppCodeLayout)
      end
  -- On app Quit
  elseif (eventType == hs.application.watcher.terminated) then
    if (appName == "Trello" or appName == "MongoDB Compass") then
      secondaryApps = secondaryApps - 1
      if (secondaryApps<1) then
        secondaryApps = 0
        -- Swap to default Layout
        hs.layout.apply(WindowLayout)
        -- Reload terminal
        reloadTerminalLayout()
      end
    end
  elseif (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      if (getDesktop()==2) then
        -- Reload Layout
        if (secondaryApps==0) then
          hs.layout.apply({{"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,(#terminalWindows-1)/#terminalWindows)}})
        else
          hs.layout.apply(SecondaryAppCodeLayout)
        end
      end
    elseif (appName == "Terminal") then
      -- Bring all Terminal windows forward when one gets activated
      terminalWindows = hs.application.get("Terminal"):allWindows()
      if (secondaryApps==0) then
        hs.application.get("Terminal"):selectMenuItem({"Window", "Bring All to Front"})
        -- hs.layout.apply({{"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/#terminalWindows)}})
        hs.application.get("Finder"):hide()
        hs.application.get("Music"):hide()
      end
    elseif (appName == "Trello" or appName == "MongoDB Compass") then
      hs.application.get("Finder"):hide()
      hs.layout.apply(SecondaryAppCodeLayout)
    end
  end
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
-- Music Mode

-- ------
-- Loops:
-- ------

local lastState = {}
local lastDesktop = getDesktop()
local chromeExpanded = false
local mainLoop = hs.timer.new(0.1, function()
  local desktop = getDesktop()
  if (not(desktop == lastDesktop)) then
    print("--------------------------")
    print("Desktop: ", desktop)
    if (#{hs.window.find("Google Chrome")}>1) then
      chromeExpanded = true
    else
      chromeExpanded = false
    end
    print("Crome Expanded: ", chromeExpanded)
  end
  lastDesktop = desktop

	local state = {}
  local apps = {hs.application.find("")}
  for i, v in ipairs(apps) do
    -- table.insert(state,#v:allWindows())
    if (#lastState>=i) then
      if (not(#v:allWindows()==lastState[i][2])) then
        if (v:name()=="Terminal") then
          reloadTerminalLayout()
          -- hs.layout.apply({{"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/#terminalWindows)}})
        elseif (v:name()=="Google Chrome") then
          if (#{hs.window.find("Google Chrome")}>1 and not(chromeExpanded)) then
            chromeExpanded = true
            local chromeWindows = hs.application.get("Google Chrome"):allWindows()
            local chromeLayout = {}
            for ii, vv in pairs(chromeWindows) do
              table.insert(chromeLayout,{"Google Chrome", vv, laptopScreen, nil, nil, Rect((#chromeWindows-ii)/#chromeWindows,0,1/#chromeWindows,1,true,((ii==1) and true or false))})
            end
            hs.layout.apply(chromeLayout)
          elseif (#{hs.window.find("Google Chrome")}==1) then
            chromeExpanded = false
            local size = tostring(hs.window.find("Google Chrome"):size())
            local sizeTable = Split(string.sub(size,18,#size-1),",")
            if (math.abs(screenHeight-tonumber(sizeTable[2])+2*padding)>0 or math.abs(screenWidth-tonumber(sizeTable[1])+2*padding)>0) then
              hs.layout.apply({{"Google Chrome", nil, laptopScreen, hs.layout.maximized, nil, nil}})
            end
          end
        end
      end
    end
    table.insert(state,{v:name(),#v:allWindows()})
  end
  for i, v in pairs(state) do
    lastState[i] = {v[1],v[2]}
  end
end)


-- --------
-- HotKeys:
-- --------

-- Reload
hs.hotkey.bind({"alt", "ctrl"}, "R", function()
  appWatcher:stop()
  mainLoop:stop()
  hs.reload()
end)

-- Open Finder
hs.hotkey.bind({"alt", "ctrl"}, "F", function()
  hs.application.get("Finder"):unhide()
  hs.application.get("Finder"):unhide()
  hs.application.get("Finder"):setFrontmost()
  hs.application.get("Finder"):activate()
end)

-- Popout Chrome Tab
hs.hotkey.bind({"alt", "ctrl"}, "C", function()
  if (getDesktop() == 3 or getDesktop() == 4) then
    hs.applescript('tell application "System Events" to tell process "Google Chrome" to click menu item "Move Tab to New Window" of menu 1 of menu bar item "Tab" of menu bar 1')
    chromeExpanded = true
    local chromeWindows = hs.application.get("Google Chrome"):allWindows()
    local chromeLayout = {}
    for ii, vv in pairs(chromeWindows) do
      table.insert(chromeLayout,{"Google Chrome", vv, laptopScreen, nil, nil, Rect((#chromeWindows-ii)/#chromeWindows,0,1/#chromeWindows,1,true,((ii==1) and true or false))})
    end
    hs.layout.apply(chromeLayout)
  end
end)

-- Return Chrome Tab
hs.hotkey.bind({"alt", "ctrl"}, "X", function()
  if (getDesktop() == 3 or getDesktop() == 4) then
    local urlSucceded, url = hs.applescript('tell application "Google Chrome" to tell active tab of window 1 to get URL')
    hs.applescript('tell application "Google Chrome" to tell active tab of window 1 to close')
    sleep(0.1)
    hs.applescript('tell application "Google Chrome" to tell window 1 to open location "' .. url .. '"')
    hs.layout.apply({{"Google Chrome", nil, laptopScreen, nil, nil, Rect(0,0,1,1)}})
  end
end)

-- Fullscreen Current Window
hs.hotkey.bind({"alt", "ctrl"}, "M", function()
  local curWindow = hs.window.focusedWindow()
  hs.layout.apply({{nil, curWindow, laptopScreen, nil, nil, Rect(0,0,1,1)}})
end)

-- Pretty Paste JSON
hs.hotkey.bind({"alt", "ctrl"}, "P", function()
  if not pcall(function ()
    JSON = require("JSON")
    local board = hs.pasteboard.getContents()
    local lua_value = JSON:decode(board)
    local pretty_json_text = JSON:encode_pretty(lua_value, nil, 
            { pretty = true, align_keys = false, array_newline = true, indent = "  " })

    hs.pasteboard.setContents(pretty_json_text)
    hs.eventtap.keyStroke({"cmd"}, "v")
    hs.pasteboard.setContents(board)
  end) then
    hs.alert("Not Proper JSON")
  end
end)

-- Tests
hs.hotkey.bind({"alt", "ctrl"}, "T", function()
  -- hs.alert.show(getDesktop())
  -- hs.applescript('tell application "System Events" to tell process "Code" to click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1')
end)

-- -----------------------------
-- Application Specific HotKeys:
-- -----------------------------

-- Open Chrome window
local newChrome = hs.hotkey.new({"cmd"}, "N", function()
  hs.applescript('tell application "Google Chrome" to make new window')
  hs.layout.apply({{"Google Chrome", nil, laptopScreen, nil, nil, Rect(0,0,1,1)}})
end)

-- Open Chrome Incog window
local newIncogChrome = hs.hotkey.new({"cmd","shift"}, "N", function()
  hs.applescript('tell application "System Events" to tell process "Google Chrome" to click menu item "New Incognito Window" of menu 1 of menu bar item "File" of menu bar 1')
  hs.layout.apply({{"Google Chrome", nil, laptopScreen, nil, nil, Rect(0,0,1,1)}})
end)

-- Open VSCode window
local newCode = hs.hotkey.new({"cmd","shift"}, "N", function()
  hs.applescript('tell application "System Events" to tell process "Code" to click menu item "New Window" of menu 1 of menu bar item "File" of menu bar 1')
  hs.layout.apply({{"Code", nil, laptopScreen, nil, nil, Rect(1/3,0,2/3,1)}})
end)

-- Open Terminal window
local newTerminal = hs.hotkey.new({"cmd"}, "N", function()
  hs.applescript('tell application "Terminal" to do script "" activate')
  reloadTerminalLayout()
  hs.layout.apply({{"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/#terminalWindows)}})
end)

-- Close Terminal window
local closeTerminal = hs.hotkey.new({"cmd"}, "W", function()
  hs.applescript('tell application "Terminal" to close (get window 1)')
  reloadTerminalLayout()
end)

-- Initialize a Chrome window filter
local chromeWF = hs.window.filter.new("Google Chrome")

-- Subscribe to when your Chrome window is focused and unfocused
chromeWF
  :subscribe(hs.window.filter.windowFocused, function()
      -- Enable hotkeys in Chrome
      newChrome:enable()
      newIncogChrome:enable()
  end)
  :subscribe(hs.window.filter.windowUnfocused, function()
      -- Disable hotkeys when focusing out of Chrome
      newChrome:disable()
      newIncogChrome:disable()
  end)

-- Initialize a Terminal window filter
local terminalWF = hs.window.filter.new("Terminal")

-- Subscribe to when your Terminal window is focused and unfocused
terminalWF
  :subscribe(hs.window.filter.windowFocused, function()
      -- Enable hotkeys in Terminal
      newTerminal:enable()
      closeTerminal:enable()
  end)
  :subscribe(hs.window.filter.windowUnfocused, function()
      -- Disable hotkeys when focusing out of Terminal
      newTerminal:disable()
      closeTerminal:disable()
  end)

-- Initialize a VS Code window filter
local vsCodeWF = hs.window.filter.new("Code")

-- Subscribe to when your VS Code window is focused and unfocused
vsCodeWF
  :subscribe(hs.window.filter.windowFocused, function()
      -- Enable hotkeys in VS Code
      newCode:enable()
  end)
  :subscribe(hs.window.filter.windowUnfocused, function()
      -- Disable hotkeys when focusing out of VS Code
      newCode:disable()
  end)

-- ---------------
-- On Config Reload:
-- ---------------
hs.alert.show("Config loaded")


-- -----------
-- Start Loop:
-- -----------

-- mainLoop:start()