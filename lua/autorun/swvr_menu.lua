properties.Add("allegiance", {
  MenuLabel = "Allegiance",
  Order = 999,
  MenuIcon = "icon16/flag_blue.png",
  Filter = function(self, ent, ply)
    if not (IsValid(ent) and ent.IsSWVRVehicle) then return false end

    return ply:IsAdmin() or ply:IsSuperAdmin()
  end,
  MenuOpen = function(self, option, ent, tr)
    local submenu = option:AddSubMenu()

    for _, faction in pairs(swvr.enum.Sides) do
      for _, allegiance in pairs(faction) do
        local opt = submenu:AddOption(allegiance, function()
          self:SetAllegiance(ent, allegiance)
        end)

        if (ent:GetAllegiance() == allegiance) then
          opt:SetChecked(true)
        end
      end
    end
  end,
  Action = function(self, ent) end,
  SetAllegiance = function(self, ent, allegiance)
    self:MsgStart()
    net.WriteEntity(ent)
    net.WriteString(allegiance)
    self:MsgEnd()
  end,
  Receive = function(self, length, ply)
    local ent = net.ReadEntity()
    local allegiance = net.ReadString()

    if hook.Run("CanProperty", ply, "allegiance", ent) == false then return end

    ent:SetAllegiance(allegiance)
  end
})

properties.Add("destroy", {
  MenuLabel = "Destroy",
  Order = 999,
  MenuIcon = "icon16/bomb.png",
  Filter = function(self, ent, ply)
    if not (IsValid(ent) and ent.IsSWVRVehicle) then return false end

    return ply:IsAdmin() or ply:IsSuperAdmin()
  end,
  Action = function(self, ent)
    self:MsgStart()
    net.WriteEntity(ent)
    self:MsgEnd()
  end,
  Receive = function(self, length, ply)
    local ent = net.ReadEntity()

    if hook.Run("CanProperty", ply, "destroy", ent) == false then return end

    ent:Destroy()
  end
})

properties.Add("repair", {
  MenuLabel = "Repair",
  Order = 999,
  MenuIcon = "icon16/bullet_wrench.png",
  Filter = function(self, ent, ply)
    if not (IsValid(ent) and ent.IsSWVRVehicle) then return false end

    if hook.Run("SWVR.CanRepairProperty", ent, ply) == true then return true end

    return ply:IsAdmin() or ply:IsSuperAdmin()
  end,
  Action = function(self, ent)
    self:MsgStart()
    net.WriteEntity(ent)
    self:MsgEnd()
  end,
  Receive = function(self, length, player)
    local ent = net.ReadEntity()

    if hook.Run("CanProperty", ply, "repair", ent) == false then return end

    ent:SetHealth(ent:GetMaxHealth())
    ent:SetShieldHealth(ent:GetMaxShieldHealth())
  end
})

cleanup.Register("swvehicles")

if SERVER then
  CreateConVar("swvr_health_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Damage Enabled")
  CreateConVar("swvr_health_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Health Multiplier")
  CreateConVar("swvr_shields_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Shields Enabled")
  CreateConVar("swvr_shields_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Shield Multiplier")
  CreateConVar("swvr_weapons_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Weapons Enabled")
  CreateConVar("swvr_weapons_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Weapon Multiplier")
  CreateConVar("swvr_collisions_enabled", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Collisions Enabled")
  CreateConVar("swvr_collisions_multiplier", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Collision Multiplier")
  CreateConVar("swvr_disable_use", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Disable players from entering ships.")
  CreateConVar("swvr_autocorrect", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable collision protection (autocorrect).")
  CreateConVar("swvr_coldstart_enabled", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Enable cold startup time.")
  CreateConVar("swvr_coldstart_time", "6", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Cold start wait time.")
else
  CreateClientConVar("swvr_hud_color_r", "255", true, false, "HUD red channel.")
  CreateClientConVar("swvr_hud_color_g", "255", true, false, "HUD green channel.")
  CreateClientConVar("swvr_hud_color_b", "255", true, false, "HUD blue channel.")
  CreateClientConVar("swvr_hud_color_a", "255", true, false, "HUD alpha channel.")

  CreateClientConVar("swvr_shields_draw", "1", true, false, "Draw shield effects.")
  CreateClientConVar("swvr_engines_draw", "1", true, false, "Draw engine effects.")

  CreateClientConVar("swvr_debug_statistics", "0", true, false, "Draw debug information.")
  CreateClientConVar("swvr_debug_visuals", "0", true, false, "Draw debug visuals.")

  CreateClientConVar("swvr_effect_volume", "100", true, false, "Volume of effects.")
  CreateClientConVar("swvr_engine_volume", "100", true, false, "Volume of the engines.")
end

if CLIENT then
  language.Add("Cleanup_swvehicles", "Star Wars Vehicles")

  local CONTROL_CVARS = {
    "swvr_key_forward",
    "swvr_key_backward",
    "swvr_key_right",
    "swvr_key_left",
    "swvr_key_up",
    "swvr_key_down",
    "swvr_key_engine",
    "swvr_key_boost",
    "swvr_key_primary",
    "swvr_key_secondary",
    "swvr_key_alternate",
    "swvr_key_modifier",
    "swvr_key_wings",
    "swvr_key_hyperdrive",
    "swvr_key_assist",
    "swvr_key_targeting",
    "swvr_key_eject",
    "swvr_key_handbrake",
    "swvr_key_exit",
    "swvr_key_freelook",
    "swvr_key_view"
  }

  local CONTROL_KEYS = {
    KEY_W,
    KEY_S,
    KEY_D,
    KEY_A,
    KEY_SPACE,
    KEY_LCONTROL,
    KEY_R,
    KEY_LSHIFT,
    MOUSE_LEFT,
    MOUSE_RIGHT,
    KEY_F,
    KEY_LSHIFT,
    KEY_G,
    KEY_Q,
    KEY_F,
    KEY_T,
    KEY_E,
    KEY_R,
    KEY_E,
    KEY_TAB,
    KEY_LALT
  }

  local CONTROL_NAMES = {
    swvr_key_forward = "Throttle +",
    swvr_key_backward = "Throttle -",
    swvr_key_left = "Roll/Strafe -",
    swvr_key_right = "Roll/Strafe +",
    swvr_key_up = "Thrust +",
    swvr_key_down = "Thrust -",
    swvr_key_engine = "Toggle Engine",
    swvr_key_boost = "Engage Afterburners",
    swvr_key_primary = "Primary Fire",
    swvr_key_secondary = "Secondary Fire",
    swvr_key_alternate = "Alternate Fire",
    swvr_key_modifier = "Modifier",
    swvr_key_wings = "Toggle Wings",
    swvr_key_hyperdrive = "Activate Hyperdrive",
    swvr_key_assist = "Toggle Flight Assist",
    swvr_key_targeting = "Toggle Targeting",
    swvr_key_eject = "Eject",
    swvr_key_handbrake = "Handbrake",
    swvr_key_exit = "Exit",
    swvr_key_freelook = "Freelook",
    swvr_key_view = "Toggle View Mode"
  }

  local CONTROL_DEFAULTS = {}

  for i = 1, #CONTROL_CVARS do
    CreateClientConVar(CONTROL_CVARS[i], tostring(CONTROL_KEYS[i]), true, true, CONTROL_NAMES[CONTROL_CVARS[i]])
    CONTROL_DEFAULTS[CONTROL_CVARS[i]] = CONTROL_KEYS[i]
  end

  local SERVER_DEFAULTS = {
    swvr_disable_use = "0",
    swvr_health_enabled = "1",
    swvr_health_multiplier = "1.00",
    swvr_shields_enabled = "1",
    swvr_shields_multiplier = "1.00",
    swvr_weapons_enabled = "1",
    swvr_weapons_multiplier = "1.00",
    swvr_collisions_enabled = "1",
    swvr_collisions_multiplier = "1.00",
    swvr_autocorrect = "1",
    swvr_coldstart_enabled = "0",
    swvr_coldstart_time = "6"
  }

  local function BuildServerSettings(pnl)
    pnl:Help("Server Settings")

    pnl:AddControl("ComboBox", {
      MenuButton = 1,
      Folder = "util_swvr_sv",
      Options = {
        ["#preset.default"] = SERVER_DEFAULTS
      },
      CVars = table.GetKeys(SERVER_DEFAULTS)
    })

    pnl:Help("Global Overrides")

    pnl:CheckBox("Damage Enabled", "swvr_health_enabled")
    pnl:CheckBox("Shields Enabled", "swvr_shields_enabled")
    pnl:CheckBox("Weapons Enabled", "swvr_weapons_enabled")
    pnl:CheckBox("Collisions Enabled", "swvr_collisions_enabled")

    pnl:Help("Global Multiplier Settings")

    pnl:NumSlider("Health Multiplier", "swvr_health_multiplier", "0.1", "10.0", 2)
    pnl:NumSlider("Shield Multiplier", "swvr_shields_multiplier", "0.0", "10.0", 2)
    pnl:NumSlider("Weapon Damage Multiplier", "swvr_weapons_multiplier", "0.0", "10.0", 2)
    pnl:NumSlider("Collision Multiplier", "swvr_collisions_multiplier", "0.0", "2.0", 2)

    pnl:Help("Extra Settings")

    pnl:CheckBox("Enable Cold Engine Start", "swvr_coldstart_enabled")
    pnl:NumSlider("Cold Start Time", "swvr_coldstart_time", "0.0", "10.0",  2)

    pnl:CheckBox("Disable Entering Ships", "swvr_disable_use")
    pnl:CheckBox("Enable Collision Protection (Autocorrect)", "swvr_autocorrect")

    return pnl
  end

  local CLIENT_DEFAULTS = {
    swvr_effect_volume = "100",
    swvr_engine_volume = "100",
    swvr_shields_draw = "1",
    swvr_engines_draw = "1",
    swvr_debug_statistics = "0",
    swvr_debug_visuals = "0",
    swvr_hud_color_r = "0",
    swvr_hud_color_g = "160",
    swvr_hud_color_b = "255",
    swvr_hud_color_a = "255"
  }

  table.Add(CLIENT_DEFAULTS, CONTROL_DEFAULTS)

  local function BuildClientSettings(pnl)
    pnl:Help("Client Settings")

    pnl:AddControl("ComboBox", {
      MenuButton = 1,
      Folder = "util_swvr_cl",
      Options = {
        ["#preset.default"] = CLIENT_DEFAULTS
      },
      CVars = table.GetKeys(CLIENT_DEFAULTS)
    })

    pnl:Help("Sound Settings")

    pnl:NumSlider("Effect Volume", "swvr_effect_volume", 0, 100, 0)
    pnl:NumSlider("Engine Volume", "swvr_engine_volume", 0, 100, 0)

    pnl:Help("Draw Settings")

    pnl:CheckBox("Draw Shields", "swvr_shields_draw")
    pnl:CheckBox("Draw Engines", "swvr_engines_draw")

    pnl:CheckBox("Draw Debug Statistics", "swvr_debug_statistics")
    pnl:CheckBox("Draw Debug Visuals", "swvr_debug_visuals")

    pnl:Help("HUD Settings")

    local color = vgui.Create("DColorMixer")
    color:SetConVarR("swvr_hud_color_r")
    color:SetConVarG("swvr_hud_color_g")
    color:SetConVarB("swvr_hud_color_b")
    color:SetConVarA("swvr_hud_color_a")

    pnl:AddItem(color)

    pnl:Help("Control Settings")

    for i, cvar in ipairs(CONTROL_CVARS) do
      local panel = vgui.Create("swvr::key")
      panel:SetLabel(CONTROL_NAMES[cvar])
      panel:SetConVar(cvar)
      pnl:AddItem(panel)

      if i == 11 then
        pnl:Help("Modifier Key")
      elseif i == 12 then
        pnl:Help("Modifier Controls")
      end
    end

    pnl:Help("Thanks to the community for all the help!")

    return pnl
  end

  -- Custom Key Control Panel

  local PANEL = {}

  function PANEL:Init()
    self.Label = vgui.Create("DLabel", self)
    self.Label:SetTextColor(Color(0, 0, 0))
    self.Key = vgui.Create("DBinder", self)

    self.Key.UpdateText = function(panel)
      local str = input.GetKeyName( panel:GetSelectedNumber() )
      if not str then str = "NONE" end

      str = string.upper(language.GetPhrase( str ))

      panel:SetText( str )
     end
  end

  function PANEL:SetLabel(text)
    self.Label:SetText(text)
  end

  function PANEL:SetConVar(cvar)
    self.Key:SetConVar(cvar)
  end

  function PANEL:PerformLayout()
    local w, h = self:GetParent():GetWide() * .9, 20

    self:SetSize(w, h)

    self.Key:InvalidateLayout(true)
    self.Key:SetSize(w / 2, h)
    self.Key:SetPos(w / 2, 0)

    self.Label:SetPos(5, 0)
    self.Label:SetSize(w / 2, h)
  end

  vgui.Register("swvr::key", PANEL, "Panel")

  -- Spawnmenu Functions

  spawnmenu.AddCreationTab("Star Wars Vehicles: Redux", function()
    local ctrl = vgui.Create("SpawnmenuContentPanel")
    ctrl:CallPopulateHook("SWVRVehiclesTab")

    return ctrl
  end, "icon16/other.png", 60)

  spawnmenu.AddContentType("swvrvehicle", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end

    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("entity")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)
    icon:SetAdminOnly(obj.admin)
    icon:SetColor(Color(205, 92, 92, 255))

    icon.DoClick = function()
      RunConsoleCommand("gm_spawnsent", obj.spawnname)
      surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function()
      local menu = DermaMenu()

      menu:AddOption("Copy to Clipboard", function()
        SetClipboardText(obj.spawnname)
      end)

      menu:AddOption("Spawn Using Toolgun", function()
        RunConsoleCommand("gmod_tool", "creator")
        RunConsoleCommand("creator_type", "0")
        RunConsoleCommand("creator_name", obj.spawnname)
      end)

      menu:Open()
    end

    if (IsValid(container)) then
      container:Add(icon)
    end

    return icon
  end)

  spawnmenu.AddContentType("swvrweapon", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end

    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("weapon")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)
    icon:SetAdminOnly(obj.admin)
    icon:SetColor(Color(135, 206, 250, 255))

    icon.DoClick = function()
      RunConsoleCommand("gm_giveswep", obj.spawnname)
      surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.DoMiddleClick = function()
      RunConsoleCommand("gm_spawnswep", obj.spawnname)
      surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function()
      local menu = DermaMenu()

      menu:AddOption("Copy to Clipboard", function()
        SetClipboardText(obj.spawnname)
      end)

      menu:AddOption("Spawn Using Toolgun", function()
        RunConsoleCommand("gmod_tool", "creator")
        RunConsoleCommand("creator_type", "3")
        RunConsoleCommand("creator_name", obj.spawnname)
      end)

      menu:Open()
    end

    if (IsValid(container)) then
      container:Add(icon)
    end

    return icon
  end)

  -- Menu Hooks

  hook.Add("PopulateToolMenu", "SWVR.PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Star Wars Vehicles", "SWVRSVSettings", "Server Settings", "", "", BuildServerSettings)
    spawnmenu.AddToolMenuOption("Utilities", "Star Wars Vehicles", "SWVRCLSettings", "Client Settings", "", "", BuildClientSettings)
  end)

  hook.Add("AddToolMenuCategories", "SWVR.AddToolMenuCategories", function()
    spawnmenu.AddToolCategory("Utilities", "Star Wars Vehicles", "Star Wars Vehicles")
  end)

  hook.Add("SWVRVehiclesTab", "AddEntityContent", function(pnlContent, tree, node)
    local Categorised = { }
    local SpawnableEntities = table.Merge({ }, list.Get("SWVRVehicles.Weapons") or { }) --[[list.Get("SWVRVehicles") or ]]

    for class, ent in pairs(scripted_ents.GetList()) do
      if ent.t.Base == "swvr_base" then
        table.insert(SpawnableEntities, ent.t)
        killicon.Add(ent.t.ClassName, "hud/killicons/swvr_vehicle", Color(255, 80, 0, 255))
      end
    end

    if (SpawnableEntities) then
      for class, ent in pairs(SpawnableEntities) do
        ent.SpawnName = class
        ent.Category = ent.Category or "Other"
        Categorised[ent.Category] = Categorised[ent.Category] or { }
        table.insert(Categorised[ent.Category], ent)
      end
    end

    for CategoryName, v in SortedPairs(Categorised) do
      local child = tree:AddNode(CategoryName, "icon16/" .. string.lower(CategoryName) .. ".png")

      if (child.PropPanel) then return end

      child.PropPanel = vgui.Create("ContentContainer", pnlContent)
      child.PropPanel:SetVisible(false)
      child.PropPanel:SetTriggerSpawnlistChange(false)

      local Types = { }
      for k, ent in pairs(v) do
        ent.Class = ent.Class or "Other"
        Types[ent.Class] = Types[ent.Class] or { }
        table.insert(Types[ent.Class], ent)
      end

      for Type, tbl in SortedPairs(Types) do
        local path = "icon16/" .. string.lower(CategoryName) .. "_" .. string.lower(Type) .. ".png"

        path = file.Exists("materials/" .. path, "GAME") and path or "icon16/" .. string.lower(CategoryName) .. ".png"

        local typeNode = child:AddNode(Type, path)
        local panel = vgui.Create("ContentContainer", pnlContent)

        panel:SetVisible(false)

        local header = vgui.Create("ContentHeader", child.PropPanel)
        header:SetText(Type)
        child.PropPanel:Add(header)

        for k, ent in SortedPairsByMemberValue(tbl, "PrintName") do
          local data = {
            nicename = ent.PrintName or ent.ClassName,
            spawnname = ent.ClassName,
            material = "entities/" .. ent.ClassName .. ".png",
            admin = ent.AdminOnly or false,
            author = ent.Author,
            info = ent.Instructions
          }

          spawnmenu.CreateContentIcon(ent.Category ~= "Weapons" and "swvrvehicle" or "swvrweapon", panel, data)
          spawnmenu.CreateContentIcon(ent.Category ~= "Weapons" and "swvrvehicle" or "swvrweapon", child.PropPanel, data)
        end

        typeNode.DoClick = function()
          pnlContent:SwitchPanel(panel)
        end
      end

      function child:DoClick()
        pnlContent:SwitchPanel(self.PropPanel)
      end

      child:SetExpanded(true)
    end

    local FirstNode = tree:Root():GetChildNode(0)

    if (IsValid(FirstNode)) then
      FirstNode:InternalDoClick()
    end
  end)
end
