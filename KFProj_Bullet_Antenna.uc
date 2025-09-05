class KFProj_Bullet_Antenna extends KFProj_Bullet
	hidedropdown;
	
/*
var transient ParticleSystemComponent ParticleEffectPSC;
var ParticleSystem ParticleEffect;

var Controller OriginalOwnerController;
var float Radius;
var int ZapDamage;

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	local KFPawn_Monster Victim;
	local int TotalDamage;
	local TraceHitInfo HitInfo;

	foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
	{
		if( Victim.IsAliveAndWell() )
		{
			if ( ZapDamage > 0 )
			{
				ParticleEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( ParticleEffect, Victim.Mesh, 'Head', true );
				ParticleEffectPSC.SetAbsolute(false, true, true);

				TotalDamage = ZapDamage * UpgradeDamageMod;
				Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
			}
		}
	}

	Super.ProcessTouch(Other, HitLocation, HitNormal);
}
*/

/*
simulated protected function StopSimulating()
{
	local KFPawn_Monster Victim;
	local int TotalDamage;
	local TraceHitInfo HitInfo;

	foreach CollidingActors(class'KFPawn_Monster', Victim, Radius)
	{
		if( Victim.IsAliveAndWell() )
		{
			if ( ZapDamage > 0 )
			{
				ParticleEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment( ParticleEffect, Victim.Mesh, 'Head', true );
				ParticleEffectPSC.SetAbsolute(false, true, true);

				TotalDamage = ZapDamage * UpgradeDamageMod;
				Victim.TakeDamage(TotalDamage, OriginalOwnerController, Victim.Mesh.GetBoneLocation('Spine'), vect(0,0,0), class'KFDT_EMP_Lodestar', HitInfo, self); //Victim.Location
			}
		}
	}

	Super.StopSimulating();
}
*/

defaultproperties
{
	MaxSpeed=22500
	Speed=22500

	// PostExplosionLifetime=1

    // ParticleEffect=ParticleSystem'DROW3_EMIT.FX_Lightning_Hit'
	// Radius=600
	// ZapDamage=110

	DamageRadius=0

	// ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	// ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	
	ProjFlightTemplate=ParticleSystem'DROW3_EMIT.FX_MuzzleFlash_DROW3_Null'
	ProjFlightTemplateZedTime=ParticleSystem'DROW3_EMIT.FX_Kruton9000_Tracer_ZedTime'

	ImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Heavy_bullet_impact'
}