class KFProj_Bullet_StormMK1 extends KFProj_BallisticExplosive
	hidedropdown;

var int ExplosivesToSpawn;
var int ExplosivesSpawned;
var int ExplosiveSpawnHeight;
var int ExplosiveSpawnSpeed;
var Vector ExplosiveTargetLocation;

// Explode this Projectile
simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
    if (Role == ROLE_Authority)
    {
        ExplosivesSpawned = 0;
        ExplosivesToSpawn = 4;
        ExplosiveTargetLocation = HitLocation;
        SetTimer(0.1, true, 'SpawnExplosive');
    }

    Super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

simulated function SpawnExplosive()
{
    local KFProj_Orb_StormMK1 Projectile;
    local Vector SpawnLocation, Direction;
    local Rotator SpawnRotation;

    SpawnLocation = ExplosiveTargetLocation + (VRand() * (float(200))); //+ (FRand() * float(5))));
    SpawnLocation.Z += ExplosiveSpawnHeight;
    Direction = Normal(ExplosiveTargetLocation - SpawnLocation);
    SpawnRotation = Rotator(Direction);
    Projectile = Spawn(class'KFProj_Orb_StormMK1', self,, SpawnLocation, SpawnRotation); //instagator is inside class

    if(Projectile != none)
    {
        Projectile.Velocity = Direction * ExplosiveSpawnSpeed; //+ vect(0,0,1);
    }

    if(ExplosivesSpawned >= ExplosivesToSpawn)
    {
        ClearTimer('SpawnExplosive');
        return;
    }

    ExplosivesSpawned++;
}

defaultproperties
{
    Physics=PHYS_Projectile
    MaxSpeed=24000
    Speed=24000
    TerminalVelocity=24000
    TossZ=0
    GravityScale=1.0
    ArmDistSquared=0

	ExplosiveSpawnHeight=200 //200
	ExplosiveSpawnSpeed=1

    ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
    ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'

    bCanDisintegrate=false
    // ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

    // Grenade explosion light
    Begin Object Class=PointLightComponent Name=ExplosionPointLight
        LightColor=(R=0,G=75,B=100,A=255)
        Brightness=4.f
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
        Damage=80 //70 90
        DamageRadius=600
        DamageFalloffExponent=2  //3
        DamageDelay=0.f
        MyDamageType=class'KFDT_Explosive_StormMK1'

        MomentumTransferScale=0 //50000
        // bIgnoreInstigator=true
        
        // Damage Effects
        KnockDownStrength=0
        FractureMeshRadius=200.0
        FracturePartVel=500.0
        ExplosionEffects=KFImpactEffectInfo'DROW3_ARCH.FX_Storm_Explosion'
        ExplosionSound=SoundCue'WEP_StormMK1_SND.emp_explosion_bl_Cue'

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