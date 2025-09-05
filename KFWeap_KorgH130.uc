class KFWeap_KorgH130 extends KFWeap_Minigun;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

/*
// Last time a submunition projectile was fired from this weapon
var float LastSubmunitionFireTime;
var transient bool AlreadyIssuedCanNuke;

simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFProjectile Proj;

	AlreadyIssuedCanNuke = false;

	Proj = Super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);

	AlreadyIssuedCanNuke = false;

	return Proj;
}

simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Bullet_KorgH130 Proj;

	Proj = KFProj_Bullet_KorgH130(Super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir));

	if (AlreadyIssuedCanNuke == false)
	{
		Proj.bCanNuke = true;
		AlreadyIssuedCanNuke = true;
	}
	else
	{
		Proj.bCanNuke = false;
	}

	return Proj;
}
*/

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
}

// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    // local KFPawn TargetPawn;

    MyProjectileClass = GetKFProjectileClass();

	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

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
            DirB = AimDir;

			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

    		DirA = AimDir;

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

simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
	}
}

static simulated event EFilterTypeUI GetAltTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
    // Inventory / Grouping
	InventoryGroup=IG_Primary
	InventorySize=9 //10
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_KorgH130_MAT.UI_WeaponSelect_KorgH130'
   	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'
   	AssociatedPerkClasses(1)=class'KFPerk_Commando'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

    // FOV
	MeshFOV=86
	MeshIronSightFOV=82
	PlayerIronSightFOV=82
	PlayerSprintFOV=95

   	// Zooming/Position
	PlayerViewOffset=(X=3.0,Y=15,Z=15)
	IronSightPosition=(X=3.0,Y=15,Z=15)

	// Content
	PackageKey="KorgH130"
	FirstPersonMeshName="WEP_KorgH130_MESH.Wep_1stP_KorgH130_Rig"
	FirstPersonAnimSetNames(0)="wep_1p_minigun_anim.Wep_1stP_Minigun_Anim"
	PickupMeshName="WEP_KorgH130_MESH.Wep_Pickup_KorgH130"
	AttachmentArchetypeName="WEP_KorgH130_ARCH.Wep_KorgH130_3P"
	MuzzleFlashTemplateName="WEP_KorgH130_ARCH.Wep_KorgH130_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=200
	SpareAmmoCapacity[0]=600 //700
	InitialSpareMags[0]=1
	AmmoPickupScale[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=200
	minRecoilPitch=150
	maxRecoilYaw=130
	minRecoilYaw=-130
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.25
	IronSightMeshFOVCompensationScale=1
    HippedRecoilModifier=1.5

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponWindingUp
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_KorgH130'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_KorgH130'
	InstantHitDamage(DEFAULT_FIREMODE)=38
	FireInterval(DEFAULT_FIREMODE)=+0.05 // 1200 RPM
	Spread(DEFAULT_FIREMODE)=0.13
	PenetrationPower(DEFAULT_FIREMODE)=0.0
	FireOffset=(X=30,Y=4.5,Z=-5)

	SelfDamageReductionValue=0.10f; //0.16

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponWindingUp
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	Begin Object Name=FirstPersonMesh
		// new anim tree with skelcontrol to rotate cylinders
		AnimTreeTemplate=AnimTree'WEP_Minigun_ARCH.WEP_Animtree_Minigun_1p'
	End Object

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Minigun'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Shoot_Loop_3P', FirstPersonCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Shoot_Loop_1P')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Minigun.Play_WEP_Mingun_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_Minigun.Play_WEP_Mingun_Shoot_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_KorgH130_SND.mfire1_3P_Cue', FirstPersonCue=SoundCue'WEP_KorgH130_SND.mfire1_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_L85A2.Play_WEP_SA_L85A2_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_L85A2.Play_WEP_SA_L85A2_Handling_DryFire'

	BarrelRotationLoopSound=(DefaultCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Loop_3P', FirstPersonCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Loop_1P')
	BarrelStopRotationSound=(DefaultCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Decelerate_3P', FirstPersonCue=AkEvent'WW_WEP_Minigun.Play_WEP_Minigun_Decelerate_1P')

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=false
	bHasFlashlight=false

	EjectedShellForegroundDuration=0.8f
	
	// Camera shake animation
	ShootCameraAnim=CameraAnim'WEP_1P_Minigun_ANIM.Shoot'
	ShootCameraAnimPlayRate=1.0f //0.6f
	ShootCameraAnimScale=0.19f //0.25f
	ShootCameraAnimBlendTime=0.1f
	
	// Wind Up variables
	WindUpActivationTime=0.25 //0.70
	WindUpRotationSpeed=1400 //1200

	// movement and rotation speed values when winding up
	WindUpViewRotationSpeed=2000 // base rotation speed is 2000
	WindUpPawnMovementSpeed=1f //0.9f || base modifier is 1
	
	// movement and rotation speed values when firing
	FiringViewRotationSpeed=2000 //488 //320 //270
	FiringPawnMovementSpeed=0.95f //0.75f

	// AlreadyIssuedCanNuke = false
}