class KFWeapAttach_LardPD4K extends KFWeaponAttachment;

var transient ParticleSystemComponent ChargingPSC;
var ParticleSystem ChargingEffect;
var ParticleSystem ChargedEffect;

var bool bIsCharging;
var bool bIsFullyCharged;

var float StartFireTime;

var int ChargeLevel;

simulated function StartFire()
{
    StartFireTime = WorldInfo.TimeSeconds;
    bIsCharging = true;

    if (ChargingPSC == none)
    {
        ChargingPSC = new(self) class'ParticleSystemComponent';

        if (WeapMesh != none)
        {
            WeapMesh.AttachComponentToSocket(ChargingPSC, 'MuzzleFlash');
        }
        else
        {
            AttachComponent(ChargingPSC);
        }
    }
    else
    {
        ChargingPSC.ActivateSystem();
    }

    if (ChargingPSC != none)
    {
        ChargingPSC.SetTemplate(ChargingEffect);
    }
}

simulated event Tick(float DeltaTime)
{
    local float ChargeRTPC;

    if(bIsCharging && !bIsFullyCharged)
    {
        ChargeRTPC = FMin(class'KFWeap_LardPD4K'.default.MaxChargeTime, WorldInfo.TimeSeconds - StartFireTime) / class'KFWeap_LardPD4K'.default.MaxChargeTime;

        if (ChargeRTPC >= 1.f)
        {
            bIsFullyCharged = true;
            ChargingPSC.SetTemplate(ChargedEffect);
        }
    }

    Super.Tick(DeltaTime);
}

simulated function FirstPersonFireEffects(Weapon W, vector HitLocation)
{
    super.FirstPersonFireEffects(W, HitLocation);

    if (ChargingPSC != none)
    {
        ChargingPSC.DeactivateSystem();
    }
}

simulated function bool ThirdPersonFireEffects(vector HitLocation, KFPawn P, byte ThirdPersonAnimRateByte)
{
    bIsCharging = false;
    bIsFullyCharged = false;

    ChargeLevel = GetChargeFXLevel();

    if (ChargingPSC != none)
    {
        ChargingPSC.DeactivateSystem();
    }

    return Super.ThirdPersonFireEffects(HitLocation, P, ThirdPersonAnimRateByte);
}

// Should generally match up with KFWeap_HuskCannon::GetChargeFXLevel
function int GetChargeFXLevel()
{
    local int MaxCharges;
    local int Charges;

    MaxCharges = int(class'KFWeap_LardPD4K'.default.MaxChargeTime / class'KFWeap_LardPD4K'.default.ValueIncreaseTime);
    Charges = Min((WorldInfo.TimeSeconds - StartFireTime) / class'KFWeap_LardPD4K'.default.ValueIncreaseTime, MaxCharges);

    if (Charges <= 1)
    {
        return 1;
    }
    else if (Charges < MaxCharges)
    {
        return 2;
    }
    else
    {
        return 3;
    }
}

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
    MuzzleFlashTemplate=KFMuzzleFlash'WEP_LardPD4K_ARCH.WEP_LardPD4K_MuzzleFlash'

    ChargingEffect=ParticleSystem'DROW3_EMIT.FX_LardPD4K_Charging'
    ChargedEffect=ParticleSystem'DROW3_EMIT.FX_LardPD4K_Charged'
}