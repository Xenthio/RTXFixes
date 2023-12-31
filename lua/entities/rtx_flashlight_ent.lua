-- Shitty solution to have a shadow for the player
CreateConVar( "rtx_allowrtxflashlight", 1,  false, false )
AddCSLuaFile()

ENT.Type 			= "anim"
ENT.PrintName		= "RTX Flashlight"
ENT.Author			= "Xenthio"
ENT.Information		= "For firstperson self shadows and body reflections with RTX"
ENT.Category		= "RTX"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false
  
function ENT:Initialize() 
    print("[RTX Fixes] - Flashlight Initialised.")
    if (SERVER) then
 
        self:SetModel("models/hunter/blocks/cube075x2x075.mdl") 
        self:SetRenderMode(2) 
        self:SetColor(Color(255,255,255,1))
        --self:PhysicsInit(SOLID_VPHYSICS)
        --SetSpawnflags( L, self:GetLightModels(), self:GetLightWorld() )  
    end

end
function ENT:Think()
 
    if self:GetOwner() then
        
 
        self:SetPos( self:GetOwner():GetPos() + self:GetOwner():GetViewOffset() + (self:GetOwner():GetAngles():Up()*32) )
        --self:SetPos(self:GetOwner():GetEyeTrace().HitPos)
 
    end
    
end

function ENT:OnRemove() 

end

function ENT:Draw()
    if self:GetOwner() then
        

        self:SetAngles( self:GetOwner():GetAngles() )
        self:SetPos( self:GetOwner():GetPos() + self:GetOwner():GetViewOffset() + (self:GetAngles():Up()*64) ) 
 
    end

	--Draw3DText( self.Entity:GetPos() + (self.Entity:GetAngles():Forward()*8), self.Entity:GetAngles(), 0.2, "hi", false )
    render.SuppressEngineLighting( true )
    render.DrawLine(self.Entity:GetPos(), self.Entity:GetPos() + (self.Entity:GetAngles():Forward()*16), color_white)
    brightness = 0
    
    if (self:GetOwner():FlashlightIsOn()) then
        brightness = 4
    end
	render.SetLocalModelLights({{
        type = MATERIAL_LIGHT_SPOT,
        dir = self:GetAngles():Forward(),
        innerAngle = 15,
        outerAngle = 60,
        color = Vector(255,255,255) * brightness,
        pos = self:GetPos() + (self:GetAngles():Forward()*16) + (self:GetAngles():Up()*-64),
        range = 512,
    }})

	-- Draw the model
	self:DrawModel()
    render.SuppressEngineLighting( false )
end

-- Draw some 3D text
local function Draw3DText( pos, ang, scale, text, flipView )
	if ( flipView ) then
		-- Flip the angle 180 degrees around the UP axis
		ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
	end

	cam.Start3D2D( pos, ang, scale )
		-- Actually draw the text. Customize this to your liking.
		draw.DrawText( text, "Default", 0, 0, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER )
	cam.End3D2D()
end

