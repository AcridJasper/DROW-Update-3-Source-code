class KFProj_Bullet_Hemoinitiative extends KFProj_BallisticExplosive
    hidedropdown; //KFProj_Bullet

// var ParticleSystem FriendlyEffect;

// Explosion actor class to use for ground fire when hitting floor
var const protected class<KFExplosionActorLingering> GroundExplosionActorClass;
// Explosion template to use for ground fire
var KFGameExplosion GroundExplosionTemplate;

// How long the ground fire should stick around
var const protected float EffectDuration;
// How often, in seconds, we should apply burn
var const protected float DamageInterval;

var bool bSpawnGroundFire;

replication
{
    if (bNetInitial)
        bSpawnGroundFire;
}

simulated function PostBeginPlay()
{
    local KFWeap_Hemoinitiative Cannon;

    if(Role == ROLE_Authority)
    {
        Cannon = KFWeap_Hemoinitiative(Owner);
        if (Cannon != none)
        {
            bSpawnGroundFire = true;
        }
    }

    super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
    local KFExplosionActorLingering GFExplosionActor;
    local vector GroundExplosionHitNormal;

    if (bHasDisintegrated)
    {
        return;
    }

    if (!bHasExploded && bSpawnGroundFire)
    {
        GroundExplosionHitNormal = HitNormal;

        // Spawn our explosion and set up its parameters
        GFExplosionActor = Spawn(GroundExplosionActorClass, self, , HitLocation + (HitNormal + vect(0,0,200))); // * 200.f), rotator(HitNormal)
        if (GFExplosionActor != None)
        {
            GFExplosionActor.Instigator = Instigator;
            GFExplosionActor.InstigatorController = InstigatorController;

            // These are needed for the decal tracing later in GameExplosionActor.Explode()
            GroundExplosionTemplate.HitLocation = HitLocation;
            GroundExplosionTemplate.HitNormal = GroundExplosionHitNormal;

            // Apply explosion direction
            if (GroundExplosionTemplate.bDirectionalExplosion)
            {
                GroundExplosionHitNormal = GetExplosionDirection(GroundExplosionHitNormal);
            }

            // Set our duration
            // GFExplosionActor.MaxTime = EffectDuration;
            // Boom
            GFExplosionActor.Explode(GroundExplosionTemplate, GroundExplosionHitNormal);
        }
    }

    super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
    local KFPlayerController KFPC;

    local KFPawn_Monster KFP;
    local KFPawn_MonsterBoss KFPB;

    local KFAIController KFAIC;
    local KFAIController KFAICB;

    // local ParticleSystemComponent ParticlePSC;

    KFPC = KFPlayerController(Instigator.Controller);
    KFP = KFPawn_Monster(Other);
    KFPB = KFPawn_MonsterBoss(Other);

    if( KFPawn_MonsterBoss(Other) != none && KFPB.IsAliveAndWell() )
    {
        // Sets bosses to neutral team to not posses them
        KFAIController( KFPB.Controller ).SetTeam(128 /*255*/);

        KFAICB = KFAIController( Other );
        if( KFAICB != none )
        {
            KFAICB.ResetKFAIC();
            KFAICB.SetEnemy( KFP );
        }

        // PlayStunned();
        // KFPB.DoSpecialMove(SM_Stunned);

        // Play custom message when boss is hit
        KFPC.ReceiveLocalizedMessage(class'KFLocalMessage_DROW3_RED', GMT_BossesCantJoinTeam);
    }
    else if( KFPawn_Monster(Other) != none && KFP.IsAliveAndWell() )
    {
        // Sets ZEDs but not bosses to join human team
        KFAIController( KFP.Controller ).SetTeam(0);

        KFAIC = KFAIController( Other );
        if( KFAIC != none )
        {
            KFAIC.ResetKFAIC();
            KFAIC.SetEnemy( KFP );
        }

        // PlayStunned();
        // KFP.DoSpecialMove(SM_Stunned);

        // Play custom message when ZED is hit
        KFPC.ReceiveLocalizedMessage(class'KFLocalMessage_DROW3_GREEN', GMT_FriendlyZEDJoined);
    }

/*
    if(KFP != none)
    {
        if(KFPawn_Monster(Other).IsDoingSpecialMove(SM_None))
        {            
            ParticlePSC = KFP.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(FriendlyEffect, KFP.Mesh, 'Hips', true);
            ParticlePSC.SetAbsolute(false, true, true);
        }

        if(KFPawn_Monster(Other).IsDoingSpecialMove(SM_DeathAnim))
        {            
            ParticlePSC.DeactivateSystem();
            DetachComponent(ParticlePSC);
            WorldInfo.MyEmitterPool.OnParticleSystemFinished(ParticlePSC);
            ParticlePSC = None;
        }

        else if(KFPawn_Monster(Other).IsDoingSpecialMove(SM_DeathAnim)) SM_Knockdown
        {            
            ParticlePSC.DeactivateSystem();
            DetachComponent(ParticlePSC);
            WorldInfo.MyEmitterPool.OnParticleSystemFinished(ParticlePSC);
            ParticlePSC = None;
        }
    }
*/

    Super.ProcessTouch(Other, HitLocation, HitNormal);
}

/*
function PlayStunned()
{
    local KFPawn_Monster P;

    Foreach WorldInfo.AllPawns(class'KFPawn_Monster', P)
    {
        if( P.IsAliveAndWell() )
        {
            // transition to the Stunned state
            P.DoSpecialMove(SM_Stunned);
        }
    }
}
*/

defaultproperties
{
    MaxSpeed=30000
    Speed=30000

    DamageRadius=0

    // TouchTimeThreshhold=0.0

    // FriendlyEffect=ParticleSystem'DTest_EMIT.FX_SuperShield'

    // Ground effect
    // EffectDuration=25.0f
    GroundExplosionActorClass=class'KFExplosion_Hemoinitiative'

    bCollideComplex=false    // Ignore simple collision on StaticMeshes, and collide per poly

    Begin Object Name=CollisionCylinder
        CollisionRadius=30.f
        CollisionHeight=30.f
        BlockNonZeroExtent=false
    End Object

    ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_Hemoinitiative_Projectile'
    ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Hemoinitiative_Projectile'
    
    // explosion ( just for stunning ZEDs )
    Begin Object Class=KFGameExplosion Name=ExploTemplate0
        Damage=1
        DamageRadius=1000 //stuns
        DamageFalloffExponent=0.1f
        DamageDelay=0.f
        MyDamageType=class'KFDT_Explosive_Hemoinitiative'

        MomentumTransferScale=1
        bIgnoreInstigator=true

        // Damage Effects
        KnockDownStrength=150
        FractureMeshRadius=200.0
        FracturePartVel=500.0
        ExplosionSound=AkEvent'WW_ZED_Patriarch.Play_Mortar_Beeps'
        // ExplosionEffects=KFImpactEffectInfo'WEP_Hemoinitiative_ARCH.Hemoinitiative_Explosion_Marker'

        // Camera Shake
        CamShake=none
    End Object
    ExplosionTemplate=ExploTemplate0
}