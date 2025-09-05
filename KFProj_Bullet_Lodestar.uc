class KFProj_Bullet_Lodestar extends KFProj_BallisticExplosive;

var transient ParticleSystemComponent HeadshotEffectPSC;
var ParticleSystem HeadshotEffect;

var float Radius;

// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

var Controller OriginalOwnerController;

var int ZapDamage;

replication
{
	if( bNetInitial )
		LockedTarget;
}

simulated event PreBeginPlay()
{
    super.PreBeginPlay();

	OriginalOwnerController = InstigatorController;
}

function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}

simulated event Tick( float DeltaTime )
{
	local vector TargetImpactPos, DirToTarget;

	// local KFPawn_Monster Victim;

	super.Tick( DeltaTime );

	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.01f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_Lodestar'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	// if (ClassIsChildOf(Other.class, class'KFPawn_Monster'))
	// {
	// 	bWaveActive = true;
	// }

	local KFPawn_Monster Victim;

	local int TotalDamage;
	local TraceHitInfo HitInfo;

	foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
	{
		if( Victim.IsAliveAndWell() )
		{
			if ( ZapDamage > 0 )
			{
				HeadshotEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( HeadshotEffect, Victim.Mesh, 'Head', true );
				HeadshotEffectPSC.SetAbsolute(false, true, true);

				TotalDamage = ZapDamage * UpgradeDamageMod;
				Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
			}
		}
	}

	super.ProcessTouch(Other, HitLocation, HitNormal);
}

simulated function AdjustCanDisintigrate(){}

simulated protected function PrepareExplosionTemplate()
{
	// skip KFProj_BallisticExplosive because it applies Demo skills
    super(KFProjectile).PrepareExplosionTemplate();
}

simulated protected function SetExplosionActorClass()
{
	// skip KFProj_BallisticExplosive because it applies Demo skills
    super(KFProjectile).SetExplosionActorClass();
}

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=5000 //6500
	MaxSpeed=5000
	TerminalVelocity=5000
	TossZ=0
	GravityScale=1.0
    ArmDistSquared=0
	LifeSpan=+10.0f

	TouchTimeThreshhold=0.0

    SeekStrength=428000.0f //528000.0f

    HeadshotEffect=ParticleSystem'DROW3_EMIT.FX_HeadshotEffect_Single'
	Radius=300 //200
	ZapDamage=30 //25

/*
	bSpawnShrapnel=true
	bDebugShrapnel=false

	NumSpawnedShrapnel=4
	ShrapnelSpreadWidthEnvironment=0.75
	ShrapnelSpreadHeightEnvironment=0.75
	ShrapnelSpreadWidthZed=0.75
	ShrapnelSpreadHeightZed=0.75
	ShrapnelClass = class'KFProj_Bullet_Lodestar_Icicles'
	// ShrapnelSpawnSoundEvent = AkEvent'WW_WEP_ChiappaRhinos.Play_WEP_ChiappaRhinos_Bullet_Fragmentation'
	// ShrapnelSpawnVFX=ParticleSystem'WEP_ChiappaRhino_EMIT.FX_ChiappaRhino_Shrapnel_Hit'
*/
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=6
		CollisionHeight=6
	End Object

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_LodeStar_Tracer'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_LodeStar_Tracer'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=50,G=100,B=150,A=255)
		Brightness=1.f
		Radius=1500.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=40 //45
		DamageRadius=300
		DamageFalloffExponent=1 //0.5
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Lodestar'

		//Impulse applied to Zeds
		MomentumTransferScale=1
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_Lodestar_ARCH.FX_Lodestar_Explosion'
		ExplosionSound=AkEvent'WW_WEP_Flare_Gun.Play_WEP_Flare_Gun_Explode_Ice'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}