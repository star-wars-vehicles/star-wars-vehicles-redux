include("shared.lua")

local function LoadDirectory(name)
  local path = "swvr/" .. name .. "/"
  local files, dirs = file.Find(path .. "*", "LUA")

  for _, dir in SortedPairs(dirs) do
    if (file.Exists(path .. dir .. "/cl_init.lua", "LUA")) then
      include(path .. dir .. "/cl_init.lua")
    end

    for _, f in SortedPairs(file.Find(path .. dir .. "/*.lua", "LUA"), false) do
      include(path .. dir .. "/" .. f)
    end
  end

  for _, f in SortedPairs(files) do
    if f:StartWith("sv_") then continue end

    include(path .. f)
    MsgN("\t--> Loaded (CL) " .. name:gsub("^%l", string.upper) .. " file: '" .. f .. "'")
  end

  MsgN(" --> " .. name:gsub("^%l", string.upper) .. " Loaded")
  SWVR[name:gsub("^%l", string.upper) .. "Loaded"] = true
  hook.Run("SWVR." .. name:gsub("^%l", string.upper) .. "Loaded")
end

function SWVR:Initialize()
  MsgN("----------------------------------------------")
  MsgN("  Initializing Star Wars Vehicles Redux [CL]  ")
  MsgN("----------------------------------------------")

  LoadDirectory("libraries")
  LoadDirectory("base")

  MsgN("----------------------------------------------")
  MsgN("  Initialized Star Wars Vehicles Redux [CL]   ")
  MsgN("----------------------------------------------")
end

SWVR:Initialize()
