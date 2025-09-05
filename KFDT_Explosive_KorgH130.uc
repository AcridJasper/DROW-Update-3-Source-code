class KFDT_Explosive_KorgH130 extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=3000 //5000 //20000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=7
	StumblePower=25
	StunPower=4 //5

	ModifierPerkList(0)=class'KFPerk_Demolitionist'	
	ModifierPerkList(1)=class'KFPerk_Commando'	

	WeaponDef=class'KFWeapDef_KorgH130'
}