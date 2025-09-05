class KFProj_Bullet_Kruton9000_ALT extends KFProj_BallisticExplosive;
    // implements(KFInterface_DamageCauser);

/*
var float DamageScale;
var float IncapScale;

// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget;
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
		TargetImpactPos = class'KFWeap_Kruton9000'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

simulated protected function PrepareExplosionActor(GameExplosionActor GEA)
{
    local KFExplosionActor_HuskCannon HuskExplode;

    HuskExplode = KFExplosionActor_HuskCannon(GEA);
    if (HuskExplode != None)
    {
        HuskExplode.DamageScale = DamageScale;
    }
}

// KFInterface_DamageCauser
function float GetIncapMod()
{
    return IncapScale;
}
*/

/** Explosion actor class to use for ground fire */
var const protected class<KFExplosionActorLingering> GroundExplosionActorClass;
/** Explosion template to use for ground fire */
var KFGameExplosion GroundExplosionTemplate;

/** How long the ground fire should stick around */
var const protected float EffectDuration;
/** How often, in seconds, we should apply burn */
var const protected float DamageInterval;

var bool bSpawnGroundFire;

replication
{
	if (bNetInitial)
		bSpawnGroundFire;
}

// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	local KFWeap_Kruton9000 Cannon;

	if (Role == ROLE_Authority)
	{
		Cannon = KFWeap_Kruton9000(Owner);
		if (Cannon != none)
		{
			bSpawnGroundFire = true;
		}
	}

	Super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFExplosionActorLingering GFExplosionActor;
	local vector GroundExplosionHitNormal;

	if (bHasDisintegrated)
	{
		return;
	}

	if (!bHasExploded && bSpawnGroundFire)
	{
		GroundExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(GroundExplosionActorClass, self, , HitLocation + (HitNormal * 32.f), rotator(HitNormal));
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			GroundExplosionTemplate.HitLocation = HitLocation;
			GroundExplosionTemplate.HitNormal = GroundExplosionHitNormal;

			// Apply explosion direction
			if (GroundExplosionTemplate.bDirectionalExplosion)
			{
				GroundExplosionHitNormal = GetExplosionDirection(GroundExplosionHitNormal);
			}

			// Set our duration
			GFExplosionActor.MaxTime = EffectDuration;
			// Set our burn interval
			GFExplosionActor.Interval = DamageInterval;
			// Boom
			GFExplosionActor.Explode(GroundExplosionTemplate, GroundExplosionHitNormal);
		}
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

// Ignore damage over time for ice floor
simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	GroundExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
    MaxSpeed=8000 //5000
    Speed=8000
	TossZ=0
	GravityScale=1.0
    ArmDistSquared=0

    // SeekStrength=428000.0f //528000.0f

    DamageRadius=0

	// Ground electricity
	EffectDuration=5.1f
	DamageInterval=1.5f // 2.5x
	GroundExplosionActorClass=class'KFExplosion_Kruton9000'

	// Ground effect
	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=40 //10
		DamageRadius=300
		DamageFalloffExponent=1.f
		DamageDelay=0.f

        bIgnoreInstigator=true // don't passively kill player
		MomentumTransferScale=1
		bDirectionalExplosion=true // rotate fire effect based on angle ( don't, rotate effect inside sdk for wall and ceiling )

		// Damage Effects
		MyDamageType=class'KFDT_EMP_Kruton9000' // it should continuously hurt zed then emp him and repeat
		KnockDownStrength=0
		FractureMeshRadius=0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_GroundFire' // ground fire effect is inside class

		// Camera Shake
		CamShake=none
	End Object
	GroundExplosionTemplate=ExploTemplate1

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Tracer_ALT'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Tracer_ALT'

	// ExplosionActorClass=class'KFExplosionActor_HuskCannon'

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
		Damage=40
		DamageRadius=300 //200
		DamageFalloffExponent=1 //0.5
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Kruton9000'

		//Impulse applied to Zeds
		MomentumTransferScale=1
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_Laser_Cutter_ARCH.Laser_Cutter_bullet_impact'
		ExplosionSound=AkEvent'ww_wep_hrg_energy.Play_WEP_HRG_Energy_AltFire_Impact' // ww_wep_hrg_energy.Play_WEP_HRG_Energy_Impact

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