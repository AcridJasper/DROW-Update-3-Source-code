class KFDT_Ballistic_StormMK1 extends KFDT_Ballistic_Rifle
	abstract
	hidedropdown;

/** Allows the damage type to customize exactly which hit zones it can dismember */
static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
	if( super.CanDismemberHitZone( InHitZoneName ) )
	{
		return true;
	}

	switch ( InHitZoneName )
	{
		case 'lupperarm':
		case 'rupperarm':
	 		return true;
	}

	return false;
}

defaultproperties
{
	// Physics
	KDamageImpulse=2750
	KDeathUpKick=750
	KDeathVel=450

	// Afflictions
    KnockdownPower=30
	StunPower=40
	StumblePower=50
	GunHitPower=150

	WeaponDef=class'KFWeapDef_StormMK1'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
}