class KFExplosion_Kruton9000 extends KFExplosionActorLingering;

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
	MaxTime=5.1

	LoopingParticleEffect=ParticleSystem'DROW3_EMIT.FX_Kruton9000_GroundEffect'

	// LoopStartEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
	// LoopStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'
}