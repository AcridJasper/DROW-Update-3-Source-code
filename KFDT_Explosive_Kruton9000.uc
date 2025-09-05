class KFDT_Explosive_Kruton9000 extends KFDT_Explosive
	abstract;

defaultproperties
{
	bShouldSpawnPersistentBlood=true
	
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	// physics impact
	RadialDamageImpulse=10000
	KDeathUpKick=2000
	KDeathVel=500

	KnockdownPower=150
	StumblePower=350
	EMPPower=50 //10

	//Prevent self-inflicted damage
	// bNoInstigatorDamage=true

	WeaponDef=class'KFWeapDef_Kruton9000'

	ModifierPerkList(0)=class'KFPerk_Gunslinger'
	ModifierPerkList(1)=class'KFPerk_Survivalist'
}