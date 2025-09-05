class KFProj_Snark extends KFProj_Nail_Nailgun
	hidedropdown;

var float FuseTime;

// var bool bRadiusReady;
// var float Radius;
// var float ReplayRadiusDelay;
// var int ZapDamage;
// var Controller OriginalOwnerController;

/** Sound to play on throw */
var SoundCue ThrowSoundCue;
/** Sound to play when bouncing */
var SoundCue BounceSoundCue;

/** How much to offset the emitter mesh when the grenade has landed so that it doesn't penetrate the ground */
var() vector LandedTranslationOffset;

/*
// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
    if( bNetInitial )
        LockedTarget;
}
*/

simulated function SpawnFlightEffects()
{
	super.SpawnFlightEffects();

	PlaySoundBase( ThrowSoundCue );
}

// Make sure that last location always exists.
simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

	// OriginalOwnerController = InstigatorController;

    if (Role == ROLE_Authority)
	{
	   SetTimer(FuseTime, false, 'Timer_Detonate');
	}
}

function Timer_Detonate()
{
	Detonate();
}

simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) );
	}
}

/** Causes charge to explode */
function Detonate()
{
	local vector ExplosionNormal;

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

/*
function SetLockedTarget( KFPawn NewTarget )
{
    LockedTarget = NewTarget;
}
*/

simulated function Tick( float DeltaTime )
{
    // local vector TargetImpactPos, DirToTarget;

    super.Tick(DeltaTime);

    // if ( WorldInfo.NetMode != NM_DedicatedServer && Physics != PHYS_None )
    // {
    //     SetRotation(Rotator(Normal(Velocity)));
    // }

    // Skip the first frame, then start seeking
    if( !bHasExploded
        /*&& LockedTarget != none*/
        && Physics == PHYS_Falling
        /*&& Velocity != vect(0,0,0)
        && LockedTarget.IsAliveAndWell()*/)
    {
        // Grab our desired relative impact location from the weapon class
        // TargetImpactPos = class'KFWeap_Snark'.static.GetLockedTargetLoc( LockedTarget );

        // Seek towards target
        // Speed = VSize( Velocity );
        // DirToTarget = Normal( TargetImpactPos - Location );
        // Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

        // Aim rotation towards velocity every frame
        SetRotation( rotator(Velocity) );
    }
}

simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	local TraceHitInfo HitInfo;

    // Don't bounce any more if being used to pin a zed
    if( bSpawnedForPin )
    {
        BouncesLeft=0;
    }

	SetRotation(rotator(Normal(Velocity)));
    SetPhysics(PHYS_Falling); //PHYS_Falling

	// check to make sure we didn't hit a pawn
	if ( Pawn(Wall) != none )
	{
		return;
	}

	// if we are moving too slowly stop moving and lay down flat
	// also, don't allow rest on -Z surfaces.
	if ( Speed < 55 && HitNormal.Z > 0 )
	{
		ImpactedActor = Wall;
		GrenadeIsAtRest();
	}

	PlaySoundBase( BounceSoundCue );

    // Should hit destructibles without bouncing
	if (!Wall.bStatic && bDamageDestructiblesOnTouch && Wall.bProjTarget)
	{
		Wall.TakeDamage(Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), MyDamageType, HitInfo, self);
		Explode(Location, HitNormal);
	}
	// check if we should do a bounce, otherwise stick
    else if( !Bounce(HitNormal, Wall) )
    {
        // Turn off the corona when it stops
    	if ( WorldInfo.NetMode != NM_DedicatedServer && ProjEffects!=None )
    	{
            ProjEffects.DeactivateSystem();
        }

        // if our last hit is a destructible, don't stick
        if ( !Wall.bStatic && !Wall.bWorldGeometry && Wall.bProjTarget )
    	{
            Explode(Location, HitNormal);
            ImpactedActor = None;
    	}
        else
        {
        	// Play the bullet impact sound and effects
        	if ( WorldInfo.NetMode != NM_DedicatedServer )
        	{
        		`ImpactEffectManager.PlayImpactEffects(Location, Instigator, HitNormal);
        	}

            SetPhysics(PHYS_None);

        	// Stop ambient sounds when this projectile ShutsDown
        	if( bStopAmbientSoundOnExplode )
        	{
                StopAmbientSound();
        	}

			//@todo: check for pinned victim
        }

        bBounce = false;
    }
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
    // @todo: Implement functionality properly choosing which actors to
    // ProcessTouch for when this projectile is being used to pin ragdolls

			// if (Role == ROLE_Authority)
			// {
			// 	GotoState('RadiusState');
			// }

    if ( Other != Instigator && !Other.bWorldGeometry && Other.bCanBeDamaged )
    {
        if ( Pawn(other) != None )
        {
            Super.ProcessTouch(Other, HitLocation, HitNormal);
        }
        else
        {
            ProcessDestructibleTouchOnBounce( Other, HitLocation, HitNormal );
        }
    }
    else
    {
        Super.ProcessTouch(Other, HitLocation, HitNormal);;
    }
}

// Called once the grenade has finished moving
simulated event GrenadeIsAtRest()
{
    local rotator NewRotation;
	SetPhysics(PHYS_None);

	if( ProjEffects != none )
	{
        ProjEffects.SetTranslation(LandedTranslationOffset);
    }

	RotationRate.Yaw = 0;
	RotationRate.Pitch = 0;
	RotationRate.Roll = 0;
	// NewRotation.Pitch=16384;
	// SetRotation(NewRotation);

	// Apply some random yaw
	NewRotation.Pitch = Rand( 65535 ); //16384
	SetRelativeRotation( NewRotation );
}

/*
state RadiusState
{
	simulated event BeginState(Name PrevStateName)
	{
		super.BeginState(PrevStateName);
		
		bRadiusReady = true;
	}

	simulated event Tick(float DeltaTime)
	{
		local KFPawn_Monster Victim;
		local int TotalDamage;
		local TraceHitInfo HitInfo;

		if ( bRadiusReady )
		{
			bRadiusReady = false;
	
			if (Role == ROLE_Authority)
			{
				SetTimer(ReplayRadiusDelay, false, 'RadiusLoading');
			}

			foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
			{
				if( Victim.IsAliveAndWell() )
				{
					if ( ZapDamage > 0 )
					{
						TotalDamage = ZapDamage * UpgradeDamageMod;
						Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
					}
				}
			}
		}
	}
}

function RadiusLoading()
{
	bRadiusReady = true;
	// GotoState('RadiusState');
}
*/

/*
simulated event Tick(float DeltaTime)
{
	local KFPawn_Monster Victim;
	local int TotalDamage;
	local TraceHitInfo HitInfo;

	super.Tick(DeltaTime);

	if ( bRadiusReady )
	{
		bRadiusReady = false;
	
		if (Role == ROLE_Authority)
		{
			SetTimer(ReplayRadiusDelay, false, 'RadiusLoading');
		}

		foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
		{
			if( Victim.IsAliveAndWell() )
			{
				if ( ZapDamage > 0 )
				{
					TotalDamage = ZapDamage * UpgradeDamageMod;
					Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
				}
			}
		}
	}
}

function RadiusLoading()
{
	bRadiusReady = true;
	// GotoState('RadiusState');
}
*/

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Falling
	MaxSpeed=2000
	Speed=2000
	TossZ=0
	GravityScale=1.0
	PostExplosionLifetime=1

    LandedTranslationOffset=(X=2)

	FuseTime=5

    // SeekStrength=105000.0f  // 228000.0f

	// bRadiusReady=true
	// Radius=70
	// ReplayRadiusDelay=1
	// ZapDamage=30 //25
	
	ThrowSoundCue=SoundCue'WEP_Snark_SND.snark_deploy_Cue'
	BounceSoundCue=SoundCue'WEP_Snark_SND.snark_hunt_Cue'

    // Projectile
	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_Snark'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Snark'
	ImpactEffects=KFImpactEffectInfo'WEP_Snark_ARCH.Snark_Bounce'

	bPinned=false;
    BouncesLeft=32
    DampingFactor=0.92 //1f 0.8 
    RicochetEffects=KFImpactEffectInfo'WEP_Snark_ARCH.Snark_Bounce'

	ExplosionActorClass=class'KFExplosionActor'

	// Projectile light
	Begin Object Class=PointLightComponent Name=PointLight0
	    LightColor=(R=0,G=252,B=0,A=255)
		Brightness=0.5f
		Radius=200.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=true
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	ProjFlightLight=PointLight0

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=100
		DamageRadius=200 //300
		DamageFalloffExponent=2.f //2
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Snark'

		MomentumTransferScale=1 //10000
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_Snark_ARCH.Snark_Explosion'
		ExplosionSound=SoundCue'WEP_Snark_SND.snark_blast_Cue'

		// Camera Shake
		CamShake=KFCameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}