class KFExplosion_Hemoinitiative extends KFExplosionActorLingering;

var KFTrigger_Shield ShieldTrigger;
var() float ShieldLifetime;

simulated function PostBeginPlay()
{
	if (ShieldTrigger == none)
	{
		ShieldTrigger = Spawn(class'KFTrigger_Shield', self);
	}

	if( Role == ROLE_Authority )
	{
		SetTimer(ShieldLifetime, false, nameof(Timer_DestroyShield), self);
	}

	// SpawnFriendly();

	super.PostBeginPlay();
}

// Destroy the shield
function Timer_DestroyShield()
{
	// DestroyShield();

	if (ShieldTrigger != none)
	{
		ShieldTrigger.Destroy();
		ShieldTrigger = none;
	}
}

// Destroys the shield
// function DestroyShield()
// {
// 	if (ShieldTrigger != none)
// 	{
// 		ShieldTrigger.Destroy();
// 		ShieldTrigger = none;
// 	}
// }

// Destroys the shield if user leaves a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_DestroyShield));
	}
}

/*
simulated function SpawnFriendly(optional float Distance = 0.f)
{
    local class<KFPawn_Monster> MonsterClass;
	local KFPawn ZED;
    local KFPawn_FleshFriend SpawnedActor;
    local vector SpawnLoc;
    local rotator SpawnRot;

    MonsterClass = class<KFPawn_Monster>(DynamicLoadObject("KFPawn_FleshFriend", class'Class'));

    SpawnLoc = Location;

   	SpawnLoc += Distance * vector(Rotation) + vect(0,0,1); // * 25.f;
   	SpawnRot.Yaw = Rotation.Yaw + 32768;

    ZED = Spawn( MonsterClass,,, SpawnLoc, SpawnRot,, false );
	if ( ZED != None )
	{
		ZED.SetPhysics(PHYS_Falling);
		ZED.SpawnDefaultController();
		// if( KFAIController(ZED.Controller) != none )
		// {
		// 	Set team to human team
		// 	KFAIController( ZED.Controller ).SetTeam(0);
		// }
	}

	// This does nothing, but should replicate kills from friendly ZED
	SpawnedActor = Spawn(class'KFPawn_FleshFriend', self);
	if( SpawnedActor != none )
	{
		SpawnedActor.SpawnDefaultController();
	}
}
*/

// Overriden to SetAbsolute
simulated function StartLoopingParticleEffect()
{
	LoopingPSC = new(self) class'ParticleSystemComponent';
	LoopingPSC.SetTemplate( LoopingParticleEffect );
	AttachComponent(LoopingPSC);
	LoopingPSC.SetAbsolute(false, true, false);
}

DefaultProperties
{
	MaxTime=140
	ShieldLifetime=140

	LoopingParticleEffect=ParticleSystem'DROW3_EMIT.FX_Hemoinitiative_Marker'

	// LoopStartEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	// LoopStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'
}