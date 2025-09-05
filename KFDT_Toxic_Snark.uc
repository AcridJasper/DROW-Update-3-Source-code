class KFDT_Toxic_Snark extends KFDT_Toxic
	abstract
	hidedropdown;

defaultproperties
{
	//DoT
	DoT_Duration=5.0
	DoT_Interval=1.0
	DoT_DamageScale=0.2

	//Afflictions
	PoisonPower=25.f

	WeaponDef=class'KFWeapDef_Snark'

	// ModifierPerkList(0)=class'KFPerk_Firebug'
}