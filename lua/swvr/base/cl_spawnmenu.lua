spawnmenu.AddCreationTab("Star Wars Vehicles: Redux", function()
  local ctrl = vgui.Create("SpawnmenuContentPanel")
  ctrl:CallPopulateHook("SWVRVehiclesTab")

  return ctrl
end, "icons16/other.png", 60)

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
    print("AHHH")
    RunConsoleCommand("gm_spawnsent", obj.spawnname)
    surface.PlaySound("ui/buttonclickrelease.wav")
  end

  icon.OpenMenu = function()
    local menu = DermaMenu()
    menu:AddOption("Copy to Clipboard", function() SetClipboardText(obj.spawnname) end)
    menu:AddOption("Spawn Using Toolgun", function() RunConsoleCommand("gmod_tool", "creator") RunConsoleCommand("creator_type", "0") RunConsoleCommand("creator_name", obj.spawnname) end)
    menu:Open()
  end

  if ( IsValid(container) ) then
    container:Add( icon )
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
    menu:AddOption("Copy to Clipboard", function() SetClipboardText(obj.spawnname) end)
    menu:AddOption("Spawn Using Toolgun", function() RunConsoleCommand("gmod_tool", "creator") RunConsoleCommand("creator_type", "3") RunConsoleCommand("creator_name", obj.spawnname) end)
    menu:Open()
  end

  if ( IsValid(container) ) then
    container:Add( icon )
  end

  return icon
end)

hook.Add("SWVRVehiclesTab", "AddEntityContent", function(pnlContent, tree, node)
  local Categorised = {}

  local SpawnableEntities = table.Merge(list.Get("SWVRVehicles") or {}, list.Get("SWVRVehicles.Weapons") or {})

  if ( SpawnableEntities ) then
    for k, v in pairs(SpawnableEntities) do
      v.SpawnName = k
      v.Category = v.Category or "Other"

      Categorised[v.Category] = Categorised[v.Category] or { }
      table.insert(Categorised[v.Category], v)
    end
  end

  for CategoryName, v in SortedPairs(Categorised) do
    local child = tree:AddNode(CategoryName, "icons16/" .. string.lower(CategoryName) .. ".png")

    child.DoPopulate = function(self)
      if (self.PropPanel) then return end

      self.PropPanel = vgui.Create("ContentContainer", pnlContent)
      self.PropPanel:SetVisible(false)
      self.PropPanel:SetTriggerSpawnlistChange(false)

      for k, ent in SortedPairsByMemberValue(v, "PrintName") do
        spawnmenu.CreateContentIcon(ent.Category ~= "Weapons" and "swvrvehicle" or "swvrweapon", self.PropPanel, {
          nicename = ent.PrintName or ent.ClassName,
          spawnname = ent.ClassName,
          material = "entities/" .. ent.ClassName .. ".png",
          admin = ent.AdminOnly or false,
          author = ent.Author,
          info = ent.Instructions
        })
      end
    end

    child.DoClick = function(self)
      self:DoPopulate()
      pnlContent:SwitchPanel(self.PropPanel)
    end
  end

  local FirstNode = tree:Root():GetChildNode(0)

  if (IsValid(FirstNode)) then
    FirstNode:InternalDoClick()
  end
end)
