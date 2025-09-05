class KFProj_Bullet_Hemoinitiative_ALT extends KFProj_Bullet;

defaultproperties
{
	MaxSpeed=22500 //18000
	Speed=22500

	DamageRadius=0

	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Rail_Tracer_ZedTime'

	ImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Heavy_bullet_impact'
}