
AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )

ENT.PrintName = "RTXPhysics"
ENT.Editable = true

-- Custom drive mode
function ENT:GetEntityDriveMode()

	return "drive_noclip"

end

function ENT:Initialize()

	self:SetModel("models/props_junk/wood_crate001a.mdl")
	if ( SERVER ) then

		self:PhysicsInit( SOLID_VPHYSICS )
		self:DrawShadow( false )

		local phys = self:GetPhysicsObject()
		if ( IsValid( phys ) ) then phys:Wake() end

	end

end

if ( SERVER ) then

	function ENT:Think()

		self.BaseClass.Think( self )

	end

	function ENT:OnTakeDamage( dmginfo )

		self:TakePhysicsDamage( dmginfo )

	end

	function ENT:OnSwitch( bOn )

		if ( bOn && IsValid( self.flashlight ) ) then return end

		if ( !bOn ) then

			--SafeRemoveEntity( self.flashlight )
			--self.flashlight = nil
			return

		end

		--self.flashlight = ents.Create( "env_projectedtexture" )
		--self.flashlight:SetParent( self )

		-- The local positions are the offsets from parent..
		--self.flashlight:SetLocalPos( vector_origin )
		--self.flashlight:SetLocalAngles( angle_zero )

		--self.flashlight:SetKeyValue( "enableshadows", 1 )
		--self.flashlight:SetKeyValue( "nearz", 12 )
		--self.flashlight:SetKeyValue( "lightfov", math.Clamp( self:GetLightFOV(), 10, 170 ) )

		local dist = self:GetDistance()
		if ( !game.SinglePlayer() ) then dist = math.Clamp( dist, 64, 2048 ) end
		--self.flashlight:SetKeyValue( "farz", dist )

		local c = self:GetColor()
		local b = self:GetBrightness()
		if ( !game.SinglePlayer() ) then b = math.Clamp( b, 0, 8 ) end
		--self.flashlight:SetKeyValue( "lightcolor", Format( "%i %i %i 255", c.r * b, c.g * b, c.b * b ) )

		--self.flashlight:Spawn()

		--self.flashlight:Input( "SpotlightTexture", NULL, NULL, self:GetFlashlightTexture() )

	end
end

function ENT:Draw()

	self:DrawModel(STUDIO_RENDER + STUDIO_STATIC_LIGHTING)

end
