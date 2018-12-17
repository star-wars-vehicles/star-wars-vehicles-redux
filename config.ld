project = "SWVR"
title = "Star Wars Vehicles Redux"
description = "The rewrite of the popular Star Wars Vehicles Episode 1 base"

merge = true
not_luadoc = true
no_space_before_args = true

format = "discount"
dir = "docs"
file = "lua"

readme = "./docs/doc.md"
kind_names = { topic = "Manual", script = "Modules" }

custom_tags = {
  { "shared", hidden = true },
  { "client", hidden = true },
  { "server", hidden = true }
}

custom_display_name_handler = function(item, default_handler)
  local name = item.type ~= "function" and item.name or item.name .. item.args

  for _, tag in ipairs({"shared", "client", "server"}) do
    if item.tags[tag] then
      name = name .. " [" .. tag .. "]"
    end
  end

  if name ~= item.name then return name end

  return default_handler(item)
end
