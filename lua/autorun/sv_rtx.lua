 
if (SERVER) then
	function RTXLoadServer( ply )  
		print("[RTX Fixes] - Initalising Server") 
		
		flashlightent = ents.Create( "rtx_flashlight" ) 
		flashlightent:SetOwner(ply)
		flashlightent:Spawn() 
	end 
	hook.Add( "PlayerInitialSpawn", "RTXReadyServer", RTXLoadServer)  

end