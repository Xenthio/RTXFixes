

CreateClientConVar(	"rtx_localplayershadow", 1,  true, false)
CreateClientConVar(	"rtx_localweaponshadow", 0,  true, false)
CreateClientConVar(	"rtx_disablevertexlighting", 0,  true, false) 
CreateClientConVar(	"rtx_experimental_manuallight", 0,  true, false) 
CreateClientConVar(	"rtx_experimental_lightupdater", 1,  true, false) 
CreateClientConVar(	"rtx_experimental_mightcrash_combinedlightingmode", 0,  false, false) 
require("niknaks")

--halo.Add = function() end
 
local flashlightent
local PrevCombinedLightingMode = false
if (CLIENT) then
	function RTXLoad()  
		print("[RTX Fixes] - Initalising Client")
		RunConsoleCommand("r_radiosity", "0")
		RunConsoleCommand("r_PhysPropStaticLighting", "0")
		RunConsoleCommand("r_colorstaticprops", "0")
		RunConsoleCommand("mat_fullbright", GetConVar( "rtx_experimental_manuallight" ):GetBool())
		

		pseudoply = ents.CreateClientside( "rtx_pseudoplayer" ) 
		
		-- the definition of insanity
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end  
		if (GetConVar( "rtx_experimental_lightupdater" ):GetBool()) then local b = ents.CreateClientside( "rtx_lightupdater" ) b:Spawn() end   
		pseudoply:Spawn() 
	end 
	
	function PreRender()   
		render.SuppressEngineLighting( GetConVar( "rtx_disablevertexlighting" ):GetBool() || GetConVar( "rtx_experimental_manuallight" ):GetBool())  
		if (GetConVar( "rtx_experimental_mightcrash_combinedlightingmode" ):GetBool()) then 
			render.SuppressEngineLighting(false)
		end   
		if (GetConVar( "rtx_experimental_manuallight" ):GetBool()) then DoCustomLights() end  
		--PrintTable(stash[1])
	end 
	function PreRenderOpaque()  
		if (GetConVar( "rtx_experimental_manuallight" ):GetBool()) then DoCustomLights() end 
	end 
	function RTXPreRenderTranslucent()  
		if (GetConVar( "rtx_experimental_manuallight" ):GetBool()) then DoCustomLights() end 
	end 
	 
	hook.Add( "InitPostEntity", "RTXReady", RTXLoad)  
	hook.Add( "PreRender", "RTXPreRender", PreRender) 
	hook.Add( "PreDrawOpaqueRenderables", "RTXPreRenderOpaque", PreRenderOpaque) 
	hook.Add( "PreDrawTranslucentRenderables", "RTXPreRenderTranslucent", RTXPreRenderTranslucent) 
end


function values(t)
	local i = 0
	return function() i = i + 1; return t[i] end
end
function shuffle(tbl)
	for i = #tbl, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end
function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end
function mysplit (inputstr, sep)
	if sep == nil then
			sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
	end
	return t
end

function convertlight(v) 
	if (!v) then return end
	local lighttype = MATERIAL_LIGHT_DISABLE
	if (v.classname == "point_spotlight")  then return end

	-- spawnflag 1 means the light will start off
	if (v.spawnflags == 1)  then return end

	if (v.classname == "light")  then lighttype = MATERIAL_LIGHT_POINT end
	if (v.classname == "light_environment")  then lighttype = MATERIAL_LIGHT_DIRECTIONAL end
	if (v.classname == "light_spot")  then lighttype = MATERIAL_LIGHT_SPOT end
	if (v.classname == "light_dynamic")  then lighttype = MATERIAL_LIGHT_POINT end

	local lightcolour = Vector(0,0,0)
	if (v._light) then
		local splitcolour = mysplit(v._light)
		local r1 = tonumber(splitcolour[1])
		local g1 = tonumber(splitcolour[2])
		local b1 = tonumber(splitcolour[3])
		local a1 = tonumber(splitcolour[4])
		if (!a1) then a1 = 200 end
		-- /60000 looks about right lol
		lightcolour = Vector( r1, g1, b1  ) * (a1/60000) 
	end 
	local newlight = {}
	newlight.type = lighttype
	newlight.color = lightcolour
	newlight.pos = v.origin
	newlight.innerAngle = v._inner_cone
	newlight.outerAngle = v._cone
	newlight.angularFalloff = v._exponent
	newlight.quadraticFalloff = v._quadratic_attn
	newlight.linearFalloff = v._linear_attn
	newlight.constantFalloff = v._constant_attn
	if (v._fifty_percent_distance && v._fifty_percent_distance > 0) then newlight.fiftyPercentDistance = v._fifty_percent_distance end
	if (v._zero_percent_distance && v._zero_percent_distance > 0) then newlight.zeroPercentDistance = v._zero_percent_distance end
	
	
	if (!v.pitch) then newlight.dir = Angle( -90, v.angles.yaw, v.angles.roll ):Forward() else
	newlight.dir = Angle( v.pitch * -1, v.angles.yaw, v.angles.roll ):Forward() end
 
	if (v.classname == "light_environment")  then newlight.dir = Angle( v.pitch * -1, v.angles.yaw, v.angles.roll ):Forward()  end
	if (v.classname == "light_environment")  then newlight.pos = Vector(0,0,0) end

	newlight.range = v.distance
	if (!newlight.range || newlight.range <= 0) then newlight.range = 512 end
	if (!newlight.innerAngle) then newlight.innerAngle = 30 end
	if (!newlight.outerAngle) then newlight.outerAngle = 45 end 

	if (newlight.innerAngle) then newlight.innerAngle = newlight.innerAngle * 2 end
	if (newlight.outerAngle) then newlight.outerAngle = newlight.outerAngle * 2 end 
	if (v.classname == "light_environment")  then
		--print(v.pitch)
		--print(v.angles)
		--PrintTable(v);
	end
	--if (v.targetname) then
		--local realents = ents.GetAll()
		--print(realents])
		--PrintTable(realents)
	--end
	--print(type(v._cone))
	--PrintTable(v);
	return newlight
end

function DoCustomLights() 
	render.ResetModelLighting(0,0,0) 
	--PrintTable(NikNaks.CurrentMap:GetEntities());
	--for value in values(NikNaks.CurrentMap:GetEntities()) do
		--print(value.classname.."\n"..tostring(value.origin))
	--end
	lights = NikNaks.CurrentMap:FindByClass( "light" )
	lights = TableConcat(lights,NikNaks.CurrentMap:FindByClass( "light_spot" ))
	lights = TableConcat(lights,NikNaks.CurrentMap:FindByClass( "light_environment" ))
	stash = shuffle(lights)
	render.SetLocalModelLights({
		convertlight(stash[1]),
		convertlight(stash[2]),
		convertlight(stash[3]),
		convertlight(stash[4]),  
	}) 
end
