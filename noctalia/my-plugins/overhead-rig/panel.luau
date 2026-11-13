--!nonstrict

local state = {
  connected = false,
  connection = "None",
  battery = "N/A",
  battery_status = "Unknown",
  charging = false,
  camera = false,
  recording = false,
  voice = false,
  torch = false,
  phone_mic = false,
  dictation_source = "headphones",
  webcam = false,
  last_error = "",
}

local copyFeedback = false

local function compactCard(props)
  local isRunning = props.active or false
  local cardFill = isRunning and (props.activeFill or "#313244") or "#1e1e2e"
  local cardBorder = isRunning and (props.activeBorder or props.iconColor) or "#313244"

  return ui.row({
    fill = cardFill,
    border = cardBorder,
    borderWidth = 1,
    radius = 8,
    padding = 7,
    gap = 8,
    align = "center",
    flexGrow = 1,
    onClick = props.onClick,
  }, {
    ui.glyph({
      name = props.glyph,
      size = 17,
      color = props.iconColor,
    }),
    ui.column({ gap = 1, flexGrow = 1 }, {
      ui.label({
        text = props.title,
        fontSize = 11,
        fontWeight = "bold",
        color = isRunning and "#ffffff" or "#cdd6f4",
      }),
      ui.label({
        text = props.subtitle,
        fontSize = 9,
        color = isRunning and props.iconColor or "#a6adc8",
      }),
    }),
  })
end

local function renderUI()
  local battColor = state.charging and "#a6e3a1" or "#cdd6f4"
  local statusBadge = "Idle"
  local statusColor = "#a6adc8"
  local statusIcon = "check"

  if state.recording then
    statusBadge = "Recording"
    statusColor = "#f38ba8"
    statusIcon = "circle-dot"
  elseif state.voice then
    statusBadge = "Voice Memo"
    statusColor = "#f38ba8"
    statusIcon = "microphone"
  elseif state.webcam then
    statusBadge = "Webcam Live"
    statusColor = "#89dceb"
    statusIcon = "camera"
  elseif state.camera then
    statusBadge = "Camera Active"
    statusColor = "#89b4fa"
    statusIcon = "video"
  elseif state.phone_mic then
    statusBadge = "Phone Mic"
    statusColor = "#fab387"
    statusIcon = "microphone"
  elseif not state.connected then
    statusBadge = "Disconnected"
    statusColor = "#f38ba8"
    statusIcon = "alert-triangle"
  end

  local children = {}

  -- 1. Header Card (Device, Connection status, Battery, Refresh)
  table.insert(children, ui.column({
    padding = 8,
    gap = 5,
    radius = 8,
    fill = "#1e1e2e",
    border = "#313244",
    borderWidth = 1,
  }, {
    ui.row({ align = "center", justify = "space_between" }, {
      ui.row({ align = "center", gap = 7 }, {
        ui.glyph({
          name = "device-mobile",
          size = 18,
          color = state.connected and "#a6e3a1" or "#f38ba8",
        }),
        ui.column({ gap = 1 }, {
          ui.label({ text = "Overhead Desk Phone", fontSize = 13, fontWeight = "bold", color = "#cdd6f4" }),
          ui.label({
            text = state.connected and ("Connected via " .. state.connection) or "Offline / Not Detected",
            fontSize = 10,
            color = state.connected and "#a6e3a1" or "#f38ba8",
          }),
        }),
      }),
      ui.button({
        glyph = "refresh",
        variant = "ghost",
        controlSize = "sm",
        onClick = function() refreshStatus() end,
      }),
    }),

    ui.separator({ thickness = 1, color = "#313244" }),

    -- Battery & Status Row
    ui.row({ align = "center", justify = "space_between" }, {
      ui.row({ align = "center", gap = 5 }, {
        ui.glyph({
          name = state.charging and "battery-charging" or "battery",
          size = 14,
          color = battColor,
        }),
        ui.label({
          text = state.battery .. " (" .. state.battery_status .. ")",
          fontSize = 10.5,
          fontWeight = "medium",
          color = battColor,
        }),
      }),
      ui.row({ align = "center", gap = 5 }, {
        ui.glyph({ name = statusIcon, size = 12, color = statusColor }),
        ui.label({ text = statusBadge, fontSize = 10, fontWeight = "medium", color = statusColor }),
      }),
    }),
  }))

  -- 2. Disconnected Alert & Quick Connect Button (when not connected)
  if not state.connected then
    table.insert(children, ui.row({
      padding = 8,
      gap = 8,
      radius = 8,
      fill = "#2a1e24",
      border = "#f38ba8",
      borderWidth = 1,
      align = "center",
      justify = "space_between",
    }, {
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = "Phone Not Connected", fontSize = 11, fontWeight = "bold", color = "#f38ba8" }),
        ui.label({ text = "Check USB cable or Wi-Fi (192.168.1.8)", fontSize = 9.5, color = "#a6adc8" }),
      }),
      ui.button({
        text = "⚡ Connect",
        variant = "primary",
        controlSize = "sm",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig connect", function()
            refreshStatus()
          end)
        end,
      }),
    }))
  end

  -- 3. Two-Column Quick Action Grid (5 Rows x 2 Columns)
  table.insert(children, ui.column({ gap = 6 }, {
    -- Row 1: Dictation Mic Switch & Camera Viewfinder
    ui.row({ gap = 6, align = "center" }, {
      compactCard({
        glyph = "microphone",
        iconColor = state.phone_mic and "#fab387" or "#a6adc8",
        title = state.phone_mic and "Phone Mic ON" or "Headphones Mic",
        subtitle = state.phone_mic and "No music pauses" or "Standard input",
        active = state.phone_mic,
        activeFill = "#38231a",
        activeBorder = "#fab387",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig mic", function()
            refreshStatus()
          end)
        end,
      }),
      compactCard({
        glyph = "video",
        iconColor = "#89b4fa",
        title = state.camera and "Close Camera" or "Desk Camera",
        subtitle = state.camera and "Viewfinder active" or "1080p normal tile",
        active = state.camera,
        activeFill = "#1e293b",
        activeBorder = "#89b4fa",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig cam", function()
            refreshStatus()
          end)
        end,
      }),
    }),

    -- Row 2: Record Desk Video & Voice Memo (Phone Mic)
    ui.row({ gap = 6, align = "center" }, {
      compactCard({
        glyph = "circle-dot",
        iconColor = "#f38ba8",
        title = state.recording and "🔴 Stop Rec" or "Record Video",
        subtitle = state.recording and "Saving MP4..." or "1080p live preview",
        active = state.recording,
        activeFill = "#3b1e28",
        activeBorder = "#f38ba8",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig record", function()
            refreshStatus()
          end)
        end,
      }),
      compactCard({
        glyph = "microphone-2",
        iconColor = state.voice and "#f38ba8" or "#eba0ac",
        title = state.voice and "🔴 Stop Voice" or "Voice Memo",
        subtitle = state.voice and "Recording AAC..." or "Headless to ~/Audio",
        active = state.voice,
        activeFill = "#3b1e28",
        activeBorder = "#f38ba8",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig voice", function()
            refreshStatus()
          end)
        end,
      }),
    }),

    -- Row 3: Virtual Webcam & Phone Screen Mirror
    ui.row({ gap = 6, align = "center" }, {
      compactCard({
        glyph = "camera",
        iconColor = state.webcam and "#89dceb" or "#a6adc8",
        title = state.webcam and "Webcam Live" or "Virtual Webcam",
        subtitle = state.webcam and "Active on Meet/Zoom" or "For Meet / Zoom",
        active = state.webcam,
        activeFill = "#182c33",
        activeBorder = "#89dceb",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig webcam", function()
            refreshStatus()
          end)
        end,
      }),
      compactCard({
        glyph = "device-mobile",
        iconColor = "#cba6f7",
        title = "Phone Mirror",
        subtitle = "Mouse & keyboard",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig screen")
        end,
      }),
    }),

    -- Row 4: Snap Photo & Physical Torch
    ui.row({ gap = 6, align = "center" }, {
      compactCard({
        glyph = "aperture",
        iconColor = "#94e2d5",
        title = "Snap Photo",
        subtitle = "To ~/Pictures/Camera",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig photo", function()
            refreshStatus()
          end)
        end,
      }),
      compactCard({
        glyph = "sun",
        iconColor = state.torch and "#f9e2af" or "#a6adc8",
        title = state.torch and "Torch ON" or "Flashlight",
        subtitle = state.torch and "Desk illuminated" or "Toggle phone LED",
        active = state.torch,
        activeFill = "#332c1c",
        activeBorder = "#f9e2af",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig torch", function()
            refreshStatus()
          end)
        end,
      }),
    }),

    -- Row 5: Scan Notebook Page & Audio Restore
    ui.row({ gap = 6, align = "center" }, {
      compactCard({
        glyph = "file-text",
        iconColor = "#a6e3a1",
        title = "Scan Notebook",
        subtitle = "Auto-crop & PDF",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig scan", function()
            refreshStatus()
          end)
        end,
      }),
      compactCard({
        glyph = "headphones",
        iconColor = "#a6adc8",
        title = "Reset Audio",
        subtitle = "A2DP AAC & Hex",
        onClick = function()
          noctalia.runAsync("/home/aps/.local/bin/phone-rig fix-audio", function()
            refreshStatus()
          end)
        end,
      }),
    }),
  }))

  -- 4. Error Display & Copy Button (if any error occurred)
  if state.last_error and state.last_error ~= "" then
    table.insert(children, ui.row({
      padding = 6,
      gap = 7,
      radius = 6,
      fill = "#2a1e24",
      border = "#f38ba8",
      borderWidth = 1,
      align = "center",
      justify = "space_between",
    }, {
      ui.row({ align = "center", gap = 6, flexGrow = 1 }, {
        ui.glyph({ name = "alert-circle", size = 14, color = "#f38ba8" }),
        ui.label({
          text = string.sub(state.last_error, 1, 45) .. (string.len(state.last_error) > 45 and "..." or ""),
          fontSize = 9.5,
          color = "#f38ba8",
        }),
      }),
      ui.button({
        text = copyFeedback and "Copied!" or "Copy",
        variant = "ghost",
        controlSize = "sm",
        onClick = function()
          noctalia.runAsync("printf '%s' " .. string.format("%q", state.last_error) .. " | wl-copy", function()
            copyFeedback = true
            renderUI()
          end)
        end,
      }),
    }))
  end

  -- Render to Noctalia panel without artificial outer fill or dead space
  panel.render(ui.column({ flexGrow = 1, gap = 7 }, children))
end

function refreshStatus()
  noctalia.runAsync("/home/aps/.local/bin/phone-rig status --json", function(result)
    local raw = result.stdout or ""
    if raw ~= "" then
      local ok, decoded = pcall(function()
        return noctalia.json.decode(raw)
      end)
      if ok and decoded and type(decoded) == "table" then
        state = decoded
        noctalia.state.set("overhead_rig_state", decoded)
      end
    end
    renderUI()
  end)
end

function onOpen(context)
  copyFeedback = false
  refreshStatus()
end

function update()
  refreshStatus()
end

noctalia.setUpdateInterval(3000)
renderUI()
refreshStatus()
