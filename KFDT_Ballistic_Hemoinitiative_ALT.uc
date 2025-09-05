class KFDT_Ballistic_Hemoinitiative_ALT extends KFDT_Ballistic_Rifle
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
	KDamageImpulse=2000
	KDeathUpKick=400
	KDeathVel=250

    // KnockdownPower=20
	StunPower=30 //25
	StumblePower=10 //85
	GunHitPower=80 //100

	ModifierPerkList(0)=class'KFPerk_FieldMedic'
    
	WeaponDef=class'KFWeapDef_Hemoinitiative'
}