if SERVER then
	function SWVR_Spawn_SENT(player, EntityName, tr)
		if (EntityName == nil) then return end
		-- Ask the gamemode if it's ok to spawn this
		if (not gamemode.Call("PlayerSpawnSENT", player, EntityName)) then return end
		local vStart = player:EyePos()
		local vForward = player:GetAimVector()

		if (not tr) then
			local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * 4096)
			trace.filter = player
			tr = util.TraceLine(trace)
		end

		local entity = nil
		local PrintName = nil
		local sent = scripted_ents.GetStored(EntityName)

		if (sent) then
			local sent = sent.t
			if (sent.AdminOnly and not player:IsAdmin()) then return end
			ClassName = EntityName
			entity = sent:SpawnFunction(player, tr, EntityName)
			ClassName = nil
			PrintName = sent.PrintName
			-- Spawn from list table
		else
			local SpawnableEntities = list.Get("SWVRVehicles")
			if (not SpawnableEntities) then return end
			local EntTable = SpawnableEntities[EntityName]
			if (not EntTable) then return end
			if (EntTable.AdminOnly and not player:IsAdmin()) then return end
			PrintName = EntTable.PrintName
			local SpawnPos = tr.HitPos + tr.HitNormal * 16

			if (EntTable.NormalOffset) then
				SpawnPos = SpawnPos + tr.HitNormal * EntTable.NormalOffset
			end

			entity = ents.Create(EntTable.ClassName)
			entity:SetPos(SpawnPos)
			entity:Spawn()
			entity:Activate()

			if (EntTable.DropToFloor) then
				entity:DropToFloor()
			end
		end

		if (IsValid(entity)) then
			if (IsValid(player)) then
				gamemode.Call("PlayerSpawnedSENT", player, entity)
			end

			undo.Create("SENT")
			undo.SetPlayer(player)
			undo.AddEntity(entity)

			if (PrintName) then
				undo.SetCustomUndoText("Undone " .. PrintName)
			end

			undo.Finish("Scripted Entity (" .. tostring(EntityName) .. ")")
			player:AddCleanup("sents", entity)
			entity:SetVar("Player", player)
		end
	end

	concommand.Add("swvr_spawnsent", function(ply, cmd, args)
		SWVR_Spawn_SENT(ply, args[1])
	end)

	function SWVR_CCGiveSWEP(player, command, arguments)
		if (arguments[1] == nil) then return end
		-- Make sure this is a SWEP
		local swept = list.Get("SWVRVehicles.Weapons")
		local swep

		for k, v in pairs(swept) do
			if (v.ClassName == arguments[1]) then
				swep = v
				break
			end
		end

		if (swep == nil) then return end
		if (not gamemode.Call("PlayerGiveSWEP", player, arguments[1], swep)) then return end
		MsgAll("Giving " .. player:Nick() .. " a " .. swep.ClassName .. "\n")
		player:Give(swep.ClassName)
		-- And switch to it
		player:SelectWeapon(swep.ClassName)
	end

	concommand.Add("swvr_giveswep", SWVR_CCGiveSWEP)

	--[[---------------------------------------------------------
	-- Give a swep.. duh.
-----------------------------------------------------------]]
	function SWVR_Spawn_Weapon(Player, wepname, tr)
		if (wepname == nil) then return end
		local swept = list.Get("SWVRVehicles.Weapons")
		local swep

		for k, v in pairs(swept) do
			if (v.ClassName == wepname) then
				swep = v
				break
			end
		end

		-- Make sure this is a SWEP
		if (swep == nil) then return end
		if (not gamemode.Call("PlayerSpawnSWEP", Player, wepname, swep)) then return end

		if (not tr) then
			tr = Player:GetEyeTraceNoCursor()
		end

		if (not tr.Hit) then return end
		local entity = ents.Create(swep.ClassName)

		if (IsValid(entity)) then
			entity:SetPos(tr.HitPos + tr.HitNormal * 32)
			entity:Spawn()
			gamemode.Call("PlayerSpawnedSWEP", Player, entity)
		end
	end

	concommand.Add("swvr_spawnswep", function(ply, cmd, args)
		SWVR_Spawn_Weapon(ply, args[1])
	end)
end

if (CLIENT) then
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

		icon.SetAdminOnly = function(self, admin)
			if (admin) then
				self.imgAdmin = vgui.Create("DImage", self)
				self.imgAdmin:SetImage("icon16/shield.png")
				self.imgAdmin:SetSize(16, 16)
				self.imgAdmin:SetPos(self:GetWide() - 22, 5)
				self.imgAdmin:SetTooltip("Admin Only")
			end
		end

		icon:SetAdminOnly(obj.admin)
		local Tooltip = Format("%s", obj.nicename)

		if (obj.info and obj.info ~= "") then
			Tooltip = Format("%s\n\n%s", Tooltip, obj.info)
		end

		icon:SetTooltip(Tooltip)
		icon:SetColor(Color(205, 92, 92, 255))

		icon.DoClick = function()
			RunConsoleCommand("swvr_spawnsent", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.OpenMenu = function(icon)
			local menu = DermaMenu()

			menu:AddOption("Copy to Clipboard", function()
				SetClipboardText(obj.spawnname)
			end)

			menu:Open()
		end

		icon.OpenMenu = function(icon)
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
			RunConsoleCommand("swvr_giveswep", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.DoMiddleClick = function()
			RunConsoleCommand("swvr_spawnswep", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.OpenMenu = function(icon)
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

	hook.Add("SWVRVehiclesTab", "AddEntityContent", function(pnlContent, tree, node)
		local Categorised = {}
		-- Add this list into the tormoil
		local SpawnableEntities = list.Get("SWVRVehicles")

		print("PRINTING THE TABLE")
		PrintTable(SpawnableEntities)

		if (SpawnableEntities) then
			for k, v in pairs(SpawnableEntities) do
				v.SpawnName = k

				if (v.Category == "Star Wars") then
					v.Category = "Other"
				else
					v.Category = string.gsub(v.Category, "%Star Wars Vehicles: ", "") or "Other"
				end

				Categorised[v.Category] = Categorised[v.Category] or {}
				table.insert(Categorised[v.Category], v)
			end
		end

		SpawnableEntities = list.Get("SWVRVehicles.Weapons")

		if (SpawnableEntities) then
			for k, v in pairs(SpawnableEntities) do
				v.SpawnName = k
				v.Category = "Weapons"
				Categorised[v.Category] = Categorised[v.Category] or {}
				table.insert(Categorised[v.Category], v)
			end
		end

		--
		-- Add a tree node for each category
		--
		for CategoryName, v in SortedPairs(Categorised) do
			-- Add a node to the tree
			local node = tree:AddNode(CategoryName, "icons16/" .. string.lower(CategoryName) .. ".png")

			-- When we click on the node - populate it using this function
			node.DoPopulate = function(self)
				-- If we've already populated it - forget it.
				if (self.PropPanel) then return end
				-- Create the container panel
				self.PropPanel = vgui.Create("ContentContainer", pnlContent)
				self.PropPanel:SetVisible(false)
				self.PropPanel:SetTriggerSpawnlistChange(false)

				for k, ent in SortedPairsByMemberValue(v, "PrintName") do
					local enttype = "swvrvehicle"

					if (CategoryName == "Weapons") then
						enttype = "weapon"
					end

					spawnmenu.CreateContentIcon(enttype, self.PropPanel, {
						nicename = ent.PrintName or ent.ClassName,
						spawnname = ent.ClassName,
						material = "entities/" .. ent.ClassName .. ".png",
						admin = ent.AdminOnly or false,
						author = ent.Author,
						info = ent.Instructions
					})
				end
			end

			-- If we click on the node populate it and switch to it.
			node.DoClick = function(self)
				self:DoPopulate()
				pnlContent:SwitchPanel(self.PropPanel)
			end
		end

		-- Select the first node
		local FirstNode = tree:Root():GetChildNode(0)

		if (IsValid(FirstNode)) then
			FirstNode:InternalDoClick()
		end
	end)
end
