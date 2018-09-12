SWEP.PrintName			= "Colt M4 Carbine"	
SWEP.Slot				= 2
SWEP.SlotPos			= 1

SWEP.Base				= "cmb_base"
SWEP.Category			= "Second Amendment"

SWEP.Spawnable			= true

SWEP.Primary.Damage		= 30
SWEP.Primary.NumShots	= 1
SWEP.Primary.Cone		= 0
SWEP.Primary.Spread 	= 0
SWEP.Primary.RPM 		= 950
SWEP.Primary.Force 		= 4

SWEP.Primary.MagSize		= 30
SWEP.Primary.DefaultClip	= 0
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "cmb_556"

SWEP.ReloadLength 		= 2.5
SWEP.FullReloadLength	= 3

SWEP.SprintSeed = 0

SWEP.VMData = {
	["Model"] = "models/weapons/danny/cmb/v_cmb_m4.mdl",

	["Anim"] = {
		["Draw"] = "draw",
		["Fire"] = "hip_shoot",
		["Reload"] = "reload",
		["HipReload"] = "hip_reload",
		["FullReload"] = "reload_full",
		["FullHipReload"] = "hip_reload_full",
		["Hip"] = "origin_to_hip",
		["Origin"] = "hip_to_origin",
		["Sprint"] = "sprint",
		["Nade"] = "grenade",
		["HipNade"] = "hip_grenade"
	},

	["Activity"] = {
		["Fire"] = "CMB_M4.Fire",
		["Draw"] = "CMB_Uni.Deploy1",
		["Reload"] = {
			{time = 0.3, snd = "CMB_M4.ClipOut"},
			{time = 1.5, snd = "CMB_M4.ClipIn"},
		},
		["FullReload"] = {
			{time = 0.3, snd = "CMB_M4.ClipOut"},
			{time = 1.5, snd = "CMB_M4.ClipIn"},
			{time = 1.95, snd = "CMB_M4.BoltBack"},
			{time = 2.2, snd = "CMB_M4.BoltForward"}
		},
	},

	["Matrix"] = {
		["Aim"] = {
			["Pos"] = Vector(-2.8,-5,0.1),
            ["Ang"] = Vector(0.15,-0.1,0)
		},
		["Sprint"] = {
			["Pos"] = Vector(0,0,0),
			["Ang"] = Vector(0,0,0)
		},
		["Origin"] = {
			["Pos"] = Vector(-0.5,1,-1),
			["Ang"] = Vector(0,0,0)
		},
		["Recoil"] = {
			["Pos"] = Vector(0,0.6,0),
			["Ang"] = Vector(-0.1,0,0)	
		}
	},

	["Shell"] = {
		["Model"] = "models/shells/shell_556.mdl"
	}
}

SWEP.ViewModel = SWEP.VMData.Model
SWEP.WorldModel = "models/weapons/danny/cmb/w_cmb_m4.mdl"

SWEP.HipRecoil		= 1.2
SWEP.AimRecoil		= 0.9
SWEP.HipSpread		= 0.01
SWEP.AimSpread		= 0
SWEP.HipVelSpread	= 1
SWEP.AimVelSpread	= 0.4
SWEP.HipSpreadAdd	= 0.40
SWEP.AimSpreadAdd	= 0.15
SWEP.CrouchAccuracy = 0.7
SWEP.DeployTime 	= 0.6

SWEP.DotSight 		= true
SWEP.WallDistance	= 50