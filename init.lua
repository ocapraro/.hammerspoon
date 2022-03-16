local padding = 12
local ok,result = hs.applescript('tell Application "Finder" to get bounds of window of desktop')
local screenHeight =  result[4]-25-2*padding
local screenWidth =  result[3]-2*padding

function Rect(x,y,w,h,b,l)
  b=b or false
  l=l or false
  return hs.geometry.rect(screenWidth*x+padding+(l and padding or 0), screenHeight*y+padding+25, screenWidth*w-(l and padding or 0), screenHeight*h-((not b) and padding or 0))
end

local function getDesktop()
  local discriminators = {"Messages","Code"}
  for i, v in ipairs(discriminators) do
    if (#hs.application.get(v):allWindows()>0) then
      return i
    end
  end
end

local clock = os.clock
local function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end


-- --------
-- Layouts:
-- --------

local laptopScreen = "C34H89x"
if (screenWidth>=3000) then
  WindowLayout = {
    {"Code", nil, laptopScreen, nil, nil, Rect(1/3,0,2/3,1, true, true)},
    {"Messages", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/2)},
    {"Discord", nil, laptopScreen, nil, nil, Rect(0,1/2,2/3,1/2, true)},
    {"Skype", nil, laptopScreen, nil, nil, Rect(1/3,0,1/3,1/2, false, true)},
  }

  SecondaryAppCodeLayout = {
    {"Terminal", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/2)},
    {"Trello", nil, laptopScreen, nil, nil, Rect(0,1/2,1/3,1/2, true)},
    {"MongoDB Compass", nil, laptopScreen, nil, nil, Rect(0,1/2,1/3,1/2, true)},
  }
else
  WindowLayout = {
    {"Code", nil, laptopScreen, nil, nil, Rect(1/3,0,2/3,1, true, true)},
    {"Messages", nil, laptopScreen, nil, nil, Rect(0,0,2/3,1/2)},
    {"Discord", nil, laptopScreen, nil, nil, Rect(0,1/2,2/3,1/2, true)},
    {"Skype", nil, laptopScreen, nil, nil, Rect(2/3,0,1/3,1, true, true)},
  }

  SecondaryAppCodeLayout = {
    {"Terminal", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/3)},
    {"Trello", nil, laptopScreen, nil, nil, Rect(0,1/3,1/3,2/3)},
    {"MongoDB Compass", nil, laptopScreen, nil, nil, Rect(0,1/3,1/3,2/3)},
  }
end


-- Add terminal windows to WindowLayout
local terminalWindows = hs.application.get("Terminal"):allWindows()
for i, v in pairs(terminalWindows) do
	table.insert(WindowLayout,{"Terminal", v, laptopScreen, nil, nil, Rect(0,(i-1)/#terminalWindows,1/3,1/#terminalWindows,((i==#terminalWindows) and true or false))})
end

hs.layout.apply(WindowLayout)


-- -----------
-- App Events:
-- -----------
local secondaryApps = 0

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
      end
    end
  elseif (eventType == hs.application.watcher.activated) then
    if (appName == "Finder") then
      if (getDesktop()==2) then
        -- Reload Layout
        hs.layout.apply({{"Finder", nil, laptopScreen, nil, nil, Rect(0,0,1/3,1/2)}})
      end
    elseif (appName == "Terminal") then
      -- Bring all Terminal windows forward when one gets activated
      hs.application.get("Terminal"):selectMenuItem({"Window", "Bring All to Front"})
    end
  end
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
-- Music Mode


-- --------
-- HotKeys:
-- --------

-- Reload
hs.hotkey.bind({"alt", "ctrl"}, "R", function()
  appWatcher:stop()
  hs.reload()
end)

-- Open Finder
hs.hotkey.bind({"alt", "ctrl"}, "F", function()
  hs.application.get("Finder"):setFrontmost()
end)

-- Tests
hs.hotkey.bind({"alt", "ctrl"}, "T", function()
  -- hs.alert.show(hs.window.focusedWindow())
  hs.alert.show(getDesktop())
end)

-- ---------------
-- On Config Reload:
-- ---------------
hs.alert.show("Config loaded")