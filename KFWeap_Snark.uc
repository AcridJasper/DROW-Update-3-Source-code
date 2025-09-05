class KFWeap_Snark extends KFWeap_ThrownBase;

var transient KFParticleSystemComponent ParticlePSC;
var const ParticleSystem ParticleFXTemplate;

/*
var const float MaxTargetAngle;
var transient float CosTargetAngle;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	CosTargetAngle = Cos(MaxTargetAngle * DegToRad);
}

// Given an potential target TA determine if we can lock on to it. By default only allow locking on to pawns
simulated function bool CanLockOnTo(Actor TA)
{
	Local KFPawn PawnTarget;

	PawnTarget = KFPawn(TA);

	// Make sure the pawn is legit, isn't dead, and isn't already at full health
	if ((TA == None) || !TA.bProjTarget || TA.bDeleteMe || (PawnTarget == None) ||
		(TA == Instigator) || (PawnTarget.Health <= 0)) //|| !HasAmmo(THROW_FIREMODE)
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
	local KFProj_Snark RocketProj;
	local KFPawn TargetPawn;

    if( CurrentFireMode == GRENADE_FIREMODE )
    {
        return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
    }
    
    if ( CurrentFireMode == THROW_FIREMODE )
	{
		FindTarget(TargetPawn);

		RocketProj = KFProj_Snark( super.SpawnProjectile( class<KFProjectile>(WeaponProjectiles[CurrentFireMode]) , RealStartLoc, AimDir) );

		if( RocketProj != none )
		{
			// We'll aim our rocket at a target here otherwise we will spawn a dumbfire rocket at the end of the function
			if ( TargetPawn != none)
			{
				//Seek to new target, then remove it
				RocketProj.SetLockedTarget( TargetPawn );
			}
		}

		return RocketProj;
	}

   	return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}
*/

// Route ironsight player input to melee
simulated function SetIronSights(bool bNewIronSights)
{
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	if ( bNewIronSights )
	{
		StartFire(BASH_FIREMODE);
	}
	else
	{
		StopFire(BASH_FIREMODE);
	}
}

static simulated event bool UsesAmmo()
{
    return true;
}

// ain't got one
simulated function AltFireMode();

// Allow weapons with abnormal state transitions to always use zed time resist
simulated function bool HasAlwaysOnZedTimeResist()
{
    return true;
}

simulated state Active
{
	// Overridden to prevent playing fidget if play has no more ammo
	simulated function bool CanPlayIdleFidget(optional bool bOnReload)
	{
		if( !HasAmmo(0) )
		{
			return false;
		}

		return super.CanPlayIdleFidget( bOnReload );
	}
}

simulated state WeaponThrowing
{
	// Never refires. Must re-enter this state instead
	simulated function bool ShouldRefire()
	{
		return false;
	}

    simulated function EndState(Name NextStateName)
    {
        local KFPerk InstigatorPerk;

        Super.EndState(NextStateName);

        //Targeted fix for Demolitionist w/ the C4.  It should remain in zed time  while waiting on
        //      the fake reload to be triggered.  This will return 0 for other perks.
        InstigatorPerk = GetPerk();
        if( InstigatorPerk != none )
        {
            SetZedTimeResist( InstigatorPerk.GetZedTimeModifier(self) );
        }
    }
}

simulated state WeaponEquipping
{
	simulated event BeginState( name PreviousStateName )
	{
		super.BeginState( PreviousStateName );

		ActivatePSC(ParticlePSC, ParticleFXTemplate, 'ParticleFX');

		// perform a "reload" if we refilled our ammo from empty while it was unequipped
		if( !HasAmmo(THROW_FIREMODE) && HasSpareAmmo() )
		{
			PerformArtificialReload();
		}
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
		// OutPSC.SetAbsolute(false, false, false);
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if (ParticlePSC != none)
	{
		ParticlePSC.SetFOV(NewFOV);
	}
}

simulated state Inactive
{
	simulated event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		if (ParticlePSC != none)
		{
			ParticlePSC.DeactivateSystem();
		}
	}
}

static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
	// Zooming/Position
	PlayerViewOffset=(X=6.0,Y=2,Z=-4)

	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	ParticlePSC=BasePSC0
	ParticleFXTemplate=ParticleSystem'DROW3_EMIT.FX_Snark_ParticleFX'

	// Content
	PackageKey="Snark"
	FirstPersonMeshName="Wep_Snark_MESH.Wep_1stP_Snark_Rig"
	FirstPersonAnimSetNames(0)="WEP_Snark_ARCH.Wep_1P_Snark_ANIM"
	PickupMeshName="Wep_Snark_MESH.Wep_Snarknest_Pickup" // Wep_Snark_MESH.Wep_Snark_Pickup
	AttachmentArchetypeName="WEP_Snark_ARCH.WEP_Snark_3P"

	// Anim
	FireAnim=C4_Throw
	FireLastAnim=C4_Throw_Last

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=20
	InitialSpareMags[0]=15
	AmmoPickupScale[0]=5.0

	// THROW_FIREMODE
	FireModeIconPaths(THROW_FIREMODE)=Texture2D'DROW3_MAT.UI_FireModeSelect_Bio'
	WeaponProjectiles(THROW_FIREMODE)=class'KFProj_Snark'
	InstantHitDamageTypes(THROW_FIREMODE)=class'KFDT_Toxic_Snark'
	InstantHitDamage(THROW_FIREMODE)=110
	FireInterval(THROW_FIREMODE)=0.25
	Spread(THROW_FIREMODE)=0.2
	NumPellets(THROW_FIREMODE)=4
	FireOffset=(X=25,Y=4) //y=15

	// MaxTargetAngle=30 //25

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_C4'
	InstantHitDamage(BASH_FIREMODE)=24

	// Inventory / Grouping
	InventoryGroup=IG_Secondary
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Snark_MAT.UI_WeaponSelect_Snark'
	InventorySize=1

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW3' // Loot beam fx (no offset)

	AssociatedPerkClasses(0)=none
   	// AssociatedPerkClasses(0)=class'KFPerk_Firebug'
}