class KFProj_Bullet_Kruton9000 extends KFProj_Bullet
	hidedropdown;

defaultproperties
{
	MaxSpeed=22500
	Speed=22500

	DamageRadius=0

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Tracer_ZedTime'
	
	ImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Heavy_bullet_impact'
}