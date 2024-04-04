-- Shitty solution to have a shadow for the player
CreateConVar( "rtx_debug_pseudoplayer", 0,  FCVAR_ARCHIVE )
AddCSLuaFile()

ENT.Type 			= "anim"
ENT.PrintName		= "Pseudoplayer"
ENT.Author			= "Xenthio"
ENT.Information		= "For firstperson self shadows and body reflections with RTX"
ENT.Category		= "RTX"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

local pseudoweapon
local pseudoplayer
local materialsset

function ENT:Initialize()
    if pseudoplayer then
        pseudoplayer:Remove()
    end
    materialsset = false
    RunConsoleCommand("r_flashlightnear", "50")

    print("[RTX Fixes] - Pseudoplayer Initialised.")
    self:SetModel(LocalPlayer():GetModel())
    self:SetParent(LocalPlayer())
    self:AddEffects( EF_BONEMERGE )
    self:SetPos(LocalPlayer():GetPos()) 

    pseudoplayer = ClientsideModel(LocalPlayer():GetModel())
    pseudoplayer:SetMoveType(MOVETYPE_NONE)
    pseudoplayer:SetParent(self)
    pseudoplayer:AddEffects( EF_BONEMERGE )

    pseudoweapon = ents.CreateClientside( "rtx_pseudoweapon" )
    pseudoweapon:Spawn() 
    pseudoweapon:SetParent(pseudoplayer)

   
    
end

-- local test = false 
function MaterialSet()
    if (!pseudoplayer) then return end
    if (materialsset) then return end
    print("hi")
    materialsset = true
    cam.Start2D()
    render.SetViewPort(0,0,512,512)
    for k, v in pairs(pseudoplayer:GetMaterials()) do
        mat = Material(v)
        tex = mat:GetTexture( "$basetexture" )
        tex:Download()
        newtex = GetRenderTarget( "pseudoplayertexture" .. k, tex:Width(), tex:Height() )
        render.ClearRenderTarget( newtex, Color( 0, 0, 0, 255 ) )
        render.PushRenderTarget( newtex )
        --render.DrawTextureToScreen( tex )

        col = Color( 0, 0, 0, 1 )
        --render.DrawQuadEasy( Vector(0,0,0), Vector(0,0,1), 1, 1, col )
        --render.SetMaterial( Material( "color" ) )
	    --render.DrawScreenQuad()
	    --render.DrawScreenQuadEx(100,100,256,256)

        --render.CopyTexture( tex, newtex )
        --render.BlurRenderTarget( newtex, 1, 1, 1 )
        render.PopRenderTarget()
        
 
        kv = {
            ["$basetexture"] = newtex:GetName(),
            ["$model"] = 1,
            ["$translucent"] = 1,
            ["$vertexalpha"] = 1,
            ["$vertexcolor"] = 1
        }
        --kv = mat:GetKeyValues()
        --kv["$basetexture"] = newtex:GetName()
        matlua = CreateMaterial( "pseudoplayermaterial" .. k, mat:GetShader(), kv )
        matlua:SetTexture( "$basetexture", newtex )
        --print("hi")
        pseudoplayer:SetSubMaterial(k, "!pseudoplayermaterial" .. k)
        --render.DrawTextureToScreen( newtex )
        
		--pseudoplayer:SetMaterial( "!pseudoplayermaterial" .. k )
    end
    cam.End2D()
end
-- local test = false 
-- hook.Add("DrawOverlay", "TEstTex", function()
    
--     if (!pseudoplayer) then return end
--     print("hi")
--     if (test) then return end
--     test = true
--     for k, v in pairs(pseudoplayer:GetMaterials()) do
--         mat = Material(v)
--         tex = mat:GetTexture( "$basetexture" )
--         tex:Download()
--         newtex = GetRenderTarget( "pseudoplayertexture" .. k, tex:Width(), tex:Height() )
--         render.ClearRenderTarget( newtex, Color( 0, 0, 0, 255 ) )
--         render.PushRenderTarget( newtex )
--         --render.DrawTextureToScreen( tex )

--         col = Color( 0, 0, 0, 1 )
--         --render.DrawQuadEasy( Vector(0,0,0), Vector(0,0,1), 1, 1, col )
--         --render.SetMaterial( Material( "color" ) )
-- 	    --render.DrawScreenQuad()
-- 	    --render.DrawScreenQuadEx(100,100,256,256)

--         --render.CopyTexture( tex, newtex )
--         --render.BlurRenderTarget( newtex, 1, 1, 1 )
--         render.PopRenderTarget()
        
 
--         kv = {
--             ["$basetexture"] = newtex:GetName(),
--             ["$model"] = 1,
--             ["$translucent"] = 1,
--             ["$vertexalpha"] = 1,
--             ["$vertexcolor"] = 1
--         }
--         --kv = mat:GetKeyValues()
--         --kv["$basetexture"] = newtex:GetName()
--         matlua = CreateMaterial( "pseudoplayermaterial" .. k, mat:GetShader(), kv )
--         matlua:SetTexture( "$basetexture", newtex )
--         --print("hi")
--         pseudoplayer:SetSubMaterial(k, "!pseudoplayermaterial" .. k)
--         --render.DrawTextureToScreen( newtex )
        
-- 		--pseudoplayer:SetMaterial( "!pseudoplayermaterial" .. k )
--     end
-- end )

function ENT:Think()
    MaterialSet()
    if not pseudoplayer or not pseudoplayer:IsValid() or pseudoplayer == nil then
        pseudoplayer = ClientsideModel(LocalPlayer():GetModel())
        pseudoplayer:SetMoveType(MOVETYPE_NONE)
        pseudoplayer:SetParent(self)
        pseudoplayer:AddEffects( EF_BONEMERGE )

        pseudoplayer:SetRenderMode(2)
        pseudoplayer:SetColor(Color(255,255,255,0))
    end
    if GetConVar( "rtx_localplayershadow" ):GetBool() == false then
        if pseudoplayer then
            pseudoplayer:Remove()
        end
        self:Remove()
    end
    if GetConVar( "rtx_localweaponshadow" ):GetBool() == false then
        if (pseudoweapon and pseudoweapon:IsValid()) then
            pseudoweapon:Remove()
        end

    else 
        if not (pseudoweapon or pseudoweapon:IsValid()) then
            pseudoweapon = ents.CreateClientside( "rtx_pseudoweapon" )
            pseudoweapon:Spawn()
        end
    end
    if LocalPlayer():Alive() then
        pseudoplayer:SetNoDraw( false )
    else
        pseudoplayer:SetNoDraw( true )
    end
    if LocalPlayer():GetObserverMode() != OBS_MODE_NONE or (LocalPlayer():GetViewEntity() != LocalPlayer()) or LocalPlayer():ShouldDrawLocalPlayer() then
        pseudoplayer:SetNoDraw( true )
    end
    if pseudoplayer:GetModel() != LocalPlayer():GetModel() then
        print("[RTX Fixes] - Pseudoplayer model changed.")
        self:RemoveEffects( EF_BONEMERGE )
        self:SetModel(LocalPlayer():GetModel())
        self:SetParent(LocalPlayer())
        self:AddEffects( EF_BONEMERGE )

        pseudoplayer:RemoveEffects( EF_BONEMERGE )
        pseudoplayer:SetModel(LocalPlayer():GetModel())
        pseudoplayer:SetParent(self)
        pseudoplayer:AddEffects( EF_BONEMERGE )
    end
    for k = 1, LocalPlayer():GetNumBodyGroups() do
        pseudoplayer:SetBodygroup(k, LocalPlayer():GetBodygroup(k))
    end
end

function ENT:OnRemove()
    RunConsoleCommand("r_flashlightnear", "4")
    pseudoplayer:Remove()
    if pseudoweapon and pseudoweapon:IsValid() then
        pseudoweapon:Remove()
    end
end
