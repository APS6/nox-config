--!nonstrict

local function render(output)
  local text = tostring(output or ""):gsub("\n", "")
  local color = text == "on" and "#a6e3a1" or "#f38ba8" -- Green for on, Red for off
  
  barWidget.render(ui.glyph({ 
    name = "graph", 
    size = 18,
    color = color
  }))
end

local function update()
  noctalia.runAsync("/home/aps/.local/bin/stats-status", function(result)
    render(result.stdout)
  end, 2000)
end

noctalia.setUpdateInterval(5000)
update()

function update_poll()
  update()
end
