class KFProj_Bullet_Lodestar_Icicles extends KFProj_Bullet_Pellet
	hidedropdown;

var AkEvent oFrozenSound;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	local KFPawn p;
	p = KFPawn(Other);

	super.ProcessTouch(Other, HitLocation, HitNormal);

	if(p != none)
	{
		if(KFPawn_Monster(p).IsDoingSpecialMove(SM_Frozen))
		{
			p.PlayAkEvent(oFrozenSound);
		}
	}
}

defaultproperties
{
	Physics=PHYS_Projectile
	MaxSpeed=7000
	Speed=7000
	TossZ=0
	GravityScale=1.0

	DamageRadius=0

	bSyncToOriginalLocation = true
	bSyncToThirdPersonMuzzleLocation = false
	bNoReplicationToInstigator = false
	bReplicateClientHitsAsFragments = true

	ProjFlightTemplate=ParticleSystem'WEP_Frost_Shotgun_Axe_EMIT.FX_FrostFang_Tracer_01'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_Frost_Shotgun_Axe_EMIT.FX_FrostFang_Tracer_Zedtime_01'

	ImpactEffects=KFImpactEffectInfo'WEP_Frost_Shotgun_Axe_ARCH.WEP_FrostFang_Projectile_Impact'

	oFrozenSound=AkEvent'WW_WEP_FrostFang.Play_FrostFang_Frozen_Impact'
}