class KFWeapActor_Hemoinitiative_Tube extends Actor;

//Visual tube mesh that embeds into the enemy
var() StaticMeshComponent TubeMesh;

//Lifetime until destroy is called
// var float Lifetime;

//Size in the X direction - @TODO - get this at runtime
// var float TubeLength;

//Destroy Delay
var float DestroyDelay;
// var bool bStopTick;

event PostBeginPlay()
{
    super.PostBeginPlay();

    // Lifetime = class'KFDT_Bleeding_Hemogoblin'.default.DoT_Duration;
    SetTimer(DestroyDelay, false, nameof(TearDown));
}

function TearDown()
{
	Destroy();

	// bStopTick = true;

	//Because Mark wants his sound things to fade
	// SetTimer(DestroyDelay, false, nameof(ActualDestroy));
}

// function ActualDestroy()
// {
	// Destroy();
// }

// event Tick(float DeltaTime)
// {
//     local Vector NewRelativeLocation;
//     super.Tick(DeltaTime);

// 	if (!bStopTick)
// 	{
// 		//Push the actor into the body based on relative rotation
// 		NewRelativeLocation = RelativeLocation + (Vector(RelativeRotation) * (TubeLength / Lifetime) * DeltaTime);
// 		SetRelativeLocation(NewRelativeLocation);
// 	}
// }

defaultproperties
{
    Begin Object Class=StaticMeshComponent Name=Mesh0
        StaticMesh=StaticMesh'WEP_Hemoinitiative_MESH.FX_Hemoinitiative_Projectile_Mesh'
    End Object
    Components.Add(Mesh0)
    TubeMesh=Mesh0

    // TubeLength=10

	// bStopTick=false
	DestroyDelay=10.0
}