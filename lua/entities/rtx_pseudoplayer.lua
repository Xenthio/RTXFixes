-- Shitty solution to have a shadow for the player
CreateConVar( "rtx_debug_pseudoplayer", 0,  FCVAR_ARCHIVE ) 
CreateClientConVar(	"rtx_pseudoplayer_unique_hashes", 0,  true, false)
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
    pseudoplayer.RenderOverride = PseudoplayerRender

    pseudoweapon = ents.CreateClientside( "rtx_pseudoweapon" )
    pseudoweapon:Spawn() 
    pseudoweapon:SetParent(pseudoplayer)
    
end

local materialtable = {}
local materialsset = false

function PseudoplayerRender(self) 
    

    if (!materialtable) then return end
    if (!GetConVar( "rtx_pseudoplayer_unique_hashes" ):GetBool()) then 
        render.ModelMaterialOverride(nil,nil)
        render.SuppressEngineLighting( true )
        self:DrawModel()
        render.SuppressEngineLighting( false )
        return
    else
        --render.MaterialOverride(nil)
        for k, v in pairs(materialtable) do
    
            --print(k)
            --self:SetSubMaterial(k, "!pseudoplayermaterial" .. k)
            render.MaterialOverrideByIndex( k-1, v ) 
            --render.ModelMaterialOverride( Material("!pseudoplayermaterial" .. k))
        end
        render.SuppressEngineLighting( true )
        self:DrawModel()
        render.SuppressEngineLighting( false )
        render.ModelMaterialOverride(nil,nil)
    end 
    
end

-- local test = false 
local function MaterialSet()
    if (!pseudoplayer) then return end
    if (materialsset) then return end
    pseudoplayer.RenderOverride = PseudoplayerRender
    materialsset = true
    for k, v in pairs(pseudoplayer:GetMaterials()) do
        local mat = Material(v)
        local tex = mat:GetTexture( "$basetexture" )   
 

        local matblank = CreateMaterial( "pseudoplayermaterialtemp" .. k, "UnlitGeneric", {
            ["$basetexture"] = "color/white",
            ["$model"] = 1,
            ["$translucent"] = 0,
            ["$vertexalpha"] = 0,
            ["$vertexcolor"] = 0,  
        } )
        local matblankalpha = CreateMaterial( "pseudoplayermaterialtempalpha" .. k, "UnlitGeneric", {
            ["$basetexture"] = "color/white",
            ["$model"] = 1,
            ["$translucent"] = 1,
            ["$vertexalpha"] = 0,
            ["$vertexcolor"] = 0,  
        } )
        matblank:SetTexture( "$basetexture", tex )
        matblankalpha:SetTexture( "$basetexture", tex )
        
        local newtex = GetRenderTargetEx( "pseudoplayertexture" .. k, tex:Width(), tex:Height(), RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 0, 0, IMAGE_FORMAT_RGBA8888 ) 
        render.PushRenderTarget( newtex )
            cam.Start2D()
                render.OverrideAlphaWriteEnable( true, true )
                render.SetWriteDepthToDestAlpha( false )
                --render.SuppressEngineLighting( true )
                render.ClearDepth()
                render.Clear( 0, 0, 0, 0 )

                render.SetMaterial( matblank )
	            render.DrawScreenQuad() 
                render.SetMaterial( matblankalpha )
	            render.DrawScreenQuad() 

                local texturedQuadStructure = {
                    texture = surface.GetTextureID( "vgui/gradv" ),
                    color   = Color( 255, 255, 255, 50 ),
                    x 	= 0,
                    y 	= 0,
                    w 	= 1,
                    h 	= 1
                }
                
                draw.TexturedQuad( texturedQuadStructure )
                 
                --render.SuppressEngineLighting( false )
                render.OverrideAlphaWriteEnable( false )
            cam.End2D()
             
            local data = render.Capture({
                format = "png",
                x = 0, 
                y = 0, 
                h = tex:Height(), 
                w = tex:Width(),
                alpha = true
            })
            local pictureFile = file.Open( "pseudoplayertexture" .. k .. ".png", "wb", "DATA" )	
            pictureFile:Write( data )
            pictureFile:Close() 
        render.PopRenderTarget()

        local kv = mat:GetKeyValues()
        --kv["$basetexture"] = newtex:GetName()
        --matlua = CreateMaterial( "pseudoplayermaterial" .. k, mat:GetShader(), kv )
        local matimg = Material( "data/pseudoplayertexture" .. k .. ".png", "smooth vertexlitgeneric")
        local matlua = CreateMaterial( "pseudoplayermaterial" .. k, mat:GetShader(), kv )
        --matlua:SetTexture( "$basetexture", newtex )
        local newertex = matimg:GetTexture( "$basetexture" )
        matlua:SetTexture( "$basetexture", newertex)
        materialtable[k] = matlua
    end
end

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
        if (!pseudoweapon or !pseudoweapon:IsValid()) then
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
        
        MaterialSet()
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
-- remove on auto refresh
hook.Add("OnReloaded", "RTXOnAutoReloadPseudoplayer", function()
    ENT:Remove()
end)

