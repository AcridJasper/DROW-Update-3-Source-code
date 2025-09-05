class KFDT_Explosive_LardPD4K extends KFDT_Freeze
	abstract;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	GibImpulseScale=0.15
	KDeathUpKick=700
	KDeathVel=300

	StumblePower=25
	EMPPower=35

	//Prevent self-inflicted damage
	// bNoInstigatorDamage=true

	ModifierPerkList(0)=class'KFPerk_Survivalist'
    ModifierPerkList(1)=class'KFPerk_Demolitionist'
	
	WeaponDef=class'KFWeapDef_LardPD4K'
}