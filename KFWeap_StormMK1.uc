class KFWeap_StormMK1 extends KFWeap_Rifle_MosinNagant;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

// Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion)
var() float SelfDamageReductionValue;

// Particle system
var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

/* Light that is applied to the blade and the bone to attach to*/
var PointLightComponent IdleLight;
var Name LightAttachBone;

// Explodes on hit
var GameExplosion ExplosionTemplate;
var transient ParticleSystemComponent ExplosionPSC;
var ParticleSystem ExplosionEffect;

var float ExplosionOriginalDamage;

var bool bWasTimeDilated;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	ExplosionOriginalDamage = ExplosionTemplate.Damage;
}

// When this weapon hits with melee attack
simulated function NotifyMeleeCollision(Actor HitActor, optional vector HitLocation)
{
	local KFPawn_Monster Victim;
	local KFExplosionActorReplicated ExploActor;

	// On local player or server, we cache off our time dilation setting here
	if (WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_DedicatedServer || Instigator.Controller != None)
	{
		bWasTimeDilated = WorldInfo.TimeDilation < 1.f;
	}

	if (HitActor.bWorldGeometry)
	{
		return;
	}
	
	Victim = KFPawn_Monster(HitActor);
	if ( Victim == None || (Victim.bPlayedDeath && `TimeSince(Victim.TimeOfDeath) > 0.f) )
	{
		return;
	}

	if ( Role == ROLE_Authority && Instigator != None && Instigator.IsLocallyControlled() )
	{
		// Nudge explosion location
		// HitLocation = HitLocation + (vect(0,0,1) * 128.f);
	
		// Explode using the given template
		ExploActor = Spawn(class'KFExplosionActorReplicated', self,, HitLocation, rotator(vect(0,0,1)),, true);
		if (ExploActor != None)
		{
			ExploActor.InstigatorController = Instigator.Controller;
			ExploActor.Instigator = Instigator;
			ExploActor.bIgnoreInstigator = true;
			ExplosionTemplate.Damage = ExplosionOriginalDamage * GetUpgradeDamageMod(BASH_FIREMODE);
	
			ExploActor.Explode(ExplosionTemplate);
		}

		// tell remote clients that we fired, to trigger effects in third person
		// IncrementFlashCount();
	}
	
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (ExplosionEffect != None)
		{
			ExplosionPSC = WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionEffect, HitLocation, rotator(vect(0,0,1)));
			ExplosionPSC.ActivateSystem();
		}
	}
}

simulated state WeaponEquipping
{
	// when picked up, start the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'Particle');

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		// OutPSC.SetAbsolute(false, false, false);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if (ParticlePSC != none)
	{
		ParticlePSC.SetFOV(NewFOV);
	}
}

simulated state Inactive
{
	// when dropped, destroyed, etc, play the stop on the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}

		IdleLight.SetEnabled(false);
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

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
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

defaultproperties
{
	// Inventory / Grouping
	InventorySize=7
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_StormMK1_MAT.UI_WeaponSelect_StormMK1'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

	// Zooming/Position
	IronSightPosition=(X=0,Y=0,Z=-0.9)

	// Content
	PackageKey="StormMK1"
	FirstPersonMeshName="WEP_StormMK1_MESH.WEP_1stP_StormMK1_Rig"
	FirstPersonAnimSetNames(0)="wep_1p_mosin_anim.Wep_1stP_Mosin_ANIM"
	PickupMeshName="WEP_StormMK1_MESH.WEP_StormMK1_Pickup"
	AttachmentArchetypeName="WEP_StormMK1_ARCH.WEP_StormMK1_Trail_3P"
	MuzzleFlashTemplateName="WEP_StormMK1_ARCH.Wep_StormMK1_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=5
	SpareAmmoCapacity[0]=50
	InitialSpareMags[0]=5

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Electricity'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_StormMK1'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_StormMK1'
	InstantHitDamage(DEFAULT_FIREMODE)=60 //50
	FireInterval(DEFAULT_FIREMODE)=0.85 // 60 RPM
	Spread(DEFAULT_FIREMODE)=0.007
	PenetrationPower(DEFAULT_FIREMODE)=0
	AmmoCost(DEFAULT_FIREMODE)=1
	LastFireInterval=0.5

	SelfDamageReductionValue=0.14f;

	// BASH_FIREMODE
	FiringStatesArray(BASH_FIREMODE)=MeleeAttackBasic
	WeaponFireTypes(BASH_FIREMODE)=EWFT_Custom
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Piercing_MosinNagant'
	InstantHitDamage(BASH_FIREMODE)=100
	InstantHitMomentum(BASH_FIREMODE)=10000.f

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=0,G=75,B=100,A=255)
		Brightness=0.5f
		Radius=400.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	ExplosionEffect=ParticleSystem'DROW3_EMIT.FX_LardPD4K_Explosion'

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=30 //25
        DamageRadius=400 //300
		DamageFalloffExponent=0.5f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_StormMK1'

		MomentumTransferScale=10000
		bAlwaysFullDamage=true
		bDoCylinderCheck=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		// ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'ww_wep_hrg_energy.Play_WEP_HRG_Energy_Impact'
		// ExplosionEffects=KFImpactEffectInfo'WEP_Saiga12_ARCH.WEP_Saiga12_Impacts'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		bIgnoreInstigator=true
		ActorClassToIgnoreForDamage=class'KFPawn_Human'

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=150
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue = AkEvent'WW_WEP_MosinNagant.Play_MosinNagant_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_MosinNagant.Play_MosinNagant_Shoot_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_StormMK1_SND.malivan_sniper_fire_1P_Cue', FirstPersonCue=SoundCue'WEP_StormMK1_SND.malivan_sniper_fire_1P_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_MosinNagant.Play_MosinNagant_DryFire'

	// Particle system
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DROW3_EMIT.FX_Storm_ParticleFX'

    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=0,G=75,B=100,A=255)
		Brightness=1.5f //0.125f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)

		// light anim
        AnimationType=1 // 2 > LightAnim_Blink
        AnimationFrequency=0.2f
        MinBrightness=0.f
        MaxBrightness=1.5f
	End Object
	IdleLight=IdlePointLight
	LightAttachBone=Particle
}