--!nonstrict

local function render(output)
  local data = nil
  if type(output) == "table" then
    data = output
  else
    local raw = tostring(output or "")
    local ok, decoded = pcall(function()
      return noctalia.json.decode(raw)
    end)
    if ok and type(decoded) == "table" then
      data = decoded
    end
  end

  if not (data and type(data) == "table") then
    barWidget.render(ui.row({ gap = 4, align = "center" }, {
      ui.glyph({ name = "device-mobile", size = 16, color = "#6c7086" }),
      ui.box({ width = 6, height = 6, radius = 3, fill = "#f38ba8" }),
    }))
    barWidget.setTooltip("Overhead Phone: Offline (Click to connect)")
    return
  end

  local isConnected = data.connected == true
  local glyphName = "device-mobile"
  local glyphColor = "#a6e3a1" -- Green
  local activeDotColor = nil
  local activeBadgeText = nil
  local statusDesc = "Idle"

  local activeFeatures = {}
  if data.recording then table.insert(activeFeatures, "Recording") end
  if data.voice then table.insert(activeFeatures, "Voice Memo") end
  if data.webcam then table.insert(activeFeatures, "Webcam Live") end
  if data.camera then table.insert(activeFeatures, "Camera Viewfinder") end
  if data.phone_mic then table.insert(activeFeatures, "Phone Mic Active") end
  if data.torch then table.insert(activeFeatures, "Torch ON") end

  local activeDots = {}
  local activeBadgeText = nil

  if not isConnected then
    glyphColor = "#6c7086"
    statusDesc = "Disconnected"
    table.insert(activeDots, "#f38ba8") -- Red alert dot
  elseif #activeFeatures > 0 then
    statusDesc = table.concat(activeFeatures, " • ")
    if data.recording then
      glyphColor = "#f38ba8"
      activeBadgeText = "REC"
    elseif data.voice then
      glyphColor = "#f38ba8"
      activeBadgeText = "MIC"
    elseif data.webcam then
      glyphColor = "#89dceb"
    elseif data.camera then
      glyphColor = "#89b4fa"
    elseif data.torch then
      glyphColor = "#f9e2af"
    end

    -- Collect indicator dots for every active modality
    if data.webcam then table.insert(activeDots, "#89dceb") end   -- Cyan for Virtual Webcam
    if data.camera then table.insert(activeDots, "#89b4fa") end   -- Blue for Camera Viewfinder
    if data.phone_mic then table.insert(activeDots, "#fab387") end -- Peach for Phone Mic
    if data.torch then table.insert(activeDots, "#f9e2af") end    -- Yellow for Torch
  else
    statusDesc = "Idle"
  end

  local children = {
    ui.glyph({
      name = glyphName,
      size = 16,
      color = glyphColor,
    }),
  }

  if isConnected and data.battery and data.battery ~= "N/A" then
    table.insert(children, ui.label({
      text = tostring(data.battery),
      fontSize = 11,
      fontWeight = "bold",
      color = data.charging and "#a6e3a1" or "#cdd6f4",
    }))
  end

  if activeBadgeText then
    table.insert(children, ui.box({
      padding = 2,
      radius = 4,
      fill = "#3b1e28",
      border = "#f38ba8",
      borderWidth = 1,
    }, {
      ui.label({
        text = activeBadgeText,
        fontSize = 9,
        fontWeight = "bold",
        color = "#f38ba8",
      }),
    }))
  end

  if #activeDots > 0 then
    local dotItems = {}
    for _, dotColor in ipairs(activeDots) do
      table.insert(dotItems, ui.box({
        width = 6,
        height = 6,
        radius = 3,
        fill = dotColor,
      }))
    end
    table.insert(children, ui.row({ gap = 3, align = "center" }, dotItems))
  end

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 5, align = "center" }, children))

  local tooltipText = isConnected
    and ("Overhead Phone: " .. tostring(data.battery) .. " (" .. tostring(data.connection) .. ") • " .. statusDesc)
    or "Overhead Phone: Offline • Click to connect"
  barWidget.setTooltip(tooltipText)
end

function update()
  noctalia.runAsync("/home/aps/.local/bin/phone-rig status --json", function(result)
    render(result.stdout)
  end)
end

noctalia.state.watch("overhead_rig_state", function(value)
  if type(value) == "table" then
    render(value)
  end
end)

function onClick()
  noctalia.togglePanel("aps/overhead-rig:panel")
end

function onRightClick()
  update()
end

noctalia.setUpdateInterval(1500)
update()
