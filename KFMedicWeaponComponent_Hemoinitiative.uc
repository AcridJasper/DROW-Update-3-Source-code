class KFMedicWeaponComponent_Hemoinitiative extends KFMedicWeaponComponent;

simulated function name GetWeaponFireAnim()
{
	return KFW.GetWeaponFireAnim(DEFAULT_FIREMODE);
}

defaultproperties
{
	bRechargeHealAmmo=true

    HealAmount=15 //25
	HealFullRechargeSeconds=10
	HealingDartAmmo=100
	HealDartShotWeakZedGrabCooldown=0.5

	DartMaxRecoilPitch=250
	DartMinRecoilPitch=200
	DartMaxRecoilYaw=100
	DartMinRecoilYaw=-100

	DartFireSnd=(DefaultCue=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Fire_3P',FirstPersonCue=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Dart_Fire_1P')
	HealingDartWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Default_Recoil'
	HealingDartDamageType=class'KFDT_Healing'

	// OpticsUIClass=class'KFGFxWorld_MedicOptics'
}