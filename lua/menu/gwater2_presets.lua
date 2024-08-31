-- CAUTION!!
-- This is not a "custompresets" file. Instead, use import functionality in presets tab.
-- This file contains code used to generate, parse, and handle presets.
-- DO NOT EDIT ANYTHING IN THERE UNLESS YOU KNOW WHAT YOU ARE DOING!!

AddCSLuaFile()

if SERVER or not gwater2 then return end

local styling = include("menu/gwater2_styling.lua")
local _util = include("menu/gwater2_util.lua")

local default_presets = {
	["000-(Default) Water"]={
		["CUST/Author"]="Meetric",
		["VISL/Color"]=(2^31-1),
		["PHYS/Cohesion"]=(2^31-1),
		["PHYS/Adhesion"]=(2^31-1),
		["PHYS/Viscosity"]=(2^31-1),
		["PHYS/Surface Tension"]=(2^31-1),
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	},
	["001-Acid"]={
		["CUST/Author"]="Meetric",
		["VISL/Color"]={240, 255, 0, 150},
		["PHYS/Cohesion"]=(2^31-1),
		["PHYS/Adhesion"]=0.1,
		["PHYS/Viscosity"]=0,
		["PHYS/Surface Tension"]=(2^31-1),
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	},
	["002-Blood"]={
		["CUST/Author"]="GHM",
		["VISL/Color"]={240, 0, 0, 250},
		["PHYS/Cohesion"]=0.45,
		["PHYS/Adhesion"]=0.15,
		["PHYS/Viscosity"]=1,
		["PHYS/Surface Tension"]=0,
		["PHYS/Fluid Rest Distance"]=0.55
	},
	["003-Glue"]={ -- yeah, sure... "glue"...
		["CUST/Author"]="Meetric",
		["VISL/Color"]={230, 230, 230, 255},
		["PHYS/Cohesion"]=0.03,
		["PHYS/Adhesion"]=0.1,
		["PHYS/Viscosity"]=10,
		["PHYS/Surface Tension"]=(2^31-1),
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	},
	["004-Lava"]={
		["CUST/Author"]="Meetric",
		["VISL/Color"]={255, 210, 0, 200},
		["PHYS/Cohesion"]=0.1,
		["PHYS/Adhesion"]=0.01,
		["PHYS/Viscosity"]=10,
		["PHYS/Surface Tension"]=(2^31-1),
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	},
	["005-Oil"]={ -- SOMEONE SAID OIL?? *freedom sounds*
		["CUST/Author"]="Meetric",
		["VISL/Color"]={0, 0, 0, 255},
		["PHYS/Cohesion"]=0,
		["PHYS/Adhesion"]=0,
		["PHYS/Viscosity"]=0,
		["PHYS/Surface Tension"]=0,
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	},
	["006-Goop"]={
		["CUST/Author"]="Meetric",
		["VISL/Color"]={170, 240, 140, 50},
		["PHYS/Cohesion"]=0.1,
		["PHYS/Adhesion"]=0.1,
		["PHYS/Viscosity"]=10,
		["PHYS/Surface Tension"]=0.25,
		["PHYS/Fluid Rest Distance"]=(2^31-1)
	}
}

function gwater2.options.detect_preset_type(preset)
	if util.JSONToTable(preset) ~= nil then
		return "JSON"
	end
	if util.Decompress(util.Base64Decode(preset)) ~= nil then
		return "B64-PI"
	end


	local preset_parts = preset:Split(',')

	if preset_parts[2] == '' and preset_parts[3] ~= nil then
		if preset_parts[4] == '' then
			return "Extension w/ Author"
		end
		if preset_parts[4] ~= nil then
			return nil
		end
		return "Extension"
	end
	if preset_parts[2] ~= '' then
		if preset_parts[3] ~= nil then
			return nil
		end
		return "CustomPresets"
	end
	return nil
end

function gwater2.options.read_preset(preset)
	local type = gwater2.options.detect_preset_type(preset)
	if type == nil then
		return {"", {}}
	end
	if type == "JSON" then
		local p = util.JSONToTable(preset)
		for k,v in pairs(p) do
			return {k, v}
		end
	end
	if type == "B64-PI" then
		local p = util.Decompress(util.Base64Decode(preset))
		local pd = p:Split("\0")
		local name, data, author = pd[1], pd[2], pd[3]
		local prst = {}
		for _,v in pairs(data:Split("\2")) do
			local n = v:Split("\1")[1]
			prst[n] = v:Split("\1")[2]
			if v:Split("\1")[3] == "j" then
				prst[n] = util.JSONToTable(prst[n])
			end
			if v:Split("\1")[3] == "n" then
				prst[n] = tonumber(prst[n])
			end
			if v:Split("\1")[3] == "b" then
				prst[n] = not (prst[n] == '0')
			end
		end
		prst["CUST/Author"] = prst["CUST/Author"] or LocalPlayer():Name()
		return {name, prst}
	end
	local preset_parts = preset:Split(',')
	if type == "Extension" then
		local name, data = preset_parts[1], preset_parts[3]
		preset_parts[5] = LocalPlayer():Name()
		type = "Extension w/ Author"
	end
	if type == "Extension w/ Author" then
		local name, data, author = preset_parts[1], preset_parts[3], preset_parts[5]
		data = data:Split("/")
		preset = {["CUST/Author"] = author}
		for _, part in pairs(data) do
			local pd = part:Split(":")
			local name, value = pd[1], pd[2]
			if value == "" then
				value = (2^31-1)
			end
			if name == "Color" then
				if value ~= (2^31-1) then value = value:Split(" ") end
				name = "VISL/"..name
			end
			if name == "Cohesion" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Adhesion" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Viscosity" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Surface Tension" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Fluid Rest Distance" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Dynamic Friction" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Anisotropy Scale" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "VISL/"..name
			end
			if name == "Reflectance" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "VISL/"..name
			end
			if name == "Iterations" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PERF/"..name
			end
			if name == "Substeps" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PERF/"..name
			end

			if name == "SwimSpeed" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "SwimFriction" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "SwimBuoyancy" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "DrownTime" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "DrownParticles" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "DrownDamage" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "MultiplyParticles" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "MultiplyWalk" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			if name == "MultiplyJump" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "INTC/"..name
			end
			preset[name] = value
		end
		return {name, preset}
	end
	if type == "CustomPresets" then
		local name, data = preset_parts[1], preset_parts[2]
		data = data:Split("\\n")
		preset = {["CUST/Author"] = LocalPlayer():Name()}
		for _, part in pairs(data) do
			local pd = part:Split(":")
			local name, value = pd[1], pd[2]
			if value == "" then
				value = (2^31-1)
			end
			if name == "Color" then
				if value ~= (2^31-1) then value = value:Split(" ") end
				name = "VISL/"..name
			end
			if name == "Cohesion" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Adhesion" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Viscosity" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Surface Tension" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Fluid Rest Distance" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Dynamic Friction" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "PHYS/"..name
			end
			if name == "Anisotropy Scale" then
				if value ~= (2^31-1) then value = tonumber(value) end
				name = "VISL/"..name
			end
			preset[name] = value
		end
		return {name, preset}
	end
	return {"", {}}
end

local function presets_tab(tabs, _parameters, _visuals, _performance, _interactions)
	local tab = vgui.Create("DPanel", tabs)
	function tab:Paint() end
	tabs:AddSheet(_util.get_localised("Presets.title"), tab, "icon16/images.png").Tab.realname = "Presets"
	tab = tab:Add("GF_ScrollPanel")
	tab:Dock(FILL)

	styling.define_scrollbar(tab:GetVBar())

	local _ = tab:Add("DLabel") _:SetText(" ") _:SetFont("GWater2Title") _:Dock(TOP) _:SizeToContents()
	function _:Paint(w, h)
		draw.DrawText(_util.get_localised("Presets.titletext"), "GWater2Title", 6, 6, Color(0, 0, 0), TEXT_ALIGN_LEFT)
		draw.DrawText(_util.get_localised("Presets.titletext"), "GWater2Title", 5, 5, Color(187, 245, 255), TEXT_ALIGN_LEFT)
	end

	if not file.Exists("gwater2/presets.txt", "DATA") then file.Write("gwater2/presets.txt", util.TableToJSON(default_presets)) end
	local succ, presets = pcall(function() return util.JSONToTable(file.Read("gwater2/presets.txt")) end)
	if not succ then
		tab.help_text = tabs.help_text
		_util.make_title_label(tab, _util.get_localised("Presets.critical_fail"))
		print(presets)
		return
	end
	local local_presets = tab:Add("DPanel")
	function local_presets:Paint() end
	local_presets:Dock(TOP)
	local mk_save_btn = nil
	local function mk_selector(k, v, id)
		local selector = local_presets:Add("DButton")
		selector.id = id
		selector:Dock(TOP)
		selector:SetText(k.." ("..(v["CUST/Author"] or _util.get_localised("Presets.author_unknown"))..")")
		function selector:Paint(w, h)
			if self:IsHovered() and not self.washovered then
				self.washovered = true
				surface.PlaySound("gwater2/menu/rollover.wav")
			elseif not self:IsHovered() and self.washovered then
				self.washovered = false
			end
            if self:IsHovered() and not self:IsDown() then
            	self:SetColor(Color(0, 127, 255, 255))
            elseif self:IsDown() then
            	self:SetColor(Color(63, 190, 255, 255))
            else
                self:SetColor(Color(255, 255, 255))
            end
            styling.draw_main_background(0, 0, w, h)
        end
		function selector:DoClick()
			surface.PlaySound("gwater2/menu/confirm.wav")
			for k,v in pairs(v) do
				local section = k:sub(0, 4)
				local name = k:sub(6)
				if v == (2^31-1) then
					v = gwater2.options.parameters[name:lower():gsub(" ", "_")].default
				end

				if section == "VISL" then
					if name == "Color" then
						if not v.r or not v.g or not v.g then
							v = Color(v[1], v[2], v[3], v[4] or 255)
						end
						_visuals[name].mixer:SetColor(v)
						continue
					end
					_visuals[name].slider:SetValue(v)
				elseif section == "PHYS" then
					_parameters[name].slider:SetValue(v)
				elseif section == "PERF" then
					if _performance[name].slider then
						_performance[name].slider:SetValue(v)
					elseif _performance[name].check then
						_performance[name].check:SetValue(v)
					end
				end
			end
		end
		function selector:DoRightClick()
			surface.PlaySound("gwater2/menu/confirm.wav")
			local menu = DermaMenu()
			local clip = menu:AddSubMenu(_util.get_localised("Presets.copy"))
			clip:AddOption(_util.get_localised("Presets.copy.as_b64pi"), function()
				local data = k .. "\0"
				for k_,v_ in pairs(v) do
					local t_ = 'n'
					if istable(v_) then v_ = util.TableToJSON(v_) t_ = 'j' end
					if isbool(v_) then v_ = v_ and '1' or '0' t_ = 'b' end
					data = data .. k_ .. "\1" .. v_ .. "\1" .. t_ .. "\2"
				end
				data = data:sub(0, -1)
				SetClipboardText(util.Base64Encode(util.Compress(data)))
			end)
			clip:AddOption(_util.get_localised("Presets.copy.as_json"), function()
				SetClipboardText(util.TableToJSON({[k]=v}))
			end)
			menu:AddOption(_util.get_localised("Presets.delete"), function()
				presets[selector.id] = nil
				file.Write("gwater2/presets.txt", util.TableToJSON(presets))
				selector:Remove()
			end)
			menu:Open()
		end
		return selector
	end
	for k,v in SortedPairs(presets) do
		k2 = k:sub(5)
		mk_selector(k2, v, k)
	end
	local function mk_save_btn()
		local div = local_presets:Add("DLabel")
		div:Dock(TOP)
		div:SetText("")
		local import_preset = local_presets:Add("DButton")
		import_preset:Dock(TOP)
		import_preset:SetText(_util.get_localised("Presets.import_preset"))
		function import_preset:Paint(w, h)
			if self:IsHovered() and not self.washovered then
				self.washovered = true
				surface.PlaySound("gwater2/menu/rollover.wav")
			elseif not self:IsHovered() and self.washovered then
				self.washovered = false
			end
            if self:IsHovered() and not self:IsDown() then
            	self:SetColor(Color(0, 127, 255, 255))
            elseif self:IsDown() then
            	self:SetColor(Color(63, 190, 255, 255))
            else
                self:SetColor(Color(255, 255, 255))
            end
            styling.draw_main_background(0, 0, w, h)
        end
        function import_preset:DoClick()
			local frame = styling.create_blocking_frame(mainFrame)
			local label = frame:Add("DLabel")
			label:Dock(TOP)
			label:SetText(_util.get_localised("Presets.import.paste_here"))
			label:SetFont("GWater2Title")
			local textarea = frame:Add("DTextEntry")
			textarea:Dock(TOP)
			textarea:SetFont("GWater2Param")
			textarea:SetValue("")
			local label_detect = frame:Add("DLabel")
			label_detect:SetText("...")
			label_detect:Dock(TOP)
			label_detect:SetTall(label_detect:GetTall()*2)
			label_detect:SetFont("GWater2Param")
			
			local confirm = vgui.Create("DButton", frame)
			confirm:SetPos(260, 160)
			confirm:SetText("")
			confirm:SetSize(20, 20)
			confirm:SetImage("icon16/accept.png")
			confirm.Paint = nil
			function confirm:DoClick()
				local pd = gwater2.options.read_preset(textarea:GetValue())
				local name, preset = pd[1], pd[2]
				local_presets:GetChildren()[#local_presets:GetChildren()]:Remove()
				local_presets:GetChildren()[#local_presets:GetChildren()-1]:Remove()
				local_presets:GetChildren()[#local_presets:GetChildren()-2]:Remove()
				local m = 0
				for k,v in SortedPairs(presets) do m = tonumber(k:sub(1, 3)) end
				mk_selector(name, preset, string.format("%03d-%s", m+1, name))
				presets[string.format("%03d-%s", m+1, name)] = preset
				file.Write("gwater2/presets.txt", util.TableToJSON(presets))
				mk_save_btn()
				frame:Close()
				surface.PlaySound("gwater2/menu/select_ok.wav")
			end

			function textarea:OnChange()
				local type = gwater2.options.detect_preset_type(textarea:GetValue())
				if type == nil then
					confirm:SetEnabled(false)
					return label_detect:SetText(_util.get_localised("Presets.import.bad_data"))
				end
				confirm:SetEnabled(true)
				label_detect:SetText(_util.get_localised("Presets.import.detected", type))
			end

			local deny = vgui.Create("DButton", frame)
			deny:SetPos(110, 160)
			deny:SetText("")
			deny:SetSize(20, 20)
			deny:SetImage("icon16/cross.png")
			deny.Paint = nil
			function deny:DoClick()
				frame:Close()
				surface.PlaySound("gwater2/menu/select_deny.wav")
			end

			surface.PlaySound("gwater2/menu/confirm.wav")
		end
		local save = local_presets:Add("DButton")
		save:Dock(TOP)
		save:SetText(_util.get_localised("Presets.save"))
		function save:Paint(w, h)
			if self:IsHovered() and not self.washovered then
				self.washovered = true
				surface.PlaySound("gwater2/menu/rollover.wav")
			elseif not self:IsHovered() and self.washovered then
				self.washovered = false
			end
            if self:IsHovered() and not self:IsDown() then
            	self:SetColor(Color(0, 127, 255, 255))
            elseif self:IsDown() then
            	self:SetColor(Color(63, 190, 255, 255))
            else
                self:SetColor(Color(255, 255, 255))
            end
            styling.draw_main_background(0, 0, w, h)
        end
		function save:DoClick()
			local frame = styling.create_blocking_frame(mainFrame)
			local label = frame:Add("DLabel")
			label:Dock(TOP)
			label:SetText(_util.get_localised("Presets.save.preset_name"))
			label:SetFont("GWater2Title")
			local textarea = frame:Add("DTextEntry")
			textarea:Dock(TOP)
			textarea:SetFont("GWater2Param")
			textarea:SetValue("PresetName")
			local label = frame:Add("DLabel")
			label:Dock(TOP)
			label:SetText(_util.get_localised("Presets.save.include_params"))
			label:SetFont("GWater2Title")
			local panel = frame:Add("GF_ScrollPanel")
			panel:Dock(TOP)
			panel:SetTall(panel:GetTall()*2)
			function panel:Paint() end
			local paramlist = {}
			for name,_ in pairs(_parameters) do paramlist[#paramlist+1] = "PHYS/"..name end
			for name,_ in pairs(_visuals) do paramlist[#paramlist+1] = "VISL/"..name end
			for name,_ in pairs(_performance) do paramlist[#paramlist+1] = "PERF/"..name end
			local preset = {}
			for k,v in pairs(paramlist) do
				local check = panel:Add("DCheckBoxLabel")
				local real = ""
				if v:sub(0, 4) == "VISL" then
					real = _visuals[v:sub(6)].label:GetText()
				elseif v:sub(0, 4) == "PHYS" then
					real = _parameters[v:sub(6)].label:GetText()
				elseif v:sub(0, 4) == "PERF" then
					real = _performance[v:sub(6)].label:GetText()
				end
				check:SetText(v:sub(0, 4).."/"..real)
				check:Dock(TOP)
				function check:OnChange(val)
					if val == false then preset[v] = nil return end
					local section = v:sub(0, 4)
					local name = v:sub(6)
					if section == "VISL" then
						if _visuals[name].slider then
							preset[v] = _visuals[name].slider:GetValue()
						elseif _visuals[name].check then
							preset[v] = _visuals[name].check:GetChecked() or false
						elseif _visuals[name].mixer then
							local c = _visuals[name].mixer:GetColor()
							preset[v] = {c.r, c.g, c.b, c.a}
						end
					elseif section == "PHYS" then
						if _parameters[name].slider then
							preset[v] = _parameters[name].slider:GetValue()
						elseif _parameters[name].check then
							preset[v] = _parameters[name].check:GetChecked() or false
						elseif _parameters[name].mixer then
							local c = _parameters[name].mixer:GetColor()
							preset[v] = {c.r, c.g, c.b, c.a}
						end
					elseif section == "PERF" then
						if _performance[name].slider then
							preset[v] = _performance[name].slider:GetValue()
						elseif _performance[name].check then
							preset[v] = _performance[name].check:GetChecked() or false
						elseif _performance[name].mixer then
							local c = _performance[name].mixer:GetColor()
							preset[v] = {c.r, c.g, c.b, c.a}
						end
					end
				end
			end
			local confirm = vgui.Create("DButton", frame)
			confirm:SetPos(260, 160)
			confirm:SetText("")
			confirm:SetSize(20, 20)
			confirm:SetImage("icon16/accept.png")
			confirm.Paint = nil
			function confirm:DoClick()
				preset["CUST/Author"] = LocalPlayer():Name()
				local_presets:GetChildren()[#local_presets:GetChildren()]:Remove()
				local_presets:GetChildren()[#local_presets:GetChildren()-1]:Remove()
				local_presets:GetChildren()[#local_presets:GetChildren()-2]:Remove()
				local m = 0
				for k,v in SortedPairs(presets) do m = tonumber(k:sub(1, 3)) end
				mk_selector(textarea:GetValue(), preset, string.format("%03d-%s", m+1, textarea:GetValue()))
				presets[string.format("%03d-%s", m+1, textarea:GetValue())] = preset
				file.Write("gwater2/presets.txt", util.TableToJSON(presets))
				mk_save_btn()
				frame:Close()
				surface.PlaySound("gwater2/menu/select_ok.wav")
			end

			local deny = vgui.Create("DButton", frame)
			deny:SetPos(110, 160)
			deny:SetText("")
			deny:SetSize(20, 20)
			deny:SetImage("icon16/cross.png")
			deny.Paint = nil
			function deny:DoClick()
				frame:Close()
				surface.PlaySound("gwater2/menu/select_deny.wav")
			end

			surface.PlaySound("gwater2/menu/confirm.wav")
		end

		local_presets:SetTall(local_presets:GetChildren()[1]:GetTall() * #local_presets:GetChildren())
	end
	mk_save_btn()
	return tab
end

return {presets_tab=presets_tab}