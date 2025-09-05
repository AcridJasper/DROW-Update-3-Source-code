class KFDT_Freeze_LodestarImpact extends KFDT_Freeze
	abstract;

defaultproperties
{
	KDamageImpulse=1000
	KDeathUpKick=700
	KDeathVel=350

	FreezePower=5 //0
	StumblePower=10 //50
	GunHitPower=50 //100

	WeaponDef=class'KFWeapDef_Lodestar'
	
	ModifierPerkList(0)=class'KFPerk_Firebug'
	ModifierPerkList(1)=class'KFPerk_Survivalist'
}