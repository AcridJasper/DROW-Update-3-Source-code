class KFProj_Thrown_ProxyC4 extends KFProjectile;

/** "beep" sound to play (on an interval) when instigator is within blast radius */
// var() AkEvent ProximityAlertAkEvent;
/** Time between proximity beeps */
var() float ProximityAlertInterval;
/** Time between proximity beeps when the instigator is within "fatal" radius */
var() float ProximityAlertIntervalClose;
/** Time until next alert */
var transient float ProximityAlertTimer;

/** Dynamic light for blinking */
var PointLightComponent BlinkLightComp;
/** Blink colors */
var LinearColor BlinkColorOn, BlinkColorOff;
/** How long LED and dynamic light should stay lit for */
var float BlinkTime;

var ParticleSystem BlinkFX;
var ParticleSystemComponent BlinkPSC;

/** Visual component of this projectile (we don't use ProjEffects particle system because we need to manipulate the MIC) */
var StaticMeshComponent ChargeMesh;
/** Mesh MIC, used to make LED blink */
var MaterialInstanceConstant ChargeMIC;

// How long to wait until this grenade explodes
var() float FuseTime;

// Information about grenade bounce effects for this class
var KFImpactEffectInfo GrenadeBounceEffectInfo;
// Dampen amount for every bounce
var() float DampenFactor;
// Dampen amount for parallel angle to velocity
var() float DampenFactorParallel;

/** Sound bomb makes when it hits something and comes to rest */
var AkEvent LandedAkEvent;

/** This is the effect indicator that is played for the current user **/
// var(Projectile) ParticleSystem ProjIndicatorTemplate;
// var ParticleSystemComponent	ProjIndicatorEffects;

// var bool IndicatorActive;

// Cached team number, because players can switch teams
var byte TeamNum;
var bool bCantBeTouchedByInstigator;
var bool bCantDetonateOnFullHP;	

// Armed mine collision settings
var float ExplodeTriggerRadius, ExplodeTriggerHeight;

/** Tells clients to trigger an explosion */
var repnotify bool bClientExplode;
/** Set on the server and replicated to clients. Ensures that even if Instigator isn't relevant, we still have a valid team */
// var repnotify byte TeamNum;

replication
{
	if( bNetDirty )
		bClientExplode;

	// if( bNetInitial && !bNetOwner )
		// TeamNum;
}

simulated event ReplicatedEvent( name VarName )
{
	if( VarName == nameOf(bClientExplode) )
	{
		TriggerExplosion( Location, vect(0,0,1), none );
	}
	else
	{
		super.ReplicatedEvent( VarName );
	}

	// switch (VarName)
	// {
	// case nameof(bClientExplode):
	// 	TriggerExplosion( Location, vect(0,0,1), none );
	// 	break;
	// case nameof(TeamNum):
	// 	EnableGrenadeWarning();
	// 	break;
	// default:
	// 	super.ReplicatedEvent(VarName);
	// };
}

/*
// Toggles an emitter in the projectile effects particle system to display a warning sprite
simulated function EnableGrenadeWarning()
{
	local PlayerController LocalPC;

	if( ProjEffects == none || GetTeamNum() != 0 )
	{
		return;
	}

	LocalPC = GetALocalPlayerController();
	if( LocalPC != none && !LocalPC.IsSpectating() && LocalPC.GetTeamNum() != GetTeamNum() )
	{
		ProjEffects.SetFloatParameter( 'Warning' , 0.75f );
	}
}
*/

// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	// Cache team num
	TeamNum = GetTeamNum();

	Super.PostBeginPlay();

	ProximityAlertTimer = ProximityAlertInterval;
	ChargeMIC = ChargeMesh.CreateAndSetMaterialInstanceConstant(0);

	RandSpin(100000);

	// fuze starts at grenade rest
	ClearTimer(nameof(ExplodeTimer));

	AdjustCanDisintigrate();
}

/** Used to check current status of StuckTo actor (to figure out if we should fall) */
simulated event Tick( float DeltaTime )
{
	super.Tick(DeltaTime);
	// StickHelper.Tick(DeltaTime);

	// if (StuckToActor != none)
	if ( Speed < 40 )
	{
		UpdateAlert(DeltaTime);
	}
}

/** Checks if deployed charge should play a warning "beep" for the instigator. Beeps faster if the instigator is within "lethal" range. */
simulated function UpdateAlert( float DeltaTime )
{
	local vector ToInstigator, BBoxCenter;
	local float DistToInstigator, DamageScale;
	local Actor TraceActor;
	local Box BBox;

	if( WorldInfo.NetMode == NM_DedicatedServer )
	{
		return;
	}

	if( bHasExploded || bHasDisintegrated )
	{
		return;
	}

	if( ProximityAlertTimer <= 0 )
	{
		return;
	}

	ProximityAlertTimer -= DeltaTime;

	if( ProximityAlertTimer > 0 )
	{
		return;
	}

	ProximityAlertTimer = ProximityAlertInterval;

	// only play sound for instigator (based on distance)
	if( Instigator != none && Instigator.IsLocallyControlled() )
	{
		ToInstigator = Instigator.Location - Location;
		DistToInstigator = VSize( ToInstigator );
		if( DistToInstigator <= ExplosionTemplate.DamageRadius )
		{
			Instigator.GetComponentsBoundingBox(BBox);
			BBoxCenter = (BBox.Min + BBox.Max) * 0.5f;
			TraceActor = class'GameExplosionActor'.static.StaticTraceExplosive(BBoxCenter, Location + vect(0,0,20), self);
			if( TraceActor == none || TraceActor == Instigator )
			{
				DamageScale = FClamp(1.f - DistToInstigator/ExplosionTemplate.DamageRadius, 0.f, 1.f);
				DamageScale = DamageScale ** ExplosionTemplate.DamageFalloffExponent;

				if( ExplosionTemplate.Damage * DamageScale > Instigator.Health )
				{
					ProximityAlertTimer = ProximityAlertIntervalClose;
				}

				// TryActivateIndicator();

				// PlaySoundBase( ProximityAlertAkEvent, true );
			}
		}
	}

	// blink for everyone to see
	BlinkOn();
}

/** Turns on LED and dynamic light */
simulated function BlinkOn()
{
	if( BlinkPSC == none )
	{
		BlinkPSC = WorldInfo.MyEmitterPool.SpawnEmitter(BlinkFX, Location + (vect(0,0,4) + vect(8,0,0) >> Rotation),, self,,, true);
	}

	BlinkPSC.SetFloatParameter('Glow', 1.0);

	ChargeMIC.SetVectorParameterValue('Vector_GlowColor', BlinkColorOn);
	BlinkLightComp.SetEnabled( true );
	SetTimer( BlinkTime, false, nameof(BlinkOff) );
}

/** Turns off LED and dynamic light */
simulated function BlinkOff()
{
	if( BlinkPSC != none )
	{
		BlinkPSC.SetFloatParameter('Glow', 0.0);
	}

	ChargeMIC.SetVectorParameterValue('Vector_GlowColor', BlinkColorOff);
	BlinkLightComp.SetEnabled( false );
}

/*
simulated function TryActivateIndicator()
{
	if(!IndicatorActive && Instigator != None)
	{
		IndicatorActive = true;

		if(WorldInfo.NetMode == NM_Standalone || Instigator.Role == Role_AutonomousProxy ||
		 (Instigator.Role == ROLE_Authority && WorldInfo.NetMode == NM_ListenServer && Instigator.IsLocallyControlled() ))
		{
			if( ProjIndicatorTemplate != None )
			{
			    ProjIndicatorEffects = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjIndicatorTemplate);
			}

			if(ProjIndicatorEffects != None)
			{
				ProjIndicatorEffects.SetAbsolute(true, true, false);
				ProjIndicatorEffects.SetLODLevel(WorldInfo.bDropDetail ? 1 : 0);
				ProjIndicatorEffects.bUpdateComponentInTick = true;
				AttachComponent(ProjIndicatorEffects);
			}
		}
	}
}

simulated protected function StopSimulating()
{
	super.StopSimulating();

	if (ProjIndicatorEffects!=None)
	{
        ProjIndicatorEffects.DeactivateSystem();
	}
}
*/

// simulated function SetStickOrientation(vector HitNormal)
// {
// 	local rotator StickRot;

// 	StickRot = CalculateStickOrientation(HitNormal);
//    	SetRotation(StickRot);
// }

/** Causes charge to explode */
function Detonate()
{
	local KFWeap_ProxyC4 BombOwner;
	local vector ExplosionNormal;

	if (Role == ROLE_Authority)
    {
    	BombOwner = KFWeap_ProxyC4(Owner);
    	if (BombOwner != none)
    	{
    		BombOwner.RemoveDeployedCharge(, self);
    	}
    }

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

simulated function Disintegrate( rotator InDisintegrateEffectRotation )
{
	local KFWeap_ProxyC4 BombOwner;

	if (Role == ROLE_Authority)
    {
    	BombOwner = KFWeap_ProxyC4(Owner);
    	if (BombOwner != none)
    	{
    		BombOwner.RemoveDeployedCharge(, self);
    	}
    }

    super.Disintegrate(InDisintegrateEffectRotation);
}

/** Blows up on a timer */
function ExplodeTimer()
{
	Detonate();
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(ExplodeTimer) );
	}
}

simulated function Destroyed()
{
    local Actor HitActor;
    local vector HitLocation, HitNormal;
	local KFWeap_ProxyC4 BombOwner;

	// Final Failsafe check for explosion effect
	if (!bHasExploded && !bHasDisintegrated)
	{
		GetExplodeEffectLocation(HitLocation, HitNormal, HitActor);
        TriggerExplosion(HitLocation, HitNormal, HitActor);
	
		// bWaitActive = false;
	}

	// PLEASE for the love of fuck ass, detonate charges after weapon was dropped PLEASE
	if (Role == ROLE_Authority)
    {
    	BombOwner = KFWeap_ProxyC4(Owner);
    	if (BombOwner != none)
    	{
    		BombOwner.RemoveDeployedCharge(, self);
    	}
    }

	super.Destroyed();
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		BlinkOff();
	}

	Shutdown();	// cleanup/destroy projectile

	super.Explode( HitLocation, HitNormal );
}
// simulated function Explode(vector HitLocation, vector HitNormal)
// {
// 	Shutdown();	// cleanup/destroy projectile
// }

// Trace down and get the location to spawn the explosion effects and decal
simulated function GetExplodeEffectLocation(out vector HitLocation, out vector HitRotation, out Actor HitActor)
{
    local vector EffectStartTrace, EffectEndTrace;
	local TraceHitInfo HitInfo;

	EffectStartTrace = Location + vect(0,0,1) * 4.f;
	EffectEndTrace = EffectStartTrace - vect(0,0,1) * 32.f;

    // Find where to put the decal
	HitActor = Trace(HitLocation, HitRotation, EffectEndTrace, EffectStartTrace, false,, HitInfo, TRACEFLAG_Bullet);

	// If the locations are zero (probably because this exploded in the air) set defaults
    if( IsZero(HitLocation) )
    {
        HitLocation = Location;
    }

	if( IsZero(HitRotation) )
    {
        HitRotation = vect(0,0,1);
    }
}

// Give a little bounce
simulated event HitWall(vector HitNormal, Actor Wall, PrimitiveComponent WallComp)
{
	// check to make sure we didn't hit a pawn
	if ( Pawn(Wall) != none )
	{
		return;
	}

    Bounce( HitNormal, Wall );

	// if we are moving too slowly stop moving and lay down flat
	// also, don't allow rest on -Z surfaces.
	if ( Speed < 40 && HitNormal.Z > 0 )
	{
		ImpactedActor = Wall;
		GrenadeIsAtRest();
		PostAkEvent( LandedAkEvent, true, true, false );
		// EnableGrenadeWarning();
	}
}

// Adjusts movement/physics of projectile. Returns true if projectile actually bounced / was allowed to bounce
simulated function bool Bounce( vector HitNormal, Actor BouncedOff )
{
	local vector VNorm;

	if ( WorldInfo.NetMode != NM_DedicatedServer )
    {
        // do the impact effects
    	`ImpactEffectManager.PlayImpactEffects(Location, Instigator, HitNormal, GrenadeBounceEffectInfo, true );
    }

    // Reflect off BouncedOff w/damping
    VNorm = (Velocity dot HitNormal) * HitNormal;
    Velocity = -VNorm * DampenFactor + (Velocity - VNorm) * DampenFactorParallel;
    Speed = VSize(Velocity);

	// also done from ProcessDestructibleTouchOnBounce. update LastBounced to solve problem with bouncing rapidly between world/non-world geometry
	LastBounced.Actor = BouncedOff;
	LastBounced.Time = WorldInfo.TimeSeconds;

	return true;
}

// Called once the grenade has finished moving
simulated event GrenadeIsAtRest()
{
    // local rotator NewRotation;
	local rotator RandRot;
	SetPhysics(PHYS_None);

	// Set collisions and go into Armed state
    CylinderComponent.SetTraceBlocking( true, true );
	SetCollisionSize( ExplodeTriggerRadius, ExplodeTriggerHeight );
	CylinderComponent.SetActorCollision( true, false );
	bBounce = false;
	// Go to armed state here
	GotoState('Armed');

	// Optimize for network
	NetUpdateFrequency = 0.25f;
	bOnlyDirtyReplication = true;
	bForceNetUpdate = true;

    // fuze timer starts once grenade stops moving
	if( Role == ROLE_Authority )
	{
	   SetTimer(FuseTime, false, 'ExplodeTimer');
	}

	RotationRate.Yaw = 0;
	RotationRate.Pitch = 0;
	RotationRate.Roll = 0;

	// Apply some random yaw
	RandRot.Yaw = Rand( 65535 );
	SetRelativeRotation( RandRot );

	// NewRotation.Pitch=16384;
	// SetRotation(NewRotation);
}

// Validates a touch
simulated function bool ValidTouch( Pawn Other )
{
	// Make sure only enemies detonate
	if( Other.GetTeamNum() == TeamNum || !Other.IsAliveAndWell() )
	{
		return false;
	}

	// Make sure only enemies detonate
	if(bCantBeTouchedByInstigator == false)
	{
		if( Other.IsAliveAndWell() == false )
		{
			return false;
		}
		if(bCantDetonateOnFullHP)
		{
			if(Other.GetTeamNum() == TeamNum &&  Other.Health >= Other.HealthMax )
			{
				return false;
			}
		}
		// Make sure not touching through wall
		return FastTrace( Other.Location, Location,, true );
	}
	else
	{
		if(bCantDetonateOnFullHP)
		{
			if(Other.GetTeamNum() == TeamNum &&  Other.Health >= Other.HealthMax )
			{
				return false;
			}
		}

		if( Other.IsAliveAndWell() == false || Other == Instigator )
		{
			return false;
		}

		// Make sure not touching through wall
		return FastTrace( Other.Location, Location,, true );
	}

	return FastTrace( Other.Location, Location,, true );
}

// When touched by an actor
simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local KFPawn_Monster P;

	// if (KFProjectile(Other) != none)
	// {
	// 	// Make sure not touching through wall
	// 	if (`TimeSince(CreationTime) >= 0.1f && FastTrace( Other.Location, Location,, true ))
	// 	{
	// 		TriggerExplosion( Location, vect(0,0,1), KFProjectile(Other) );
	// 		return;
	// 	}
	// }

	// If touched by ballistic bouncer, explode
	if (KFProj_HRG_BallisticBouncer(Other) != none)
	{
		// Make sure not touching through wall
		if (`TimeSince(CreationTime) >= 0.1f && FastTrace( Other.Location, Location,, true ))
		{
			TriggerExplosion( Location, vect(0,0,1), KFProj_HRG_BallisticBouncer(Other) );
			return;
		}
	}

	// If touched by mine reconstructor, explode
	if (KFProj_Mine_Reconstructor(Other) != none)
	{
		// Make sure not touching through wall
		if (`TimeSince(CreationTime) >= 0.1f && FastTrace( Other.Location, Location,, true ))
		{
			TriggerExplosion( Location, vect(0,0,1), KFProj_Mine_Reconstructor(Other) );
			return;
		}
	}	

	// if( IsInState('Armed') )
	// {)

	// If touched by an enemy pawn in armed state, explode
	P = KFPawn_Monster( Other );
	if( P != None )
	{
		if( `TimeSince(CreationTime) >= 0.1f && ValidTouch(P) )
		{
			TriggerExplosion( Location, vect(0,0,1), P );
		}
	}
	else if( bBounce )
	{
		super.Touch( Other, OtherComp, HitLocation, HitNormal );
	}
}

// State where this mine is waiting to detonate (fail safe)
simulated state Armed
{
	// Make sure no pawn already touching
	simulated function CheckTouching()
	{
		local KFPawn_Monster P;
		
		foreach TouchingActors( class'KFPawn_Monster', P )
		{
			Touch( P, None, Location, Normal(Location - P.Location) );
		}
	}

	// Adjust collision
	simulated function BeginState( Name PreviousStateName )
	{
		if(Role != Role_Authority)
		{
			SetPhysics( PHYS_Falling );
			CheckTouching();
		}
	}
}

// Explode this mine
simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	super.TriggerExplosion( HitLocation, HitNormal, HitActor );

	SetHidden( true );

	// Tell clients to explode
	if( Role == ROLE_Authority )
	{
		bClientExplode = true;
		bForceNetUpdate = true;
	}
}

// Touching (bounces of a ZED)
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if ( Other != none && Other != Instigator && (!Other.bWorldGeometry || !Other.bStatic) )
	{
		if ( Pawn(other) != None )
		{
            // For opposing team, make the grenade stop and just start falling
			if( Pawn(Other).GetTeamNum() != GetTeamNum() )
			{
				// Setting SetCollision makes the grenade undetectable by the Siren's scream, so instead
				// disable Touch & HitWall event notifications. If there's a problem with using execDisable, we
				// can add a new flag instead, like "bStopBounce" to exit ProcessTouch & HitWall early if true.
				// Events with indices between NAME_PROBEMIN and NAME_PROBEMAX can be enabled/disabled.
				
				// Disable( 'Touch' );

				// Velocity = Vect(0,0,0);
			}
		}
		else if ( !Other.bCanBeDamaged && Other.bBlockActors )
		{
			// Not a destructible... treat as if it's bWorldGeometry=TRUE
			// e.g. SkeletalMeshActor
			if ( !CheckRepeatingTouch(Other) )
			{
				HitWall(HitNormal, Other, LastTouchComponent);
			}
		}
		else
		{
			ProcessDestructibleTouchOnBounce( Other, HitLocation, HitNormal );
		}
	}
}

// simulated function bool AllowNuke()
// {
//     return false;
// }

// for nukes && concussive force
simulated protected function PrepareExplosionTemplate()
{
	class'KFPerk_Demolitionist'.static.PrepareExplosive( Instigator, self );

    super.PrepareExplosionTemplate();
}

simulated protected function SetExplosionActorClass()
{
   local KFPlayerReplicationInfo InstigatorPRI;

    if( WorldInfo.TimeDilation < 1.f && Instigator != none )
    {
       InstigatorPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
        if( InstigatorPRI != none )
        {
            if( InstigatorPRI.bNukeActive && class'KFPerk_Demolitionist'.static.ProjectileShouldNuke( self ) )
            {
                ExplosionActorClass = class'KFPerk_Demolitionist'.static.GetNukeExplosionActorClass();
            }
        }
    }

    super.SetExplosionActorClass();
}

defaultproperties
{
	Physics=PHYS_Falling
	MaxSpeed=1200
	Speed=1200
	TossZ=100
	GravityScale=1.0

   	FuseTime=600 //500
   	LifeSpan=600
	bCantBeTouchedByInstigator=true
	bCantDetonateOnFullHP=true

	bBounce=true
   	DampenFactor=0.45 //0.55
   	DampenFactorParallel=0.45

	PostExplosionLifetime=1

	GlassShatterType=FMGS_ShatterDamaged

	DamageRadius=0

	bCollideComplex=true

	bIgnoreFoliageTouch=true

	bBlockedByInstigator=false
	bAlwaysReplicateExplosion=true

	bNetTemporary=false

	bCanBeDamaged=true
	bCanDisintegrate=true
	ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// bCanStick=true
	// Begin Object Class=KFProjectileStickHelper Name=StickHelper0
	// 	StickAkEvent=AkEvent'WW_WEP_EXP_C4.Play_WEP_EXP_C4_Handling_Place'
	// End Object
	// StickHelper=StickHelper0
	// StuckToBoneIdx=INDEX_NONE

	// Collision size we should use when waiting to be triggered
	ExplodeTriggerRadius=100.f //meters
	ExplodeTriggerHeight=22.f

	Begin Object Name=CollisionCylinder
		CollisionRadius=5
		CollisionHeight=5
		BlockNonZeroExtent=false
		// for siren scream
		CollideActors=true
		// PhysMaterialOverride=PhysicalMaterial'WEP_Mine_Reconstructor_EMIT.BloatPukeMine_PM'
	End Object
	// ExtraLineCollisionOffsets.Add((Y=-2))
 	// ExtraLineCollisionOffsets.Add((Y=2))
  	// Since we're still using an extent cylinder, we need a line at 0
  	// ExtraLineCollisionOffsets.Add(())

	AlwaysRelevantDistanceSquared=6250000 // 25m, same as grenade

	// projectile mesh (use this instead of ProjEffects particle system)
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh=StaticMesh'WEP_ProxyC4_MESH.Wep_ProxyC4_Projectile'
		bCastDynamicShadow=FALSE
		CollideActors=false
		LightingChannels=(bInitialized=True,Dynamic=True,Indoor=True,Outdoor=True)
	End Object
	ChargeMesh=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

	// ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_Warning_V1_DROW3'
	// ProjIndicatorTemplate=ParticleSystem'WEP_Seal_Squeal_EMIT.FX_Harpoon_Projectile_Indicator'

	// ImpactEffectInfo=KFImpactEffectInfo'WEP_C4_ARCH.C4_Projectile_Impacts'
	GrenadeBounceEffectInfo=KFImpactEffectInfo'FX_Impacts_ARCH.DefaultGrenadeImpacts'
	LandedAkEvent=AkEvent'WW_WEP_EXP_C4.Play_WEP_EXP_C4_Handling_Place'

	// ProximityAlertAkEvent=AkEvent'WW_WEP_EXP_C4.Play_WEP_EXP_C4_Prox_Beep'
	ProximityAlertInterval=1.0
	ProximityAlertIntervalClose=0.5

	BlinkTime=0.2f
	BlinkColorOff=(R=0, G=0, B=0)
	BlinkColorOn=(R=1, G=0, B=0)

	BlinkFX=ParticleSystem'WEP_C4_EMIT.FX_C4_Glow'

	// blink light
	Begin Object Class=PointLightComponent Name=BlinkPointLight
	    LightColor=(R=255,G=63,B=63,A=255)
		Brightness=4.f
		Radius=300.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
		Translation=(X=8, Z=4)
	End Object
	BlinkLightComp=BlinkPointLight
	Components.Add(BlinkPointLight)

	ExplosionActorClass=class'KFExplosionActorC4'

	// explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	   LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2000.f
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
		Damage=300
	   	DamageRadius=800
		DamageFalloffExponent=2.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_ProxyC4'

		MomentumTransferScale=1

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_C4_ARCH.C4_Explosion'
		ExplosionSound=AkEvent'WW_WEP_EXP_C4.Play_WEP_EXP_C4_Explosion'

      	// Dynamic Light
      	ExploLight=ExplosionPointLight
      	ExploLightStartFadeOutTime=0.0
      	ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}