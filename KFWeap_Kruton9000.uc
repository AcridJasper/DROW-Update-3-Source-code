class KFWeap_Kruton9000 extends KFWeap_PistolBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** The minimum amount of ammo that must be consumed before this weapon can stop firing */
var() protected byte MinAmmoConsumed;
/** How much ammo we've consumed since firing began */
var protected byte AmmoConsumed;

/*
//Props related to charging the weapon
var float MaxChargeTime;
var float ValueIncreaseTime;
var float DmgIncreasePerCharge;
var float IncapIncreasePerCharge;
var int AmmoIncreasePerCharge;

var transient float ChargeTime;
var transient float ConsumeAmmoTime;
var transient float MaxChargeLevel;

var ParticleSystem ChargingEffect;
var ParticleSystem ChargedEffect;

var transient ParticleSystemComponent ChargingPSC;
var transient bool bIsFullyCharged;

var const WeaponFireSndInfo FullyChargedSound;

var float FullChargedTimerInterval;
*/

// const SecondaryFireAnim     = 'Shoot_ALT';
// const SecondaryFireIronAnim = 'Shoot_ALT_Iron';

// var const float MaxTargetAngle;
// var transient float CosTargetAngle;

/*
// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		AltAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(AltAmmo))
	{
		AmmoCount[ALTFIRE_FIREMODE] = AltAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAltRecharge();
}

function StartAltRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAltRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAltRechargeTime = AltFullRechargeSeconds;
	    AltRechargePerSecond = MagazineCapacity[ALTFIRE_FIREMODE] / UsedAltRechargeTime;
		AltIncrement = 0;
	}
}

function RechargeAlt(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AltIncrement += AltRechargePerSecond * DeltaTime;

		if( AltIncrement >= 1.0 && AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
		{
			AmmoCount[ALTFIRE_FIREMODE]++;
			AltIncrement -= 1.0;
			AltAmmo = AmmoCount[ALTFIRE_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAltRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	{
        RechargeAlt(DeltaTime);
	}

	Super.Tick(DeltaTime);
}
*/


/*
// Given an potential target TA determine if we can lock on to it. By default only allow locking on to pawns
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0)) //|| !HasAmmo(DEFAULT_FIREMODE)
	{
		return false;
	}

	// Make sure and only lock onto players on the same team
	return !WorldInfo.GRI.OnSameTeam(Instigator, TA);
}

// Finds a new lock on target
simulated function bool FindTarget( out KFPawn RecentlyLocked )
{
	local KFPawn P, BestTargetLock;
	local byte TeamNum;
	local vector AimStart, AimDir, TargetLoc, Projection, DirToPawn, LinePoint;
	local Actor HitActor;
	local float PointDistSQ, Score, BestScore, TargetSizeSQ;

	TeamNum   = Instigator.GetTeamNum();
	AimStart  = GetSafeStartTraceLocation();
	AimDir    = vector( GetAdjustedAim(AimStart) );
	BestScore = 0.f;

	foreach WorldInfo.AllPawns( class'KFPawn', P )
	{
		if (!CanLockOnTo(P))
		{
			continue;
		}
		// Want alive pawns and ones we already don't have locked
		if( P != none && P.IsAliveAndWell() && P.GetTeamNum() != TeamNum )
		{
			TargetLoc  = GetLockedTargetLoc( P );
			Projection = TargetLoc - AimStart;
			DirToPawn  = Normal( Projection );

			// Filter out pawns too far from center
			
			if( AimDir dot DirToPawn < CosTargetAngle )
			{
				continue;
			}

			// Check to make sure target isn't too far from center
            PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            // Make sure it's not obstructed
            HitActor = class'KFAIController'.static.ActorBlockTest(self, TargetLoc, AimStart,, true, true);
            if( HitActor != none && HitActor != P )
            {
            	continue;
            }

            // Distance from target has much more impact on target selection score
            Score = VSizeSQ( Projection ) + PointDistSQ;
            if( BestScore == 0.f || Score < BestScore )
            {
            	BestTargetLock = P;
            	BestScore = Score;
            }
		}
	}

	if( BestTargetLock != none )
	{
		RecentlyLocked = BestTargetLock;

		// Plays sound/FX when locking on to a new target
		// PlayTargetLockOnEffects();

		return true;
	}

	RecentlyLocked = none;

	return false;
}

// Adjusts our destination target impact location
static simulated function vector GetLockedTargetLoc( Pawn P )
{
	// Go for the chest, but just in case we don't have something with a chest bone we'll use collision and eyeheight settings
	if( P.Mesh.SkeletalMesh != none && P.Mesh.bAnimTreeInitialised )
	{
		if( P.Mesh.MatchRefBone('Spine2') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine2' );
		}
		else if( P.Mesh.MatchRefBone('Spine1') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine1' );
		}
		
		return P.Mesh.GetPosition() + ((P.CylinderComponent.CollisionHeight + (P.BaseEyeHeight  * 0.5f)) * vect(0,0,1)) ;
	}

	// General chest area, fallback
	return P.Location + ( vect(0,0,1) * P.BaseEyeHeight * 0.75f );	
}

// Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Bullet_Kruton9000_ALT RocketProj;
    local int Charges;
	local KFPawn TargetPawn;

    if ( CurrentFireMode == ALTFIRE_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Bullet_Kruton9000_ALT( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( RocketProj != none )
		{
			Charges = GetChargeLevel();
        	RocketProj.DamageScale = 1.f + DmgIncreasePerCharge * Charges;
        	RocketProj.IncapScale = 1.f + IncapIncreasePerCharge * Charges;

			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				RocketProj.SetLockedTarget( TargetPawn );
			}
		}

		// Resetting the firemode to default.
		CurrentFireMode = DEFAULT_FIREMODE;

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}
*/


/*
// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}

simulated function name GetWeaponFireAnim(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		return bUsingSights ? SecondaryFireIronAnim : SecondaryFireAnim;
	}

	return super.GetWeaponFireAnim(FireModeNum);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
}

/. Called during reload state
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	return super.CanOverrideMagReload(FireModeNum) || FireModeNum == ALTFIRE_FIREMODE;
}
*/


/*
simulated function StartFire(byte FireModeNum)
{
	if (IsTimerActive('RefireCheckTimer'))
	{
		return;
	}

	super.StartFire(FireModeNum);
}

simulated function OnStartFire()
{
	local KFPawn PawnInst;
	PawnInst = KFPawn(Instigator);

	if (PawnInst != none)
	{
		PawnInst.OnStartFire();
	}
}
*/

/*
simulated function FireAmmunition()
{
	// Let the accuracy tracking system know that we fired
	HandleWeaponShotTaken(CurrentFireMode);

	// Handle the different fire types
	switch (WeaponFireTypes[CurrentFireMode])
	{
	case EWFT_InstantHit:
		// Launch a projectile if we are in zed time, and this weapon has a projectile to launch for this mode
		if (`IsInZedTime(self) && WeaponProjectiles[CurrentFireMode] != none )
		{
			ProjectileFire();
		}
		else
		{
			InstantFireClient();
		}
		break;

	case EWFT_Projectile:
		ProjectileFire();
		break;

	case EWFT_Custom:
		CustomFire();
		break;
	}

	// If we're firing without charging, still consume one ammo
	if (GetChargeLevel() < 1)
	{
		ConsumeAmmo(CurrentFireMode);
	}

	NotifyWeaponFired(CurrentFireMode);

	// Play fire effects now (don't wait for WeaponFired to replicate)
	PlayFireEffects(CurrentFireMode, vect(0, 0, 0));
}
*/

/*
simulated state CannonCharge extends WeaponFiring
{
    //For minimal code purposes, I'll directly call global.FireAmmunition after charging is released
    simulated function FireAmmunition() {}

	simulated function bool AllowIronSights() { return false; }

    //Store start fire time so we don't have to timer this
    simulated event BeginState(Name PreviousStateName)
    {
        super.BeginState(PreviousStateName);

		ChargeTime = 0;
		ConsumeAmmoTime = 0;
		MaxChargeLevel = int(MaxChargeTime / ValueIncreaseTime);

		if (ChargingPSC == none)
		{
			ChargingPSC = new(self) class'ParticleSystemComponent';

			if(MySkelMesh != none)
			{
				MySkelMesh.AttachComponentToSocket(ChargingPSC, 'MuzzleFlash');
			}
			else
			{
				AttachComponent(ChargingPSC);
			}
		}
		else
		{
			ChargingPSC.ActivateSystem();
		}

		bIsFullyCharged = false;

		if (bUsingSights)
		{
			SetIronSights(false);
		}

		global.OnStartFire();

		if(ChargingPSC != none)
		{
			ChargingPSC.SetTemplate(ChargingEffect);
		}
    }

	simulated function bool ShouldRefire()
	{
		// ignore how much ammo is left (super/global counts ammo)
		return StillFiring(CurrentFireMode);
	}

    simulated event Tick(float DeltaTime)
    {
        local float ChargeRTPC;

		global.Tick(DeltaTime);

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ConsumeAmmoTime += DeltaTime;
		}

		if (bIsFullyCharged)
		{
			if (ConsumeAmmoTime >= FullChargedTimerInterval)
			{
				//ConsumeAmmo(ALTFIRE_FIREMODE);
				ConsumeAmmoTime -= FullChargedTimerInterval;
			}

			return;
		}

		// Don't charge unless we're holding down the button
		if (PendingFire(CurrentFireMode))
		{
			ChargeTime += DeltaTime;
		}

		ChargeRTPC = FMin(ChargeTime / MaxChargeTime, 1.f);
        KFPawn(Instigator).SetWeaponComponentRTPCValue("Weapon_Charge", ChargeRTPC); //For looping component
        Instigator.SetRTPCValue('Weapon_Charge', ChargeRTPC); //For one-shot sounds

		if (ConsumeAmmoTime >= ValueIncreaseTime)
		{
			ConsumeAmmo(ALTFIRE_FIREMODE);
			ConsumeAmmoTime -= ValueIncreaseTime;
		}

		if (ChargeTime >= MaxChargeTime || !HasAmmo(ALTFIRE_FIREMODE))
		{
			bIsFullyCharged = true;
			ChargingPSC.SetTemplate(ChargedEffect);
			KFPawn(Instigator).SetWeaponAmbientSound(FullyChargedSound.DefaultCue, FullyChargedSound.FirstPersonCue);
		}
    }

    //Now that we're done charging, directly call FireAmmunition. This will handle the actual projectile fire and scaling.
    simulated event EndState(Name NextStateName)
    {
		ClearZedTimeResist();
        ClearPendingFire(CurrentFireMode);
		ClearTimer(nameof(RefireCheckTimer));

		KFPawn(Instigator).bHasStartedFire = false;
		KFPawn(Instigator).bNetDirty = true;

		if (ChargingPSC != none)
		{
			ChargingPSC.DeactivateSystem();
		}

		KFPawn(Instigator).SetWeaponAmbientSound(none);
    }

	simulated function HandleFinishedFiring()
	{
		global.FireAmmunition();

		// Gotta restart the timer every shot :(
		if( IsTimerActive(nameOf(RefireCheckTimer)) )
		{
			ClearTimer( nameOf(RefireCheckTimer) );
			TimeWeaponFiring( CurrentFireMode );
		}

		if (bPlayingLoopingFireAnim)
		{
			StopLoopingFireEffects(CurrentFireMode);
		}

		if (MuzzleFlash != none)
		{
			SetTimer(MuzzleFlash.MuzzleFlash.Duration, false, 'Timer_StopFireEffects');
		}
		else
		{
			SetTimer(0.3f, false, 'Timer_StopFireEffects');
		}

		NotifyWeaponFinishedFiring(CurrentFireMode);

		super.HandleFinishedFiring();
	}
}

// Placing the actual Weapon Firing end state here since we need it to happen at the end of the actual firing loop.
simulated function Timer_StopFireEffects()
{
	// Simulate weapon firing effects on the local client
	if (WorldInfo.NetMode == NM_Client)
	{
		Instigator.WeaponStoppedFiring(self, false);
	}

	ClearFlashCount();
	ClearFlashLocation();
}

simulated function int GetChargeLevel()
{
	return Min(ChargeTime / ValueIncreaseTime, MaxChargeLevel);
}

// Should generally match up with KFWeapAttach_HuskCannon::GetChargeFXLevel
simulated function int GetChargeFXLevel()
{
	local int ChargeLevel;

	ChargeLevel = GetChargeLevel();
	if (ChargeLevel < 1)
	{
		return 1;
	}
	else if (ChargeLevel < MaxChargeLevel)
	{
		return 2;
	}
	else
	{
		return 3;
	}
}
*/

/*
// Increase the instant hit damage based on the charge level
simulated function int GetModifiedDamage(byte FireModeNum, optional vector RayDir)
{
	local int ModifiedDamage;

	ModifiedDamage = super.GetModifiedDamage(FireModeNum, RayDir);
	if (FireModeNum == ALTFIRE_FIREMODE)
	{
		ModifiedDamage = ModifiedDamage * (1.f + DmgIncreasePerCharge * GetChargeLevel());
	}

	return ModifiedDamage;
}
*/

/*
// Increase explosive damage based on the charge level
simulated function KFProjectile SpawnProjectile(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
    local KFProj_Bullet_Kruton9000_ALT HuskBall;
    local int Charges;

    HuskBall = KFProj_Bullet_Kruton9000_ALT(super.SpawnProjectile(KFProjClass, RealStartLoc, AimDir));

    //Calc and set scaling values
    if (HuskBall != none)
    {
        Charges = GetChargeLevel();
        HuskBall.DamageScale = 1.f + DmgIncreasePerCharge * Charges;
        HuskBall.IncapScale = 1.f + IncapIncreasePerCharge * Charges;

        return HuskBall;
    }

    return none;
}
*/

/*
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
*/

/*
// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}
*/

simulated state WeaponFullFiringBurst extends WeaponFiring
{
	simulated function BeginState( Name PreviousStateName )
	{
		AmmoConsumed = 0;

		super.BeginState(PreviousStateName);
	}

	// Overriden here to enforce a minimum amount of ammo consumed
	simulated function ConsumeAmmo( byte FireMode )
	{
		global.ConsumeAmmo(FireMode);

		AmmoConsumed++;
	}

	simulated function bool ShouldRefire()
	{
		// if doesn't have ammo to keep on firing, then stop
		if( !HasAmmo( CurrentFireMode ) )
		{
			return false;
		}

		// refire if owner is still willing to fire or if we've matched or surpassed minimum
		// amount of ammo consumed
		return ( StillFiring(CurrentFireMode) || AmmoConsumed < MinAmmoConsumed );
	}
}

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
    // FOV
	MeshFOV=92 //96
	MeshIronSightFOV=75 //80
    PlayerIronSightFOV=75 //80

	// Zooming/Position
	PlayerViewOffset=(X=12.0,Y=8,Z=-6)
	IronSightPosition=(X=10,Y=4,Z=0)
	ZoomInRotation=(Pitch=0,Yaw=0,Roll=2910)

	// Content
	PackageKey="Kruton9000"
	FirstPersonMeshName="WEP_Kruton9000_MESH.WEP_1P_Kruton9000_Rig" 
	FirstPersonAnimSetNames(0)="WEP_Kruton9000_ARCH.Wep_1stP_Kruton9000_Anim"
	PickupMeshName="WEP_Kruton9000_MESH.Wep_Kruton9000_Pickup"
	AttachmentArchetypeName="WEP_Kruton9000_ARCH.Wep_Kruton9000_Trail_3P" // WEP_Kruton9000_ARCH.Wep_Kruton9000_3P
	MuzzleFlashTemplateName="WEP_Kruton9000_ARCH.Wep_Kruton9000_MuzzleFlash"

	// Ammo
    MagazineCapacity[0]=30
    SpareAmmoCapacity[0]=210 //240
    InitialSpareMags[0]=1
	AmmoPickupScale[0]=1.0
    bCanBeReloaded=true
    bReloadFromMagazine=true
    bNoMagazine=true

	// Recoil
	maxRecoilPitch=180 //160
	minRecoilPitch=140 //140
	maxRecoilYaw=80 //60
	minRecoilYaw=-80 //60
	RecoilRate=0.01
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=250
	RecoilISMinPitchLimit=65485

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFullFiringBurst //WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Kruton9000'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Kruton9000'
	FireInterval(DEFAULT_FIREMODE)=+0.0857 // 700 RPM //+0.1 // 600 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=65 //70
	Spread(DEFAULT_FIREMODE)=0.015
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	AmmoCost(DEFAULT_FIREMODE)=1
	FireOffset=(X=20,Y=4.0,Z=-3)
	MinAmmoConsumed=3 //4

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring //CannonCharge
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_Kruton9000_ALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_EMP_Kruton9000'
	InstantHitDamage(ALTFIRE_FIREMODE)=60
	FireInterval(ALTFIRE_FIREMODE)=0.15 // 400 RPM //+0.223 //269 RPMs
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=0.005
	AmmoCost(ALTFIRE_FIREMODE)=100
*/

/*
	MaxTargetAngle=20

	FullChargedTimerInterval=2.0f
    MaxChargeTime=1.0
    ValueIncreaseTime=0.4 //0.2
    DmgIncreasePerCharge=0.8
    IncapIncreasePerCharge=0.22
    AmmoIncreasePerCharge=1
*/

/*
	AltAmmo=100
	MagazineCapacity[1]=100
	AltFullRechargeSeconds=10 //20
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DROW3_MAT.UI_FireModeSelect_Percentage_DROW3'
*/

/*
	// Charging effects
	ChargingEffect=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Charging'
	ChargedEffect=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Charged'

	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LazerCutter_Beam_Shoot_LP_Level_2_3P', FirstPersonCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LazerCutter_Beam_Shoot_LP_Level_2_1P')
	FullyChargedSound=(DefaultCue = AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_3_3P', FirstPersonCue=AkEvent'WW_WEP_Lazer_Cutter.Play_WEP_LaserCutter_Beam_Charged_LP_Level_3_1P')
	WeaponFireLoopEndSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_M99.Play_WEP_M99_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_M99.Play_WEP_M99_Fire_1P_Single')
	
	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(ALTFIRE_FIREMODE)=true
	bLoopingFireSnd(ALTFIRE_FIREMODE)=true
*/

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_93R'
	InstantHitDamage(BASH_FIREMODE)=21

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_93R.Play_WEP_HRG_93R_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_93R.Play_WEP_HRG_93R_Fire_1P')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_M79.Play_WEP_SA_M79_Fire_M', FirstPersonCue=AkEvent'WW_WEP_SA_M79.Play_WEP_SA_M79_Fire_S')
	// WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_3P_Cue', FirstPersonCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_Cue')
	// WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_3P_Cue', FirstPersonCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_Cue')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Kruton9000_SND.k9_shot_3P_Cue', FirstPersonCue=SoundCue'WEP_Kruton9000_SND.k9_shot_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_3P_Cue', FirstPersonCue=SoundCue'WEP_Kruton9000_SND.auto9_shot_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_HRG_93R.Play_WEP_HRG_93R_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_HRG_93R.Play_WEP_HRG_93R_Handling_DryFire'
	
	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Inventory
	InventorySize=2 //1
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_Kruton9000_MAT.UI_WeaponSelect_Kruton9000'
	bIsBackupWeapon=false
	AssociatedPerkClasses(0)=class'KFPerk_Gunslinger'
	// AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW3' // Loot beam fx (no offset)

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4)

	bHasFireLastAnims=true

	BonesToLockOnEmpty=(RW_Bolt, RW_Bullets1)
}