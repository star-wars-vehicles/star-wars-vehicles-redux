if SERVER then
  CreateConVar("swvr_health_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Damage Enabled")
  CreateConVar("swvr_health_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Health Multiplier")
  CreateConVar("swvr_shields_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Shields Enabled")
  CreateConVar("swvr_shields_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Shield Multiplier")
  CreateConVar("swvr_weapons_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Weapons Enabled")
  CreateConVar("swvr_weapons_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Weapon Multiplier")
  CreateConVar("swvr_collsions_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Collisions Enabled")
  CreateConVar("swvr_collisions_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Collision Multiplier")
  CreateConVar("swvr_disable_use", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Disable players from entering ships.")
end

if CLIENT then
  CreateClientConVar("swvr_shields_draw", "1", true, false, "Draw shield effects.")
  CreateClientConVar("swvr_engines_draw", "1", true, false, "Draw engine effects.")

  local SERVER_DEFAULTS = {
    swvr_disable_use = "0",
    swvr_health_enabled = "1",
    swvr_health_multiplier = "1.00",
    swvr_shields_enabled = "1",
    swvr_shields_multiplier = "1.00",
    swvr_weapons_enabled = "1",
    swvr_weapons_multiplier = "1.00",
    swvr_collsion_enabled = "1",
    swvr_collision_multiplier = "1.00"
  }

  local function BuildServerSettings(pnl)
    pnl:AddControl("ComboBox", {
      MenuButton = 1,
      Folder = "util_swvr_sv",
      Options = {
        ["#preset.default"] = SERVER_DEFAULTS
      },
      CVars = table.GetKeys(SERVER_DEFAULTS)
    })

    pnl:CheckBox("Damage Enabled", "swvr_health_enabled")
    pnl:NumSlider("Health Multiplier", "swvr_health_multiplier", "0.0", "10.0", 2)

    pnl:CheckBox("Shields Enabled", "swvr_shields_enabled")
    pnl:NumSlider("Shield Multiplier", "swvr_shields_multiplier", "0.0", "10.0", 2)

    pnl:CheckBox("Weapons Enabled", "swvr_weapons_enabled")
    pnl:NumSlider("Weapon Damage Multiplier", "swvr_weapons_multiplier", "0.0", "10.0", 2)

    pnl:CheckBox("Collisions Enabled", "swvr_collisions_enabled")
    pnl:NumSlider("Collision Multiplier", "swvr_collisions_multiplier", "0.0", "2.0", 2)

    pnl:CheckBox("Disable Entering Ships", "swvr_disable_use")

    return pnl
  end

  local CLIENT_DEFAULTS = {
    swvr_shields_draw = "1",
    swvr_engines_draw = "1"
  }

  local function BuildClientSettings(pnl)
    pnl:AddControl("ComboBox", {
      MenuButton = 1,
      Folder = "util_swvr_cl",
      Options = {
        ["#preset.default"] = CLIENT_DEFAULTS
      },
      CVars = table.GetKeys(CLIENT_DEFAULTS)
    })

    return pnl
  end

  hook.Add("PopulateToolMenu", "SWVR.PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Star Wars Vehicles", "SWVRSVSettings", "Server Settings", "", "", BuildServerSettings)
    spawnmenu.AddToolMenuOption("Utilities", "Star Wars Vehicles", "SWVRCLSettings", "Client Settings", "", "", BuildClientSettings)
  end)

  hook.Add("AddToolMenuCategories", "SWVR.AddToolMenuCategories", function()
    spawnmenu.AddToolCategory("Utilities", "Star Wars Vehicles", "Star Wars Vehicles")
  end)
end