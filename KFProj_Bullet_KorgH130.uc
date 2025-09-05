class KFProj_Bullet_KorgH130 extends KFProj_BallisticExplosive
	hidedropdown;

// var bool bCanNuke;

simulated function bool AllowNuke()
{
	return false; //bCanNuke;
}

// simulated protected function PrepareExplosionTemplate()
// {
// 	super.PrepareExplosionTemplate();

// 	// Since bIgnoreInstigator is transient, its value must be defined here
// 	ExplosionTemplate.bIgnoreInstigator = true;
// }

defaultproperties
{
	Physics=PHYS_Projectile
	MaxSpeed=22500
	Speed=22500
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000
    ArmDistSquared=0 // Arm instantly
	LifeSpan=10.0f

	DamageRadius=0

    AlwaysRelevantDistanceSquared=2250000 // 15m
	// bCanNuke = true

	ProjFlightTemplate=ParticleSystem'WEP_HRG_Boomy_EMIT.FX_Boomy_Tracer_ZEDTime'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_HRG_Boomy_EMIT.FX_Boomy_Tracer_ZEDTime'

	ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
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
		Damage=30
		DamageRadius=250 //200
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_KorgH130'

		MomentumTransferScale=1.f
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=SoundCue'WEP_KorgH130_SND.KorgH130_rnd2_Cue'
		ExplosionEffects=KFImpactEffectInfo'WEP_KorgH130_ARCH.KorgH130_Explosion'

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