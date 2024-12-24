-- Configuration
local ADDON = ADDON or {}
ADDON.Config = {
    EnableWorldRendering = true,
    EnableEntities = true,
    EnableViewmodel = false,
    EnableEffects = false,
    EnableHUD = true,
    SafeMode = true
}

-- Extended dangerous classes specifically for fire and explosions
local fireAndExplosionClasses = {
    ["env_fire"] = true,
    ["env_explosion"] = true,
    ["env_physexplosion"] = true,
    ["env_smokestack"] = true,
    ["entityflame"] = true,
    ["func_smokevolume"] = true,
    ["info_particle_system"] = true,  -- Often used for fire/explosion effects
    ["prop_physics_multiplayer"] = true, -- Often creates fire/explosion effects when damaged
}

-- Block fire and explosion effects
local function BlockFireAndExplosions()
    -- Override effect creation for fire/explosions
    local oldUtilEffect = util.Effect
    util.Effect = function(name, data)
        -- List of effects to block
        local blockedEffects = {
            "Explosion",
            "explosion",
            "explosion_trail",
            "MuzzleEffect",
            "FireProjectile",
            "fire_large",
            "fire_small",
            "fire_jet",
            "burning",
            "burning_gib",
            "rpg_explosion",
            "HelicopterMegaBomb",
            "napalm_explosion",
            "HunterDamage",
        }
        
        -- Check if effect should be blocked
        for _, effect in ipairs(blockedEffects) do
            if name:find(effect) then
                return
            end
        end
        
        return oldUtilEffect(name, data)
    end
    
    -- Block decals from explosions/fire
    local oldUtilDecal = util.Decal
    util.Decal = function(decalname, start, endpos, filter)
        if decalname:find("Scorch") or 
           decalname:find("Fire") or 
           decalname:find("Explosion") or 
           decalname:find("Burn") then
            return
        end
        return oldUtilDecal(decalname, start, endpos, filter)
    end
end

-- Enhanced entity processing for fire/explosions
hook.Add("OnEntityCreated", "BlockFireExplosionEntities", function(ent)
    if not IsValid(ent) then return end
    
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        
        local class = ent:GetClass()
        
        -- Check if entity is fire/explosion related
        if fireAndExplosionClasses[class] or 
           class:find("fire") or 
           class:find("explosion") or 
           class:find("flame") or 
           class:find("burn") then
            
            -- Disable the entity
            ent:SetNoDraw(true)
            ent:SetNotSolid(true)
            ent:SetMoveType(MOVETYPE_NONE)
            
            -- Remove after a frame
            timer.Simple(0, function()
                if IsValid(ent) then
                    ent:Remove()
                end
            end)
        end
    end)
end)

-- Block damage from explosions/fire
hook.Add("EntityTakeDamage", "BlockFireExplosionDamage", function(target, dmginfo)
    local damageType = dmginfo:GetDamageType()
    
    -- Check for explosion or fire damage
    if bit.band(damageType, DMG_BLAST) > 0 or
       bit.band(damageType, DMG_BURN) > 0 or
       bit.band(damageType, DMG_PLASMA) > 0 or
       bit.band(damageType, DMG_BLAST_SURFACE) > 0 then
        
        return true -- Block the damage
    end
end)

-- Block specific fire/explosion sounds
hook.Add("EntityEmitSound", "BlockFireExplosionSounds", function(data)
    if data.SoundName:find("explosion") or
       data.SoundName:find("blast") or
       data.SoundName:find("fire") or
       data.SoundName:find("flame") or
       data.SoundName:find("burn") then
        return false
    end
end)

-- Preserve critical render functions
local originalRenderOverride = render.RenderView
local originalRenderScene = render.RenderScene
local originalDrawHUD = _G.GAMEMODE and _G.GAMEMODE.HUDPaint

-- Only block dangerous render operations
local function SafeRenderProcessing()
    -- Restore basic rendering but maintain safety
    render.RenderView = function(viewData)
        if not viewData then return end
        return originalRenderOverride(viewData)
    end
    
    render.RenderScene = function(origin, angles, fov)
        return originalRenderScene(origin, angles, fov)
    end
    
    -- Block problematic effects
    hook.Add("RenderScreenspaceEffects", "BlockEffects", function()
        return true
    end)
end

-- Simple entity processing (keeping it minimal)
local function SelectiveEntityProcessing()
    local dangerousClasses = {
        ["env_fire"] = true,
        ["env_explosion"] = true,
        ["env_smoketrail"] = true,
        ["env_shooter"] = true,
        ["env_spark"] = true,
        ["entityflame"] = true,
        ["env_spritetrail"] = true,
        ["beam"] = true,
        ["_firesmoke"] = true,
        ["_explosionfade"] = true
    }

    hook.Add("Think", "SelectiveBlock", function()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and dangerousClasses[ent:GetClass()] then
                ent:SetNoDraw(true)
                ent:SetNotSolid(true)
                ent:SetMoveType(MOVETYPE_NONE)
            end
        end
    end)
end

-- Safe engine settings
local function ConfigureEngineSettings()
    RunConsoleCommand("r_drawworld", "1")
    RunConsoleCommand("r_drawstaticprops", "1")
    RunConsoleCommand("r_drawentities", "1")
    RunConsoleCommand("cl_drawhud", "1")
    
    -- Keep these disabled for safety
    RunConsoleCommand("r_3dsky", "0")
    RunConsoleCommand("r_shadows", "0")
    RunConsoleCommand("r_drawparticles", "0")
    RunConsoleCommand("r_drawtracers", "0")
    RunConsoleCommand("r_drawsprites", "0")
end

-- Block only dangerous effects
hook.Add("PostProcessPermitted", "BlockDangerousEffects", function(element)
    return false
end)

-- Block only particle sounds
hook.Add("EntityEmitSound", "BlockParticleSounds", function(data)
    if data.SoundName:find("particles") or 
       data.SoundName:find("explosion") or
       data.SoundName:find("fire") then
        return false
    end
end)

-- Initialize
SafeRenderProcessing()
SelectiveEntityProcessing()
ConfigureEngineSettings()
BlockFireAndExplosions()

-- Simple cleanup timer
timer.Create("SafeCleanup", 1, 0, function()
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GetClass and ent:GetClass():find("effect") then
            ent:Remove()
        end
    end
end)

-- Restore HUD rendering
hook.Add("HUDPaint", "RestoreHUD", function()
    if originalDrawHUD then
        originalDrawHUD(_G.GAMEMODE)
    end
end)