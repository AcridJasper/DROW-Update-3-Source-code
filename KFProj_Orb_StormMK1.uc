class KFProj_Orb_StormMK1 extends KFProjectile;

// How long to wait until this grenade explodes
// var() float FuseTime;
var() float FuseTimeMin;
var() float FuseTimeMax;

var int MaxNumberOfZedsZapped;
var int MaxDistanceToBeZapped;
var float ZapInterval;
var float TimeToZap;
var int ZapDamage;

var KFPawn_Monster oZedCurrentlyBeingSprayed;

var ParticleSystem BeamPSCTemplate;

var string EmitterPoolClassPath;
var EmitterPool vBeamEffects;

struct BeamZapInfo
{
	var ParticleSystemComponent oBeam;
	var KFPawn_Monster oAttachedZed;
	var Actor oSourceActor;
	var float oControlTime;
};

var array<BeamZapInfo> CurrentZapBeams;

var AkComponent ZapSFXComponent;
var() AkEvent ZapSFX;

var Controller oOriginalOwnerController;
var Pawn oOriginalInstigator;

simulated event PreBeginPlay()
{
	local class<EmitterPool> PoolClass;
	
    super.PreBeginPlay();

    bIsAIProjectile = InstigatorController == none || !InstigatorController.bIsPlayer;
	oOriginalOwnerController = InstigatorController;
	oOriginalInstigator = Instigator;

	PoolClass = class<EmitterPool>(DynamicLoadObject(EmitterPoolClassPath, class'Class'));
	if (PoolClass != None)
	{
		vBeamEffects = Spawn(PoolClass, self,, vect(0,0,0), rot(0,0,0));
	}

	if( Role == ROLE_Authority )
	{
	   // SetTimer(FuseTime, false, 'ExplodeTimer');
	   SetTimer(RandRange(FuseTimeMin, FuseTimeMax), false, 'ExplodeTimer');
	}
}

// Explode after a certain amount of time
function ExplodeTimer()
{
    local Actor HitActor;
    local vector HitLocation, HitNormal;

    GetExplodeEffectLocation(HitLocation, HitNormal, HitActor);
    TriggerExplosion(HitLocation, HitNormal, HitActor);

	Detonate(); // remove harpoon
}

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
    if (IsZero(HitLocation))
    {
        HitLocation = Location;
    }

	if (IsZero(HitRotation))
    {
        HitRotation = vect(0,0,1);
    }
}

/** Causes charge to explode */
function Detonate()
{
	local vector ExplosionNormal;

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(ExplodeTimer) );
	}
}

// Notification that a direct impact has occurred
event ProcessDirectImpact()
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(oOriginalOwnerController);

    if( KFPC != none )
    {
        KFPC.AddShotsHit(1);
    }
}

function Init(vector Direction)
{
    if( LifeSpan == default.LifeSpan && WorldInfo.TimeDilation < 1.f )
    {
        LifeSpan /= WorldInfo.TimeDilation;
    }
    super.Init( Direction );
}

simulated event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	if( !bHasExploded )
	{
		Explode(Location - (HitNormal * CylinderComponent.CollisionRadius), HitNormal);
		//DrawDebugSphere(Location, CylinderComponent.CollisionRadius, 10, 255, 255, 0, true );
		//DrawDebugSphere(Location, 2, 10, 0, 0, 255, true );
		//DrawDebugSphere(Location - (HitNormal * CylinderComponent.CollisionRadius), 2, 10, 255, 0, 0, true );
	}
}

simulated function Destroyed()
{	
	FinalEffectHandling();
	Super.Destroyed();
}

simulated function FinalEffectHandling()
{
	Local int i;

	if(CurrentZapBeams.length > 0)
	{
		for(i=0 ; i<CurrentZapBeams.length ; i++)
		{
			CurrentZapBeams[i].oBeam.DeactivateSystem();
		}
	}
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	// If there is an explosion template do the parent version
	if ( ExplosionTemplate != None )
	{
		Super.TriggerExplosion(HitLocation, HitNormal, HitActor);
		return;
	}
}

simulated function bool ZapFunction(Actor _TouchActor)
{
	local vector BeamEndPoint;
	local KFPawn_Monster oMonsterPawn;
	local int iZapped;
	local ParticleSystemComponent BeamPSC;
	foreach WorldInfo.AllPawns( class'KFPawn_Monster', oMonsterPawn )
	{
		if( oMonsterPawn.IsAliveAndWell() && oMonsterPawn != _TouchActor)
		{
			//`Warn("PAWN CHECK IN: "$oMonsterPawn.Location$"");
			//`Warn(VSizeSQ(oMonsterPawn.Location - _TouchActor.Location));
			if( VSizeSQ(oMonsterPawn.Location - _TouchActor.Location) < Square(MaxDistanceToBeZapped) )
			{
				if(FastTrace(_TouchActor.Location, oMonsterPawn.Location, vect(0,0,0)) == false)
				{
					continue;
				}

				if(WorldInfo.NetMode != NM_DedicatedServer)
				{
					BeamPSC = vBeamEffects.SpawnEmitter(BeamPSCTemplate, _TouchActor.Location, _TouchActor.Rotation);

					BeamEndPoint = oMonsterPawn.Mesh.GetBoneLocation('Spine1');
					if(BeamEndPoint == vect(0,0,0)) BeamEndPoint = oMonsterPawn.Location;

					BeamPSC.SetBeamSourcePoint(0, _TouchActor.Location, 0);
					BeamPSC.SetBeamTargetPoint(0, BeamEndPoint, 0);
					
					BeamPSC.SetAbsolute(false, false, false);
					BeamPSC.bUpdateComponentInTick = true;
					BeamPSC.SetActive(true);

					StoreBeam(BeamPSC, oMonsterPawn);
					ZapSFXComponent.PlayEvent(ZapSFX, true);
				}

				if(WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_StandAlone ||  WorldInfo.NetMode == NM_ListenServer)
				{
					ChainedZapDamageFunction(oMonsterPawn, _TouchActor);
				}

				++iZapped;
			}
		}

		if(iZapped >= MaxNumberOfZedsZapped) break;
	}
	if(iZapped > 0) 
		return true;
	else
		return false;
}

simulated function StoreBeam(ParticleSystemComponent Beam, KFPawn_Monster Monster)
{
	local BeamZapInfo BeamInfo;
	BeamInfo.oBeam = Beam;
	BeamInfo.oAttachedZed = Monster;
	BeamInfo.oSourceActor = self;
	BeamInfo.oControlTime = ZapInterval;
	CurrentZapBeams.AddItem(BeamInfo);
}

function ChainedZapDamageFunction(Actor _TouchActor, Actor _OriginActor)
{
	//local float DistToHitActor;
	local vector Momentum;
	local TraceHitInfo HitInfo;
	local Pawn TouchPawn;
	local int TotalDamage;
 
	if (_OriginActor != none)
	{
		Momentum = _TouchActor.Location - _OriginActor.Location;
	}

	//DistToHitActor = VSize(Momentum);
	//Momentum *= (MomentumScale / DistToHitActor);
	if (ZapDamage > 0)
	{
		TouchPawn = Pawn(_TouchActor);
		// Let script know that we hit something
		if (TouchPawn != none)
		{
			ProcessDirectImpact();
		}
		//`Warn("["$WorldInfo.TimeSeconds$"] Damaging "$_TouchActor.Name$" for "$ZapDamage$", Dist: "$VSize(_TouchActor.Location - _OriginActor.Location));
		
		TotalDamage = ZapDamage * UpgradeDamageMod;
		_TouchActor.TakeDamage(TotalDamage, oOriginalOwnerController, _TouchActor.Location, Momentum, class'KFDT_EMP_Lightning', HitInfo, self);
	}
}

simulated event Tick( float DeltaTime )
{
	Local int i;
	local vector BeamEndPoint;
	
	// super.Tick( DeltaTime );

	if(CurrentZapBeams.length > 0)
	{
		for(i=0 ; i<CurrentZapBeams.length ; i++)
		{
			CurrentZapBeams[i].oControlTime -= DeltaTime;
			if(CurrentZapBeams[i].oControlTime > 0 && CurrentZapBeams[i].oAttachedZed.IsAliveAndWell())
			{
				BeamEndPoint = CurrentZapBeams[i].oAttachedZed.Mesh.GetBoneLocation('Spine1');
				if(BeamEndPoint == vect(0,0,0)) BeamEndPoint = CurrentZapBeams[i].oAttachedZed.Location;

				CurrentZapBeams[i].oBeam.SetBeamSourcePoint(0, CurrentZapBeams[i].oSourceActor.Location, 0);
				CurrentZapBeams[i].oBeam.SetBeamTargetPoint(0, BeamEndPoint, 0);
			}
			else
			{
				CurrentZapBeams[i].oBeam.DeactivateSystem();
				CurrentZapBeams.RemoveItem(CurrentZapBeams[i]);
				i--;
			}
		}
	}

	TimeToZap += DeltaTime;
	//`Warn(TimeToZap);
	//`Warn(TimeToZap > ZapInterval);
	if(TimeToZap > ZapInterval)
	{
		if(ZapFunction(self))
		{
			TimeToZap = 0;
		}
	}
}

simulated function bool AllowNuke()
{
    return false;
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
    MaxSpeed=1
	Speed=1
	TerminalVelocity=1
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=0
	LifeSpan=4

    // FuseTime=1.0
    FuseTimeMin=0.5
    FuseTimeMax=1.0

	DamageRadius=0

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_Storm_Bomblet'

	// ImpactEffects=KFImpactEffectInfo'' 

    bCanBeDamaged=false
	bCanDisintegrate=false
	bIgnoreFoliageTouch=true

    bCollideActors=true
    bCollideComplex=false //true

	bBlockedByInstigator=false
	bAlwaysReplicateExplosion=true

	bNetTemporary=false
	NetPriority=5
	NetUpdateFrequency=200

	bNoReplicationToInstigator=false
	bUseClientSideHitDetection=true
	bUpdateSimulatedPosition=true
	bSyncToOriginalLocation=true
	bSyncToThirdPersonMuzzleLocation=true

	Begin Object Name=CollisionCylinder
		CollisionRadius=5
		CollisionHeight=5
		BlockNonZeroExtent=true
		// for siren scream
		CollideActors=true
	End Object
  	// Since we're still using an extent cylinder, we need a line at 0
  	ExtraLineCollisionOffsets.Add(())

  	Begin Object Class=AkComponent name=ZapOneShotSFX
    	BoneName=dummy // need bone name so it doesn't interfere with default PlaySoundBase functionality
    	bStopWhenOwnerDestroyed=true
    End Object
    ZapSFXComponent=ZapOneShotSFX
    Components.Add(ZapOneShotSFX)

    ZapSFX=AkEvent'WW_DEV_TestTones.Play_Beep_WeaponAtten' //ww_wep_hrg_energy.Play_WEP_HRG_Energy_1P_Shoot
    BeamPSCTemplate = ParticleSystem'DROW3_EMIT.FX_Storm_Beam'
	EmitterPoolClassPath="Engine.EmitterPool"

	MaxNumberOfZedsZapped=1
	MaxDistanceToBeZapped=500
	ZapInterval=0.2 //0.4
	TimeToZap=100
	ZapDamage=8 //9 10

	ExplosionActorClass=class'KFExplosionActor'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=0,G=75,B=100,A=255)
		Brightness=1.f
		Radius=1000.f
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
		Damage=45 //200
		DamageRadius=450 //500
		DamageFalloffExponent=0.5f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_StormMK1'

		MomentumTransferScale=1
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0.0
		FracturePartVel=0.0
		ParticleEmitterTemplate=ParticleSystem'DROW3_EMIT.FX_Storm_Bomblet_Explosion'
        ExplosionSound=SoundCue'WEP_StormMK1_SND.emp_explosion_bl_q_Cue'
		// ExplosionSound=AkEvent''
		
        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}