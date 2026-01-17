---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@alias itemapi.SurfaceType
---|"sector_floor"
---|"sector_ceiling"
---|"fof_bottom"
---|"fof_top"
---|"fof_side"
---|"side_bottom"
---|"side_middle"
---|"side_top"
---|"mobj_top"
---|"mobj_bottom"


--#region Surface

---@class itemapi.Surface : ljclass.Class
---@field type itemapi.SurfaceType
---@field z fixed_t
---@field texture string
---
---@field zAt fun(x: fixed_t, y: fixed_t): fixed_t
local Surface = ljclass.class()
mod.Surface = Surface


---@param type itemapi.SurfaceType
---@param mapElement any
function Surface:__init(type, mapElement)
end

--#endregion


--#region Sector floor

---@class itemapi.SectorFloor : itemapi.Surface
---@field sector sector_t
local SectorFloor = ljclass.class(Surface)
mod.SectorFloor = SectorFloor

SectorFloor.type = "sector_floor"

---@param sector sector_t
function SectorFloor:__init(sector)
	self.sector = sector
end

ljclass.getterSetter(SectorFloor, "z", function(self)
	return self.sector.floorheight
end, function(self, z)
	self.sector.floorheight = z
end)

ljclass.getter(SectorFloor, "slope", function(self)
	return self.sector.f_slope
end)

ljclass.getterSetter(SectorFloor, "texture", function(self)
	return self.sector.floorpic
end, function(self, texture)
	self.sector.floorpic = texture
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function SectorFloor:zAt(x, y)
	return P_GetZAt(self.sector.f_slope, x, y, self.sector.floorheight)
end

--#endregion


--#region Sector ceiling

---@class itemapi.SectorCeiling : itemapi.Surface
---@field sector sector_t
local SectorCeiling = ljclass.class(Surface)
mod.SectorCeiling = SectorCeiling

SectorCeiling.type = "sector_ceiling"

---@param sector sector_t
function SectorCeiling:__init(sector)
	self.sector = sector
end

ljclass.getterSetter(SectorCeiling, "z", function(self)
	return self.sector.ceilingheight
end, function(self, z)
	self.sector.ceilingheight = z
end)

ljclass.getter(SectorCeiling, "slope", function(self)
	return self.sector.c_slope
end)

ljclass.getterSetter(SectorCeiling, "texture", function(self)
	return self.sector.ceilingpic
end, function(self, texture)
	self.sector.ceilingpic = texture
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function SectorCeiling:zAt(x, y)
	return P_GetZAt(self.sector.c_slope, x, y, self.sector.ceilingheight)
end

--#endregion


--#region FOF bottom

---@class itemapi.FOFBottom : itemapi.Surface
---@field fof ffloor_t
local FOFBottom = ljclass.class(Surface)
mod.FOFBottom = FOFBottom

FOFBottom.type = "fof_bottom"

---@param fof ffloor_t
function FOFBottom:__init(fof)
	self.fof = fof
end

ljclass.getterSetter(FOFBottom, "z", function(self)
	return self.fof.bottomheight
end, function(self, z)
	self.fof.bottomheight = z
end)

ljclass.getter(FOFBottom, "slope", function(self)
	return self.fof.b_slope
end)

ljclass.getterSetter(FOFBottom, "texture", function(self)
	return self.fof.bottompic
end, function(self, texture)
	self.fof.bottompic = texture
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function FOFBottom:zAt(x, y)
	return P_GetZAt(self.fof.b_slope, x, y, self.fof.bottomheight)
end

--#endregion


--#region FOF top

---@class itemapi.FOFTop : itemapi.Surface
---@field fof ffloor_t
local FOFTop = ljclass.class(Surface)
mod.FOFTop = FOFTop

FOFTop.type = "fof_top"

---@param fof ffloor_t
function FOFTop:__init(fof)
	self.fof = fof
end

ljclass.getterSetter(FOFTop, "z", function(self)
	return self.fof.topheight
end, function(self, z)
	self.fof.topheight = z
end)

ljclass.getter(FOFTop, "slope", function(self)
	return self.fof.t_slope
end)

ljclass.getterSetter(FOFTop, "texture", function(self)
	return self.fof.toppic
end, function(self, texture)
	self.fof.toppic = texture
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function FOFTop:zAt(x, y)
	return P_GetZAt(self.fof.t_slope, x, y, self.fof.topheight)
end

--#endregion


--#region FOF side

---@class itemapi.FOFSide : itemapi.Surface
---@field fof ffloor_t
---@field texture string
local FOFSide = ljclass.class(Surface)
mod.FOFSide = FOFSide

FOFSide.type = "fof_side"

---@param fof ffloor_t
function FOFSide:__init(fof)
	self.fof = fof
end

ljclass.getterSetter(FOFSide, "texture", function(self)
	return R_TextureNameForNum(self.fof.master.frontside.midtexture)
end, function(self, texture)
	self.fof.master.frontside.midtexture = R_TextureNumForName(texture)
end)

--#endregion


--#region Side bottom

---@class itemapi.SideBottom : itemapi.Surface
---@field side side_t
---@field texture string
local SideBottom = ljclass.class(Surface)
mod.SideBottom = SideBottom

SideBottom.type = "side_bottom"

---@param side side_t
function SideBottom:__init(side)
	self.side = side
end

ljclass.getterSetter(SideBottom, "texture", function(self)
	return R_TextureNameForNum(self.side.bottomtexture)
end, function(self, texture)
	self.side.bottomtexture = R_TextureNumForName(texture)
end)

--#endregion


--#region Side middle

---@class itemapi.SideMiddle : itemapi.Surface
---@field side side_t
---@field texture string
local SideMiddle = ljclass.class(Surface)
mod.SideMiddle = SideMiddle

SideMiddle.type = "side_middle"

---@param side side_t
function SideMiddle:__init(side)
	self.side = side
end

ljclass.getterSetter(SideMiddle, "texture", function(self)
	return R_TextureNameForNum(self.side.midtexture)
end, function(self, texture)
	self.side.midtexture = R_TextureNumForName(texture)
end)

--#endregion


--#region Side top

---@class itemapi.SideTop : itemapi.Surface
---@field side side_t
---@field texture string
local SideTop = ljclass.class(Surface)
mod.SideTop = SideTop

SideTop.type = "side_top"

---@param side side_t
function SideTop:__init(side)
	self.side = side
end

ljclass.getterSetter(SideTop, "texture", function(self)
	return R_TextureNameForNum(self.side.toptexture)
end, function(self, texture)
	self.side.toptexture = R_TextureNumForName(texture)
end)

--#endregion

--#region Mobj bottom

---@class itemapi.MobjBottom : itemapi.Surface
---@field mobj mobj_t
local MobjBottom = ljclass.class(Surface)
mod.MobjBottom = MobjBottom

MobjBottom.type = "mobj_bottom"

---@param mobj mobj_t
function MobjBottom:__init(mobj)
	self.mobj = mobj
end

ljclass.getterSetter(MobjBottom, "z", function(self)
	return self.mobj.z
end, function(self, z)
	self.mobj.z = z
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function MobjBottom:zAt(x, y)
	return self.mobj.z
end

--#endregion


--#region Mobj top

---@class itemapi.MobjTop : itemapi.Surface
---@field mobj mobj_t
local MobjTop = ljclass.class(Surface)
mod.MobjTop = MobjTop

MobjTop.type = "mobj_top"

---@param mobj mobj_t
function MobjTop:__init(mobj)
	self.mobj = mobj
end

ljclass.getterSetter(MobjTop, "z", function(self)
	return self.mobj.z + self.mobj.height
end, function(self, z)
	self.mobj.z = z - self.mobj.height
end)

---@param x fixed_t
---@param y fixed_t
---@return fixed_t
function MobjTop:zAt(x, y)
	return self.mobj.z + self.mobj.height
end

--#endregion
