class KFWeap_LardPD4K extends KFWeap_ScopedBase;

var float LastFireInterval;

// Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion)
var() float SelfDamageReductionValue;

//Props related to charging the weapon
var float MaxChargeTime;
var float ValueIncreaseTime;
var float DmgIncreasePerCharge;
var float ZapDmgIncreasePerCharge;
var int AmmoIncreasePerCharge;

var transient float ChargeTime;
var transient float ConsumeAmmoTime;
var transient float MaxChargeLevel;

var transient KFParticleSystemComponent ChargingPSC; //ParticleSystemComponent
var ParticleSystem ChargingEffect;
var ParticleSystem ChargedEffect;

var transient bool bIsFullyCharged;

var const WeaponFireSndInfo FullyChargedSound;

var float FullChargedTimerInterval;

simulated function StartFire(byte FireModeNum)
{
	if (IsTimerActive('RefireCheckTimer'))
	{
		return;
	}

	super.StartFire(FireModeNum);
}

simulated function OnStartFire()
{
	local KFPawn PawnInst;
	PawnInst = KFPawn(Instigator);

	if (PawnInst != none)
	{
		PawnInst.OnStartFire();
	}
}

simulated function FireAmmunition()
{
	// Let the accuracy tracking system know that we fired
	HandleWeaponShotTaken(CurrentFireMode);

	// Handle the different fire types
	switch (WeaponFireTypes[CurrentFireMode])
	{
	case EWFT_InstantHit:
		// Launch a projectile if we are in zed time, and this weapon has a projectile to launch for this mode
		if (`IsInZedTime(self) && WeaponProjectiles[CurrentFireMode] != none )
		{
			ProjectileFire();
		}
		else
		{
			InstantFireClient();
		}
		break;

	case EWFT_Projectile:
		ProjectileFire();
		break;

	case EWFT_Custom:
		CustomFire();
		break;
	}

	// If we're firing without charging, still consume one ammo
	if (GetChargeLevel() < 1)
	{
		ConsumeAmmo(CurrentFireMode);
	}

	NotifyWeaponFired(CurrentFireMode);

	// Play fire effects now (don't wait for WeaponFired to replicate)
	PlayFireEffects(CurrentFireMode, vect(0, 0, 0));
}

simulated state CannonCharge extends WeaponFiring
{
    //For minimal code purposes, I'll directly call global.FireAmmunition after charging is released
    simulated function FireAmmunition() {}

	// simulated function bool AllowIronSights() { return false; }

    //Store start fire time so we don't have to timer this
    simulated event BeginState(Name PreviousStateName)
    {
        super.BeginState(PreviousStateName);

		ChargeTime = 0;
		ConsumeAmmoTime = 0;
		MaxChargeLevel = int(MaxChargeTime / ValueIncreaseTime);

		if (ChargingPSC == none)
		{
			ChargingPSC = new(self) class'KFParticleSystemComponent'; //ParticleSystemComponent
			ChargingPSC.SetDepthPriorityGroup(SDPG_Foreground);
			ChargingPSC.SetTickGroup(TG_PostUpdateWork);
			ChargingPSC.SetFOV(MySkelMesh.FOV);

			if(MySkelMesh != none)
			{
				MySkelMesh.AttachComponentToSocket(ChargingPSC, 'MuzzleFlash');
			}
			else
			{
				AttachComponent(ChargingPSC);
			}
		}
		else
		{
			ChargingPSC.ActivateSystem();
		}

		bIsFullyCharged = false;

		// if (bUsingSights)
		// {
		// 	SetIronSights(false);
		// }

		global.OnStartFire();

		if(ChargingPSC != none)
		{
			ChargingPSC.SetTemplate(ChargingEffect);
		}
    }

	simulated function bool ShouldRefire()
	{
		// ignore how much ammo is left (super/global counts ammo)
		return StillFiring(CurrentFireMode);
	}

    simulated event Tick(float DeltaTime)
    {
        local float ChargeRTPC;

		global.Tick(DeltaTime);

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ConsumeAmmoTime += DeltaTime;
		}

		if (bIsFullyCharged)
		{
			if (ConsumeAmmoTime >= FullChargedTimerInterval)
			{
				//ConsumeAmmo(ALTFIRE_FIREMODE);
				ConsumeAmmoTime -= FullChargedTimerInterval;
			}

			return;
		}

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ChargeTime += DeltaTime;
		}

		ChargeRTPC = FMin(ChargeTime / MaxChargeTime, 1.f);
        KFPawn(Instigator).SetWeaponComponentRTPCValue("Weapon_Charge", ChargeRTPC); //For looping component
        Instigator.SetRTPCValue('Weapon_Charge', ChargeRTPC); //For one-shot sounds

		if (ConsumeAmmoTime >= ValueIncreaseTime)
		{
			ConsumeAmmo(ALTFIRE_FIREMODE);
			ConsumeAmmoTime -= ValueIncreaseTime;
		}

		if (ChargeTime >= MaxChargeTime || !HasAmmo(ALTFIRE_FIREMODE))
		{
			bIsFullyCharged = true;
			ChargingPSC.SetTemplate(ChargedEffect);
			KFPawn(Instigator).SetWeaponAmbientSound(FullyChargedSound.DefaultCue, FullyChargedSound.FirstPersonCue);
		}
    }

    //Now that we're done charging, directly call FireAmmunition. This will handle the actual projectile fire and scaling.
    simulated event EndState(Name NextStateName)
    {
		ClearZedTimeResist();
        ClearPendingFire(CurrentFireMode);
		ClearTimer(nameof(RefireCheckTimer));

		KFPawn(Instigator).bHasStartedFire = false;
		KFPawn(Instigator).bNetDirty = true;

		if (ChargingPSC != none)
		{
			ChargingPSC.DeactivateSystem();
		}

		KFPawn(Instigator).SetWeaponAmbientSound(none);
    }

	simulated function HandleFinishedFiring()
	{
		global.FireAmmunition();

		// Gotta restart the timer every shot :(
		if( IsTimerActive(nameOf(RefireCheckTimer)) )
		{
			ClearTimer( nameOf(RefireCheckTimer) );
			TimeWeaponFiring( CurrentFireMode );
		}

		if (bPlayingLoopingFireAnim)
		{
			StopLoopingFireEffects(CurrentFireMode);
		}

		if (MuzzleFlash != none)
		{
			SetTimer(MuzzleFlash.MuzzleFlash.Duration, false, 'Timer_StopFireEffects');
		}
		else
		{
			SetTimer(0.3f, false, 'Timer_StopFireEffects');
		}

		NotifyWeaponFinishedFiring(CurrentFireMode);

		super.HandleFinishedFiring();
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if(ChargingPSC != none)
	{
		ChargingPSC.SetFOV(NewFOV);
	}
}

// Placing the actual Weapon Firing end state here since we need it to happen at the end of the actual firing loop.
simulated function Timer_StopFireEffects()
{
	// Simulate weapon firing effects on the local client
	if (WorldInfo.NetMode == NM_Client)
	{
		Instigator.WeaponStoppedFiring(self, false);
	}

	ClearFlashCount();
	ClearFlashLocation();
}

simulated function int GetChargeLevel()
{
	return Min(ChargeTime / ValueIncreaseTime, MaxChargeLevel);
}

// Should generally match up with KFWeapAttach_HuskCannon::GetChargeFXLevel
simulated function int GetChargeFXLevel()
{
	local int ChargeLevel;

	ChargeLevel = GetChargeLevel();
	if (ChargeLevel < 1)
	{
		return 1;
	}
	else if (ChargeLevel < MaxChargeLevel)
	{
		return 2;
	}
	else
	{
		return 3;
	}
}

// Increase the instant hit damage based on the charge level
simulated function int GetModifiedDamage(byte FireModeNum, optional vector RayDir)
{
	local int ModifiedDamage;

	ModifiedDamage = super.GetModifiedDamage(FireModeNum, RayDir);
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		ModifiedDamage = ModifiedDamage * (1.f + DmgIncreasePerCharge * GetChargeLevel());
		// ModifiedDamage = ModifiedDamage * (ZapDmgIncreasePerCharge * GetChargeLevel());
	}

	return ModifiedDamage;
}

// Increase explosive damage based on the charge level
simulated function KFProjectile SpawnProjectile(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
    local KFProj_Bullet_LardPD4K Proj;
    local int Charges;

    Proj = KFProj_Bullet_LardPD4K(super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir));

    //Calc and set scaling values
    if (Proj != none)
    {
        Charges = GetChargeLevel();
        Proj.DamageScale = 1.f + DmgIncreasePerCharge * Charges;
        Proj.ZapDamage = ZapDmgIncreasePerCharge * Charges; //int

        return Proj;
    }

    return none;
}

//Overriden to use instant hit vfx. Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    MyProjectileClass = GetKFProjectileClass();

	// This is where we would start an instant trace. (what CalcWeaponFire uses)
	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	// if projectile is spawned at different location of crosshair,
	// then simulate an instant trace where crosshair is aiming at, Get hit info.
	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	// Set flash location to trigger client side effects.  Bypass Weapon.SetFlashLocation since
	// that function is not marked as simulated and we want instant client feedback.
	// ProjectileFire/IncrementFlashCount has the right idea:
	//	1) Call IncrementFlashCount on Server & Local
	//	2) Replicate FlashCount if ( !bNetOwner )
	//	3) Call WeaponFired() once on local player
	if( Instigator != None )
	{
		Instigator.SetFlashLocation( Self, CurrentFireMode, TestImpact.HitLocation );
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{

		if( StartTrace != RealStartLoc )
		{	
			// Store the original aim direction without correction
            DirB = AimDir;

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            // Store the desired corrected aim direction
    		DirA = AimDir;

    		// Clamp the maximum aim adjustment for the AimDir so you don't get wierd
    		// cases where the projectiles velocity is going WAY off of where you
    		// are aiming. This can happen if you are really close to what you are
    		// shooting - Ramm
    		if ( (DirA dot DirB) < MaxAimAdjust_Cos )
    		{
    			Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), MaxAimAdjust_Angle);
    			AimDir = QuatRotateVector(Q,DirB);
    		}
		}

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

simulated function float GetFireInterval(byte FireModeNum)
{
	if (FireModeNum == DEFAULT_FIREMODE)
	{
		return LastFireInterval;
	}

	return super.GetFireInterval(FireModeNum);
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
}

defaultproperties
{
	// Inventory
	InventorySize=7 //6
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_LardPD4K_MAT.UI_WeaponSelect_LardPD4K'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'
	AssociatedPerkClasses(1)=class'KFPerk_Demolitionist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

    // FOV
	MeshFOV=80 //90
	MeshIronSightFOV=10
    PlayerIronSightFOV=70

	// Zooming/Position
	IronSightPosition=(X=15,Y=-0.045,Z=2.9)
	PlayerViewOffset=(X=6.0,Y=14,Z=-3.2) //z -5.0

	// Content
	PackageKey="LardPD4K" //Lard P-D 4K
	FirstPersonMeshName="WEP_LardPD4K_MESH.WEP_1stP_LardPD4K_Rig"
	FirstPersonAnimSetNames(0)="WEP_LardPD4K_ARCH.Wep_1stP_LardPD4K_Anim"
	PickupMeshName="WEP_LardPD4K_MESH.WEP_LardPD4K_Pickup"
	AttachmentArchetypeName="WEP_LardPD4K_ARCH.WEP_LardPD4K_Trail_3P"
	MuzzleFlashTemplateName="WEP_LardPD4K_ARCH.WEP_LardPD4K_MuzzleFlash"

	// Scope Render
  	// 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
	   //TextureTarget=TextureRenderTarget2D'WEP_1P_FNFAL_MAT.WEP_1P_FNFAL_Scope_MAT'
	   FieldOfView=8.5 //23.0 // "1.5X" = 35.0(our real world FOV determinant)/1.5
	End Object

    ScopedSensitivityMod=6.0 //8
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_LardPD4K_MAT.WEP_1P_LardPD4K_Reticle_MAT'
	ScopeMICIndex=1

	// Ammo
	MagazineCapacity[0]=10 //30
	SpareAmmoCapacity[0]=200 //300
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=90
	minRecoilPitch=80
	maxRecoilYaw=90
	minRecoilYaw=-90
	RecoilRate=0.09
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.6
	HippedRecoilModifier=1.5 //1.25

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Electricity'
	FiringStatesArray(DEFAULT_FIREMODE)=CannonCharge
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_LardPD4K'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_LardPD4K'
	InstantHitDamage(DEFAULT_FIREMODE)=30 //60
	FireInterval(DEFAULT_FIREMODE)=0.15 // 400 RPM
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.005
	// AmmoCost(DEFAULT_FIREMODE)=1
	FireOffset=(X=30,Y=4.5,Z=-4)
	LastFireInterval=0.2

	SelfDamageReductionValue=0.14f;

	FullChargedTimerInterval=2.0f
    MaxChargeTime=1.0
    ValueIncreaseTime=0.2 //0.2
    DmgIncreasePerCharge=1 //0.8
    ZapDmgIncreasePerCharge=10
    AmmoIncreasePerCharge=1

    // Charging effects
	ChargingEffect=ParticleSystem'DROW3_EMIT.FX_LardPD4K_Charging'
	ChargedEffect=ParticleSystem'DROW3_EMIT.FX_LardPD4K_Charged'

	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LazerCutter_Beam_Shoot_LP_Level_2_3P', FirstPersonCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LazerCutter_Beam_Shoot_LP_Level_2_1P')
	FullyChargedSound=(DefaultCue = AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_3_3P', FirstPersonCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_3_1P')
	WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Shoot_1P')
	
	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=true

	// ALTFIRE_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_FNFAl'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_FNFAL.Play_WEP_FNFAL_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Shooting Animations
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
}