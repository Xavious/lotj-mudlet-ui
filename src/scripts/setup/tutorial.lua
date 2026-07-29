lotj = lotj or {}
lotj.tutorial = lotj.tutorial or {}
lotj.tutorial.data = lotj.tutorial.data or {}
local path = getMudletHomeDir() .. "/lotj-ui-tutorial.lua"

local style = [[
  QLabel {
    background-color: #0a1a2e;
    border: 1px solid #00aaff;
    border-top-right-radius: 4px;
    border-top-left-radius: 4px;
    margin: 3px 3px 3px 3px;
    font-family: ]] .. getFont() .. [[;
  }
]]

--- Return values:
--- `1` : `v1` is newer
--- `-1`: `v2` is newer
--- `0` :  Versions are equal
function lotj.tutorial.compareVersions(v1, v2)
  -- Remove 'v' prefix if present
  v1 = v1:gsub("^v", "")
  v2 = v2:gsub("^v", "")

  -- Split versions into parts
  local v1_parts = {}
  local v2_parts = {}

  for num in v1:gmatch("%d+") do
    table.insert(v1_parts, tonumber(num))
  end

  for num in v2:gmatch("%d+") do
    table.insert(v2_parts, tonumber(num))
  end

  -- Compare each part
  for i = 1, math.max(#v1_parts, #v2_parts) do
    local v1_part = v1_parts[i] or 0
    local v2_part = v2_parts[i] or 0

    if v1_part < v2_part then
      return -1  -- v2 is newer
    elseif v1_part > v2_part then
      return 1   -- v1 is newer
    end
  end

  return 0  -- versions are equal
end

--- This function contains all the code that will run when a user installs this
--- version of the package for the first time. There is no guarantee that the
--- user viewed the tutorial for the previous version, so only remove tutorial
--- features if absolutely necessary, prefer to add on.
function lotj.tutorial.run()
  local tutorialElements = {}
  lotj.tutorial.activeElements = tutorialElements
  local flashTimerKillID = nil
  local btnCount = 0
  local labelCount = 0
  local fakeShipDataActive = false

  local function hideTutorialElements()
    for _, g in ipairs(tutorialElements) do
      g:hide()
    end
    if tutorialElements.upperCon then tutorialElements.upperCon:hide() end
    if tutorialElements.lowerCon then tutorialElements.lowerCon:hide() end
    if tutorialElements.farewell then tutorialElements.farewell:hide() end
  end

  local function recursiveFlash(label)
    label:flash()
    flashTimerKillID = tempTimer(2, function()
      label:flash()
      recursiveFlash(label)
    end)
  end

  local function clearFakeShipData()
    if fakeShipDataActive then
      gmcp.Ship = gmcp.Ship or {}
      gmcp.Ship.Info = {}
      raiseEvent("gmcp.Ship.Info")
      fakeShipDataActive = false
    end
  end

  local function sendRerunHint()
    cecho("[<cyan>LOTJ UI<reset>] Tutorial Complete. Rerun at any time with command: ")
    cechoLink("<cyan><u>lotj tutorial<reset>", [[lotj.tutorial.run()]], "Click to rerun the tutorial", true)
    cecho("\n")
  end

  local function endTutorial()
    clearFakeShipData()
    hideTutorialElements()
    lotj.tutorial.data.ran = true
    table.save(path, lotj.tutorial.data)
    sendRerunHint()
  end

  local greenBtnStyle = [[QLabel { background-color: #004400; border: 1px solid #00aa00; border-radius: 3px; }]]
  local redBtnStyle   = [[QLabel { background-color: #440000; border: 1px solid #aa0000; border-radius: 3px; }]]

  -- Adds a green Continue button and red End Tutorial button to `container`.
  -- `cleanupFn` is called before either button acts (use it to kill flash timers, etc.).
  -- Buttons are tracked in tutorialElements so hideTutorialElements() hides them.
  local function addButtons(container, nextFn, cleanupFn, nextLabel, endLabel)
    btnCount = btnCount + 1
    local base = "tutorial_btn_" .. btnCount
    nextLabel = nextLabel or "Continue"
    endLabel  = endLabel  or "End Tutorial"

    local function doNext()
      if cleanupFn then cleanupFn() end
      nextFn()
    end
    local function doEnd()
      if cleanupFn then cleanupFn() end
      endTutorial()
    end

    local cBtn = Geyser.Label:new({
      name = base .. "_c",
      x = "5%", y = "85%", width = "40%", height = "10%",
      fontSize = 14,
      message = "<center>" .. nextLabel .. "</center>",
    }, container)
    cBtn:setStyleSheet(greenBtnStyle)
    cBtn:setCursor("PointingHand")
    cBtn:setClickCallback(doNext)
    cBtn:raiseAll()
    table.insert(tutorialElements, cBtn)

    local eBtn = Geyser.Label:new({
      name = base .. "_e",
      x = "55%", y = "85%", width = "40%", height = "10%",
      fontSize = 14,
      message = "<center>" .. endLabel .. "</center>",
    }, container)
    eBtn:setStyleSheet(redBtnStyle)
    eBtn:setCursor("PointingHand")
    eBtn:setClickCallback(doEnd)
    eBtn:raiseAll()
    table.insert(tutorialElements, eBtn)
  end

  -- Flash multiple labels in sync under a single killable timer ID
  local function recursiveFlashMulti(labels)
    for _, lbl in ipairs(labels) do lbl:flash() end
    flashTimerKillID = tempTimer(2, function() recursiveFlashMulti(labels) end)
  end

  local function killFlash()
    if flashTimerKillID then killTimer(flashTimerKillID) end
  end

  -- Transparent highlight overlay covering 100% of a Geyser element
  local function createHighlightOverlay(parent)
    labelCount = labelCount + 1
    local ov = Geyser.Label:new({
      name = "tutorial_ov_" .. labelCount,
      x = "0%", y = "0%", width = "100%", height = "100%",
    }, parent)
    ov:setStyleSheet([[QLabel { background-color: rgba(0,170,255,20); border: 2px solid #00aaff; border-radius: 3px; }]])
    ov:raiseAll()
    table.insert(tutorialElements, ov)
    return ov
  end

  -- Floating info label centered over the main console
  local function createInfoLabel(message)
    labelCount = labelCount + 1
    local lbl = Geyser.Label:new({
      name = "tutorial_info_" .. labelCount,
      x = "25%", y = "20%", width = "50%", height = "45%",
      fontSize = 14,
      message = "<center>" .. message .. "</center>",
    })
    lbl:setStyleSheet(style)
    table.insert(tutorialElements, lbl)
    return lbl
  end

  local step2 -- forward declaration so step13 can reference it

  -- Tutorial exit
  local function step14()
    local discord_link = gmcp.External.Discord.Info.inviteurl or "https://discord.gg/f7tajUT"
    hideTutorialElements()
    tutorialElements.farewell = Geyser.Label:new({
      name="tutorial_farwell",
      x="25%",y="25%",width="50%",height="50%",
      fontSize = 14,
      message=[[<center>
      <p>You made it to the end of the tutorial.</p>
      <h1>Welcome to Legends of the Jedi!</h1>
      <p>We're a very welcoming community. If you get lost or have questions,<br>
      don't hesitate to reach out for help on the OOC channel or Discord.</p>
      <p>Join our <a href="]]..discord_link..[[" style="color: #00aaff; text-decoration: underline;">Discord</a></p>
      <p> Visit our official <a href="https://legendsofthejedi.com" style="color: #00aaff; text-decoration: underline;">website.</p>
      </center>]]
    })
    tutorialElements.farewell:setStyleSheet(style)
    tutorialElements.farewell:raiseAll()
    -- Set ran flag now so closing the window also counts as done
    lotj.tutorial.data.ran = true
    table.save(path, lotj.tutorial.data)
    local finishBtn = Geyser.Label:new({
      name = "tutorial_btn_finish",
      x = "30%", y = "85%", width = "40%", height = "10%",
      fontSize = 14,
      message = "<center>Finish</center>",
    }, tutorialElements.farewell)
    finishBtn:setStyleSheet(greenBtnStyle)
    finishBtn:setCursor("PointingHand")
    finishBtn:setClickCallback(function()
      hideTutorialElements()
      lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
      lotj.layout.selectTab(lotj.layout.lowerRightTabData, "all")
      sendRerunHint()
    end)
    finishBtn:raiseAll()
    table.insert(tutorialElements, finishBtn)
  end

  -- Galaxy map: right-click context menu on planet dots
  local function step13RightClick()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
    local con = tutorialElements.lowerCon
    con:clear()
    con:echo([[<center>
    <h1>Galaxy Map - Planet Context Menu</h1>
    <p>Right-clicking any planet or point on the map<br>
    will pop up with an interactive menu.</p>
    <p>You can calculate a jump, lookup planetary info, or<br>
    delete manually added locations.
    </center>]])
    con:show()
    con:raiseAll()
    addButtons(lotj.layout.lowerContainer, step2)
  end

  -- Galaxy map: + button for adding custom locations
  local function step13AddBtn()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
    local ov = createHighlightOverlay(lotj.galaxyMap.addButton)
    recursiveFlash(ov)
    local con = tutorialElements.lowerCon
    con:clear()
    con:echo([[<center>
    <h1>Galaxy Map - Custom Locations</h1>
    <p>Use the flashing (+) button at the top right to manually<br>
    add locations to the map.</p>
    <p>Useful for marking points of interest,<br>
    or hidden planets and spacestations</p>
    <p>Note: The button is disabled for this step of the tutorial</p>
    </center>]])
    con:show()
    con:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lotj.layout.lowerContainer, step13RightClick, cleanup)
  end

  -- Introduce the upper panel: `Galaxy`
  local function step13()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.upperRightTabData, "galaxy")
    local con = tutorialElements.lowerCon
    con:setStyleSheet(style)
    con:clear()
    con:echo([[<center>
    <h1>Galaxy Map</h1>
    <p>This map will show all the publicly known planets.<br>
    A datapad is required to initialize and update.</p>
    <p>Use <a href="send:gmap" style="color: #00aaff; text-decoration: underline;">gmap</a> for a list of commands.</p>
    </center>]])
    con:show()
    con:raiseAll()
    addButtons(lotj.layout.lowerContainer, step13AddBtn)
  end

  -- Introduce the upper panel: `System`
  local function step12()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.upperRightTabData, "system")
    local con = tutorialElements.lowerCon
    con:setStyleSheet(style)
    con:clear()
    con:echo([[<center>
    <h1>System</h1>
    <p>The system tab shows a visual radar of nearby<br>
    objects when in space</p>
    <p>Use the plus and minus buttons to change the<br>
    radar's zoom, and click the radar button to<br>
    refresh the radar's data</p>
    </center>]])
    con:show()
    con:raiseAll()
    addButtons(lotj.layout.lowerContainer, step13)
  end

  -- Introduce the upper panel: `Map`
  local function step11()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.upperRightTabData, "map")
    tutorialElements.lowerCon = Geyser.Label:new({
      name="tutorial_lowerCon",
      x="0%",y="0%",width="100%",height="100%",
      fontSize = 14,
      message = [[<center>
      <h1>Map</h1>
      <p>The mapper tracks your position as you move<br>
      through the galaxy and records new rooms.</p>
      <p>You start with the Newbie Academy pre-mapped.<br>
      The rest of the galaxy you must map on your own.</p>
      <p>Use <a href="send:map help" style="color: #00aaff; text-decoration: underline;">map help</a> for commands and tips.</p>
      </center>]]
    }, lotj.layout.lowerContainer)
    local con = tutorialElements.lowerCon
    con:setStyleSheet(style)
    con:show()
    con:raiseAll()
    addButtons(lotj.layout.lowerContainer, step12)
  end

  -- ── Info panel steps (inserted between settings walkthrough and map tabs) ──

  -- Ship HUD: speed and coordinates
  local function stepShipCoords()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Speed &amp; Coordinates</h1>
      <p>The arrow icon indicates your speed and the XYZ<br>
      icon shows your coordinates in the system</p>
    ]])
    lbl:raiseAll()
    local function cleanup()
      killFlash()
      clearFakeShipData()
    end
    addButtons(lbl, step11, cleanup)
  end

  -- Ship HUD: pilot status active
  local function stepShipPilotActive()
    hideTutorialElements()
    gmcp.Ship = gmcp.Ship or {}
    gmcp.Ship.Info = gmcp.Ship.Info or {}
    gmcp.Ship.Info.piloting = true
    raiseEvent("gmcp.Ship.Info")
    local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Pilot Status (Active)</h1>
      <p>When you are at the controls the ship icon<br>
      lights up green to show you are piloting</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipCoords, cleanup)
  end

  -- Ship HUD: pilot status inactive
  local function stepShipPilotInactive()
    hideTutorialElements()
    gmcp.Ship = gmcp.Ship or {}
    gmcp.Ship.Info = gmcp.Ship.Info or {}
    gmcp.Ship.Info.piloting = nil
    raiseEvent("gmcp.Ship.Info")
    local ov = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Pilot Status</h1>
      <p>The ship icon shows whether you are<br>
      piloting the ship or just a passenger</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipPilotActive, cleanup)
  end

  -- Ship energy gauge
  local function stepShipEnergy()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.shipEnergyGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Energy</h1>
      <p>The yellow gauge shows your ship's<br>
      energy reserves — weapons, shields,<br>
      and engines all draw from this pool</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipPilotInactive, cleanup)
  end

  -- Ship hull gauge
  local function stepShipHull()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.shipHullGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Hull</h1>
      <p>The gray gauge shows your ship's<br>
      structural integrity — if it reaches<br>
      zero the ship is destroyed</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipEnergy, cleanup)
  end

  -- Ship shield gauge
  local function stepShipShield()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.shipShieldGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Shields</h1>
      <p>The teal gauge shows your ship's<br>
      shield strength — shields absorb damage<br>
      before the hull takes hits</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipHull, cleanup)
  end

  -- Ship bar intro: inject fake GMCP ship data to reveal the overlay
  local function stepShipIntro()
    hideTutorialElements()
    gmcp.Ship = gmcp.Ship or {}
    gmcp.Ship.Info = {
      shield = 80, maxShield = 100,
      hull   = 95, maxHull   = 100,
      energy = 60, maxEnergy = 100,
      piloting = true,
      speed = 75, maxSpeed = 100,
      posX = 100, posY = 200, posZ = 50,
    }
    raiseEvent("gmcp.Ship.Info")
    fakeShipDataActive = true
    local ov1 = createHighlightOverlay(lotj.infoPanel.shipGaugesContainer)
    local ov2 = createHighlightOverlay(lotj.infoPanel.shipHudContainer)
    recursiveFlashMulti({ov1, ov2})
    local lbl = createInfoLabel([[
      <h1>Ship Status Bar</h1>
      <p>When you board a ship, a second status<br>
      bar appears with info about your ship</p>
    ]])
    lbl:raiseAll()
    addButtons(lbl, stepShipShield, function() killFlash() end)
  end

  -- Comlink info area
  local function stepInfoComlink()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.chatContainer)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Commlink</h1>
      <p>This area shows your active commlink<br>
      channel and encryption code when<br>
      you have a commlink set</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepShipIntro, cleanup)
  end

  -- Combat target gauge
  local function stepInfoCombat()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.combatContainer)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Combat Target</h1>
      <p>The orange gauge shows the health<br>
      percentage of your current combat target</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepInfoComlink, cleanup)
  end

  -- Mana / Force gauge
  local function stepInfoMana()
    hideTutorialElements()
    local savedMana    = gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.mana
    local savedMaxMana = gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.maxMana
    local fakingMana = not savedMaxMana or savedMaxMana == 0
    if fakingMana then
      gmcp.Char = gmcp.Char or {}
      gmcp.Char.Vitals = gmcp.Char.Vitals or {}
      gmcp.Char.Vitals.maxMana = 100
      gmcp.Char.Vitals.mana = 75
      raiseEvent("gmcp.Char.Vitals")
    end
    local ov = createHighlightOverlay(lotj.infoPanel.manaGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Force</h1>
      <p>The blue gauge shows your Force<br>
      points (if your class uses them)<br>
      It stays hidden when not applicable</p>
    ]])
    lbl:raiseAll()
    local function cleanup()
      killFlash()
      if fakingMana then
        gmcp.Char.Vitals.maxMana = savedMaxMana or 0
        gmcp.Char.Vitals.mana = savedMana or 0
        raiseEvent("gmcp.Char.Vitals")
      end
    end
    addButtons(lbl, stepInfoCombat, cleanup)
  end

  -- Movement gauge
  local function stepInfoMove()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.movementGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Movement</h1>
      <p>The green gauge shows your current<br>
      movement points. Used when traveling<br>
      between rooms or using skills</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepInfoMana, cleanup)
  end

  -- HP gauge
  local function stepInfoHP()
    hideTutorialElements()
    local ov = createHighlightOverlay(lotj.infoPanel.healthGauge)
    recursiveFlash(ov)
    local lbl = createInfoLabel([[
      <h1>Hit Points</h1>
      <p>The red gauge shows your current HP<br>
      Keep a close eye on this during combat!<br></p>
      <p>The yellow line marks your <a href="send:help wimpy" style="color: #00aaff; text-decoration: underline;">wimpy</a> threshold (if set).</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepInfoMove, cleanup)
  end

  -- Entire status bar intro
  local function stepInfoBar()
    hideTutorialElements()
    local ov1 = createHighlightOverlay(lotj.infoPanel.basicStatsContainer)
    local ov2 = createHighlightOverlay(lotj.infoPanel.combatContainer)
    local ov3 = createHighlightOverlay(lotj.infoPanel.chatContainer)
    recursiveFlashMulti({ov1, ov2, ov3})
    local lbl = createInfoLabel([[
      <h1>Status Bar</h1>
      <p>The bar at the bottom of your screen<br>
      shows your character's vitals</p>
    ]])
    lbl:raiseAll()
    local function cleanup() killFlash() end
    addButtons(lbl, stepInfoHP, cleanup)
  end

  -- Break down the bottom buttons
  local function step10()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Buttons</h1>
    <p>Buttons on the bottom will save, load, <br>or reset settings to default.</p>
    <p>Changes will impact the current session, but must be saved<br>
    if you want them to persist after closing and re-opening.</p>
    <p>Use load to revert back to your last saved state.</p>
    <p>Reload the profile if an unexpected UI bug occurs</p>
    </center>]])
    con:show()
    con:raiseAll()
    recursiveFlashMulti({
      lotj.configWindow.buttons[1],
      lotj.configWindow.buttons[2],
      lotj.configWindow.buttons[3],
      lotj.configWindow.buttons[4],
    })
    addButtons(lotj.layout.upperContainer, step14, function() killFlash() end)
  end

  -- Break down the categories: `Debug Options`
  local function step9()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Debug</h1>
    <p>Advanced settings for developers who<br>
    like to play with GMCP.</p>
    <p>Must click the <b>Reload Profile</b> button for<br>
    the debug tab to show after enabling.</p>
    <p>The input field can be used to run Lua code<br>
    right from the debug tab.</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Debug_Options_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step10, resetCategory)
  end

  -- Break down the categories: `Advanced Options`
  local function step8()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Logging</h1>
    <p>Toggles logging. Logs start and end<br>
    on connect/disconnect events</p>
    <p>Timer option will automatically stop<br>
    and start a new log daily</p>
    <p>Log files save in the default log directory<br>
    in a folder labeled with the character's name.</p>
    <p>Can use TXT or HTML. Use HTML to save in color.</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Logging_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step9, resetCategory)
  end

  -- Break down the categories: `GUI Preferences`
  local function step7()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - GUI Preferences</h1>
    <p>Click to toggle which tabs you want in focus on startup.</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_GUI_Preferences_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step8, resetCategory)
  end

  -- Break down the categories: `Extras`
  local function step6()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Extras</h1>
    <p>Miscellaneous or uncategorized settings.<p> 
    <p>Used to enable study triggers and clickable change logs</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Extras_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step7, resetCategory)
  end

  -- Break down the categories: `Notification Settings`
  local function step5()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Notification Settings</h1>
    <p>Enabling any of these will make their respective<br>
    tabs flash when they resceive a new message</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Notification_Settings_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step6, resetCategory)
  end

  -- Break down the categories: `Keybinds`
  local function step4()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Keybinds</h1>
    <p>These settings enable various directonal actions with the numpad.<br></p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Keybinds_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step5, resetCategory)
  end

  -- Break down the categories: `Gag Options`
  local function step3()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    local con = tutorialElements.upperCon
    con:clear()
    con:echo([[<center>
    <h1>Settings - Gag Options</h1>
    <p>These options enable gagging various channels from the main<br>
    window and only show them in the chat tabs.</p>
    </center>]])
    con:show()
    con:raiseAll()
    local category = lotj.configWindow.scrollArea.windowList.configContent_lotj.windowList.category_Gag_Options_lotj
    local function resetCategory()
      killTimer(flashTimerKillID)
      category:setClickCallback(function() end)
      category:setCursor("Reset")
    end
    category:setClickCallback(resetCategory)
    category:setCursor("PointingHand")
    recursiveFlash(category)
    addButtons(lotj.layout.upperContainer, step4, resetCategory)
  end

  -- Introduce the user to the settings tab
  step2 = function()
    hideTutorialElements()
    lotj.layout.selectTab(lotj.layout.lowerRightTabData, "settings")
    tutorialElements.upperCon = Geyser.Label:new({
      name="tutorial_upperCon",
      x="0%",y="0%",width="100%",height="100%",
      fontSize = 14,
      message = [[<center>
      <h1>Settings</h1>
      <p>Below is the Settings tab</p>
      <p>Here you'll find all the settings the LotJ-UI can modify</p>
      </center>]]
    }, lotj.layout.upperContainer)
    local con = tutorialElements.upperCon
    con:setStyleSheet(style)
    con:raiseAll()
    tempTimer(1  , function() lotj.chat["settings"]:flash(0.2) end)
    tempTimer(1.5, function() lotj.chat["settings"]:flash(0.2) end)
    tempTimer(2  , function() lotj.chat["settings"]:flash(0.2) end)
    addButtons(lotj.layout.upperContainer, step3)
  end

  -- Welcome user to version `2.5.1`
  local function step1()
    local welcome_label = Geyser.Label:new({
      name="tutorial_welcome_label",
      x="25%",y="25%",width="50%",height="50%",
      fontSize = 14,
      message = [[<center>
      <p>Welcome to LOTJ Mudlet UI @VERSION@!</p>
      <p>Use the buttons below to start the feature tutorial<br>
      or dismiss it permanently</p>
      </center>]]
    })
    table.insert(tutorialElements, welcome_label)
    welcome_label:setStyleSheet(style)
    welcome_label:raiseAll()
    addButtons(welcome_label, stepInfoBar, nil, "Start Tutorial")
  end

  -- Run
  step1()
end

function lotj.tutorial.setup()
  lotj.tutorial.data = {}
  local version = getPackageInfo("@PKGNAME@").version

  if io.exists(path) then
    table.load(path, lotj.tutorial.data)
  else
    lotj.tutorial.data = {
      newest = version,
      ran = false
    }
    table.save(path, lotj.tutorial.data)
  end

  local out = lotj.tutorial.compareVersions(version, lotj.tutorial.data.newest or "0")
  -- We have the same version
  if out == 0 then
    -- Tutorial has already run
    if lotj.tutorial.data.ran then
      return
    -- Tutorial has not run
    else
      lotj.setup.registerEventHandler("lotjUiLoaded", lotj.tutorial.run)
    end
  -- The stored version is newer - probably shouldn't happen
  elseif out == -1 then
    return
  -- We have installed a new version
  elseif out == 1 then
    -- No need to check if the tutorial has already run
    lotj.tutorial.data.ran = false
    lotj.tutorial.data.newest = version
    lotj.setup.registerEventHandler("lotjUiLoaded", lotj.tutorial.run)
  end
end
