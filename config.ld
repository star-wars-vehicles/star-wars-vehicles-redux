project = 'SWVR'
title = 'Star Wars Vehicles Redux'
description = 'The rewrite of the popular Star Wars Vehicles Episode 1 base'

merge = true
not_luadoc = true
no_space_before_args = true

format = 'discount'
dir = 'docs'
file = 'lua'

style = true

readme = './README.md'
kind_names = { topic = 'Manual', module = 'Libraries' }

custom_tags = {
  { 'shared', hidden = true },
  { 'client', hidden = true },
  { 'server', hidden = true },
  { 'internal', hidden = true },
  { 'future', hidden = true },
  { 'deprecated', hidden = true },
  { 'bug', hidden = true }
}

local display_handlers = {}
local registered = false

local function register_handler(name, display_handler)
  display_handlers[name] = display_handler
end

-- Prepend an HTML tag to a string
local function prepend_html(str, tag, options)
  local html = '<' .. tag .. ' ' .. options .. '>' .. '</' .. tag .. '>'

  return html .. str
end

local function append_html(str, tag, options)
  local html = '<' .. tag .. ' ' .. options .. '>' .. '</' .. tag .. '>'

  return str .. html
end

local function register_handlers()
  for _, tag in ipairs({'shared', 'client', 'server'}) do
    register_handler(tag, function(name) return prepend_html(name, 'span', 'class="realm ' .. tag .. '" ' .. 'title="' .. tag:sub(1,1):upper() .. tag:sub(2) .. '"') end)
  end

  for _, tag in ipairs({'internal', 'deprecated', 'future', 'bug'}) do
    register_handler(tag, function(name) return append_html(name, 'div', 'class="notice ' .. tag .. '" ' .. 'title="' .. tag:sub(1,1):upper() .. tag:sub(2) .. '"') end)
  end

  registered = true
end

custom_display_name_handler = function(item, default_handler)
  if not registered then register_handlers() end

  local name = item.type ~= 'function' and item.name or item.name .. item.args

  for tag, handler in pairs(display_handlers) do
    if item.tags[tag] then
      name = handler(name)
    end
  end

  if name ~= item.name then return name end

  return default_handler(item)
end

tparam_alias('entity', 'entity')
tparam_alias('player', 'player')
tparam_alias('vector', 'vector')
tparam_alias('angle', 'angle')
