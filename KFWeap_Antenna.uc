class KFWeap_Antenna extends KFWeap_ScopedBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

var transient ParticleSystemComponent ParticleEffectPSC;
var ParticleSystem ParticleEffect;

var Controller OriginalOwnerController;
var float Radius;
var int ZapDamage;

//Overriden to use instant hit vfx. Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    MyProjectileClass = GetKFProjectileClass();

	// This is where we would start an instant trace. (what CalcWeaponFire uses)
	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	// if projectile is spawned at different location of crosshair,
	// then simulate an instant trace where crosshair is aiming at, Get hit info.
	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	// Set flash location to trigger client side effects.  Bypass Weapon.SetFlashLocation since
	// that function is not marked as simulated and we want instant client feedback.
	// ProjectileFire/IncrementFlashCount has the right idea:
	//	1) Call IncrementFlashCount on Server & Local
	//	2) Replicate FlashCount if ( !bNetOwner )
	//	3) Call WeaponFired() once on local player
	if( Instigator != None )
	{
		Instigator.SetFlashLocation( Self, CurrentFireMode, TestImpact.HitLocation );
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{

		if( StartTrace != RealStartLoc )
		{	
			// Store the original aim direction without correction
            DirB = AimDir;

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            // Store the desired corrected aim direction
    		DirA = AimDir;

    		// Clamp the maximum aim adjustment for the AimDir so you don't get wierd
    		// cases where the projectiles velocity is going WAY off of where you
    		// are aiming. This can happen if you are really close to what you are
    		// shooting - Ramm
    		if ( (DirA dot DirB) < MaxAimAdjust_Cos )
    		{
    			Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), MaxAimAdjust_Angle);
    			AimDir = QuatRotateVector(Q,DirB);
    		}
		}

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

/*
// Does mechanic around player within radius
simulated function ProcessInstantHitEx(byte FiringMode, ImpactInfo Impact, optional int NumHits, optional out float out_PenetrationVal, optional int ImpactNum)
{
	local int TotalDamage;
	local KActorFromStatic NewKActor;
	local StaticMeshComponent HitStaticMesh;
	local InterpCurveFloat PenetrationCurve;
    local KFPawn KFP;
    local float InitialPenetrationPower, OriginalPenetrationVal;
    local KFPerk CurrentPerk;
    local bool bNoPenetrationDmgReduction;

	local KFPawn_Monster Victim;
	local TraceHitInfo HitInfo;

	foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
	{
		if( Victim.IsAliveAndWell() )
		{
			if ( ZapDamage > 0 )
			{
				ParticleEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( ParticleEffect, Victim.Mesh, 'Head', true );
				ParticleEffectPSC.SetAbsolute(false, true, true);

				TotalDamage = ZapDamage;
				Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
			}
		}
	}

	if (MedicComp != none && FiringMode == ALTFIRE_FIREMODE)
	{
		if (MedicComp.ProcessInstantHitEx(Impact))
		{
			return;
		}
	}

	if (Impact.HitActor != None)
	{
        OriginalPenetrationVal = out_PenetrationVal;

        // default damage model is just hits * base damage
		NumHits = Max(NumHits, 1);
		TotalDamage = GetModifiedDamage(FiringMode) * NumHits;

		if ( Impact.HitActor.bWorldGeometry )
		{
			HitStaticMesh = StaticMeshComponent(Impact.HitInfo.HitComponent);
			if ( !WorldInfo.bDropDetail && WorldInfo.GetDetailMode() != DM_Low &&
				(HitStaticMesh != None) && HitStaticMesh.CanBecomeDynamic() )
			{
				NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitStaticMesh);
				if ( NewKActor != None )
				{
					Impact.HitActor = NewKActor;
				}
			}
		}

		// Handle PenetrationDamageReduction / DamageModifier if the weapon has penetration
		else if ( Impact.HitActor.bCanBeDamaged && GetInitialPenetrationPower(FiringMode) > 0  )
		{
            if ( out_PenetrationVal <= 0 )
			{
                return;
			}
			else
			{
                CurrentPerk = GetPerk();
                if( CurrentPerk != none )
                {
                	bNoPenetrationDmgReduction = CurrentPerk.IgnoresPenetrationDmgReduction();
				}

                PenetrationCurve = PenetrationDamageReductionCurve[FiringMode];
                if( !bNoPenetrationDmgReduction )
                {
               		TotalDamage *= EvalInterpCurveFloat(PenetrationCurve, out_PenetrationVal/GetInitialPenetrationPower(FiringMode));
               	}

                // Reduce penetration power for every KFPawn penetrated
                KFP = KFPawn(Impact.HitActor);
            	if ( KFP != none )
            	{
                    out_PenetrationVal -= KFP.PenetrationResistance;
            	}
			}
		}

		// The the skill tracking know that we got our initial impact for this shot
		if( KFPawn_Monster(Impact.HitActor) != none )
		{
			if ( KFPlayer != none )
			{
				InitialPenetrationPower = GetInitialPenetrationPower(FiringMode);
				if( InitialPenetrationPower <= 0 || OriginalPenetrationVal == InitialPenetrationPower )
				{
					KFPlayer.AddShotsHit(1);
				}
			}

			if (GetAmmoType(FiringMode) == 0)
			{
				ShotsHit++;
			}
		}

		Impact.HitActor.TakeDamage( TotalDamage, Instigator.Controller,
						Impact.HitLocation, InstantHitMomentum[FiringMode] * Impact.RayDir,
						InstantHitDamageTypes[FiringMode], Impact.HitInfo, self );
	}
}
*/

simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
	}
}

defaultproperties
{
	// Inventory / Grouping
	InventorySize=8 //7
	GroupPriority=21 // funny number 96
	WeaponSelectTexture=Texture2D'WEP_Antenna_MAT.UI_WeaponSelect_Antenna'
   	AssociatedPerkClasses(0)=class'KFPerk_Sharpshooter'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

 	// 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
	   // TextureTarget=TextureRenderTarget2D'Wep_Mat_Lib.WEP_ScopeLense_Target'
	   FieldOfView=8.5 // "2.0X" = 25.0(our real world FOV determinant)/2.0
	End Object

    ScopedSensitivityMod=6.0 //8
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_Antenna_MAT.WEP_1P_Antenna_Reticle_MAT'
	ScopeMICIndex=1

    // FOV
    MeshFOV=80 //70
	MeshIronSightFOV=40 //27
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=11.5,Z=-4)
	IronSightPosition=(X=0,Y=-0.158,Z=1.2)

	// Content
	PackageKey="Antenna"
	FirstPersonMeshName="WEP_Antenna_MESH.WEP_1stP_Antenna_Rig"
	FirstPersonAnimSetNames(0)="WEP_Antenna_ARCH.Wep_1stP_Antenna_Anim"
	PickupMeshName="WEP_Antenna_MESH.Wep_Antenna_Pickup"
	AttachmentArchetypeName="WEP_Antenna_ARCH.Wep_Antenna_3P"
	MuzzleFlashTemplateName="WEP_Antenna_ARCH.Wep_Antenna_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=10 //15 20
	SpareAmmoCapacity[0]=120
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Recoil
	maxRecoilPitch=225
	minRecoilPitch=200
	maxRecoilYaw=200
	minRecoilYaw=-200
	RecoilRate=0.08
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.6

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit //EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Antenna'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Antenna'
	InstantHitDamage(DEFAULT_FIREMODE)=135 //250
	FireInterval(DEFAULT_FIREMODE)=0.22 //0.2
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	Spread(DEFAULT_FIREMODE)=0.006
	FireOffset=(X=35,Y=3.0,Z=-2.0 )

    // ParticleEffect=ParticleSystem'DROW3_EMIT.FX_Lightning_Hit'
	// Radius=600
	// ZapDamage=110
	
	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M14EBR'
	InstantHitDamage(BASH_FIREMODE)=27

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Fire_Single_S')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Antenna_SND.ant_suppressed_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Antenna_SND.ant_suppressed_fire_1P_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'WEP_Antenna_ARCH.Antenna_LaserSight_WithAttachment_1P'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'
}