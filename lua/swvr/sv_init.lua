
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local function LoadDirectory(name)
  MsgN("Loading " .. name:gsub("^%l", string.upper) .. "...")

  local path = "swvr/" .. name .. "/"
  local files, dirs = file.Find(path .. "*", "LUA")

  for _, dir in SortedPairs(dirs) do
    if (file.Exists(path .. dir .. "/sv_init.lua", "LUA")) then
      include(path .. dir .. "/sv_init.lua")
    end

    for _, f in SortedPairs(file.Find(path .. dir .. "/*.lua", "LUA"), false) do
      if (not f:StartWith("sv_") and not f:StartWith("cl_")) then
        AddCSLuaFile(path .. dir .. "/" .. f)
        include(path .. dir .. "/" .. f)
      elseif (f:StartWith("sv_")) then
        include(path .. dir .. "/" .. f)
      elseif (f:StartWith("cl_")) then
        AddCSLuaFile(path .. dir .. "/" .. f)
      end
    end

    MsgN("\t--> Loaded " .. dir .. " in " .. name:gsub("^%l", string.upper) .. "!")
  end

  if (#files) > 0 then MsgN("Loading miscellaneous " .. name:gsub("^%l", string.upper) .. "...") end
  for _, f in SortedPairs(files) do
    if (not f:StartWith("sv_") and not f:StartWith("cl_")) then
      AddCSLuaFile(path .. f)
      include(path .. f)

      MsgN("\t--> Loaded (SH) " .. name:gsub("^%l", string.upper) .. " file: '" .. f .. "'")
    elseif (f:StartWith("sv_")) then
      include(path .. f)
      MsgN("\t--> Loaded (SV) " .. name:gsub("^%l", string.upper) .. " file: '" .. f .. "'")
    elseif (f:StartWith("cl_")) then
      AddCSLuaFile(path .. f)
      MsgN("\t--> Loaded (CL) " .. name:gsub("^%l", string.upper) .. " file: '" .. f .. "'")
    end
  end

  MsgN(name:gsub("^%l", string.upper) .. " Loaded!")
  SWVR[name:gsub("^%l", string.upper) .. "Loaded"] = true
  hook.Run("SWVR." .. name:gsub("^%l", string.upper) .. "Loaded")
end

function SWVR:Initialize()
  MsgN("----------------------------------------------")
  MsgN("  Initializing Star Wars Vehicles Redux [SV]  ")
  MsgN("----------------------------------------------")

  LoadDirectory("libraries")
  LoadDirectory("base")
  LoadDirectory("weapons")

  MsgN("----------------------------------------------")
  MsgN("  Initialized Star Wars Vehicles Redux [SV]   ")
  MsgN("----------------------------------------------")
end

SWVR:Initialize()

hook.Add("OnReloaded", "SWVRReload", function()
  SWVR:Initialize()
end)
