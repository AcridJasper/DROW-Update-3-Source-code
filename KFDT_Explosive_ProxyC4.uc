class KFDT_Explosive_ProxyC4 extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	ObliterationHealthThreshold=-400
	ObliterationDamageThreshold=400

	bShouldSpawnPersistentBlood=true
	EffectGroup=FXG_Fire

	// physics impact
	RadialDamageImpulse=2000//3000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=150
	StumblePower=50 //400
	BurnPower=2

	// DOT
	DoT_Type=DOT_Fire
	DoT_Duration=3.0
	DoT_Interval=1.0
	DoT_DamageScale=0.0 // don't want it to do any actual damage, because dying from DOT or taking DOT after death will cause obliteration, which looks weird

	WeaponDef=class'KFWeapDef_ProxyC4'
	ModifierPerkList(0)=class'KFPerk_Demolitionist'
}