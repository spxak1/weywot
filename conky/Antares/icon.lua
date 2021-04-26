script = [[
${execi 300 ./scripts/weather-icon.sh #{theme} $(cat ~/.cache/eleg-weather.json | jq -r '.weather[0].icon')}${image ~/.cache/eleg-weather-icon.png -p 410,30 -s 100x100}
]];

local function interp (s, t)
  return s:gsub('(#%b{})', function (w)
      return t[w:sub(3, -2)] or w
  end)
end

function load(theme)
  return interp(script, {
    theme = white,
     })
end
