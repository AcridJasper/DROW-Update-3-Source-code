class KFDT_Ballistic_KorgH130 extends KFDT_Ballistic_Submachinegun
	abstract
	hidedropdown;

defaultproperties
{
    KDamageImpulse=900
	KDeathUpKick=-300
	KDeathVel=100

	StumblePower=35
	GunHitPower=30

	WeaponDef=class'KFWeapDef_KorgH130'

	ModifierPerkList(0)=class'KFPerk_Demolitionist'
	ModifierPerkList(1)=class'KFPerk_Commando'
}