class KFDroppedPickup_LootBeam_Uncommon_DROW3 extends KFDroppedPickup;

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

defaultproperties
{
	LootBeamFX=ParticleSystem'DROW3_EMIT.FX_LootBeam_Uncommon_DROW3'
}