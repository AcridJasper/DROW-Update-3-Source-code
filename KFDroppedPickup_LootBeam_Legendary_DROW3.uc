class KFDroppedPickup_LootBeam_Legendary_DROW3 extends KFDroppedPickup;

var() SoundCue PickupSound;

var() ParticleSystem LootBeamFX;
var	transient ParticleSystemComponent LootBeamPSC;

simulated function PostBeginPlay()
{
	if( LootBeamFX != none )
	{
		StartLootBeamFX();
	}
}

simulated function StartLootBeamFX()
{
	LootBeamPSC = new(self) class'ParticleSystemComponent';
	LootBeamPSC.SetTemplate( LootBeamFX );
	AttachComponent(LootBeamPSC);
	LootBeamPSC.SetAbsolute(false, true, true);
}

State FadeOut
{
	function Tick(float DeltaTime)
	{
		// Scales down loot beam fx same way the mesh does
		LootBeamPSC.SetScale(FMax(0.01, DrawScale - Default.DrawScale * DeltaTime));

		SetDrawScale(FMax(0.01, DrawScale - Default.DrawScale * DeltaTime));
		Global.Tick(DeltaTime);
	}

	simulated event BeginState(Name PreviousStateName)
	{
		bFadeOut = true;
		RotationRate.Yaw=60000;
		SetPhysics(PHYS_Rotating);
		LifeSpan = 1.0;

		SetTimer(2.0, false, nameof(StopLootBeamFX));
		// StopLootBeamFX();
	}

	/** disable normal touching. we require input from the player to pick it up */
	event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
	{
	}
}

simulated function StopLootBeamFX()
{
	if( WorldInfo.NetMode != NM_DedicatedServer && LootBeamPSC != none )
	{
        LootBeamPSC.DeactivateSystem();
	}
}

/**
 * Give pickup to player
 * Overriden to play SoundCue sound (still plays the original pickup sound from Inventory)
 */
function GiveTo(Pawn P)
{
    local KFWeapon KFW;
    local class<KFWeapon> KFWInvClass;
    local Inventory NewInventory;
    local KFInventoryManager KFIM;
	local KFGameReplicationInfo KFGRI;
	local class<Inventory> NewInventoryClass;
	local bool bIsSecondaryPistol;
	local bool bIs9mmInInventory;
	local bool bIsHRG93InInventory;

	NewInventoryClass = InventoryClass;

	if (PickupSound != None)
	{
		PlaySoundBase( PickupSound ); //Other.PlaySound
	}

	// For HRG93R and 9mm pistols, if one of the other type is picked just give the one owned

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != none && KFGRI.bIsEndlessPaused)
	{
		return;
	}

    KFIM = KFInventoryManager(P.InvManager);
    if (KFIM != None)
    {
		bIsSecondaryPistol = InventoryClass.name == 'KFWeap_HRG_93R'         ||
								InventoryClass.name == 'KFWeap_HRG_93R_Dual' || 
								InventoryClass.name == 'KFWeap_Pistol_9mm'   || 
								InventoryClass.name == 'KFWeap_Pistol_Dual9mm';

		if (bIsSecondaryPistol)
		{
			bIs9mmInInventory = KFIM.Is9mmInInventory();
			bIsHRG93InInventory = KFIM.IsHRG93InInventory();
			if (!(bIs9mmInInventory && bIsHRG93InInventory))
			{
				if (bIs9mmInInventory)
				{
					if (InventoryClass.name == 'KFWeap_HRG_93R')
					{
						NewInventoryClass = class<Weapon>(DynamicLoadObject(class'KfWeapDef_9mm'.default.WeaponClassPath, class'Class'));
					}
					else if (InventoryClass.name == 'KFWeap_HRG_93R_Dual')
					{
						NewInventoryClass = class<Weapon>(DynamicLoadObject(class'KfWeapDef_9mmDual'.default.WeaponClassPath, class'Class'));
					}
				}
				else
				{
					if(InventoryClass.name == 'KFWeap_Pistol_9mm')
					{
						NewInventoryClass = class<Weapon>(DynamicLoadObject(class'KFWeapDef_HRG_93R'.default.WeaponClassPath, class'Class'));
					}
					else if (InventoryClass.name == 'KFWeap_Pistol_Dual9mm')
					{
						NewInventoryClass = class<Weapon>(DynamicLoadObject(class'KFWeapDef_HRG_93R_Dual'.default.WeaponClassPath, class'Class'));
					}
				}
			}
		}
		
        KFWInvClass = class<KFWeapon>(NewInventoryClass);
        foreach KFIM.InventoryActors(class'KFWeapon', KFW)
        {
            if (KFW.Class == NewInventoryClass)
            {
                // if this isn't a dual-wield class, then we can't carry another
                if (KFW.DualClass == none)
                {
                    PlayerController(P.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_AlreadyCarryingWeapon);
                    return;
                }
                break;
            }
            // if we already have the dual version of this single, then we can't carry another
            else if (KFWInvClass != none && KFW.Class == KFWInvClass.default.DualClass)
            {
                PlayerController(P.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_AlreadyCarryingWeapon);
                return;
            }
        }

		if (KFWInvClass != none && KFWeapon(Inventory) != none && !KFIM.CanCarryWeapon(KFWInvClass, KFWeapon(Inventory).CurrentWeaponUpgradeIndex))
		{
			PlayerController(P.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_TooMuchWeight);
			return;
		}

        NewInventory = KFIM.CreateInventory(NewInventoryClass, true);
        if (NewInventory != none)
        {
            // Added extra check in case we want to pick up a non-weapon based pickup
            KFW = KFWeapon(NewInventory);
            if (KFW != none)
            {
				if (PreviousOWner != none)
				{
					KFW.KFPlayer = PreviousOwner;
				}

                KFW.SetOriginalValuesFromPickup(KFWeapon(Inventory));
                KFW = KFIM.CombineWeaponsOnPickup(KFW);
                KFW.NotifyPickedUp();
            }

            Destroy();
        }
    }

    if (Role == ROLE_Authority)
    {
        //refresh weapon hud here
        NotifyHUDofWeapon(P);
    }
}

defaultproperties
{
	LootBeamFX=ParticleSystem'DROW3_EMIT.FX_LootBeam_Legendary_DROW3'

    PickupSound=SoundCue'DROW3_ARCH.item_up_Cue'
}