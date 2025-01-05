if not CLIENT then return end
require("niknaks")
local lights
local stash
local model
local doshuffle = true
local showlights = CreateConVar( "rtx_lightupdater_show", 0,  FCVAR_ARCHIVE )
local updatelights = CreateConVar( "rtx_lightupdater", 1,  FCVAR_ARCHIVE )

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end
local function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end

local function MovetoPositions()
	if (updatelights:GetBool() == false) then return end
	if (lights == nil) then
		lights = NikNaks.CurrentMap:FindByClass( "light" )
		lights = TableConcat(lights, NikNaks.CurrentMap:FindByClass( "light_spot" ))
	end

	if (model == nil) then
		model = ClientsideModel("models/hunter/plates/plate.mdl")
		model:Spawn()
		model:SetRenderMode(2)
		model:SetColor(Color(255,255,255,1))
		if (showlights:GetBool()) then
			model:SetRenderMode(0)
		end
	end

	if (doshuffle) then
	stash = shuffle(lights)
	end
	for i, light in pairs(stash) do
		pos1 = stash[i].origin - (stash[i].angles:Forward() * 8)
		render.Model({model = "models/hunter/plates/plate.mdl", pos = pos1}, model) 	-- lighting
	end
end


local function RTXLightUpdater()
	MovetoPositions()
end

hook.Add( "Think", "RTXReady_PropHashFixer", RTXLightUpdater)  