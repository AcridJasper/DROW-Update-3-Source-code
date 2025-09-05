class KFPawn_FleshFriend extends KFPawn_ZedFleshpoundKing;

var transient KFProj_Grenade_ZEDNade OwnerWeapon;

var AkEvent EntranceSound;

simulated function PostBeginPlay()
{
    // body scale
    // IntendedBodyScale=0.95f;

    // adds entrance sound
    SoundGroupArch.EntranceSound = default.EntranceSound;

    super.PostBeginPlay();
}

// ********************* WEAPON / ETC *********************

simulated function UpdateInstigator(Pawn NewInstigator)
{
    Instigator = NewInstigator;

    // TeamNum = Instigator.GetTeamNum(); //0 128 255

    if (Weapon != none)
    {
        Weapon.Instigator = NewInstigator;
    }
}

function UpdateReadyToUse(bool bReady)
{
    if (OwnerWeapon != none)
    {
        OwnerWeapon.SetReadyToUse(bReady);
    }
}

// Ends rage after X seconds after melee hit
function NotifyMeleeDamageDealt()
{
    if( !IsTimerActive(nameOf(EndRage)) )
    {
        SetTimer( 4.f, false, nameOf(EndRage) ); //2
    }
}

/** Ends rage mode */
function EndRage()
{
    SetEnraged( false );
}

/** Summon some children */
function SummonChildren(){}

/** Play music for this boss (overridden for each boss) */
function PlayBossMusic(){}

static simulated event bool IsABoss()
{
    return false;
}

// Can this pawn be grabbed by Zed performing grab special move (clots & Hans's energy drain)
function bool CanBeGrabbed(KFPawn GrabbingPawn, optional bool bIgnoreFalling, optional bool bAllowSameTeamGrab)
{
    return false;
}

DefaultProperties
{
	CharacterMonsterArch = KFCharacterInfo_Monster'DROW3_ARCH.ZED_Fren_Archetype' //ZED_ARCH.ZED_Fleshpound_Archetype

	ControllerClass=class'KFAIController_FleshFriend'

    Health=300 //450

	DoshValue=1 // 1 dollar
    XPValues(0)=0
    XPValues(1)=0
    XPValues(2)=0
    XPValues(3)=0

    ShrinkEffectModifier=0.0
    VortexAttracionModifier=0.0
    bCanBePinned=false
    bCanBeKilledByShrinking=false

    EntranceSound=AkEvent'ww_zed_fleshpound_2.Play_FP_Charge'

    ShieldHealthMaxDefaults[0]=100
    ShieldHealthMaxDefaults[1]=100
    ShieldHealthMaxDefaults[2]=100
    ShieldHealthMaxDefaults[3]=100
    ShieldHealthScale=0.2f

	Begin Object Name=MeleeHelper_0
		BaseDamage=80.f
		MaxHitRange=250.f
	    MomentumTransfer=55000.f
		MyDamageType=class'KFDT_Bludgeon_Fleshpound'
		MeleeImpactCamScale=0.0 // Disables screen shake
	End Object

	Begin Object Name=SpecialMoveHandler_0
        SpecialMoveClasses(SM_Taunt)=class'DROW3.KFSM_Zed_NOTaunt_DROW3'
        SpecialMoveClasses(SM_HoseWeaponAttack)=class'KFSM_FleshFriend_ChestBeam'
    End Object

    // **************** NORMAL/BATTLE LIGHTS / RAGE ****************

    RageExplosionMinPhase=0

    EnragedGlowColor=(R=2.0,G=0.0)
    DefaultGlowColor=(R=0.01,G=0.13,B=0.78)
    DeadGlowColor=(R=0.0f,G=0.0f)

    // normal lights
    Begin Object Name=PointLightComponent1
        Brightness=1.f
        Radius=128.f
        FalloffExponent=4.f
        LightColor=(R=0,G=128,B=200,A=255)
        CastShadows=false
        CastDynamicShadows=TRUE
        LightingChannels=(Indoor=true,Outdoor=true,bInitialized=TRUE)
    End Object
    BattlePhaseLightTemplateYellow=PointLightComponent1
    
    // enraged lights
    Begin Object Name=PointLightComponent2
        Brightness=1.f
        Radius=128.f
        FalloffExponent=4.f
        LightColor=(R=255,G=64,B=0,A=255)
        CastShadows=false
        CastDynamicShadows=TRUE
        LightingChannels=(Indoor=true,Outdoor=true,bInitialized=TRUE)
    End Object
    BattlePhaseLightTemplateRed=PointLightComponent2
}