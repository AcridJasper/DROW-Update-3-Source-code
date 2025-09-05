class KFProj_Bullet_LardPD4K extends KFProj_BallisticExplosive;

// var float ResidualFlameHalfConeAngle;

// var int BombSpawnHeight;
// var int BombSpawnSpeed;
// var Vector BombTargetLocation;

var transient ParticleSystemComponent ParticleEffectPSC;
var ParticleSystem ParticleEffect;

var Controller OriginalOwnerController;
var float Radius;
var int ZapDamage;

var float DamageScale;

simulated protected function PrepareExplosionActor(GameExplosionActor GEA)
{
    local KFExplosionActor_HuskCannon ProjExplosion;

    ProjExplosion = KFExplosionActor_HuskCannon(GEA);
    if (ProjExplosion != None)
    {
        ProjExplosion.DamageScale = DamageScale;
    }
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFPawn_Monster Victim;
	local int TotalDamage;
	local TraceHitInfo HitInfo;

	foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
	{
		if( Victim.IsAliveAndWell() )
		{
			if ( ZapDamage > 0 )
			{
				ParticleEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( ParticleEffect, Victim.Mesh, 'Head', true );
				ParticleEffectPSC.SetAbsolute(false, true, true);

				TotalDamage = ZapDamage * UpgradeDamageMod;
				Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lightning', HitInfo, self); //Victim.Location
			}
		}
	}

/*	
	if (Role == ROLE_Authority)
    {
        BombTargetLocation = HitLocation;
    	// BombTargetLocation = VRandCone( HitNormal, ResidualFlameHalfConeAngle * DegToRad );
        SpawnBomba();
    }
*/

	Super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

/*
simulated function SpawnBomba()
{
    local KFProj_Rocket_Construct BombProj;
    local Vector SpawnLocation, Direction;
    local Rotator SpawnRotation;

    // Rain anywere
    // SpawnLocation = BombTargetLocation + (VRand() * (float(300) + (FRand() * float(5))));
    // Rain point
    SpawnLocation = BombTargetLocation + (VRand() * (float(500)));
    SpawnLocation.Z += BombSpawnHeight; //float(1000)
    Direction = Normal(BombTargetLocation - SpawnLocation);
    SpawnRotation = Rotator(Direction);
    BombProj = Spawn(class'KFProj_Rocket_Construct', self,, SpawnLocation, SpawnRotation, OriginalOwnerController);

    if(BombProj != none)
    {
        BombProj.Velocity = Direction * BombSpawnSpeed; //float(5)
    }
}
*/

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=23000
	MaxSpeed=23000
	TossZ=0
	GravityScale=1.0
    ArmDistSquared=0
	LifeSpan=+10.0f

	// ResidualFlameHalfConeAngle=72
	// BombSpawnHeight=800
	// BombSpawnSpeed=4000

	PostExplosionLifetime=1

    ParticleEffect=ParticleSystem'DROW3_EMIT.FX_Lightning_Hit'
	Radius=600
	ZapDamage=0 //70 //90

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'

	// explosion damage increase based on charge level for this class
    ExplosionActorClass=class'KFExplosionActor_HuskCannon'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=50,G=100,B=150,A=255)
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
		Damage=70 //60
		DamageRadius=300
		DamageFalloffExponent=1 //0.5
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_LardPD4K'

		//Impulse applied to Zeds
		MomentumTransferScale=1
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_LardPD4K_ARCH.FX_LardPD4K_Explosion'
		ExplosionSound=AkEvent'ww_wep_hrg_energy.Play_WEP_HRG_Energy_Impact'

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