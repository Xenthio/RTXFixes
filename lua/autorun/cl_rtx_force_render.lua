if not CLIENT then return end

-- ConVars
local CONVARS = {
    ENABLED = CreateClientConVar("rtx_force_render", "1", true, false, "Forces custom mesh rendering of map"),
    DEBUG = CreateClientConVar("rtx_force_render_debug", "0", true, false, "Shows debug info for mesh rendering"),
    CHUNK_SIZE = CreateClientConVar("rtx_chunk_size", "512", true, false, "Size of chunks for mesh combining")
}

-- Local Variables
local mapMeshes = {}
local isEnabled = false
local renderStats = {draws = 0}
local materialCache = {}

-- Utility Functions
local function IsSkyboxFace(face)
    if not face then return false end
    
    local material = face:GetMaterial()
    if not material then return false end
    
    local matName = material:GetName():lower()
    
    return matName:find("tools/toolsskybox") or
           matName:find("skybox/") or
           matName:find("sky_") or
           false
end

local function GetChunkKey(x, y, z)
    return string.format("%d,%d,%d", x, y, z)
end

local function CalculateFaceVertexCount(face)
    local verts = face:GenerateVertexTriangleData()
    return verts and #verts or 0
end

-- Mesh Creation Functions
local function CreateChunkMeshGroup(faces, material)
    if not faces or #faces == 0 or not material then return nil end

    local MAX_VERTICES = 10000
    local meshGroups = {}
    
    -- Collect vertex data
    local allVertices = {}
    local totalVertices = 0
    
    for _, face in ipairs(faces) do
        local verts = face:GenerateVertexTriangleData()
        if verts then
            for _, vert in ipairs(verts) do
                if vert.pos and vert.normal then
                    totalVertices = totalVertices + 1
                    table.insert(allVertices, vert)
                end
            end
        end
    end
    
    if CONVARS.DEBUG:GetBool() then
        print(string.format("[RTX Fixes] Processing chunk with %d total vertices", totalVertices))
    end
    
    -- Calculate mesh distribution
    local meshCount = math.ceil(totalVertices / MAX_VERTICES)
    local vertsPerMesh = math.floor(totalVertices / meshCount)
    
    if CONVARS.DEBUG:GetBool() then
        print(string.format("[RTX Fixes] Splitting into %d meshes with ~%d vertices each", 
            meshCount, vertsPerMesh))
    end
    
    -- Create mesh batches
    local vertexIndex = 1
    while vertexIndex <= #allVertices do
        local remainingVerts = #allVertices - vertexIndex + 1
        local vertsThisMesh = math.min(MAX_VERTICES, remainingVerts)
        
        if vertsThisMesh > 0 then
            if CONVARS.DEBUG:GetBool() then
                print(string.format("[RTX Fixes] Creating mesh with %d vertices", vertsThisMesh))
            end
            
            if vertsThisMesh > 32000 then
                print(string.format("[RTX Fixes] ERROR: Tried to create mesh with too many vertices (%d)", 
                    vertsThisMesh))
                vertexIndex = vertexIndex + vertsThisMesh
                continue
            end
            
            local newMesh = Mesh(material)
            mesh.Begin(newMesh, MATERIAL_TRIANGLES, vertsThisMesh)
            
            for i = 0, vertsThisMesh - 1 do
                local vert = allVertices[vertexIndex + i]
                mesh.Position(vert.pos)
                mesh.Normal(vert.normal)
                mesh.TexCoord(0, vert.u or 0, vert.v or 0)
                mesh.AdvanceVertex()
            end
            
            mesh.End()
            table.insert(meshGroups, newMesh)
        end
        
        vertexIndex = vertexIndex + vertsThisMesh
    end
    
    if CONVARS.DEBUG:GetBool() then
        print(string.format("[RTX Fixes] Successfully created %d meshes", #meshGroups))
    end
    
    return meshGroups
end

-- Main Mesh Building Function
local function BuildMapMeshes()
    mapMeshes = {}
    materialCache = {}
    
    if not NikNaks or not NikNaks.CurrentMap then return end

    print("[RTX Fixes] Building chunked meshes...")
    local startTime = SysTime()
    local totalVertCount = 0
    
    local chunkSize = CONVARS.CHUNK_SIZE:GetInt()
    local chunks = {
        opaque = {},
        translucent = {}
    }
    
    -- Sort faces into chunks
    for _, leaf in pairs(NikNaks.CurrentMap:GetLeafs()) do  
        if not leaf or leaf:IsOutsideMap() then continue end
        
        local leafFaces = leaf:GetFaces(true)
        if not leafFaces then continue end

        for _, face in pairs(leafFaces) do
            if not face or not face:ShouldRender() or IsSkyboxFace(face) then continue end
            
            local vertices = face:GetVertexs()
            if not vertices or #vertices == 0 then continue end
            
            -- Calculate face center
            local center = Vector(0, 0, 0)
            for _, vert in ipairs(vertices) do
                if not vert then continue end
                center = center + vert
            end
            center = center / #vertices
            
            -- Get chunk coordinates
            local chunkX = math.floor(center.x / chunkSize)
            local chunkY = math.floor(center.y / chunkSize)
            local chunkZ = math.floor(center.z / chunkSize)
            local chunkKey = GetChunkKey(chunkX, chunkY, chunkZ)
            
            local material = face:GetMaterial()
            if not material then continue end
            
            local matName = material:GetName()
            if not matName then continue end
            
            -- Cache material
            if not materialCache[matName] then
                materialCache[matName] = material
            end
            
            -- Sort into appropriate chunk group
            local isTranslucent = face:IsTranslucent()
            local chunkGroup = isTranslucent and chunks.translucent or chunks.opaque
            
            chunkGroup[chunkKey] = chunkGroup[chunkKey] or {}
            chunkGroup[chunkKey][matName] = chunkGroup[chunkKey][matName] or {
                material = materialCache[matName],
                faces = {},
                isTranslucent = isTranslucent
            }
            
            table.insert(chunkGroup[chunkKey][matName].faces, face)
        end
    end
    
    -- Create combined meshes
    mapMeshes = {
        opaque = {},
        translucent = {}
    }
    
    for renderType, chunkGroup in pairs(chunks) do
        for chunkKey, materials in pairs(chunkGroup) do
            mapMeshes[renderType][chunkKey] = {}
            for matName, group in pairs(materials) do
                if group.faces and #group.faces > 0 then
                    local meshes = CreateChunkMeshGroup(group.faces, group.material)
                    if meshes then
                        for _, face in ipairs(group.faces) do
                            local verts = face:GenerateVertexTriangleData()
                            if verts then
                                totalVertCount = totalVertCount + #verts
                            end
                        end
                        
                        mapMeshes[renderType][chunkKey][matName] = {
                            meshes = meshes,
                            material = group.material
                        }
                    end
                end
            end
        end
    end

    print(string.format("[RTX Fixes] Built chunked meshes in %.2f seconds", SysTime() - startTime))
    print(string.format("[RTX Fixes] Total vertex count: %d", totalVertCount))
end

-- Rendering Functions
local function RenderCustomWorld(translucent)
    if not isEnabled then return end

    renderStats.draws = 0

    if translucent then
        render.SetBlend(1)
        render.OverrideDepthEnable(true, true)
    end

    local groups = translucent and mapMeshes.translucent or mapMeshes.opaque
    local currentMaterial = nil
    
    for _, chunkMaterials in pairs(groups) do
        for _, group in pairs(chunkMaterials) do
            if currentMaterial ~= group.material then
                render.SetMaterial(group.material)
                currentMaterial = group.material
            end
            for _, mesh in ipairs(group.meshes) do
                mesh:Draw()
                renderStats.draws = renderStats.draws + 1
            end
        end
    end

    if translucent then
        render.OverrideDepthEnable(false)
    end

    if CONVARS.DEBUG:GetBool() then
        print(string.format("[RTX Fixes] Rendering: %d %s draws", 
            renderStats.draws,
            translucent and "translucent" or "opaque"))
    end
end

-- Enable/Disable Functions
local function EnableCustomRendering()
    if isEnabled then return end
    isEnabled = true

    RunConsoleCommand("r_drawworld", "0")
    
    hook.Add("PreDrawOpaqueRenderables", "RTXCustomWorld", function()
        RenderCustomWorld(false)
    end)
    
    hook.Add("PreDrawTranslucentRenderables", "RTXCustomWorld", function()
        RenderCustomWorld(true)
    end)
end

local function DisableCustomRendering()
    if not isEnabled then return end
    isEnabled = false

    RunConsoleCommand("r_drawworld", "1")
    
    hook.Remove("PreDrawOpaqueRenderables", "RTXCustomWorld")
    hook.Remove("PreDrawTranslucentRenderables", "RTXCustomWorld")
end

-- Initialization and Cleanup
local function Initialize()
    BuildMapMeshes()
    
    timer.Simple(1, function()
        if CONVARS.ENABLED:GetBool() then
            EnableCustomRendering()
        end
    end)
end

-- Hooks
hook.Add("InitPostEntity", "RTXMeshInit", Initialize)

hook.Add("PostCleanupMap", "RTXMeshRebuild", Initialize)

hook.Add("PreDrawParticles", "ParticleSkipper", function()
    return true
end)

hook.Add("ShutDown", "RTXCustomWorld", function()
    DisableCustomRendering()
    for _, chunkMaterials in pairs(mapMeshes) do
        for _, group in pairs(chunkMaterials) do
            for _, mesh in ipairs(group.meshes) do
                if mesh.Destroy then
                    mesh:Destroy()
                end
            end
        end
    end
    mapMeshes = {}
    materialCache = {}
end)

-- ConVar Changes
cvars.AddChangeCallback("rtx_force_render", function(_, _, new)
    if tobool(new) then
        EnableCustomRendering()
    else
        DisableCustomRendering()
    end
end)

-- Menu
hook.Add("PopulateToolMenu", "RTXCustomWorldMenu", function()
    spawnmenu.AddToolMenuOption("Utilities", "User", "RTX_ForceRender", "#RTX Custom World", "", "", function(panel)
        panel:ClearControls()
        
        panel:CheckBox("Enable Custom World Rendering", "rtx_force_render")
        panel:ControlHelp("Renders the world using chunked meshes")
        
        panel:NumSlider("Chunk Size", "rtx_chunk_size", 4, 8196, 0)
        panel:ControlHelp("Size of chunks for mesh combining. Larger = better performance but more memory")
        
        panel:CheckBox("Show Debug Info", "rtx_force_render_debug")
        
        panel:Button("Rebuild Meshes", "rtx_rebuild_meshes")
    end)
end)

-- Console Commands
concommand.Add("rtx_rebuild_meshes", BuildMapMeshes)