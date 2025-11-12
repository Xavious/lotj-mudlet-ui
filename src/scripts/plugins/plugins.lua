-- ============================================================================
-- Plugin Dock System - Shared namespace for LOTJ plugins
-- ============================================================================

-- Global plugin registry
lotj = lotj or {}
lotj.plugin = lotj.plugin or {}
lotj.plugin.dock = lotj.plugin.dock or {}

-- Initialize dock state
lotj.plugin.dock.container = lotj.plugin.dock.container or nil
lotj.plugin.dock.plugins = lotj.plugin.dock.plugins or {}

function lotj.plugin.log(text)
  cecho("[<cyan>LOTJ Plugin Dock<reset>] "..text.."\n")
end


-- Rebuild the dock container with all registered plugins
function lotj.plugin.dock.rebuild()
  -- Destroy existing container if it exists
  if lotj.plugin.dock.container then
    lotj.plugin.dock.container:hide()
    lotj.plugin.dock.container = nil
  end

  -- Count registered plugins
  local pluginCount = 0
  for _ in pairs(lotj.plugin.dock.plugins) do
    pluginCount = pluginCount + 1
  end

  -- If no plugins, nothing to do
  if pluginCount == 0 then
    return
  end

  -- Calculate container width (64px per plugin)
  local containerWidth = (pluginCount * 64)
  local containerOffset = (containerWidth + 15) .. "px"

  -- Create new HBox container at fixed position
  lotj.plugin.dock.container = Geyser.HBox:new({
    name = "lotj_plugin_dock_container",
    x = "-40%-"..containerOffset,
    y = 0,
    width = containerWidth,
    height = "64px"
  })

  -- Add all registered plugins to the container
  for pluginId, pluginData in pairs(lotj.plugin.dock.plugins) do
    -- Create launcher label with HBox as parent
    local launcher = Geyser.Label:new({
      name = pluginId .. "_launcher",
      width = "64px",
      height = "64px"
    }, lotj.plugin.dock.container)

    -- Set background image
    launcher:setStyleSheet([[
      background-image: url(']] .. pluginData.icon .. [[');
      background-repeat: no-repeat;
      background-position: center;
      background-color: transparent;
      border: none;
    ]])

    -- Set click callback
    if pluginData.onClick then
      launcher:setClickCallback(pluginData.onClick)
    end

    -- Set hover callbacks if provided
    if pluginData.hoverIcon then
      launcher:setOnEnter(function()
        launcher:setMovie(pluginData.hoverIcon)
      end)

      launcher:setOnLeave(function()
        launcher:setBackgroundImage(pluginData.icon)
      end)
    end

    launcher:show()

    -- Store reference to launcher in plugin data
    pluginData.launcher = launcher
  end

  lotj.plugin.dock.container:show()
end

-- Register a plugin with the dock
function lotj.plugin.dock.register(pluginId, pluginData)
  lotj.plugin.log("Registering: "..pluginId)
  if not pluginId or not pluginData then
    cecho("\n<red>[Plugin Dock] Error: pluginId and pluginData required for registration<reset>\n")
    return false
  end

  if not pluginData.icon then
    cecho("\n<red>[Plugin Dock] Error: Plugin must provide an icon path<reset>\n")
    return false
  end

  -- Store plugin data
  lotj.plugin.dock.plugins[pluginId] = pluginData

  -- Rebuild the dock
  lotj.plugin.dock.rebuild()

  -- ============================================================================
  -- Uninstall Handler
  -- ============================================================================

  -- Register event handler to clean up when package is uninstalled
  registerAnonymousEventHandler("sysUninstallPackage", function(_, packageName)
    if packageName == pluginId then
        lotj.plugin.dock.unregister(pluginId)
    end
  end)


  return true
end

-- Unregister a plugin from the dock
function lotj.plugin.dock.unregister(pluginId)
  if not lotj.plugin.dock.plugins[pluginId] then
    return false
  end

  -- Remove plugin
  lotj.plugin.log("Removing: "..pluginId)
  lotj.plugin.dock.plugins[pluginId] = nil

  -- Rebuild the dock
  lotj.plugin.dock.rebuild()

  return true
end