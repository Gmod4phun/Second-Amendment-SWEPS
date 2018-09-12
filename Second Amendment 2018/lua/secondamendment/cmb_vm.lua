local int = SecondAmendment.Lerp

function SWEP:SetViewModel(mdl)
	self.vm = ClientsideModel(mdl, RENDERGROUP_VIEWMODEL_TRANSLUCENT)
	self.vm:SetNoDraw(true)
	self.vm.blur = 0
end

SWEP.BlurAmount = 0

if CLIENT then
	local ps2 = render.SupportsPixelShaders_2_0()
	local blurMat = Material("pp/toytown-top")
	blurMat:SetTexture("$fbtexture", render.GetScreenEffectTexture())

	function SWEP:CalcViewBlur()
		if ps2 then
			local FT, CT = FrameTime(), CurTime()

			local alpha_scope = self.ScopeAlpha or 255
				
			if SecondAmendment.CVar["view_blur"]:GetBool() then
				self.BlurAmount = math.Approach(self.BlurAmount, (self:GetReloading() and 5 or 0) + (255-alpha_scope)*5/255, FT*50)
			else
				self.BlurAmount = 0
			end

			local x, y = ScrW(), ScrH()

			cam.Start2D()
				surface.SetMaterial(blurMat)
				surface.SetDrawColor(255, 255, 255, 255)

				for i = 1, self.BlurAmount do
					render.UpdateScreenEffectTexture()
					surface.DrawTexturedRect(0, 0, x, y*2)
				end
			cam.End2D()
		end
	end
end


function SWEP:DrawViewModel()
	local vm = self.vm
	local hands = LocalPlayer():GetHands()
	local FT = FrameTime()
	vm.blur = int(FT*5, vm.blur or 0, (self:GetAiming() and self:GetHip() and !self:GetReloading() and SecondAmendment.CVar["vm_blur"]:GetBool()) and 6 or 0)

	hands:SetParent(vm)

	vm:FrameAdvance(FT)
	vm:SetupBones()

	render.ClearStencil()
	render.SetStencilEnable(true)
	
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilReferenceValue(1)

	vm:DrawModel()
	hands:DrawModel()

	if self.DotSight then
		self:DrawDot(vm)
	end

	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		
	cam.Start2D()
		DrawToyTown(vm.blur, ScrH()/2)
	cam.End2D()
		
	render.SetStencilEnable(false)
end

function util_NormalizeAngles(a)
	a.p = math.NormalizeAngle(a.p)
	a.y = math.NormalizeAngle(a.y)
	a.r = math.NormalizeAngle(a.r)
	return a
end

SWEP.BobPos = Vector()
SWEP.BobPos2 = Vector()

SWEP.IdlePos = Vector()
SWEP.IdleAng = Vector()

local hipMul = 0
local mul = 0
local mul2 = 0
local idle_mul = 0

local shoot_intensity = 0

local run_mul = 0

SWEP.CustomRecoil = {Vector(), Vector()}
local curIdle = 0
local curStep = 0
local crouchPos = 0
local sideVel, newVel = 0, 0
local AimPos, AimAng = Vector(), Vector()
local angTab, oldDelta, angDelta, angDelta2, angDif = Angle(), Angle(), Angle(), Angle(), Angle()
local AirTime, GroundHit, FallVel, FallVel2 = 0, 0, 0, 0
local PA = Angle()

local AimMul = 0
local SmoothAimMul = 0

local last_Sprint = false
local meta = {}
function SWEP:CalcVMMatrix()
	local vm = self.vm
	local _sharpMul = 1

	local EP, EA = EyePos(), EyeAngles()
	local FT, CT = FrameTime(), CurTime()

	meta.origin = EP
	meta.angles = EA

	if sharpeye and sharpeye:IsEnabled() and sharpeye:IsMotionEnabled() then
		_sharpMul = 0
		local _sharpeYeSupport = util_NormalizeAngles(EA-self.Owner:EyeAngles())*(self.ViewModelFOV/10) - self.Owner:GetViewPunchAngles()
		meta.angles = meta.angles - _sharpeYeSupport
	end

	local speed = self.Owner:GetVelocity()

	local len = speed:Length2D()

	local vel = math.Clamp(len / 200, 0, 1.3)
	local vel_norm = len / 200

	local Hip = self:GetHip()
	local Aiming = self:GetAiming()
	local Reloading = self:GetReloading()
	local Sprinting = self:GetSprinting()
	local Crouching = self.Owner:Crouching() or self.Owner:KeyDown(IN_DUCK)
	local Airborne = !self.Owner:OnGround() and self.Owner:GetMoveType() != MOVETYPE_NOCLIP
		
	if last_Sprint != Sprinting and Sprinting then
		curStep = self.SprintSeed
	end
	
	PA = self.Owner:GetViewPunchAngles()
	
	local CustomAimMul = (Aiming and Hip) and self.CustomRecoilAimMultiplier or 1
	
	self.CustomRecoil[1] = self.VMData["Matrix"]["Recoil"]["Pos"] * PA.p * CustomAimMul
	self.CustomRecoil[2] = self.VMData["Matrix"]["Recoil"]["Ang"] * PA.p * CustomAimMul
	
	last_Sprint = Sprinting

	curStep = curStep + (vel/math.pi)*(FT*50)

	mul = int(FT*5, mul, Reloading and 2 or (Aiming and Hip) and 0.1 or Aiming and 1 or 2)
	idle_mul = int(FT*5, idle_mul, (Aiming and Hip) and 0.05 or Aiming and 1 or 2)
	run_mul = int(FT*5, run_mul, Sprinting and 0 or 1)
	mul2 = int(FT*15, mul2, (Aiming and Hip) and 0 or 1)
	
	if !Airborne then
		self.BobPos[1] = int(FT*7, self.BobPos[1], math.sin(curStep/2)*vel_norm*mul)
		self.BobPos[2] = int(FT*7, self.BobPos[2], math.cos(curStep)*vel_norm*mul)
		self.BobPos2[1] = int(FT*7, self.BobPos2[1], math.sin(curStep/2+45)*vel_norm*mul)
		self.BobPos2[2] = int(FT*7, self.BobPos2[2], math.cos(curStep+45)*vel_norm*mul)
	end


	PA = PA*(math.Clamp(mul, 0, 1)^2)

	self.IdlePos[1] = math.sin(CT)*idle_mul
	self.IdlePos[2] = math.cos(CT*2)*idle_mul
	self.IdleAng[1] = math.sin(45+CT)*idle_mul
	self.IdleAng[2] = math.cos(45+CT*2)*idle_mul
	
	AirTime = Airborne and math.Clamp(-speed[3]/75, 0, 25) or int(FT*15, AirTime, 0)
	GroundHit = !Airborne and int(FT*9, GroundHit, AirTime*1.5) or int(FT*15, GroundHit, 0)
	FallVel = int(FT*16, FallVel, Airborne and math.Clamp(speed[3]/250, -2, 2) or 0)
	FallVel2 = int(FT*35, FallVel2, Airborne and math.Clamp(speed[3]/250, -2, 2) or 0)
	
	local vm_origin = SecondAmendment.CVar["vm_origin"]:GetBool()
	local vec_origin = vm_origin and self.VMData.Matrix.Origin.Pos or vector_origin
	local vec_angle = vm_origin and self.VMData.Matrix.Origin.Ang or vector_origin
	
	AimMul = math.Approach(AimMul, (Hip and Aiming and !Reloading) and 1 or 0, 10*FT)
	SmoothAimMul = int(FT*25, SmoothAimMul, AimMul)

	--[[if Aiming and !Reloading then
		AimPos = int(FT*15, AimPos, Hip and self.VMData.Matrix.Aim.Pos or vec_origin)
		AimAng = int(FT*15, AimAng, Hip and self.VMData.Matrix.Aim.Ang or vec_angle)
	else
		AimPos = int(FT*15, AimPos, vec_origin)
		AimAng = int(FT*15, AimAng, vec_origin)
	end]]
	
	AimPos = vec_origin + (self.VMData.Matrix.Aim.Pos - vec_origin) * SmoothAimMul
	AimAng = vec_angle + (self.VMData.Matrix.Aim.Ang - vec_angle) * SmoothAimMul
		

	sideVel = int(FT*5, sideVel, math.Clamp(speed:DotProduct(meta.angles:Right())/50, -5, 5))
	newVel = int(FT*10, newVel, vel*mul2)
	crouchPos = int(FT*5, crouchPos, (Crouching and Aiming and !Hip) and 1 or 0)

	angTab.p = EA.p
	angTab.y = EA.y
	
	delta = util_NormalizeAngles(angTab - oldDelta)*mul
	
	oldDelta.p = EA.p
	oldDelta.y = EA.y
	
	angDelta2 = int(FT*12, angDelta2, angDelta)
	
	angDif.p = (angDelta.p - angDelta2.p)
	angDif.y = (angDelta.y - angDelta2.y)
	
	angDelta = int(FT*13, angDelta, delta + angDif)

	self.AngDelta = util_NormalizeAngles(angDelta)
	
	meta.angles:RotateAroundAxis(meta.angles:Right(), AimAng.x + angDelta.p - self.IdleAng.y/3 + GroundHit*mul*3 - FallVel*mul*3 + self.BobPos2.y*run_mul + self.CustomRecoil[2].x)
	meta.angles:RotateAroundAxis(meta.angles:Up(), AimAng.y + self.IdleAng.x/3 - self.BobPos2.x*run_mul + self.CustomRecoil[2].y)
	meta.angles:RotateAroundAxis(meta.angles:Forward(), AimAng.z + sideVel + angDelta2.y/2 + self.BobPos.x*run_mul + self.CustomRecoil[2].z)

	local right = meta.angles:Right()
	local up = meta.angles:Up()
	local forward = meta.angles:Forward()

	meta.origin = meta.origin + (AimPos[1] + sideVel/3*mul2 + newVel/3 + angDelta[2]/6 - crouchPos + self.IdlePos[1]/12 + self.BobPos[1]/3*run_mul + self.CustomRecoil[1][1]) * right
	meta.origin = meta.origin + (AimPos[2] + EA.P/60*mul2 - crouchPos + FallVel*mul + self.CustomRecoil[1][2]) * forward
	meta.origin = meta.origin + (AimPos[3] - newVel - angDelta[1]/6 - (EA.P/90*mul2) + self.IdlePos[2]/12 - self.BobPos[2]/2*run_mul + self.CustomRecoil[1][3]) * up
	
	meta.angles.p = math.Clamp(meta.angles.p, -89, 89)
	meta.origin[3] = meta.origin[3] + FallVel*mul*1.25 - GroundHit*mul
	vm:SetPos(meta.origin)
	vm:SetAngles(meta.angles)
end

function SWEP:GetViewModelPosition()
	return meta.origin, meta.angles
end

function SWEP:HandleBoneMods(vm)

end

function CMB_PreDrawViewModel(vm, ply, wpn)
	if not IsValid(wpn) or not wpn.SecondAmendment then
		return
	end

	if wpn.vm then
		render.SetBlend(0)

		wpn:CalcVMMatrix()
		wpn:CalcViewBlur()
		wpn:HandleBoneMods(wpn.vm)
	end
end

hook.Add("PreDrawViewModel", "CMB_PreDrawViewModel", CMB_PreDrawViewModel)

function CMB_PostDrawViewModel(vm, ply, wpn)
	if not IsValid(wpn) or not wpn.SecondAmendment then
		return
	end

	render.SetBlend(1)
	wpn:DrawViewModel()
end

hook.Add("PostDrawViewModel", "CMB_PostDrawViewModel", CMB_PostDrawViewModel)

local _fov = 90
local LastMuzzle = Angle()
local _cam, _ang = Angle(), Angle()
local view = {}
function SWEP:CalcView(ply, origin, angles, fov)
	local vm = self.vm

	local up = angles:Up()
	local right = angles:Right()
	local forward = angles:Forward()

	local CT = CurTime()
	local FT = FrameTime()

	view.origin = origin
	view.angles = angles
	view.fov = fov

	local muzzle_att = self.vm:GetAttachment(1)

	if muzzle_att then
		local vmAng, muzzleAng = vm:GetAngles(), muzzle_att.Ang
		local muzzle = util_NormalizeAngles(vmAng-muzzleAng)

		muzzle.y = muzzle.y + 90
		muzzle.r = -muzzle.p

		local fps = math.Clamp((1/FT)/150, 0, 1)
		
		muzzle2 = util_NormalizeAngles(LastMuzzle-muzzle)*fps

		LastMuzzle = muzzle
		local act = self:GetActTime() >= CurTime() and angles.p < 85 and angles.p > -85

		_cam = int(FT*15, _cam, (act) and muzzle2 or _ang)
	end

	view.origin = view.origin + (0) * right
	view.origin = view.origin + (0) * forward
	view.origin = view.origin + (-GroundHit) * up

	view.angles:RotateAroundAxis(right, (self.BobPos[2]/3 + _cam[1] - GroundHit*3 - FallVel*3))
 	view.angles:RotateAroundAxis(up, (-self.BobPos2[1]/3 + _cam[2]))
 	view.angles:RotateAroundAxis(forward, (-_cam[3] - self.BobPos[1]/4 + sideVel/3))

 	local real_fov = self.Owner:GetFOV()
 	_fov = int(FT*15, _fov, self:GetReloading() and real_fov or (self:GetAiming() and self:GetHip()) and self.AimFOV or (self:GetAiming() and !self:GetHip()) and self.HipFOV or real_fov)

 	view.fov = _fov
	return view.origin, view.angles, view.fov
end

function SWEP:AdjustMouseSensitivity()
	sens = _fov/90
	return sens
end

local dotCol = Color(0, 255, 0, 255)
local dot = Material("cmb/circle")
function SWEP:DrawDot(vm)
	if self:GetAiming() then
		local ang = vm:GetAttachment(1).Ang
		ang.y = ang.y - AimAng.y
		ang.p = ang.p - AimAng.x

		dist = math.Round(5 - (AimPos.y - self.VMData.Matrix.Aim.Pos.y), 1)/5 > 0.88
		local pos = EyePos() - ang:Forward()*25

		if dist and self:GetActTime() <= CurTime() + 0.2 then
			render.SetMaterial(dot)
			render.DrawSprite(pos, 0.085, 0.085, dotCol)
		end
	end
end

local function emitShell()
			
	ply = LocalPlayer()
	wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.EmitShell then
		wep:EmitShell()
	end
end

usermessage.Hook("CMB_EMITSHELL", emitShell)

local function PlayAnim(um)
	seq = um:ReadString()
	speed = um:ReadFloat()
	cycle = um:ReadFloat()	

	ply = LocalPlayer()
	wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep.PlayAnimation then
		wep:PlayAnimation(seq, speed, cycle)
	end
end

usermessage.Hook("CMB_PLAYANIM", PlayAnim)

local shellTab = {}
function SWEP:EmitShell()
	if CLIENT then
		local eject = self.vm:GetAttachment(2)

		if !eject then return end
		local pos = eject.Pos
		local ang = eject.Ang
		local vel = ang:Right()*125

		pos = pos + (0) * ang:Right()
		pos = pos + (0) * ang:Up()
		pos = pos + (0) * ang:Forward()

		local shell = ClientsideModel(self.VMData.Shell.Model, RENDERGROUP_VIEWMODEL) 
		shell:SetPos(pos)
		shell:PhysicsInitBox(Vector(-0.5, -0.15, -0.5), Vector(0.5, 0.15, 0.5))
		shell:SetAngles(ang)
		shell:SetMoveType(MOVETYPE_VPHYSICS)
		shell:SetSolid(SOLID_VPHYSICS)
		shell:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		shell:SetNoDraw(false)
		
			
		local phys = shell:GetPhysicsObject()
		phys:SetMaterial("gmod_silent")
		phys:SetMass(5)
		phys:SetVelocity(vel)
		phys:AddAngleVelocity(VectorRand()*400)

		SafeRemoveEntityDelayed(shell, 5)
	elseif game.SinglePlayer() and SERVER then
		SendUserMessage("CMB_EMITSHELL", self.Owner)
	end
end