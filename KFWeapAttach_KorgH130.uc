class KFWeapAttach_KorgH130 extends KFWeaponAttachment;

/*
`define BARREL_MIC_INDEX 0

var const float BarrelHeatPerProjectile;
var const float MaxBarrelHeat;
var const float BarrelCooldownRate;
var transient float CurrentBarrelHeat;
var transient float LastBarrelHeat;

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();

    // Force start with "Glow_Intensity" of 0.0f
    LastBarrelHeat = MaxBarrelHeat;
    ChangeBarrelMaterial();
}

simulated function CauseMuzzleFlash(byte FiringMode)
{
    if (MuzzleFlash == None && MuzzleFlashTemplate != None)
    {
        AttachMuzzleFlash();
    }

    if (MuzzleFlash != None )
    {
        MuzzleFlash.CauseMuzzleFlash(FiringMode);
        if ( MuzzleFlash.bAutoActivateShellEject )
        {
            MuzzleFlash.CauseShellEject();
        }
    }

    CurrentBarrelHeat = fmin(CurrentBarrelHeat + BarrelHeatPerProjectile, MaxBarrelHeat);
    ChangeBarrelMaterial();
}

simulated function ChangeBarrelMaterial()
{
    if( CurrentBarrelHeat != LastBarrelHeat )
    {
        if( WeaponMIC == None && WeapMesh != None )
        {
            WeaponMIC = WeapMesh.CreateAndSetMaterialInstanceConstant(`BARREL_MIC_INDEX);
            LastBarrelHeat = CurrentBarrelHeat; 
        }
    }

    WeaponMIC.SetScalarParameterValue('Glow_Intensity', CurrentBarrelHeat);
}

simulated event Tick( float DeltaTime )
{
    // Super.Tick(DeltaTime);

    CurrentBarrelHeat = fmax(CurrentBarrelHeat - BarrelCooldownRate * DeltaTime, 0.0f);
    ChangeBarrelMaterial();
}
*/

// Spawn tracer effects for this weapon
simulated function SpawnTracer(vector EffectLocation, vector HitLocation)
{
    local ParticleSystemComponent PSC;
    local vector Dir;
    local float DistSQ;
    local float TracerDuration;
    local KFTracerInfo TracerInfo;

    if (Instigator == None || Instigator.FiringMode >= TracerInfos.Length)
    {
        return;
    }

    TracerInfo = TracerInfos[Instigator.FiringMode];
    if (((`NotInZedTime(self) && TracerInfo.bDoTracerDuringNormalTime)
        || (`IsInZedTime(self) && TracerInfo.bDoTracerDuringZedTime))
        && TracerInfo.TracerTemplate != none )
    {
        Dir = HitLocation - EffectLocation;
        DistSQ = VSizeSq(Dir);
        if (DistSQ > TracerInfo.MinTracerEffectDistanceSquared)
        {
            // Lifetime scales based on the distance from the impact point. Subtract a frame so it doesn't clip.
            TracerDuration = fMin((Sqrt(DistSQ) - 100.f) / TracerInfo.TracerVelocity, 1.f);
            if (TracerDuration > 0.f)
            {
                PSC = WorldInfo.MyEmitterPool.SpawnEmitter(TracerInfo.TracerTemplate, EffectLocation, rotator(Dir));
                PSC.SetFloatParameter('Tracer_Lifetime', TracerDuration);
                PSC.SetVectorParameter('Shotend', HitLocation);
            }
        }
    }
}

defaultproperties
{
/*
    MaxBarrelHeat=1.5f
    BarrelHeatPerProjectile=0.2f
    BarrelCooldownRate=1.2f
    
    CurrentBarrelHeat=0.0f
    LastBarrelHeat=0.0f
*/
}