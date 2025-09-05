class KFDT_EMP_Lodestar extends KFDT_EMP
	abstract
	hidedropdown;

// var ParticleSystem ForceImpactEffect;
var AkEvent ForceImpactSound;

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			// SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
			SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
		}
	}
}

defaultproperties
{
	KDamageImpulse=2000
	KDeathUpKick=400
	KDeathVel=250

    // KnockdownPower=20
	// StunPower=25
	StumblePower=25 //85
	// GunHitPower=80

	EMPPower=15 //25

	GoreDamageGroup=DGT_EMP
	EffectGroup=FXG_Electricity

	// ForceImpactEffect=ParticleSystem'DROW3_EMIT.FX_HeadshotEffect_Single'
	ForceImpactSound=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Impact'

	WeaponDef=class'KFWeapDef_Lodestar'

	ModifierPerkList(0)=class'KFPerk_Firebug'
	ModifierPerkList(1)=class'KFPerk_Survivalist'
}