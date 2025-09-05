class KFProj_Grenade_ZEDNade extends KFProj_Grenade
	hidedropdown;

var ParticleSystemComponent	ProjectorPSC;
var(Projectile) ParticleSystem ProjectorFX;

var transient bool bZEDReadyToUse;
var transient KFPlayerController KFPC;

var Controller OriginalOwnerController;
var float Radius;
var int ZapDamage;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		KFPC = KFPlayerController(Instigator.Controller);
	}

	OriginalOwnerController = InstigatorController;

	// fuze starts at rest
	ClearTimer(nameof(ExplodeTimer));
}

simulated event GrenadeIsAtRest()
{
	local rotator NewRotation;

	super.GrenadeIsAtRest();

	NewRotation.Pitch=0;
	SetRotation(NewRotation);

	if (Role == ROLE_Authority)
	{
		SetTimer(FuseTime, false, 'ExplodeTimer');

		SetTimer(9.0, false, 'SpawnPawn');
		// SpawnFriendly();
	}

	if( ProjectorFX != None )
	{
	    ProjectorPSC = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjectorFX);
	}

	if(ProjectorPSC != None)
	{
		ProjectorPSC.SetAbsolute(false, true, true);
		AttachComponent(ProjectorPSC);
	}
}

simulated protected function StopSimulating()
{
	super.StopSimulating();

	if (ProjectorPSC!=None)
	{
        ProjectorPSC.DeactivateSystem();
	}
}

function SpawnPawn()
{
	SpawnFriendly();
}

simulated function SpawnFriendly(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local KFPawn_FleshFriend SpawnedActor;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("KFPawn_FleshFriend", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SetPhysics(PHYS_Falling);
		ZED.SpawnDefaultController();

		// Setup inside KFAIController
		// if( KFAIController(ZED.Controller) != none )
		// {
		// 	Set team to human team
		// 	KFAIController( ZED.Controller ).SetTeam(0);
		// }
	}

	// This does nothing, but should replicate kills from friendly ZED
	SpawnedActor = Spawn(class'KFPawn_FleshFriend', self);
	if( SpawnedActor != none )
	{
		SpawnedActor.SpawnDefaultController();
		SpawnedActor.OwnerWeapon = self;
		SpawnedActor.UpdateInstigator(Instigator); //updates TeamNum
	}
}

function SetReadyToUse(bool bReady)
{
	if (bZEDReadyToUse != bReady)
	{
		bZEDReadyToUse = bReady;
		bNetDirty = true;
	}
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Falling
	Speed=1500 //2000
	MaxSpeed=1500
	TossZ=150
    GravityScale=1.5

	bZEDReadyToUse=true
	ProjectorFX=ParticleSystem'DROW3_EMIT.FX_KingFleshpound_Hologram'

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_ZEDNade_Grenade_Projectile'
	GrenadeBounceEffectInfo=KFImpactEffectInfo'FX_Impacts_ARCH.DefaultGrenadeImpacts'

	bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	WeaponSelectTexture=Texture2D'DROW3_MAT.UI_WeaponSelect_ZEDNade'
	// AssociatedPerkClass=class'KFPerk_Survivalist'

    LandedTranslationOffset=(X=0)

    FuseTime=10

	ExplosionActorClass=class'KFExplosionActor'

	// Grenade explosion light
	Begin Object Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
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

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=1
		DamageRadius=1
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_HRG_Boomy'
		
		MomentumTransferScale=10000
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=AkEvent'ww_wep_hrg_boomy.Play_WEP_HRG_Boomy_ProjExplosion'
		ExplosionEffects=KFImpactEffectInfo'WEP_HRG_Boomy_ARCH.WEB_HRG_Boomy_Impacts'

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