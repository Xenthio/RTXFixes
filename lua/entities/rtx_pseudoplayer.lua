-- Shitty solution to have a shadow for the player
CreateConVar( "rtx_debug_pseudoplayer", 0,  false, false )
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

function ENT:Initialize()
    if pseudoplayer then
        pseudoplayer:Remove()
    end
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
function ENT:Think()
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
