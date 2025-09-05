class KFDT_Explosive_Lodestar extends KFDT_Freeze
	abstract;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	GibImpulseScale=0.15
	KDeathUpKick=700
	KDeathVel=300

	StumblePower=25
	FreezePower=10 // 25

	//Prevent self-inflicted damage
	// bNoInstigatorDamage=true

	CameraLensEffectTemplate=class'KFCameraLensEmit_Iced_DROW3'

	ModifierPerkList(0)=class'KFPerk_Firebug'
	ModifierPerkList(1)=class'KFPerk_Survivalist'

	WeaponDef=class'KFWeapDef_Lodestar'
}