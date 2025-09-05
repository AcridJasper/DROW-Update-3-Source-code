class KFDT_Explosive_StormMK1 extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2000//3000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=90
	StumblePower=200
	
	EMPPower=45

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_StormMK1'
}