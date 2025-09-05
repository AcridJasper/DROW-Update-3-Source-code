class KFDT_Explosive_Snark extends KFDT_Explosive
	abstract
	hidedropdown;

static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
	return true;
}

DefaultProperties
{
	KDeathUpKick=500
	KDeathVel=700
	KDamageImpulse=1500
	// unreal physics momentum
	bExtraMomentumZ=True

	// hit effects
	bShouldSpawnBloodSplat=true
	bShouldSpawnPersistentBlood=true //jc
	bCanGib=true

	bAnyPerk=true
	bConsideredIndirectOrAoE=true

	// DamageModifierAP=0.5f //0.4
	ArmorDamageModifier=6.0f
}