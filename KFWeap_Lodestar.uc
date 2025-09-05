class KFWeap_Lodestar extends KFWeap_PistolBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

var transient bool bLockOnActive;

/*
// Name of the special anim used for the ultimate attack
var name SwitchAnim;
// Whether this can be interrupted by another attack/reload/etc
var bool StartFireDisabled;
// Amount of time required between cancelling attacks with reload
var private const float SwitchCancelTimeLimit;
*/

const MAX_LOCKED_TARGETS = 3;

/** Constains all currently locked-on targets */
var protected array<Pawn> LockedTargets;
/** The last time a target was acquired */
var protected float LastTargetLockTime;
/** The last time a target validation check was performed */
var protected float LastTargetValidationCheckTime;
/** How much time after a lock on occurs before another is allowed */
var const float TimeBetweenLockOns;
/** How much time should pass between target validation checks */
var const float TargetValidationCheckInterval;
/** Minimum distance a target can be from the crosshair to be considered for lock on */
// var const float MinTargetDistFromCrosshairSQ;
/** Dot product FOV that targets need to stay within to maintain a target lock */
var const float MaxLockMaintainFOVDotThreshold;

var const float MaxTargetAngle;
var transient float CosTargetAngle;

/** How much to scale recoil when firing in multi-rocket mode */
var float BurstFireRecoilModifier;

/** Sound Effects to play when Locking */
// var AkBaseSoundObject LockAcquiredSoundFirstPerson;
// var AkBaseSoundObject LockLostSoundFirstPerson;
var SoundCue LockAcquiredSoundCueFirstPerson;
var SoundCue LockLostSoundCueFirstPerson;

/** Icon textures for lock on drawing */
var const Texture2D LockedOnIcon;
var LinearColor LockedIconColor;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

var class<KFGFxWorld_MedicOptics> OpticsUIClass; //KFGFxWorld_MedicOptics
var KFGFxWorld_MedicOptics OpticsUI;

/** The last updated value for our ammo - Used to know when to update our optics ammo */
var byte StoredPrimaryAmmo;
var byte StoredSecondaryAmmo;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

// Re-enables target lock-on
simulated state WeaponEquipping
{
	simulated function BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		bLockOnActive = true;
	}
}

/** We need to update our locked targets every frame and make sure they're within view and not dead */
simulated event Tick( float DeltaTime )
{
	local Pawn RecentlyLocked, StaticLockedTargets[3];
	local bool bUpdateServerTargets;
	local int i;

	if (Instigator != none && Instigator.weapon == self)
	{
		UpdateOpticsUI();
	}

	super.Tick( DeltaTime );

	if( bLockOnActive )
	{
    	if( Instigator != none && Instigator.IsLocallyControlled() )
    	{
			if( `TimeSince(LastTargetLockTime) > TimeBetweenLockOns
				&& LockedTargets.Length < AmmoCount[GetAmmoType(0)]
				&& LockedTargets.Length < MAX_LOCKED_TARGETS)
			{
		        bUpdateServerTargets = FindTargets( RecentlyLocked );
		    }
	
			if( LockedTargets.Length > 0 )
			{
				bUpdateServerTargets = bUpdateServerTargets || ValidateTargets( RecentlyLocked );
			}
	
			// If we are a client, synchronize our targets with the server
			if( bUpdateServerTargets && Role < ROLE_Authority )
			{
				for( i = 0; i < MAX_LOCKED_TARGETS; ++i )
				{
					if( i < LockedTargets.Length )
					{
						StaticLockedTargets[i] = LockedTargets[i];
					}
					else
					{
						StaticLockedTargets[i] = none;
					}
				}
	
				ServerSyncLockedTargets( StaticLockedTargets );
			}
    	}
    }
}

// Disables target lock-on
simulated state WeaponPuttingDown
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		bLockOnActive = false;
    	LockedTargets.Length = 0;

		// if( LockedTargets.Length < 0 )
		// {
		// 	PlayTargetLostEffects();
		// }
	}

	// simulated function EndState(Name NextStateName)
	// {
	// 	Super.EndState(NextStateName);

	// 	bLockOnActive = false;
    // 	LockedTargets.Length = 0;

	// PlayTargetLostEffects();
	// }
}

// Given an potential target TA determine if we can lock on to it.  By default only allow locking on to pawns.
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0) /*|| 
		!HasAmmo(DEFAULT_FIREMODE)*/ )
	{
		return false;
	}

	// Make sure and only lock onto players on the same team
	return !WorldInfo.GRI.OnSameTeam(Instigator, TA);
}

/** Finds a new lock on target, adds it to the target array and returns TRUE if the array was updated */
simulated function bool FindTargets( out Pawn RecentlyLocked )
{
	local Pawn P, BestTargetLock;
	local byte TeamNum;
	local vector AimStart, AimDir, TargetLoc, Projection, DirToPawn, LinePoint;
	local Actor HitActor;
	local float PointDistSQ, Score, BestScore, TargetSizeSQ;

	TeamNum = Instigator.GetTeamNum();
	AimStart = GetSafeStartTraceLocation();
	AimDir = vector( GetAdjustedAim(AimStart) );
	BestScore = 0.f;

    //Don't add targets if we're already burst firing
    if (IsInState('WeaponBurstFiring'))
    {
        return false;
    }

	foreach WorldInfo.AllPawns( class'Pawn', P )
	{
		if (!CanLockOnTo(P))
		{
			continue;
		}
		// Want alive pawns and ones we already don't have locked
		if( P != none && P.IsAliveAndWell() && P.GetTeamNum() != TeamNum && LockedTargets.Find(P) == INDEX_NONE )
		{
			TargetLoc = GetLockedTargetLoc( P );
			Projection = TargetLoc - AimStart;
			DirToPawn = Normal( Projection );

			// Filter out pawns too far from center
			// if( AimDir dot DirToPawn < 0.5f )
			// {
			// 	continue;
			// }

			if( AimDir dot DirToPawn < CosTargetAngle )
			{
				continue;
			}

			// Check to make sure target isn't too far from center
            PointDistToLine( TargetLoc, AimDir, AimStart, LinePoint );
            PointDistSQ = VSizeSQ( LinePoint - P.Location );

			TargetSizeSQ = P.GetCollisionRadius() * 2.f;
			TargetSizeSQ *= TargetSizeSQ;

            // if( PointDistSQ > (TargetSizeSQ + MinTargetDistFromCrosshairSQ) )
            // {
            // 	continue;
            // }

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
		LastTargetLockTime = WorldInfo.TimeSeconds;
		LockedTargets.AddItem( BestTargetLock );
		RecentlyLocked = BestTargetLock;

		// Plays sound/FX when locking on to a new target
		PlayTargetLockOnEffects();

		return true;
	}

	RecentlyLocked = none;

	return false;
}

/** Checks to ensure all of our current locked targets are valid */
simulated function bool ValidateTargets( optional Pawn RecentlyLocked )
{
	local int i;
	local bool bShouldRemoveTarget, bAlteredTargets;
	local vector AimStart, AimDir, TargetLoc;
	local Actor HitActor;

	if( `TimeSince(LastTargetValidationCheckTime) < TargetValidationCheckInterval )
	{
		return false;
	}

	LastTargetValidationCheckTime = WorldInfo.TimeSeconds;

	AimStart = GetSafeStartTraceLocation();
	AimDir = vector( GetAdjustedAim(AimStart) );

	bAlteredTargets = false;
	for( i = 0; i < LockedTargets.Length; ++i )
	{
		// For speed don't bother checking a target we just locked
		if( RecentlyLocked != none && RecentlyLocked == LockedTargets[i] )
		{
			continue;
		}

		bShouldRemoveTarget = false;

		if( LockedTargets[i] == none
			|| !LockedTargets[i].IsAliveAndWell() )
		{
			bShouldRemoveTarget = true;
		}
		else
		{
			TargetLoc = GetLockedTargetLoc( LockedTargets[i] );
			if( AimDir dot Normal(LockedTargets[i].Location - AimStart) >= MaxLockMaintainFOVDotThreshold )
			{
				HitActor = class'KFAIController'.static.ActorBlockTest( self, TargetLoc, AimStart,, true, true );
				if( HitActor != none && HitActor != LockedTargets[i] )
				{
					bShouldRemoveTarget = true;
				}
			}
			else
			{
				bShouldRemoveTarget = true;
			}
		}

		// A target was invalidated, remove it from the list
		if( bShouldRemoveTarget )
		{
			LockedTargets.Remove( i, 1 );
			--i;
			bAlteredTargets = true;
			continue;
		}
	}

	// Plays sound/FX when losing a target lock, but only if we didn't play a lock on this frame
	if( bAlteredTargets && RecentlyLocked == none )
	{
		PlayTargetLostEffects();
	}

	return bAlteredTargets;
}

/** Synchronizes our locked targets with the server */
reliable server function ServerSyncLockedTargets( Pawn TargetPawns[MAX_LOCKED_TARGETS] )
{
	local int i;

    LockedTargets.Length = 0;
	for( i = 0; i < MAX_LOCKED_TARGETS; ++i )
	{
        if (TargetPawns[i] != none)
        {
            LockedTargets.AddItem(TargetPawns[i]);
        }		
	}
}

/** Adjusts our destination target impact location */
static simulated function vector GetLockedTargetLoc( Pawn P )
{
	// Go for the chest, but just in case we don't have something with a chest bone we'll use collision and eyeheight settings
	if( P.Mesh.SkeletalMesh != none && P.Mesh.bAnimTreeInitialised )
	{
    	if( P.Mesh.MatchRefBone('Spine') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine' );
		}
		else if( P.Mesh.MatchRefBone('Spine2') != INDEX_NONE )
		{
			return P.Mesh.GetBoneLocation( 'Spine2' );
		}

		return P.Mesh.GetPosition() + ((P.CylinderComponent.CollisionHeight + (P.BaseEyeHeight  * 0.5f)) * vect(0,0,1)) ;
	}

	// General chest area, fallback
	return P.Location + ( vect(0,0,1) * P.BaseEyeHeight * 0.75f );	
}

/** Play FX or sounds when locking on to a new target */
simulated function PlayTargetLockOnEffects()
{
	if( Instigator != none && Instigator.IsHumanControlled() )
	{
		// PlaySoundBase( LockAcquiredSoundFirstPerson, true );
		PlaySoundBase( LockAcquiredSoundCueFirstPerson, true );
	}
}

/** Play FX or sounds when losing a target lock */
simulated function PlayTargetLostEffects()
{
	if( Instigator != none && Instigator.IsHumanControlled() )
	{
		// PlaySoundBase( LockLostSoundFirstPerson, true );
		PlaySoundBase( LockLostSoundCueFirstPerson, true );
	}
}

/** Spawn projectile is called once for each rocket fired. In burst mode it will cycle through targets until it runs out */
simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
	local KFProj_Bullet_Lodestar BulletProj;
 
    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }

    // We need to set our target if we are firing from a locked on position
    if( CurrentFireMode == DEFAULT_FIREMODE && LockedTargets.Length > 0 )
	{
		// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
		if( LockedTargets.Length > 0 )
		{
			BulletProj = KFProj_Bullet_Lodestar( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );
			if( BulletProj != none )
			{
				//Seek to new target, then remove from list.  Always use first target in the list for new fire.
				BulletProj.SetLockedTarget( KFPawn(LockedTargets[0]) );
                LockedTargets.Remove(0, 1);

				return BulletProj;
			}
		}

		return none;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

/** Handle drawing our custom lock on HUD  */
simulated function DrawHUD( HUD H, Canvas C )
{
    local int i;

    if( LockedTargets.Length == 0 )
    {
       return;
    }

    // Draw target locked icons
	C.EnableStencilTest( true );
    for( i = 0; i < LockedTargets.Length; ++i )
    {
        if( LockedTargets[i] != none )
        {
            DrawTargetingIcon( C, i );
        }
    }
	C.EnableStencilTest( false );
}

/** Draws a targeting icon for each one of our locked targets */
simulated function DrawTargetingIcon( Canvas Canvas, int Index )
{
    local vector WorldPos, ScreenPos;
    local float IconSize, IconScale;

    // Project world pos to canvas
    WorldPos = GetLockedTargetLoc( LockedTargets[Index] );
    ScreenPos = Canvas.Project( WorldPos );//WorldToCanvas(Canvas, WorldPos);

    // calculate scale based on resolution and distance
    IconScale = fMin( float(Canvas.SizeX) / 1024.f, 1.f );
	// Scale down up to 40 meters away, with a clamp at 20% size
    IconScale *= fClamp( 1.f - VSize(WorldPos - Instigator.Location) / 4000.f, 0.2f, 1.f );
 
    // Apply size scale
    IconSize = 200.f * IconScale;
    ScreenPos.X -= IconSize / 2.f;
    ScreenPos.Y -= IconSize / 2.f;

    // Off-screen check
    if( ScreenPos.X < 0 || ScreenPos.X > Canvas.SizeX || ScreenPos.Y < 0 || ScreenPos.Y > Canvas.SizeY )
    {
        return;
    }

    Canvas.SetPos( ScreenPos.X, ScreenPos.Y );

	// Draw the icon
    Canvas.DrawTile( LockedOnIcon, IconSize, IconSize, 0, 0, LockedOnIcon.SizeX, LockedOnIcon.SizeY, LockedIconColor );
}

/*
simulated function Activate()
{
    LockedTargets.Length = 0;

	super.Activate();
}

simulated state WeaponSingleFiring
{
	simulated function BeginState( Name PrevStateName )
	{
		LockedTargets.Length = 0;

		super.BeginState( PrevStateName );
	}
}
*/

simulated state WeaponBurstFiring
{
	simulated function int GetBurstAmount()
	{
		// Clamp our bursts to either the number of targets or how much ammo we have remaining
		return Clamp( LockedTargets.Length, 1, AmmoCount[GetAmmoType(CurrentFireMode)] );
	}

    /** Overridden to apply scaled recoil when in multi-rocket mode */
    simulated function ModifyRecoil( out float CurrentRecoilModifier )
	{
		super.ModifyRecoil( CurrentRecoilModifier );

	    CurrentRecoilModifier *= BurstFireRecoilModifier;
	}

    simulated function bool ShouldRefire()
    {
        return LockedTargets.Length > 0;
    }

    simulated function FireAmmunition()
    {
        super.FireAmmunition();
        if (Role < ROLE_Authority)
        {
            LockedTargets.Remove(0, 1);
        }
    }

	simulated event EndState( Name NextStateName )
	{
		LockedTargets.Length = 0;

		super.EndState( NextStateName );
	}
}

/** Get our optics movie from the inventory once our InvManager is created */
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFInventoryManager KFIM;

	super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	if (OpticsUI == none && OpticsUIClass != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			OpticsUI = KFGFxWorld_MedicOptics(KFIM.GetOpticsUIMovie(OpticsUIClass)); // KFGFxWorld_MedicOptics
		}
	}
}

// Update our displayed ammo count if it's changed
simulated function UpdateOpticsUI(optional bool bForceUpdate)
{
	if (OpticsUI != none && OpticsUI.OpticsContainer != none)
	{
		if (AmmoCount[DEFAULT_FIREMODE] != StoredPrimaryAmmo || bForceUpdate)
		{
			StoredPrimaryAmmo = AmmoCount[DEFAULT_FIREMODE];
			OpticsUI.SetPrimaryAmmo(StoredPrimaryAmmo);
		}

		// if (AmmoCount[ALTFIRE_FIREMODE] != StoredSecondaryAmmo || bForceUpdate)
		// {
		// 	StoredSecondaryAmmo = AmmoCount[ALTFIRE_FIREMODE];`
		// 	OpticsUI.SetPrimaryAmmo(StoredSecondaryAmmo);
		// }

		// if(OpticsUI.MinPercentPerShot != AmmoCost[ALTFIRE_FIREMODE])
		// {
		// 	OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE] );
		// }
	}
}

// Fuck this function
function ItemRemovedFromInvManager()
{
	local KFInventoryManager KFIM;
	local KFWeap_MedicBase KFW;

	Super.ItemRemovedFromInvManager();

	if (OpticsUI != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			// @todo future implementation will have optics in base weapon class
			foreach KFIM.InventoryActors(class'KFWeap_MedicBase', KFW)
			{
				if( KFW.OpticsUI.Class == OpticsUI.class)
				{
					// A different weapon is still using this optics class
					return;
				}
			}

			//Create the screen's UI piece
			KFIM.RemoveOpticsUIMovie(OpticsUI.class);

			OpticsUI.Close();
			OpticsUI = none;
		}
	}
}

/** Unpause our optics movie and reinitialize our ammo when we equip the weapon */
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo(MeshCpnt, SocketName);

	if (OpticsUI != none)
	{
		OpticsUI.SetPause(false);
		OpticsUI.ClearLockOn();
		UpdateOpticsUI(true);
		OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE]);
		OpticsUI.SetShotPercentCost( AmmoCost[DEFAULT_FIREMODE]);
	}
}

/** Pause the optics movie once we unequip the weapon so it's not playing in the background */
simulated function DetachWeapon()
{
	local Pawn OwnerPawn;
	
	super.DetachWeapon();

	OwnerPawn = Pawn(Owner);
	if( OwnerPawn != none && OwnerPawn.Weapon == self )
	{
		if (OpticsUI != none)
		{
			OpticsUI.SetPause();
		}
	}
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
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

static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}


/*
simulated function StartFire(byte FireModeNum)
{
	// can't start fire because it's in an uninterruptible state
	if (StartFireDisabled)
	{
		return;
	}

	// if the weapon is currently attacking
	if (CurrentFireMode == DEFAULT_FIREMODE || CurrentFireMode == ALTFIRE_FIREMODE || CurrentFireMode == BASH_FIREMODE)
	{
		// and the player tries to cancel with a reload action
		if(FireModeNum == RELOAD_FIREMODE)
		{
			// stop them from reload cancelling if it has already happened too recently
			if (IsTimerActive(nameof(Timer_SwitchCancel)))
			{
				return;
			}
			else
			{
				SetTimer(SwitchCancelTimeLimit, false, nameof(Timer_SwitchCancel));
			}
		}
	}

	Super.StartFire(FireModeNum);
}

simulated function Timer_SwitchCancel(){}

simulated function AltFireMode()
{
	super.AltFireMode();
	
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	if( bUseAltFireMode )
	{
		// Plays custom firemode that plays custom anim
		StartFire(CUSTOM_FIREMODE);
		bUseAltFireMode = false;
		SetTimer(5.f, false, nameof(AltFireUnlock));
	}
	else
	{
		// Play same anim again
		StartFire(CUSTOM_FIREMODE);
		bUseAltFireMode = false;
		SetTimer(5.f, false, nameof(AltFireUnlock));
	}
}

simulated function AltFireUnlock()
{
	bUseAltFireMode = true;
}

simulated state SwitchAnimState extends MeleeAttackBasic
{
	simulated function bool TryPutDown() { return false; }

	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		// stop the player from interrupting the super attack with another attack
		StartFireDisabled = true;
	}

	simulated function name GetMeleeAnimName(EPawnOctant AtkDir, EMeleeAttackType AtkType)
	{
		// use the special attack anim
		return SwitchAnim;
	}

	simulated event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);

		// player can now interrupt attacks with other attacks again
		StartFireDisabled = false;
	}
}
*/


defaultproperties
{
    // FOV
	MeshFOV=94 //96
	MeshIronSightFOV=77
    PlayerIronSightFOV=77

	// Zooming/Position
	PlayerViewOffset=(X=12.0,Y=-4,Z=-8)
	IronSightPosition=(X=10,Y=0,Z=0.5)
	ZoomInRotation=(Pitch=910,Yaw=0,Roll=2910)

	// Content
	PackageKey="Lodestar"
	FirstPersonMeshName="WEP_Lodestar_MESH.WEP_1P_Lodestar_Rig"
	FirstPersonAnimSetNames(0)="WEP_Lodestar_ARCH.Wep_1stP_Lodestar_Anim"
	PickupMeshName="WEP_Lodestar_MESH.Wep_Lodestar_Pickup"
	AttachmentArchetypeName="WEP_Lodestar_ARCH.WEP_Lodestar_3P"
	MuzzleFlashTemplateName="WEP_Lodestar_ARCH.Wep_Lodestar_MuzzleFlash"

    OpticsUIClass=class'KFGFxWorld_MedicOptics'

	// Ammo
	MagazineCapacity[0]=12
	SpareAmmoCapacity[0]=72 //48 60
	InitialSpareMags[0]=2
	AmmoPickupScale[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true
	bNoMagazine=true

	// Recoil
	maxRecoilPitch=450
	minRecoilPitch=400
	maxRecoilYaw=150
	minRecoilYaw=-150
	RecoilRate=0.01
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=250
	RecoilISMinPitchLimit=65485
	BurstFireRecoilModifier=0.3f //0.20 - Reduce recoil between tracking bullets when in burst mode

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)="UI_SecondaryAmmo_TEX.UI_FireModeSelect_ManualTarget"
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponBurstFiring //WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Lodestar'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Freeze_LodestarImpact'
	FireInterval(DEFAULT_FIREMODE)=+0.1 // 600 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=100 //91
	Spread(DEFAULT_FIREMODE)=0.025
	PenetrationPower(DEFAULT_FIREMODE)=0
	AmmoCost(DEFAULT_FIREMODE)=1
	// FireOffset=(X=22,Y=4.0,Z=0) //y4
	FireOffset=(X=22,Y=-2.5,Z=-12) //y4

	SelfDamageReductionValue=0.14f; //0.16

	// Target Locking
	// MinTargetDistFromCrosshairSQ=4500.0f // 0.5 meters
	MaxTargetAngle=20 //30
	TimeBetweenLockOns=0.08f //0.03
	TargetValidationCheckInterval=0.1f //0.6
	MaxLockMaintainFOVDotThreshold=0.36f

	// LockOn Visuals
    LockedOnIcon=Texture2D'DROW3_MAT.Wep_1stP_Target_Cube_45_Gap_Small_DROW3'
    LockedIconColor=(R=1.f,G=0.f,B=0.f,A=1.0f) //a=0.5

    // Lock On/Lost Sounds
	// LockAcquiredSoundFirstPerson=AkEvent'WW_WEP_SA_MedicDart.Play_WEP_SA_Medic_Alert_Locked_1P'
	// LockLostSoundFirstPerson=AkEvent'WW_WEP_SA_Railgun.Play_Railgun_Scope_Lost'
    LockAcquiredSoundCueFirstPerson=SoundCue'WEP_Lodestar_SND.Lodestar_targetlock_Cue'
    LockLostSoundCueFirstPerson=SoundCue'WEP_Lodestar_SND.Lodestar_targetlock_lost_Cue'
    
	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	FiringStatesArray(CUSTOM_FIREMODE)=SwitchAnimState
	SwitchAnim=Reload_Half
	SwitchCancelTimeLimit = 0.5f;

	// ALT_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)="UI_SecondaryAmmo_TEX.UI_FireModeSelect_ManualTarget"
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class''
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class''
	FireInterval(ALTFIRE_FIREMODE)=+0.1 // 600 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=100 //91
	Spread(ALTFIRE_FIREMODE)=0.025
	PenetrationPower(ALTFIRE_FIREMODE)=0
	AmmoCost(ALTFIRE_FIREMODE)=1
*/

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_93R'
	InstantHitDamage(BASH_FIREMODE)=24

	// Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_MedicAssault.Play_SA_MedicAssault_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_SA_MedicAssault.Play_SA_MedicAssault_Fire_1P_Single')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Lodestar_SND.Lodestar_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Lodestar_SND.Lodestar_fire_Cue')
	// WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Lodestar_SND.Lodestar_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Lodestar_SND.Lodestar_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_9mm.Play_WEP_SA_9mm_Handling_DryFire'
	// WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_9mm.Play_WEP_SA_9mm_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.Default_LaserSight_1P'

	// Perks
	AssociatedPerkClasses(0)=class'KFPerk_Firebug'
	AssociatedPerkClasses(1)=class'KFPerk_Survivalist'
	
	// Inventory
	WeaponSelectTexture=Texture2D'WEP_Lodestar_MAT.UI_WeaponSelect_Lodestar'
	InventorySize=4 //3
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	bIsBackupWeapon=false

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

	// bugged lock-on when inactive
	// DualClass=class''

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4, Guncheck_v5)

	bHasFireLastAnims=true

	BonesToLockOnEmpty=(RW_Bolt, RW_Bullets1)

	// Weapon upgrades
	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
}