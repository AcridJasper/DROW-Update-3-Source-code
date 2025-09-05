class KFWeap_Hemoinitiative extends KFWeap_ScopedBase;

const ShootDartAnim = 'Shoot_Dart';
const ShootDartIronAnim = 'Shoot_Dart_Iron';

var class<KFGFxWorld_MedicOptics> OpticsUIClass;
var KFGFxWorld_MedicOptics OpticsUI;

// The last updated value for our ammo - Used to know when to update our optics ammo
var byte StoredPrimaryAmmo;
var byte StoredSecondaryAmmo;

// How many Alt ammo to recharge per second
var float AmmoFullRechargeSeconds;
var transient float AmmoRechargePerSecond;
var transient float AmmoIncrement;
var repnotify byte FakeAmmo;

replication
{
    if (bNetDirty && Role == ROLE_Authority)
        FakeAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
    if (VarName == nameof(FakeAmmo))
    {
        AmmoCount[DEFAULT_FIREMODE] = FakeAmmo;
    }
    else
    {
        Super.ReplicatedEvent(VarName);
    }
}

simulated event PreBeginPlay()
{
    super.PreBeginPlay();
    StartAmmoRecharge();
}

function StartAmmoRecharge()
{
    local float UsedAmmoRechargeTime;

    // begin ammo recharge on server
    if( Role == ROLE_Authority )
    {
        UsedAmmoRechargeTime = AmmoFullRechargeSeconds;
        AmmoRechargePerSecond = MagazineCapacity[DEFAULT_FIREMODE] / UsedAmmoRechargeTime;
        AmmoIncrement = 0;
    }
}

function RechargeAmmo(float DeltaTime)
{
    if ( Role == ROLE_Authority )
    {
        AmmoIncrement += AmmoRechargePerSecond * DeltaTime;

        if( AmmoIncrement >= 1.0 && AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
        {
            AmmoCount[DEFAULT_FIREMODE]++;
            AmmoIncrement -= 1.0;
            FakeAmmo = AmmoCount[DEFAULT_FIREMODE];
        }
    }
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
    super.GivenTo( thisPawn, bDoNotActivate );

    if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
    {
        StartAmmoRecharge();
    }
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
    {
        RechargeAmmo(DeltaTime);
    }
    
    if (Instigator != none && Instigator.weapon == self)
    {
        UpdateOpticsUI();
    }

    Super.Tick(DeltaTime);
}

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
// simulated function bool HasAnyAmmo()
// {
//     return HasSpareAmmo() || HasAmmo(ALTFIRE_FIREMODE);
// }
/** Healing charge doesn't count as ammo for purposes of inventory management (e.g. switching) */
simulated function bool HasAnyAmmo()
{
    if (HasSpareAmmo() || HasAmmo(DEFAULT_FIREMODE))
    {
        return true;
    }

    return false;
}

simulated function string GetSpecialAmmoForHUD()
{
    return int(FakeAmmo)$"%";
}

simulated function bool CanBuyAmmo()
{
    return false;
}

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
    super.SetTraderWeaponStats( WeaponStats );

    WeaponStats.Length = WeaponStats.Length + 1;
    WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
    WeaponStats[WeaponStats.Length-1].StatValue = default.AmmoFullRechargeSeconds;
}

// Instead of switch fire mode use as immediate alt fire
simulated function AltFireMode()
{
    if (!Instigator.IsLocallyControlled())
    {
        return;
    }

    // StartFire - StopFire called from KFPlayerInput
    StartFire(ALTFIRE_FIREMODE);
}

simulated function StartFire(byte FireModeNum)
{
    // Skip KFWeap_Rifle_RailGun::StartFire because of some irrelevant cheat detection there
    super(KFWeap_ScopedBase).StartFire(FireModeNum);
}

// Set parameters for the weapon once replication is complete (works in Standalone as well)
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
    local KFInventoryManager KFIM;

    Super.ClientWeaponSet(bOptionalSet);

    if (OpticsUI == none && OpticsUIClass != none)
    {
        KFIM = KFInventoryManager(InvManager);
        if (KFIM != none)
        {
            //Create the screen's UI piece
            OpticsUI = KFGFxWorld_MedicOptics(KFIM.GetOpticsUIMovie(OpticsUIClass));
        }
    }
}

/** Event called when weapon actor is destroyed */
simulated event Destroyed()
{
    local Pawn OwnerPawn;

    super.Destroyed();

    OwnerPawn = Pawn(Owner);
    if( OwnerPawn != none && OwnerPawn.Weapon == self )
    {
        if (OpticsUI != none)
        {
            OpticsUI.SetPause();
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

        if (AmmoCount[ALTFIRE_FIREMODE] != StoredSecondaryAmmo || bForceUpdate)
        {
            StoredSecondaryAmmo = AmmoCount[ALTFIRE_FIREMODE];
            OpticsUI.SetHealerCharge(StoredSecondaryAmmo);
        }

        if(OpticsUI.MinPercentPerShot != AmmoCost[ALTFIRE_FIREMODE])
        {
            OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE] );
        }
    }
}

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

// Unpause our optics movie and reinitialize our ammo when we equip the weapon
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
    super.AttachWeaponTo(MeshCpnt, SocketName);

    if (OpticsUI != none)
    {
        OpticsUI.SetPause(false);
        OpticsUI.ClearLockOn();
        UpdateOpticsUI(true);
        OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE]);
    }
}

// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
    local vector        StartTrace, EndTrace, RealStartLoc, AimDir;
    local ImpactInfo    TestImpact;
    local vector DirA, DirB;
    local Quat Q;
    local class<KFProjectile> MyProjectileClass;

    // local KFPawn TargetPawn;

    MyProjectileClass = GetKFProjectileClass();

    StartTrace = GetSafeStartTraceLocation();
    AimDir = Vector(GetAdjustedAim( StartTrace ));

    RealStartLoc = GetPhysicalFireStartLoc(AimDir);

    EndTrace = StartTrace + AimDir * GetTraceRange();
    TestImpact = CalcWeaponFire( StartTrace, EndTrace );

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
            DirB = AimDir;

            AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            DirA = AimDir;

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

static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

// Medic darts
static simulated event EFilterTypeUI GetAltTraderFilter()
{
    return FT_Rifle;
}

defaultproperties
{
    // Inventory / Grouping
    InventorySize=5 //7
    GroupPriority=21 // funny number
    WeaponSelectTexture=Texture2D'WEP_Hemoinitiative_MAT.UI_WeaponSelect_Hemoinitiative'
    AssociatedPerkClasses(0)=class'KFPerk_FieldMedic'

    DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW3' // Loot beam fx (no offset)

    // FOV
    MeshFOV=65 //70
    MeshIronSightFOV=18 //20 27
    PlayerIronSightFOV=70

    // Zooming/Position
    PlayerViewOffset=(X=20.0,Y=11.0,Z=-2) //(X=15.0,Y=11.5,Z=-4)
    IronSightPosition=(X=30.0,Y=0.07,Z=0) //-0.035

	// Content
	PackageKey="Hemoinitiative"
	FirstPersonMeshName="WEP_Hemoinitiative_MESH.Wep_1stP_Hemoinitiative_Rig"
    FirstPersonAnimSetNames(0)="wep_1p_hrg_cranialpopper_anim.Wep_1stP_HRG_CranialPopper_Anim"
    PickupMeshName="WEP_Hemoinitiative_MESH.Wep_Pickup_Hemoinitiative"
    AttachmentArchetypeName="WEP_Hemoinitiative_ARCH.Wep_Hemoinitiative_3P"
    MuzzleFlashTemplateName="WEP_Hemoinitiative_ARCH.Wep_Hemoinitiative_MuzzleFlash"

    OpticsUIClass=class'KFGFxWorld_MedicOptics'

    // Scope Render
    // 2D scene capture
    Begin Object Name=SceneCapture2DComponent0
       //TextureTarget=TextureRenderTarget2D'WEP_1P_HRG_CranialPopper_MAT.WEP_1P_Cranial_zoomed_Scope_MAT'
       FieldOfView=8.0 //12.5 //23.0 // "1.5X" = 35.0(our real world FOV determinant)/1.5
    End Object

    ScopeMICIndex=3
    ScopedSensitivityMod=10.0 //8.0 16.0
    ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_1P_HRG_CranialPopper_MAT.WEP_1P_Cranial_zoomed_Scope_MAT'

    // Ammo
    AmmoFullRechargeSeconds=180 //60
    FakeAmmo=100
    MagazineCapacity[0]=100
    SpareAmmoCapacity[0]=0
    InitialSpareMags[0]=0
    bCanBeReloaded=false //true
    bReloadFromMagazine=false //true
    bNoMagazine=true

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
    FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Electricity'
    FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
    WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
    WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Hemoinitiative'
    InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Hemoinitiative'
    InstantHitDamage(DEFAULT_FIREMODE)=20 //120
    FireInterval(DEFAULT_FIREMODE)=0.25
    PenetrationPower(DEFAULT_FIREMODE)=0.0
    Spread(DEFAULT_FIREMODE)=0.006
    AmmoCost(DEFAULT_FIREMODE)=100
    FireOffset=(X=30,Y=3.0,Z=-2.5)

    // ALT_FIREMODE
    SecondaryAmmoTexture=Texture2D'UI_SecondaryAmmo_TEX.MedicDarts'
    FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
    WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_InstantHit
    WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_Hemoinitiative_ALT'
    InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Hemoinitiative_ALT'
    FireInterval(ALTFIRE_FIREMODE)=+0.175
    InstantHitDamage(ALTFIRE_FIREMODE)=75
    InstantHitMomentum(ALTFIRE_FIREMODE)=50000.f
    Spread(ALTFIRE_FIREMODE)=0.005
    PenetrationPower(ALTFIRE_FIREMODE)=10.0
    AmmoCost(ALTFIRE_FIREMODE)=25 //50

    MagazineCapacity[1]=100
    bCanRefillSecondaryAmmo=false
    MedicCompClass=class'KFMedicWeaponComponent_Hemoinitiative'
    
    // BASH_FIREMODE
    InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Hemogoblin'
    InstantHitDamage(BASH_FIREMODE)=27

    // Fire Effects
    WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Bleeder.Play_WEP_Bleeder_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_Bleeder.Play_WEP_Bleeder_Fire_1P')
    WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_EBR.Play_WEP_SA_EBR_Handling_DryFire'

    // From original KFWeap_RifleBase base class
    AimCorrectionSize=40.f

    // Attachments
    bHasIronSights=true
    bHasFlashlight=false

    // Custom animations
    FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

    WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'
}