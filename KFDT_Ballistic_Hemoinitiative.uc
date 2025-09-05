class KFDT_Ballistic_Hemoinitiative extends KFDT_Ballistic_Rifle
    abstract
    hidedropdown;

// var ParticleSystem FriendlyEffect;

var ParticleSystem ForceImpactEffect;
var AkEvent ForceImpactSound;

//Visual class to attach to the victim when impact occurs
var class<Actor> TubeAttachClass;

static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
    if( super.CanDismemberHitZone( InHitZoneName ) )
    {
        return true;
    }

    switch ( InHitZoneName )
    {
    case 'lupperarm':
    case 'rupperarm':
    case 'chest':
    case 'heart':
        return true;
    }

    return false;
}

// Allows the damage type to customize exactly which hit zones it can dismember while the zed is alive
static simulated function bool CanDismemberHitZoneWhileAlive(name InHitZoneName)
{
    return false;
}

static function PlayImpactHitEffects(KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator)
{
    local KFSkinTypeEffects SkinType;

    local Actor TubeAttachment;
    local Vector StickLocation;
    local Rotator StickRotation;
    local name BoneName;
    local WorldInfo WI;
    local KFPawn RetracePawn;
    local Vector RetraceLocation;
    local Vector RetraceNormal;
    local TraceHitInfo HitInfo;

    // local ParticleSystemComponent ParticlePSC;

    // ParticlePSC = P.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(default.FriendlyEffect, P.Mesh, 'Hips', true);
    // ParticlePSC.SetAbsolute(false, true, true);

    WI = class'WorldInfo'.static.GetWorldInfo();
    if (P != none && HitZoneIndex > 0 && HitZoneIndex < P.HitZones.Length && WI != none && WI.NetMode != NM_DedicatedServer)
    {
        //Don't play additional FX here if we aren't attaching a new tube, let its built in blood spray handle things
        //super.PlayImpactHitEffects(P, HitLocation, HitDirection, HitZoneIndex, HitInstigator);

        //Retrace to get valid hit normal
        foreach WI.TraceActors(class'KFPawn', RetracePawn, RetraceLocation, RetraceNormal, HitLocation + HitDirection * 50, HitLocation - HitDirection * 50, vect(0, 0, 0), HitInfo, 1) //TRACEFLAG_Bullet
        {
            if (P == RetracePawn)
            {
                HitLocation = RetraceLocation;
                HitDirection = -RetraceNormal;
                break;
            }
        }

        TubeAttachment = P.Spawn(default.TubeAttachClass, P, , HitLocation, Rotator(HitDirection));
        if (TubeAttachment != none)
        {
            BoneName = P.HitZones[HitZoneIndex].BoneName;
            P.Mesh.TransformToBoneSpace(BoneName, TubeAttachment.Location, TubeAttachment.Rotation, StickLocation, StickRotation);
            TubeAttachment.SetBase(P, , P.Mesh, BoneName);
            TubeAttachment.SetRelativeLocation(StickLocation);
            TubeAttachment.SetRelativeRotation(StickRotation);
        }
    }

    if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
    {
        SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

        if (SkinType != none)
        {
            SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
            SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
        }
    }
}

    // if ( P.Health <= 0 )
    // {
    //     if (ParticlePSC != none)
    //     {
    //         ParticlePSC.DeactivateSystem();
    //     }
    // }
    
defaultproperties
{
    KDamageImpulse=3000
    KDeathUpKick=800
    KDeathVel=500

    // StunPower=300
    GunHitPower=0

    // FriendlyEffect=ParticleSystem''

    ForceImpactEffect=ParticleSystem'WEP_HVStormCannon_EMIT.FX_HVStormCannon_Impact_Zed'
    ForceImpactSound=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Impact'

    TubeAttachClass=class'KFWeapActor_Hemoinitiative_Tube'

    WeaponDef=class'KFWeapDef_Hemoinitiative'
    ModifierPerkList(0)=class'KFPerk_FieldMedic'
}