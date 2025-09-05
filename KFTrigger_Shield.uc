class KFTrigger_Shield extends Trigger;

// var transient ParticleSystemComponent ParticlePSC;
// var ParticleSystem FriendlyEffect;

var transient ParticleSystemComponent WeakpointSmallEffectPSCs[4];
var ParticleSystem WeakpointSmallEffect;

var transient ParticleSystemComponent WeakpointBigEffectPSCs[4];
var ParticleSystem WeakpointBigEffect;

// Misc FX

var transient ParticleSystemComponent WeakpointMatriarchHeadEffectPSC;
var ParticleSystem WeakpointMatriarchHeadEffect;
var transient ParticleSystemComponent WeakpointMatriarchCannonEffectPSC;
var ParticleSystem WeakpointMatriarchCannonEffect;

var transient ParticleSystemComponent WeakpointEDARChestEffectPSC;
var ParticleSystem WeakpointEDARChestEffect;

// var() AkEvent TouchSoundEvent;

var() float WeakpointFXLifetime;

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

	if( Role == ROLE_Authority )
	{
		SetTimer(WeakpointFXLifetime, false, nameof(Timer_DestroyWeakpointFX), self);
	}
}

// Fallback ?
function Timer_DestroyWeakpointFX()
{
	local KFPawn_Monster KFP;

	foreach WorldInfo.AllPawns( class'KFPawn_Monster', KFP )
	{
		if (WeakpointSmallEffectPSCs[0] != None && WeakpointSmallEffectPSCs[0].bIsActive)
	    {
	        WeakpointSmallEffectPSCs[0].DeactivateSystem();
	    }
	    if (WeakpointSmallEffectPSCs[1] != None && WeakpointSmallEffectPSCs[1].bIsActive)
	    {
	        WeakpointSmallEffectPSCs[1].DeactivateSystem();
	    }
	    if (WeakpointSmallEffectPSCs[2] != None && WeakpointSmallEffectPSCs[2].bIsActive)
	    {
	        WeakpointSmallEffectPSCs[2].DeactivateSystem();
	    }
	    if (WeakpointSmallEffectPSCs[3] != None && WeakpointSmallEffectPSCs[3].bIsActive)
	    {
	        WeakpointSmallEffectPSCs[3].DeactivateSystem();
	    }
	
	    // Big FX
	
	    if (WeakpointBigEffectPSCs[0] != None && WeakpointBigEffectPSCs[0].bIsActive)
	    {
	        WeakpointBigEffectPSCs[0].DeactivateSystem();
	    }
	    if (WeakpointBigEffectPSCs[1] != None && WeakpointBigEffectPSCs[1].bIsActive)
	    {
	        WeakpointBigEffectPSCs[1].DeactivateSystem();
	    }
	    if (WeakpointBigEffectPSCs[2] != None && WeakpointBigEffectPSCs[2].bIsActive)
	    {
	        WeakpointBigEffectPSCs[2].DeactivateSystem();
	    }
	    if (WeakpointBigEffectPSCs[3] != None && WeakpointBigEffectPSCs[3].bIsActive)
	    {
	        WeakpointBigEffectPSCs[3].DeactivateSystem();
	    }
	
		// Misc FX
	
	    if (WeakpointMatriarchHeadEffectPSC != None && WeakpointMatriarchHeadEffectPSC.bIsActive)
	    {
	        WeakpointMatriarchHeadEffectPSC.DeactivateSystem();
	    }
	    if (WeakpointMatriarchCannonEffectPSC != None && WeakpointMatriarchCannonEffectPSC.bIsActive)
	    {
	        WeakpointMatriarchCannonEffectPSC.DeactivateSystem();
	    }
	    
	    if (WeakpointEDARChestEffectPSC != None && WeakpointEDARChestEffectPSC.bIsActive)
	    {
	        WeakpointEDARChestEffectPSC.DeactivateSystem();
	    }
	}
}

/*
event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	// local KFPawn_Human KFPH;
	local KFPawn_Monster KFP;
	local float CollidingRadius;

	super.Touch( Other, OtherComp, HitLocation, HitNormal );

    // KFP = KFPawn_Monster( Outer );

	CollidingRadius = CylinderComponent.CollisionRadius;

	foreach CollidingActors(class'KFPawn_Human', KFPH, CollidingRadius, Location, true,,)
	{

	}

	foreach CollidingActors(class'KFPawn_Monster', KFP, CollidingRadius, Location, true,,)
	{
	    ParticlePSC = KFP.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(FriendlyEffect, KFP.Mesh, 'head', true);
	    ParticlePSC.SetAbsolute(false, true, true);

		if( TouchSoundEvent != none && WorldInfo.NetMode != NM_Client )
		{
			PlaySoundBase(TouchSoundEvent, false, WorldInfo.NetMode == NM_DedicatedServer);
		}
	}
}
*/

// Spawn FX per frame because we are unable to turn these off when ZED dies or leaves area
simulated event Tick(float DeltaTime)
{
	local KFPawn_ZedClot KFPCL;
	local KFPawn_ZedCrawler KFPCR;
	local KFPawn_ZedStalker KFPST;
	local KFPawn_ZedGorefast KFPGF;
	local KFPawn_ZedBloat KFPB;
	local KFPawn_ZedBloatKingSubspawn KFPBS;
	local KFPawn_ZedDAR KFPD;
	local KFPawn_ZedHusk KFPHU;
	local KFPawn_ZedSiren KFPSR;
	local KFPawn_ZedScrake KFPSC;
	local KFPawn_ZedFleshpound KFPFP;
	local KFPawn_ZedHans KFPHA;
	local KFPawn_ZedPatriarch KFPPAT;
	local KFPawn_ZedMatriarch KFPMAT;

	local float CollidingRadius;

	CollidingRadius = CylinderComponent.CollisionRadius;

/*
	foreach CollidingActors( class'KFPawn_Monster', KFP, CollidingRadius ) //, Location, true,,
	{
		// if(WorldInfo.NetMode == NM_Standalone || Instigator.Role == Role_AutonomousProxy || (Instigator.Role == ROLE_Authority && WorldInfo.NetMode == NM_ListenServer) || KFP.IsAliveAndWell() )
		if( WorldInfo.NetMode != NM_DedicatedServer && KFP.IsAliveAndWell() )
		{
			// SpawnEmitterCustomLifetime
			// SpawnEmitterMeshAttachment
			// SpawnEmitter
	
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFP.Mesh, 'Head', 		 	true );
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFP.Mesh, 'RightForearm',	true );
			WeakpointSmallEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFP.Mesh, 'LeftLeg', 	 	true );
	
	    	WeakpointSmallEffectPSCs[0].SetAbsolute(false, true, true);
	    	WeakpointSmallEffectPSCs[1].SetAbsolute(false, true, true);
	    	WeakpointSmallEffectPSCs[2].SetAbsolute(false, true, true);
		}
		else if( KFP.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpoWeakpointSmallEffectintEffect, KFP.Mesh, 'RightForearm', true );
		}
	}
*/

	// Spawn FX for each ZED base

	foreach CollidingActors( class'KFPawn_ZedClot', KFPCL, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPCL.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPCL.Mesh, 'Head', 		true );
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPCL.Mesh, 'RightForearm', true );
			WeakpointSmallEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPCL.Mesh, 'LeftLeg', 		true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedCrawler', KFPCR, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPCR.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPCR.Mesh, 'Head', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedStalker', KFPST, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPST.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPST.Mesh, 'Head', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedGorefast', KFPGF, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPGF.IsAliveAndWell() && KFPGF.IsA('KFPawn_ZedGorefast') )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPGF.Mesh, 'Head', 		true );
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPGF.Mesh, 'RightForearm', true );
			WeakpointSmallEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPGF.Mesh, 'LeftLeg', 		true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedBloat', KFPB, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPB.IsAliveAndWell() )
		{
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPB.Mesh, 'Head', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedBloatKingSubspawn', KFPBS, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPBS.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPBS.Mesh, 'Head', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedDAR', KFPD, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPD.IsAliveAndWell() )
		{
			WeakpointEDARChestEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointEDARChestEffect, KFPD.Mesh, 'FX_Armor_Chest', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedHusk', KFPHU, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPHU.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPHU.Mesh, 'Head', 			true );
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPHU.Mesh, 'RightForearm', 	true );
			WeakpointSmallEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPHU.Mesh, 'LeftLeg', 	    	true );
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, 	KFPHU.Mesh, 'WeakPointSocket1', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedSiren', KFPSR, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPSR.IsAliveAndWell() )
		{
			WeakpointSmallEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPSR.Mesh, 'Head',    true );
			WeakpointSmallEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointSmallEffect, KFPSR.Mesh, 'LeftLeg', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedScrake', KFPSC, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPSC.IsAliveAndWell() )
		{
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPSC.Mesh, 'Head',    true );
			WeakpointBigEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPSC.Mesh, 'LeftLeg', true );
		}
	}

	foreach CollidingActors( class'KFPawn_ZedFleshpound', KFPFP, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPFP.IsAliveAndWell() )
		{
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPFP.Mesh, 'Head',    			true );
			WeakpointBigEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPFP.Mesh, 'LeftLeg', 			true );
			WeakpointBigEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPFP.Mesh, 'WeakPointSocket1', true );
		}
	}

	// Bosses (King Fleshpound and Abomination are above)

	foreach CollidingActors( class'KFPawn_ZedHans', KFPHA, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPHA.IsAliveAndWell() )
		{
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPHA.Mesh, 'Head', 			true );
			WeakpointBigEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPHA.Mesh, 'RightForearm', 	true );
			WeakpointBigEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPHA.Mesh, 'LeftLeg', 			true );
			WeakpointBigEffectPSCs[3] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPHA.Mesh, 'WeakPointSocket1', true );
		}
	}
	
	foreach CollidingActors( class'KFPawn_ZedPatriarch', KFPPAT, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPPAT.IsAliveAndWell() )
		{
			WeakpointBigEffectPSCs[0] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPPAT.Mesh, 'Head', 		 true );
			WeakpointBigEffectPSCs[1] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPPAT.Mesh, 'RightForearm', true );
			WeakpointBigEffectPSCs[2] = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointBigEffect, KFPPAT.Mesh, 'RightLeg', 	 true );
		}
	}
	
	foreach CollidingActors( class'KFPawn_ZedMatriarch', KFPMAT, CollidingRadius )
	{
		if( WorldInfo.NetMode != NM_DedicatedServer && KFPMAT.IsAliveAndWell() )
		{
			WeakpointMatriarchHeadEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointMatriarchHeadEffect, 	KFPMAT.Mesh, 'Driver_Head',  true );
			WeakpointMatriarchCannonEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( WeakpointMatriarchCannonEffect, KFPMAT.Mesh, 'LeftHandMain', true );
		}
	}
}

// Removes weakpoint FX when ZED leaves the radius
event UnTouch(Actor Other)
{
    super.UnTouch(Other);

    // Small FX

	if (WeakpointSmallEffectPSCs[0] != None && WeakpointSmallEffectPSCs[0].bIsActive)
    {
        WeakpointSmallEffectPSCs[0].DeactivateSystem();
    }
    if (WeakpointSmallEffectPSCs[1] != None && WeakpointSmallEffectPSCs[1].bIsActive)
    {
        WeakpointSmallEffectPSCs[1].DeactivateSystem();
    }
    if (WeakpointSmallEffectPSCs[2] != None && WeakpointSmallEffectPSCs[2].bIsActive)
    {
        WeakpointSmallEffectPSCs[2].DeactivateSystem();
    }
    if (WeakpointSmallEffectPSCs[3] != None && WeakpointSmallEffectPSCs[3].bIsActive)
    {
        WeakpointSmallEffectPSCs[3].DeactivateSystem();
    }

    // Big FX

    if (WeakpointBigEffectPSCs[0] != None && WeakpointBigEffectPSCs[0].bIsActive)
    {
        WeakpointBigEffectPSCs[0].DeactivateSystem();
    }
    if (WeakpointBigEffectPSCs[1] != None && WeakpointBigEffectPSCs[1].bIsActive)
    {
        WeakpointBigEffectPSCs[1].DeactivateSystem();
    }
    if (WeakpointBigEffectPSCs[2] != None && WeakpointBigEffectPSCs[2].bIsActive)
    {
        WeakpointBigEffectPSCs[2].DeactivateSystem();
    }
    if (WeakpointBigEffectPSCs[3] != None && WeakpointBigEffectPSCs[3].bIsActive)
    {
        WeakpointBigEffectPSCs[3].DeactivateSystem();
    }

	// Misc FX

    if (WeakpointMatriarchHeadEffectPSC != None && WeakpointMatriarchHeadEffectPSC.bIsActive)
    {
        WeakpointMatriarchHeadEffectPSC.DeactivateSystem();
    }
    if (WeakpointMatriarchCannonEffectPSC != None && WeakpointMatriarchCannonEffectPSC.bIsActive)
    {
        WeakpointMatriarchCannonEffectPSC.DeactivateSystem();
    }
    
    if (WeakpointEDARChestEffectPSC != None && WeakpointEDARChestEffectPSC.bIsActive)
    {
        WeakpointEDARChestEffectPSC.DeactivateSystem();
    }
}

defaultproperties
{
	bHidden=false
	bStatic=false
	bNoDelete=false
	bProjTarget=false
	AITriggerDelay=0

	WeakpointFXLifetime=139 // lol

	// TouchSoundEvent=AkEvent'WW_ENV_HellmarkStation.Play_KFTrigger_Activation'

    WeakpointSmallEffect=ParticleSystem'DROW3_EMIT.FX_Weakpoint_Small'
    WeakpointBigEffect=ParticleSystem'DROW3_EMIT.FX_Weakpoint_Big'

	// Misc FX

    WeakpointMatriarchHeadEffect=ParticleSystem'DROW3_EMIT.FX_Weakpoint_Matriarch_Head'
    WeakpointMatriarchCannonEffect=ParticleSystem'DROW3_EMIT.FX_Weakpoint_Matriarch_Head'

    WeakpointEDARChestEffect=ParticleSystem'DROW3_EMIT.FX_Weakpoint_EDAR_Chest'

    // Drawns a sprite on spawn (disable when finished Sprite=none)
	Begin Object Name=Sprite
		Sprite=none //Texture2D'EditorResources.S_Trigger'
		HiddenGame=False
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Triggers"
	End Object
	Components.Add(Sprite)

	Begin Object Name=CollisionCylinder
		CollisionRadius=2000
		CollisionHeight=2000
	End Object
}