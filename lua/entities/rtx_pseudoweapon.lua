-- Shitty solution to have a shadow for the player, weapon edition wow
CreateConVar( "rtx_debug_pseudoplayer", 0, FCVAR_ARCHIVE )
AddCSLuaFile()

ENT.Type 			= "anim"
ENT.PrintName		= "Pseudoweapon"
ENT.Author			= "Xenthio"
ENT.Information		= "For firstperson self shadows and reflections with RTX"
ENT.Category		= "RTX"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

local pseudoweapon

local prevclassname = ""

function ENT:Initialize()
    if pseudoweapon then
        pseudoweapon:Remove()
    end

    weaponmodel = "models/weapons/w_pistol.mdl"
    if LocalPlayer():GetActiveWeapon():IsValid() and (LocalPlayer():GetActiveWeapon():GetWeaponWorldModel() != "") then
        weaponmodel = LocalPlayer():GetActiveWeapon():GetModel()
    end

    print("[RTX Fixes] - Pseudoweapon Initialised.")
    self:SetModel(weaponmodel)
    self:SetParent(LocalPlayer():GetActiveWeapon())
    self:AddEffects( EF_BONEMERGE ) 
    self:SetMoveType( MOVETYPE_NONE )

    pseudoweapon = ClientsideModel(weaponmodel)
    pseudoweapon:SetParent(self)
    pseudoweapon:AddEffects( EF_BONEMERGE ) 
end

function ENT:Think()
    if not pseudoweapon or not pseudoweapon:IsValid() then
        weaponmodel = "models/weapons/w_pistol.mdl"
        if LocalPlayer():GetActiveWeapon():IsValid() and (LocalPlayer():GetActiveWeapon():GetWeaponWorldModel() != "") then
            weaponmodel = LocalPlayer():GetActiveWeapon():GetModel()
        end
        pseudoweapon = ClientsideModel(weaponmodel)
        pseudoweapon:SetParent(self)
        pseudoweapon:AddEffects( EF_BONEMERGE )
        pseudoweapon:SetRenderMode(2)
        pseudoweapon:SetColor(Color(255,255,255,0))
    end
    if GetConVar( "rtx_localweaponshadow" ):GetBool() == false then
        if pseudoweapon then
            pseudoweapon:Remove()
        end
        self:Remove()
    end

    if LocalPlayer():GetActiveWeapon():IsValid() and pseudoweapon != nil and LocalPlayer():Alive() then
        pcall(function() LocalPlayer():GetActiveWeapon():DrawWorldModel() end)
        if prevclassname != LocalPlayer():GetActiveWeapon():GetClass() or LocalPlayer():GetActiveWeapon():GetModel() != self:GetModel() then
            prevclassname = LocalPlayer():GetActiveWeapon():GetClass()
            self:RemoveEffects( EF_BONEMERGE )
            self:SetModel(LocalPlayer():GetActiveWeapon():GetModel())
            self:SetParent(LocalPlayer():GetActiveWeapon():GetParent(), LocalPlayer():GetActiveWeapon():GetParentAttachment())

            --self:SetPos(LocalPlayer():GetActiveWeapon():GetPos())
            --self:SetAngles(LocalPlayer():GetActiveWeapon():GetAngles())
            --self:SetupBones()

            self:AddEffects( EF_BONEMERGE )

            pseudoweapon:RemoveEffects( EF_BONEMERGE )
            pseudoweapon:SetModel(LocalPlayer():GetActiveWeapon():GetModel())
            pseudoweapon:SetParent(self)
            pseudoweapon:AddEffects( EF_BONEMERGE )
        end
        self:SetRenderOrigin(LocalPlayer():GetActiveWeapon():GetRenderOrigin())
        self:SetRenderAngles(LocalPlayer():GetActiveWeapon():GetRenderAngles())
        self:SetModelScale(LocalPlayer():GetActiveWeapon():GetModelScale())

        pcall(function() -- Customisable Weaponry Fix.
            self:SetRenderOrigin(LocalPlayer():GetActiveWeapon().WMEnt:GetRenderOrigin())
            self:SetRenderAngles(LocalPlayer():GetActiveWeapon().WMEnt:GetRenderAngles())
        end)


        pseudoweapon:SetModelScale(LocalPlayer():GetActiveWeapon():GetModelScale())
        pseudoweapon:SetNoDraw( false )
    else
        pseudoweapon:SetNoDraw( true )
    end

    if (LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon():GetWeaponWorldModel() == "") then
        pseudoweapon:SetNoDraw( true )
    end
    if LocalPlayer():GetObserverMode() != OBS_MODE_NONE or (LocalPlayer():GetViewEntity() != LocalPlayer()) or LocalPlayer():ShouldDrawLocalPlayer() then
        pseudoweapon:SetNoDraw( true )
    end
   -- LocalPlayer():GetActiveWeapon():AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
    --LocalPlayer():GetActiveWeapon():AddEFlags(EFL_IN_SKYBOX)
    --LocalPlayer():GetActiveWeapon():RemoveEFlags(EF_NODRAW)
    --debugoverlay.Text( self:GetPos(), "hello!", 0.001)
    --debugoverlay.Text( LocalPlayer():GetActiveWeapon():GetPos(), "PlyrWepon", 0.001)
    --pseudoweapon:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
    --pseudoweapon:AddEFlags(EFL_IN_SKYBOX)
    --self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
    --self:AddEFlags(EFL_IN_SKYBOX)


end

function ENT:OnRemove()
    if pseudoweapon then
        pseudoweapon:Remove()
    end
end
-- remove on auto refresh
hook.Add("OnReloaded", "RTXOnAutoReloadPseudoplayer", function()
    if pseudoweapon then
        pseudoweapon:Remove()
    end
    ENT:Remove()
end)

