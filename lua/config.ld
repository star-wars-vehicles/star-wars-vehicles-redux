title = "Star Wars Vehicles Redux"
project = "SWVR"
merge = true
format = "markdown"
not_luadoc = true
dir = "docs"

custom_tags = {
  { "shared", hidden = true },
  { "client", hidden = true },
  { "server", hidden = true }
}

custom_display_name_handler = function(item, default_handler)
  local name = item.name

  print(item.tags.shared)

  for _, tag in ipairs({"shared", "client", "server"}) do
    if item.tags[tag] then
      name = name .. " [" .. tag .. "]"
    end
  end

  if name ~= item.name then return name end

  return default_handler(item)
end
