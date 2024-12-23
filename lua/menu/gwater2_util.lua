AddCSLuaFile()

if SERVER or not gwater2 then return end

gwater2.cursor_busy = nil

local function get_localised(loc, ...)
	return language.GetPhrase("gwater2.menu."..loc):gsub("^%s+", ""):format(...)
end

local function is_hovered_any(panel)
	if panel:IsHovered() then return true end
	for k,v in pairs(panel:GetChildren()) do
		if v.IsEditing and v:IsEditing() then
			return true
		end
		if v.IsDown and v:IsDown() then
			return true
		end
		if is_hovered_any(v) then
			return true
		end
	end
	return false
end

local function set_gwater_parameter(option, val)
	local parsed = false

	local rval = val

	if type(val) == "table" and val[5] == "COLOR" and not parsed then
		val = Color(val[1], val[2], val[3], val[4])
		parsed = true
	end
	if IsColor(val) and not parsed then
		val = val:ToTable()
		val[5] = "COLOR"
		parsed = true
	end

	gwater2.ChangeParameter(option, val)

	val = rval

	gwater2.options.parameters[option].real = val

	if gwater2.options.initialised[option][1].type == "scratch" or
		gwater2.options.initialised[option][1].type == "check" then
		gwater2.options.initialised[option][2].block = true
		gwater2.options.initialised[option][2]:SetValue(val)
		gwater2.options.initialised[option][2].block = false
	end

	if gwater2.options.initialised[option][1].type == "color" then
		gwater2.options.initialised[option][2].block = true
		gwater2.options.initialised[option][2]:SetColor(val)
		gwater2.options.initialised[option][2].block = false
	end

	if gwater2.options.initialised[option][1].func then
		if gwater2.options.initialised[option][1].func(val) then return end
	end

	if gwater2.options.parameters[option].defined then
		gwater2.options.parameters[option].val = val
		gwater2.options.parameters[option].func()
		return
	end

	-- nondirect options (eg. parameter scales based on radius)
	if gwater2[option] then
		gwater2[option] = val
		if option == "surface_tension" then	-- hack hack hack! this parameter scales based on radius
			local r1 = val / gwater2.solver:GetParameter("radius")^4	-- cant think of a name for this variable rn
			local r2 = val / math.min(gwater2.solver:GetParameter("radius"), 15)^4
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r2)
		elseif option == "fluid_rest_distance" or option == "collision_distance" then -- hack hack hack! this parameter scales based on radius
			local r1 = val * gwater2.solver:GetParameter("radius")
			local r2 = val * math.min(gwater2.solver:GetParameter("radius"), 15)
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r2)
		elseif option == "cohesion" then	-- also scales by radius
			local r1 = math.min(val / gwater2.solver:GetParameter("radius") * 10, 1)
			gwater2.solver:SetParameter(option, r1)
			gwater2.options.solver:SetParameter(option, r1)
		end
		return
	end

	gwater2.solver:SetParameter(option, val)

	if option == "gravity" then val = -val end	-- hack hack hack! y coordinate is considered down in screenspace!
	if option == "radius" then 					-- hack hack hack! radius needs to edit multiple parameters!
		gwater2.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)	-- literally no idea why this is a power of 4
		gwater2.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		gwater2.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
		gwater2.solver:SetParameter("cohesion", math.min(gwater2["cohesion"] / val * 10, 1))
		
		if val > 15 then val = 15 end	-- explody
		gwater2.options.solver:SetParameter("surface_tension", gwater2["surface_tension"] / val^4)
		gwater2.options.solver:SetParameter("fluid_rest_distance", val * gwater2["fluid_rest_distance"])
		gwater2.options.solver:SetParameter("collision_distance", val * gwater2["collision_distance"])
		gwater2.options.solver:SetParameter("cohesion", math.min(gwater2["cohesion"] / val * 10, 1))
	end

	if option ~= "diffuse_threshold" and option ~= "dynamic_friction" then -- hack hack hack! fluid preview doesn't use diffuse particles
		gwater2.options.solver:SetParameter(option, val)
	end
end

local function make_title_label(tab, txt)
	local label = tab:Add("DLabel")
	label:SetText(txt)
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Title")
	label:Dock(TOP)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local defhelptext = nil
	function label:Paint()
		if gwater2.cursor_busy ~= label and gwater2.cursor_busy ~= nil then return end
		local hovered = label:IsHovered()
		if hovered and not label.washovered then
			defhelptext = tab.help_text:GetText()
			label.washovered = true
			gwater2.cursor_busy = label
			tab.help_text:SetText(txt)
			if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(Color(187, 245, 255))
		elseif not label:IsHovered() and label.washovered then
			gwater2.cursor_busy = nil
			label.washovered = false
			if tab.help_text:GetText() == txt then
				tab.help_text:SetText(defhelptext)
			end
			self:SetColor(Color(255, 255, 255))
		end
	end
	return label
end
local function make_parameter_scratch(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local slider = panel:Add("DNumSlider")
	slider:SetMinMax(parameter.min, parameter.max)
	pcall(function()
		local parameter_name = string.lower(parameter_name):gsub(" ", "_")
		if gwater2.options.parameters[parameter_name] and gwater2.options.parameters[parameter_name].defined then
			slider:SetValue(gwater2.options.parameters[parameter_name].val)
			return
		end
		slider:SetValue(gwater2[parameter_name] or gwater2.solver:GetParameter(parameter_name))
	end) -- if we can't get parameter, let's hope .setup() does that for us
	slider:SetDecimals(parameter.decimals)
	local button = panel:Add("DButton")
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())
	button.Paint = nil
	panel.label = label
	panel.slider = slider
	panel.button = button
	label:Dock(LEFT)
	button:Dock(RIGHT)
	slider:Dock(FILL)
	slider.Label:Hide()
	slider.TextArea:SizeToContents()
	if parameter.setup then parameter.setup(slider) end
	gwater2.options.initialised[string.lower(parameter_name):gsub(" ", "_")] = {parameter, slider}
	function button:DoClick()
		slider:SetValue(gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].default)
		if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function slider:OnValueChanged(val)
		if slider.block then return end
		if parameter.decimals == 0 and val ~= math.Round(val, parameter.decimals) then
			self:SetValue(math.Round(val, parameter.decimals))
			return
		end
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].real = val
		set_gwater_parameter(string.lower(parameter_name):gsub(" ", "_"), val)
	end
	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then  LocalPlayer():EmitSound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(Color(255, 255, 255))
		end
	end
	if not gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] then
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] = {real=slider:GetValue(), default=slider:GetValue()}
	end
	panel:SetTall(panel:GetTall()+2)
	return panel
end
local function make_parameter_color(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:Dock(LEFT)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local mixer = panel:Add("DColorMixer")
	mixer:Dock(FILL)
	mixer:DockPadding(5, 0, 5, 0)
	panel:SetTall(110)
	mixer:SetPalette(false)
	mixer:SetLabel()
	mixer:SetAlphaBar(true)
	mixer:SetWangs(true)
	mixer:SetColor(gwater2.options.parameters.color.real) 
	local button = panel:Add("DButton")
	button:Dock(RIGHT)
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())
	button.Paint = nil
	panel:SizeToContents()
	panel.button = button
	panel.mixer = mixer
	panel.label = label

	if parameter.setup then parameter.setup(mixer) end
	gwater2.options.initialised[string.lower(parameter_name):gsub(" ", "_")] = {parameter, mixer}
	function button:DoClick()
		mixer:SetColor(gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].default)
		if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function mixer:ValueChanged(val)
		if mixer.block then return end
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].real = val
		set_gwater_parameter(string.lower(parameter_name):gsub(" ", "_"), Color(val.r, val.g, val.b, val.a))
	end

	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(Color(255, 255, 255))
		end
	end
	panel:SetTall(panel:GetTall()+5)
	if not gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] then
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] = {real=mixer:GetValue(), default=mixer:GetValue()}
	end
	return panel
end
local function make_parameter_check(tab, locale_parameter_name, parameter_name, parameter)
	local panel = tab:Add("DPanel")
	function panel:Paint() end
	panel:Dock(TOP)
	local label = panel:Add("DLabel")
	label:SetText(get_localised(locale_parameter_name))
	label:SetColor(Color(255, 255, 255))
	label:SetFont("GWater2Param")
	label:Dock(LEFT)
	label:SetMouseInputEnabled(true)
	label:SizeToContents()
	local check = panel:Add("DCheckBoxLabel")
	local button = panel:Add("DButton")
	button:Dock(RIGHT)
	check:Dock(FILL)
	check:DockMargin(5, 0, 5, 0)
	check:SetText("")
	button:SetText("")
	button:SetImage("icon16/arrow_refresh.png")
	button:SetWide(button:GetTall())
	button.Paint = nil
	panel.label = label
	panel.check = check
	panel.button = button
	if parameter.setup then parameter.setup(check) end
	gwater2.options.initialised[string.lower(parameter_name):gsub(" ", "_")] = {parameter, check}
	function button:DoClick()
		check:SetValue(gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].default)
		if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/reset.wav", 75, 100, 1, CHAN_STATIC) end
	end
	function check:OnChange(val)
		if check.block then return end
		if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/toggle.wav", 75, 100, 1, CHAN_STATIC) end
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")].real = val
		if parameter.func then if parameter.func(val) then return end end
		set_gwater_parameter(string.lower(parameter_name):gsub(" ", "_"), val)
	end
	local defhelptext = nil
	function panel:Paint()
		if gwater2.cursor_busy ~= panel and gwater2.cursor_busy ~= nil and IsValid(gwater2.cursor_busy) then return end
		local hovered = is_hovered_any(panel)
		if hovered and not panel.washovered then
			defhelptext = tab.help_text:GetText()
			panel.washovered = true
			gwater2.cursor_busy = panel
			tab.help_text:SetText(get_localised(locale_parameter_name..".desc"))
			if gwater2.options.read_config().sounds then LocalPlayer():EmitSound("gwater2/menu/rollover.wav", 75, 100, 1, CHAN_STATIC) end
			label:SetColor(Color(187, 245, 255))
		elseif not hovered and panel.washovered then
			panel.washovered = false
			gwater2.cursor_busy = nil
			if tab.help_text:GetText() == get_localised(locale_parameter_name..".desc") then
				tab.help_text:SetText(defhelptext)
			end
			label:SetColor(Color(255, 255, 255))
		end
	end
	panel:SetTall(panel:GetTall()+5)
	if not gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] then
		gwater2.options.parameters[string.lower(parameter_name):gsub(" ", "_")] = {real=check:GetValue(), default=check:GetValue()}
	end
	return panel
end

return {
	make_title_label=make_title_label,
	make_parameter_check=make_parameter_check,
	make_parameter_color=make_parameter_color,
	make_parameter_scratch=make_parameter_scratch,
	set_gwater_parameter=set_gwater_parameter,
	get_localised=get_localised
}