---@class itemapi
local mod = itemapi


---@type { [string]: string }
mod.textureToSurfaceMaterial = {}


function mod.addSurfaceMaterialTexture(materialID, textureName)
	mod.textureToSurfaceMaterial[textureName] = materialID
end

function mod.addSurfaceMaterialTextures(materialID, textureNames)
	for _, texture in ipairs(textureNames) do
		itemapi.addSurfaceMaterialTexture(materialID, texture)
	end
end
